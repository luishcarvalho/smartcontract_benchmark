



















pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/BoringMath.sol";
import "./interfaces/IOracle.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./interfaces/IMasterContract.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IWETH.sol";





contract LendingPair is ERC20, Ownable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;


    IBentoBox public immutable bentoBox;
    LendingPair public immutable masterContract;
    address public feeTo;
    address public dev;
    mapping(ISwapper => bool) public swappers;



    IERC20 public collateral;
    IERC20 public asset;
    IOracle public oracle;
    bytes public oracleData;


    mapping(address => uint256) public userCollateralAmount;

    mapping(address => uint256) public userBorrowFraction;

    struct TokenTotals {
        uint128 amount;
        uint128 fraction;
    }


    uint256 public totalCollateralAmount;
    TokenTotals public totalAsset;
    TokenTotals public totalBorrow;


    function totalSupply() public view returns(uint256) {
        return totalAsset.fraction;
    }


    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 interestPerBlock;
        uint64 lastBlockAccrued;
        uint128 feesPendingAmount;
    }
    AccrueInfo public accrueInfo;


    function symbol() public view returns(string memory) {
        (bool success, bytes memory data) = address(asset).staticcall(abi.encodeWithSelector(0x95d89b41));
        string memory assetSymbol = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        (success, data) = address(collateral).staticcall(abi.encodeWithSelector(0x95d89b41));
        string memory collateralSymbol = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        return string(abi.encodePacked("bm", collateralSymbol, ">", assetSymbol, "-", oracle.symbol(oracleData)));
    }

    function name() public view returns(string memory) {
        (bool success, bytes memory data) = address(asset).staticcall(abi.encodeWithSelector(0x06fdde03));
        string memory assetName = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        (success, data) = address(collateral).staticcall(abi.encodeWithSelector(0x06fdde03));
        string memory collateralName = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        return string(abi.encodePacked("Bento Med Risk ", collateralName, ">", assetName, "-", oracle.symbol(oracleData)));
    }

    function decimals() public view returns (uint8) {
        (bool success, bytes memory data) = address(asset).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint256 accruedAmount, uint256 feeAmount, uint256 rate, uint256 utilization);
    event LogAddCollateral(address indexed user, uint256 amount);
    event LogAddAsset(address indexed user, uint256 amount, uint256 fraction);
    event LogAddBorrow(address indexed user, uint256 amount, uint256 fraction);
    event LogRemoveCollateral(address indexed user, uint256 amount);
    event LogRemoveAsset(address indexed user, uint256 amount, uint256 fraction);
    event LogRemoveBorrow(address indexed user, uint256 amount, uint256 fraction);
    event LogFeeTo(address indexed newFeeTo);
    event LogDev(address indexed newDev);
    event LogWithdrawFees();

    constructor(IBentoBox bentoBox_) public {
        bentoBox = bentoBox_;
        masterContract = LendingPair(this);
        dev = msg.sender;
        feeTo = msg.sender;
        emit LogDev(msg.sender);
        emit LogFeeTo(msg.sender);
    }


    uint256 public constant CLOSED_COLLATERIZATION_RATE = 75000;
    uint256 public constant OPEN_COLLATERIZATION_RATE = 77000;
    uint256 public constant MINIMUM_TARGET_UTILIZATION = 7e17;
    uint256 public constant MAXIMUM_TARGET_UTILIZATION = 8e17;

    uint256 public constant STARTING_INTEREST_PER_BLOCK = 4566210045;
    uint256 public constant MINIMUM_INTEREST_PER_BLOCK = 1141552511;
    uint256 public constant MAXIMUM_INTEREST_PER_BLOCK = 4566210045000;
    uint256 public constant INTEREST_ELASTICITY = 2000e36;

    uint256 public constant LIQUIDATION_MULTIPLIER = 112000;


    uint256 public constant PROTOCOL_FEE = 10000;
    uint256 public constant DEV_FEE = 10000;
    uint256 public constant BORROW_OPENING_FEE = 50;


    function init(bytes calldata data) public override {
        require(address(collateral) == address(0), "LendingPair: already initialized");
        (collateral, asset, oracle, oracleData) = abi.decode(data, (IERC20, IERC20, IOracle, bytes));

        accrueInfo.interestPerBlock = uint64(STARTING_INTEREST_PER_BLOCK);
        updateExchangeRate();
    }

    function getInitData(IERC20 collateral_, IERC20 asset_, IOracle oracle_, bytes calldata oracleData_) public pure returns(bytes memory data) {
        return abi.encode(collateral_, asset_, oracle_, oracleData_);
    }


    function accrue() public {
        AccrueInfo memory info = accrueInfo;

        uint256 blocks = block.number - info.lastBlockAccrued;
        if (blocks == 0) {return;}
        info.lastBlockAccrued = uint64(block.number);

        uint256 extraAmount;
        uint256 feeAmount;

        TokenTotals memory _totalBorrow = totalBorrow;
        TokenTotals memory _totalAsset = totalAsset;
        if (_totalBorrow.amount > 0) {

            extraAmount = uint256(_totalBorrow.amount).mul(info.interestPerBlock).mul(blocks) / 1e18;
            feeAmount = extraAmount.mul(PROTOCOL_FEE) / 1e5;
            _totalBorrow.amount = _totalBorrow.amount.add(extraAmount.to128());
            totalBorrow = _totalBorrow;
            _totalAsset.amount = _totalAsset.amount.add(extraAmount.sub(feeAmount).to128());
            totalAsset = _totalAsset;
            info.feesPendingAmount = info.feesPendingAmount.add(feeAmount.to128());
        }

        if (_totalAsset.amount == 0) {
            if (info.interestPerBlock != STARTING_INTEREST_PER_BLOCK) {
                info.interestPerBlock = uint64(STARTING_INTEREST_PER_BLOCK);
                emit LogAccrue(extraAmount, feeAmount, STARTING_INTEREST_PER_BLOCK, 0);
            }
            accrueInfo = info; return;
        }


        uint256 utilization = uint256(_totalBorrow.amount).mul(1e18) / _totalAsset.amount;
        uint256 newInterestPerBlock;
        if (utilization < MINIMUM_TARGET_UTILIZATION) {
            uint256 underFactor = MINIMUM_TARGET_UTILIZATION.sub(utilization).mul(1e18) / MINIMUM_TARGET_UTILIZATION;
            uint256 scale = INTEREST_ELASTICITY.add(underFactor.mul(underFactor).mul(blocks));
            newInterestPerBlock = uint256(info.interestPerBlock).mul(INTEREST_ELASTICITY) / scale;
            if (newInterestPerBlock < MINIMUM_INTEREST_PER_BLOCK) {newInterestPerBlock = MINIMUM_INTEREST_PER_BLOCK;}
       } else if (utilization > MAXIMUM_TARGET_UTILIZATION) {
            uint256 overFactor = utilization.sub(MAXIMUM_TARGET_UTILIZATION).mul(1e18) / uint256(1e18).sub(MAXIMUM_TARGET_UTILIZATION);
            uint256 scale = INTEREST_ELASTICITY.add(overFactor.mul(overFactor).mul(blocks));
            newInterestPerBlock = uint256(info.interestPerBlock).mul(scale) / INTEREST_ELASTICITY;
            if (newInterestPerBlock > MAXIMUM_INTEREST_PER_BLOCK) {newInterestPerBlock = MAXIMUM_INTEREST_PER_BLOCK;}
        } else {
            emit LogAccrue(extraAmount, feeAmount, info.interestPerBlock, utilization);
            accrueInfo = info; return;
        }

        info.interestPerBlock = uint64(newInterestPerBlock);
        emit LogAccrue(extraAmount, feeAmount, newInterestPerBlock, utilization);
        accrueInfo = info;
    }



    function isSolvent(address user, bool open) public view returns (bool) {

        if (userBorrowFraction[user] == 0) return true;
        if (totalCollateralAmount == 0) return false;

        TokenTotals memory _totalBorrow = totalBorrow;

        return userCollateralAmount[user].mul(1e13).mul(open ? OPEN_COLLATERIZATION_RATE : CLOSED_COLLATERIZATION_RATE)
            >= (userBorrowFraction[user].mul(_totalBorrow.amount) / _totalBorrow.fraction).mul(exchangeRate);
    }

    function peekExchangeRate() public view returns (bool, uint256) {
        return oracle.peek(oracleData);
    }


    function updateExchangeRate() public returns (uint256) {
        (bool success, uint256 rate) = oracle.get(oracleData);


        if (success) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        }
        return exchangeRate;
    }


    function _addCollateralAmount(address user, uint256 amount) private {

        userCollateralAmount[user] = userCollateralAmount[user].add(amount);

        totalCollateralAmount = totalCollateralAmount.add(amount);
        emit LogAddCollateral(msg.sender, amount);
    }


    function _addAssetAmount(address user, uint256 amount) private {
        TokenTotals memory _totalAsset = totalAsset;

        uint256 newFraction = _totalAsset.fraction == 0 ? amount : amount.mul(_totalAsset.fraction) / _totalAsset.amount;

        balanceOf[user] = balanceOf[user].add(newFraction);

        _totalAsset.fraction = _totalAsset.fraction.add(newFraction.to128());

        _totalAsset.amount = _totalAsset.amount.add(amount.to128());
        totalAsset = _totalAsset;
        emit LogAddAsset(msg.sender, amount, newFraction);
    }


    function _addBorrowAmount(address user, uint256 amount) private {
        TokenTotals memory _totalBorrow = totalBorrow;

        uint256 newFraction = _totalBorrow.fraction == 0 ? amount : amount.mul(_totalBorrow.fraction) / _totalBorrow.amount;

        userBorrowFraction[user] = userBorrowFraction[user].add(newFraction);

        _totalBorrow.fraction = _totalBorrow.fraction.add(newFraction.to128());

        _totalBorrow.amount = _totalBorrow.amount.add(amount.to128());
        totalBorrow = _totalBorrow;
        emit LogAddBorrow(msg.sender, amount, newFraction);
    }


    function _removeCollateralAmount(address user, uint256 amount) private {

        userCollateralAmount[user] = userCollateralAmount[user].sub(amount);

        totalCollateralAmount = totalCollateralAmount.sub(amount);
        emit LogRemoveCollateral(msg.sender, amount);
    }


    function _removeAssetFraction(address user, uint256 fraction) private returns (uint256 amount) {
        TokenTotals memory _totalAsset = totalAsset;

        balanceOf[user] = balanceOf[user].sub(fraction);

        amount = fraction.mul(_totalAsset.amount) / _totalAsset.fraction;

        _totalAsset.fraction = _totalAsset.fraction.sub(fraction.to128());

        _totalAsset.amount = _totalAsset.amount.sub(amount.to128());
        totalAsset = _totalAsset;
        emit LogRemoveAsset(msg.sender, amount, fraction);
    }


    function _removeBorrowFraction(address user, uint256 fraction) private returns (uint256 amount) {
        TokenTotals memory _totalBorrow = totalBorrow;

        userBorrowFraction[user] = userBorrowFraction[user].sub(fraction);

        amount = fraction.mul(_totalBorrow.amount) / _totalBorrow.fraction;

        _totalBorrow.fraction = _totalBorrow.fraction.sub(fraction.to128());

        _totalBorrow.amount = _totalBorrow.amount.sub(amount.to128());
        totalBorrow = _totalBorrow;
        emit LogRemoveBorrow(msg.sender, amount, fraction);
    }


    function addCollateral(uint256 amount) public payable { addCollateralTo(amount, msg.sender); }
    function addCollateralTo(uint256 amount, address to) public payable {
        _addCollateralAmount(to, amount);
        bentoBox.deposit{value: msg.value}(collateral, msg.sender, amount);
    }

    function addCollateralFromBento(uint256 amount) public { addCollateralFromBentoTo(amount, msg.sender); }
    function addCollateralFromBentoTo(uint256 amount, address to) public {
        _addCollateralAmount(to, amount);
        bentoBox.transferFrom(collateral, msg.sender, address(this), amount);
    }


    function addAsset(uint256 amount) public payable { addAssetTo(amount, msg.sender); }
    function addAssetTo(uint256 amount, address to) public payable {

        accrue();
        _addAssetAmount(to, amount);
        bentoBox.deposit{value: msg.value}(asset, msg.sender, amount);
    }

    function addAssetFromBento(uint256 amount) public payable { addAssetFromBentoTo(amount, msg.sender); }
    function addAssetFromBentoTo(uint256 amount, address to) public payable {

        accrue();
        _addAssetAmount(to, amount);
        bentoBox.transferFrom(asset, msg.sender, address(this), amount);
    }


    function removeCollateral(uint256 amount, address to) public {
        accrue();
        _removeCollateralAmount(msg.sender, amount);

        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
        bentoBox.withdraw(collateral, to, amount);
    }

    function removeCollateralToBento(uint256 amount, address to) public {
        accrue();
        _removeCollateralAmount(msg.sender, amount);

        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
        bentoBox.transfer(collateral, to, amount);
    }


    function removeAsset(uint256 fraction, address to) public {

        accrue();
        uint256 amount = _removeAssetFraction(msg.sender, fraction);
        bentoBox.withdraw(asset, to, amount);
    }

    function removeAssetToBento(uint256 fraction, address to) public {

        accrue();
        uint256 amount = _removeAssetFraction(msg.sender, fraction);
        bentoBox.transfer(asset, to, amount);
    }


    function borrow(uint256 amount, address to) public {
        accrue();
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / 1e5;
        _addBorrowAmount(msg.sender, amount.add(feeAmount));
        totalAsset.amount = totalAsset.amount.add(feeAmount.to128());
        bentoBox.withdraw(asset, to, amount);
        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
    }

    function borrowToBento(uint256 amount, address to) public {
        accrue();
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / 1e5;
        _addBorrowAmount(msg.sender, amount.add(feeAmount));
        totalAsset.amount = totalAsset.amount.add(feeAmount.to128());
        bentoBox.transfer(asset, to, amount);
        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
    }


    function repay(uint256 fraction) public { repayFor(fraction, msg.sender); }
    function repayFor(uint256 fraction, address beneficiary) public {
        accrue();
        uint256 amount = _removeBorrowFraction(beneficiary, fraction);
        bentoBox.deposit(asset, msg.sender, amount);
    }

    function repayFromBento(uint256 fraction) public { repayFromBentoTo(fraction, msg.sender); }
    function repayFromBentoTo(uint256 fraction, address beneficiary) public {
        accrue();
        uint256 amount = _removeBorrowFraction(beneficiary, fraction);
        bentoBox.transferFrom(asset, msg.sender, address(this), amount);
    }


    function short(ISwapper swapper, uint256 assetAmount, uint256 minCollateralAmount) public {
        require(masterContract.swappers(swapper), "LendingPair: Invalid swapper");
        accrue();
        _addBorrowAmount(msg.sender, assetAmount);
        bentoBox.transferFrom(asset, address(this), address(swapper), assetAmount);



        swapper.swap(asset, collateral, assetAmount, minCollateralAmount);
        uint256 returnedCollateralAmount = bentoBox.skim(collateral);
        require(returnedCollateralAmount >= minCollateralAmount, "LendingPair: not enough");
        _addCollateralAmount(msg.sender, returnedCollateralAmount);

        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
    }


    function unwind(ISwapper swapper, uint256 borrowFraction, uint256 maxAmountCollateral) public {
        require(masterContract.swappers(swapper), "LendingPair: Invalid swapper");
        accrue();
        bentoBox.transferFrom(collateral, address(this), address(swapper), maxAmountCollateral);

        uint256 borrowAmount = _removeBorrowFraction(msg.sender, borrowFraction);


        uint256 usedAmount = swapper.swapExact(collateral, asset, maxAmountCollateral, borrowAmount, address(this));
        uint256 returnedAssetAmount = bentoBox.skim(asset);
        require(returnedAssetAmount >= borrowAmount, "LendingPair: Not enough");

        _removeCollateralAmount(msg.sender, maxAmountCollateral.sub(usedAmount));

        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
    }


    function liquidate(address[] calldata users, uint256[] calldata borrowFractions, address to, ISwapper swapper, bool open) public {
        accrue();
        updateExchangeRate();

        uint256 allCollateralAmount;
        uint256 allBorrowAmount;
        uint256 allBorrowFraction;
        TokenTotals memory _totalBorrow = totalBorrow;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!isSolvent(user, open)) {

                uint256 borrowFraction = borrowFractions[i];

                uint256 borrowAmount = borrowFraction.mul(_totalBorrow.amount) / _totalBorrow.fraction;

                uint256 collateralAmount = borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(exchangeRate) / 1e23;


                userCollateralAmount[user] = userCollateralAmount[user].sub(collateralAmount);

                userBorrowFraction[user] = userBorrowFraction[user].sub(borrowFraction);
                emit LogRemoveCollateral(user, collateralAmount);
                emit LogRemoveBorrow(user, borrowAmount, borrowFraction);


                allCollateralAmount = allCollateralAmount.add(collateralAmount);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowFraction = allBorrowFraction.add(borrowFraction);
            }
        }
        require(allBorrowAmount != 0, "LendingPair: all are solvent");
        _totalBorrow.amount = _totalBorrow.amount.sub(allBorrowAmount.to128());
        _totalBorrow.fraction = _totalBorrow.fraction.sub(allBorrowFraction.to128());
        totalBorrow = _totalBorrow;
        totalCollateralAmount = totalCollateralAmount.sub(allCollateralAmount);

        if (!open) {

            require(masterContract.swappers(swapper), "LendingPair: Invalid swapper");


            bentoBox.transferFrom(collateral, address(this), address(swapper), allCollateralAmount);

            swapper.swap(collateral, asset, allCollateralAmount, allBorrowAmount);
            uint256 returnedAssetAmount = bentoBox.skim(asset);
            uint256 extraAssetAmount = returnedAssetAmount.sub(allBorrowAmount);


            uint256 feeAmount = extraAssetAmount.mul(PROTOCOL_FEE) / 1e5;
            accrueInfo.feesPendingAmount = accrueInfo.feesPendingAmount.add(feeAmount.to128());
            totalAsset.amount = totalAsset.amount.add(extraAssetAmount.sub(feeAmount).to128());
            emit LogAddAsset(address(0), extraAssetAmount, 0);
        } else if (address(swapper) == address(0)) {

            bentoBox.deposit(asset, msg.sender, allBorrowAmount);
            bentoBox.withdraw(collateral, to, allCollateralAmount);
        } else if (address(swapper) == address(1)) {

            bentoBox.transferFrom(asset, msg.sender, address(this), allBorrowAmount);
            bentoBox.transfer(collateral, to, allCollateralAmount);
        } else {


            bentoBox.transferFrom(collateral, address(this), address(swapper), allCollateralAmount);

            swapper.swap(collateral, asset, allCollateralAmount, allBorrowAmount);
            uint256 returnedAssetAmount = bentoBox.skim(asset);
            uint256 extraAssetAmount = returnedAssetAmount.sub(allBorrowAmount);

            totalAsset.amount = totalAsset.amount.add(extraAssetAmount.to128());
            emit LogAddAsset(address(0), extraAssetAmount, 0);
        }
    }

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory, bytes[] memory) {
        bool[] memory successes = new bool[](calls.length);
        bytes[] memory results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, "LendingPair: Transaction failed");
            successes[i] = success;
            results[i] = result;
        }
        return (successes, results);
    }


    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        address _dev = masterContract.dev();
        uint256 feeAmount = accrueInfo.feesPendingAmount.sub(1);
        uint256 devFeeAmount = _dev == address(0) ? 0 : feeAmount.mul(DEV_FEE) / 1e5;
        accrueInfo.feesPendingAmount = 1;
        bentoBox.withdraw(asset, _feeTo, feeAmount.sub(devFeeAmount));
        if (devFeeAmount > 0) {
            bentoBox.withdraw(asset, _dev, devFeeAmount);
        }
        emit LogWithdrawFees();
    }


    function setSwapper(ISwapper swapper, bool enable) public onlyOwner {
        swappers[swapper] = enable;
    }

    function setFeeTo(address newFeeTo) public onlyOwner
    {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    function setDev(address newDev) public
    {
        require(msg.sender == dev, "LendingPair: Not dev");
        dev = newDev;
        emit LogDev(newDev);
    }


    function swipe(IERC20 token) public {
        require(msg.sender == masterContract.owner(), "LendingPair: caller is not owner");

        if (address(token) == address(0)) {
            uint256 balanceETH = address(this).balance;
            if (balanceETH > 0) {
                (bool success,) = msg.sender.call{value: balanceETH}(new bytes(0));
                require(success, "LendingPair: ETH transfer failed");
            }
        } else if (address(token) != address(asset) && address(token) != address(collateral)) {
            uint256 balanceAmount = token.balanceOf(address(this));
            if (balanceAmount > 0) {
                (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, msg.sender, balanceAmount));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "LendingPair: Transfer failed");
            }
        } else {
            uint256 excessAmount = bentoBox.balanceOf(token, address(this)).sub(token == asset ? totalAsset.amount : totalCollateralAmount);
            bentoBox.transfer(token, msg.sender, excessAmount);
        }
    }
}
