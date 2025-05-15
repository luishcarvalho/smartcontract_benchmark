








pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IWethERC20 is IWeth, IERC20 {}














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }














    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);
        uint256 c = a / b;


        return c;
    }




    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return divCeil(a, b, "SafeMath: division by zero");
    }




    function divCeil(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        if (a == 0) {
            return 0;
        }
        uint256 c = ((a - 1) / b) + 1;

        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }














    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}





library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;











    function mul(int256 a, int256 b) internal pure returns (int256) {



        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }













    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }











    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }











    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}







contract ReentrancyGuard {



    uint256 internal constant REENTRANCY_GUARD_FREE = 1;


    uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;




    uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;









    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
        reentrancyLock = REENTRANCY_GUARD_LOCKED;
        _;
        reentrancyLock = REENTRANCY_GUARD_FREE;
    }
}




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}











contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}










contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "unauthorized");
        _;
    }




    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ProtocolLike {
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId,
        bool isTorqueLoan,
        uint256 initialMargin,
        address[4] calldata sentAddresses,




        uint256[5] calldata sentValues,





        bytes calldata loanDataBytes)
        external
        payable
        returns (uint256 newPrincipal, uint256 newCollateral);

    function getTotalPrincipal(
        address lender,
        address loanToken)
        external
        view
        returns (uint256);

    function withdrawAccruedInterest(
        address loanToken)
        external;

    function getLenderInterestData(
        address lender,
        address loanToken)
        external
        view
        returns (
            uint256 interestPaid,
            uint256 interestPaidDate,
            uint256 interestOwedPerDay,
            uint256 interestUnPaid,
            uint256 interestFeePercent,
            uint256 principalTotal);

    function priceFeeds()
        external
        view
        returns (address);

    function getEstimatedMarginExposure(
        address loanToken,
        address collateralToken,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        uint256 interestRate,
        uint256 newPrincipal)
        external
        view
        returns (uint256);

    function getRequiredCollateralByParams(
        bytes32 loanParamsId,
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        bool isTorqueLoan)
        external
        view
        returns (uint256 collateralAmountRequired);

    function getBorrowAmountByParams(
        bytes32 loanParamsId,
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        bool isTorqueLoan)
        external
        view
        returns (uint256 borrowAmount);

    function isLoanPool(
        address loanPool)
        external
        view
        returns (bool);

    function lendingFeePercent()
        external
        view
        returns (uint256);
}

interface FeedsLike {
    function queryRate(
        address sourceTokenAddress,
        address destTokenAddress)
        external
        view
        returns (uint256 rate, uint256 precision);
}

contract ITokenHolderLike {
    function balanceOf(address _who) public view returns (uint256);
    function freeUpTo(uint256 value) public returns (uint256);
    function freeFromUpTo(address from, uint256 value) public returns (uint256);
}

contract GasTokenUser {

    ITokenHolderLike constant public gasToken = ITokenHolderLike(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    ITokenHolderLike constant public tokenHolder = ITokenHolderLike(0x55Eb3DD3f738cfdda986B8Eff3fa784477552C61);

    modifier usesGasToken(address holder) {
        if (holder == address(0)) {
            holder = address(tokenHolder);
        }

        if (gasToken.balanceOf(holder) != 0) {
            uint256 gasCalcValue = gasleft();

            _;

            gasCalcValue = (_gasUsed(gasCalcValue) + 14154) / 41947;

            if (holder == address(tokenHolder)) {
                tokenHolder.freeUpTo(
                    gasCalcValue
                );
            } else {
                tokenHolder.freeFromUpTo(
                    holder,
                    gasCalcValue
                );
            }

        } else {
            _;
        }
    }

    function _gasUsed(
        uint256 startingGas)
        internal
        view
        returns (uint256)
    {
        return 21000 +
            startingGas -
            gasleft() +
            16 *
            msg.data.length;

    }
}

contract Pausable {


    bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;

    modifier pausable(bytes4 sig) {
        require(!_isPaused(sig), "unauthorized");
        _;
    }

    function _isPaused(
        bytes4 sig)
        internal
        view
        returns (bool isPaused)
    {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            isPaused := sload(slot)
        }
    }
}

contract LoanTokenBase is ReentrancyGuard, Ownable, Pausable {

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    int256 internal constant sWEI_PRECISION = 10**18;

    string public name;
    string public symbol;
    uint8 public decimals;


    uint88 internal lastSettleTime_;

    address public loanTokenAddress;

    uint256 public baseRate;
    uint256 public rateMultiplier;
    uint256 public lowUtilBaseRate;
    uint256 public lowUtilRateMultiplier;

    uint256 public targetLevel;
    uint256 public kinkLevel;
    uint256 public maxScaleRate;

    uint256 internal _flTotalAssetSupply;
    uint256 public checkpointSupply;
    uint256 public initialPrice;

    mapping (uint256 => bytes32) public loanParamsIds;
    mapping (address => uint256) internal checkpointPrices_;
}

contract AdvancedTokenStorage is LoanTokenBase {
    using SafeMath for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Mint(
        address indexed minter,
        uint256 tokenAmount,
        uint256 assetAmount,
        uint256 price
    );

    event Burn(
        address indexed burner,
        uint256 tokenAmount,
        uint256 assetAmount,
        uint256 price
    );

    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 internal totalSupply_;

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply_;
    }

    function balanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}

contract AdvancedToken is AdvancedTokenStorage {
    using SafeMath for uint256;

    function approve(
        address _spender,
        uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender]
            .add(_addedValue);
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 _allowed = allowed[msg.sender][_spender];
        if (_subtractedValue >= _allowed) {
            _allowed = 0;
        } else {
            _allowed -= _subtractedValue;
        }
        allowed[msg.sender][_spender] = _allowed;

        emit Approval(msg.sender, _spender, _allowed);
        return true;
    }

    function _mint(
        address _to,
        uint256 _tokenAmount,
        uint256 _assetAmount,
        uint256 _price)
        internal
        returns (uint256)
    {
        require(_to != address(0), "15");

        uint256 _balance = balances[_to]
            .add(_tokenAmount);
        balances[_to] = _balance;

        totalSupply_ = totalSupply_
            .add(_tokenAmount);

        emit Mint(_to, _tokenAmount, _assetAmount, _price);
        emit Transfer(address(0), _to, _tokenAmount);

        return _balance;
    }

    function _burn(
        address _who,
        uint256 _tokenAmount,
        uint256 _assetAmount,
        uint256 _price)
        internal
        returns (uint256)
    {
        uint256 _balance = balances[_who].sub(_tokenAmount, "16");


        if (_balance <= 10) {
            _tokenAmount = _tokenAmount.add(_balance);
            _balance = 0;
        }
        balances[_who] = _balance;

        totalSupply_ = totalSupply_.sub(_tokenAmount);

        emit Burn(_who, _tokenAmount, _assetAmount, _price);
        emit Transfer(_who, address(0), _tokenAmount);

        return _balance;
    }
}

contract LoanTokenLogicStandard is AdvancedToken, GasTokenUser {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    modifier settlesInterest() {
        _settleInterest();
        _;
    }

    address internal target_;

    uint256 public constant VERSION = 6;
    address internal constant arbitraryCaller = 0x000F400e6818158D541C3EBE45FE3AA0d47372FF;

    address public constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f;
    address public constant wethToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bytes32 internal constant iToken_ProfitSoFar = 0x37aa2b7d583612f016e4a4de4292cb015139b3d7762663d06a53964912ea2fb6;
    bytes32 internal constant iToken_LowerAdminAddress = 0x7ad06df6a0af6bd602d90db766e0d5f253b45187c3717a0f9026ea8b10ff0d4b;
    bytes32 internal constant iToken_LowerAdminContract = 0x34b31cff1dbd8374124bd4505521fc29cab0f9554a5386ba7d784a4e611c7e31;


    constructor(
        address _newOwner)
        public
    {
        transferOwnership(_newOwner);
    }

    function()
        external
    {
        revert("fallback not allowed");
    }



    function mint(
        address receiver,
        uint256 depositAmount)
        external
        nonReentrant
        returns (uint256)
    {
        return _mintToken(
            receiver,
            depositAmount
        );
    }

    function burn(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 loanAmountPaid)
    {
        loanAmountPaid = _burnToken(
            burnAmount
        );

        if (loanAmountPaid != 0) {
            _safeTransfer(loanTokenAddress, receiver, loanAmountPaid, "5");
        }
    }

    function flashBorrow(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data)
        external
        payable
        nonReentrant
        pausable(msg.sig)
        settlesInterest
        returns (bytes memory)
    {
        require(borrowAmount != 0, "38");


        uint256 beforeEtherBalance = address(this).balance.sub(msg.value);
        uint256 beforeAssetsBalance = _underlyingBalance()
            .add(totalAssetBorrow());


        _flTotalAssetSupply = beforeAssetsBalance;


        _safeTransfer(loanTokenAddress, borrower, borrowAmount, "39");

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }


        (bool success, bytes memory returnData) = arbitraryCaller.call.value(msg.value)(
            abi.encodeWithSelector(
                0xde064e0d,
                target,
                callData
            )
        );
        require(success, "call failed");


        _flTotalAssetSupply = 0;


        require(
            address(this).balance >= beforeEtherBalance &&
            _underlyingBalance()
                .add(totalAssetBorrow()) >= beforeAssetsBalance,
            "40"
        );

        return returnData;
    }


    function borrow(
        bytes32 loanId,
        uint256 withdrawAmount,
        uint256 initialLoanDuration,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address borrower,
        address receiver,
        bytes memory )
        public
        payable
        returns (uint256, uint256)
    {
        return _borrow(
            loanId,
            withdrawAmount,
            initialLoanDuration,
            collateralTokenSent,
            collateralTokenAddress,
            borrower,
            receiver,
            ""
        );
    }


    function borrowWithGasToken(
        bytes32 loanId,
        uint256 withdrawAmount,
        uint256 initialLoanDuration,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address borrower,
        address receiver,
        address gasTokenUser,
        bytes memory )
        public
        payable
        usesGasToken(gasTokenUser)
        returns (uint256, uint256)
    {
        return _borrow(
            loanId,
            withdrawAmount,
            initialLoanDuration,
            collateralTokenSent,
            collateralTokenAddress,
            borrower,
            receiver,
            ""
        );
    }



    function marginTrade(
        bytes32 loanId,
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes)
        public
        payable
        returns (uint256, uint256)
    {
        return _marginTrade(
            loanId,
            leverageAmount,
            loanTokenSent,
            collateralTokenSent,
            collateralTokenAddress,
            trader,
            loanDataBytes
        );
    }



    function marginTradeWithGasToken(
        bytes32 loanId,
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        address gasTokenUser,
        bytes memory loanDataBytes)
        public
        payable
        usesGasToken(gasTokenUser)
        returns (uint256, uint256)
    {
        return _marginTrade(
            loanId,
            leverageAmount,
            loanTokenSent,
            collateralTokenSent,
            collateralTokenAddress,
            trader,
            loanDataBytes
        );
    }

    function transfer(
        address _to,
        uint256 _value)
        external
        returns (bool)
    {
        return _internalTransferFrom(
            msg.sender,
            _to,
            _value,
            uint256(-1)
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        external
        returns (bool)
    {
        return _internalTransferFrom(
            _from,
            _to,
            _value,
            allowed[_from][msg.sender]



        );
    }

    function _internalTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _allowanceAmount)
        internal
        returns (bool)
    {
        if (_allowanceAmount != uint256(-1)) {
            allowed[_from][msg.sender] = _allowanceAmount.sub(_value, "14");
        }

        uint256 _balancesFrom = balances[_from];
        uint256 _balancesTo = balances[_to];

        require(_to != address(0), "15");

        uint256 _balancesFromNew = _balancesFrom
            .sub(_value, "16");
        balances[_from] = _balancesFromNew;

        uint256 _balancesToNew = _balancesTo
            .add(_value);
        balances[_to] = _balancesToNew;


        uint256 _currentPrice = tokenPrice();

        _updateCheckpoints(
            _from,
            _balancesFrom,
            _balancesFromNew,
            _currentPrice
        );
        _updateCheckpoints(
            _to,
            _balancesTo,
            _balancesToNew,
            _currentPrice
        );

        emit Transfer(_from, _to, _value);
        return true;
    }

    function _updateCheckpoints(
        address _user,
        uint256 _oldBalance,
        uint256 _newBalance,
        uint256 _currentPrice)
        internal
    {
        bytes32 slot = keccak256(
            abi.encodePacked(_user, iToken_ProfitSoFar)
        );

        int256 _currentProfit;
        if (_newBalance == 0) {
            _currentPrice = 0;
        } else if (_oldBalance != 0) {
            _currentProfit = _profitOf(
                slot,
                _oldBalance,
                _currentPrice,
                checkpointPrices_[_user]
            );
        }

        assembly {
            sstore(slot, _currentProfit)
        }

        checkpointPrices_[_user] = _currentPrice;
    }



    function profitOf(
        address user)
        public
        view
        returns (int256)
    {
        bytes32 slot = keccak256(
            abi.encodePacked(user, iToken_ProfitSoFar)
        );

        return _profitOf(
            slot,
            balances[user],
            tokenPrice(),
            checkpointPrices_[user]
        );
    }

    function _profitOf(
        bytes32 slot,
        uint256 _balance,
        uint256 _currentPrice,
        uint256 _checkpointPrice)
        internal
        view
        returns (int256 profitSoFar)
    {
        if (_checkpointPrice == 0) {
            return 0;
        }

        assembly {
            profitSoFar := sload(slot)
        }

        profitSoFar = int256(_currentPrice)
            .sub(int256(_checkpointPrice))
            .mul(int256(_balance))
            .div(sWEI_PRECISION)
            .add(profitSoFar);
    }

    function tokenPrice()
        public
        view
        returns (uint256)
    {
        uint256 interestUnPaid;
        if (lastSettleTime_ != uint88(block.timestamp)) {
            (,interestUnPaid) = _getAllInterest();
        }

        return _tokenPrice(_totalAssetSupply(interestUnPaid));
    }

    function checkpointPrice(
        address _user)
        public
        view
        returns (uint256)
    {
        return checkpointPrices_[_user];
    }

    function marketLiquidity()
        public
        view
        returns (uint256)
    {
        uint256 totalSupply = _totalAssetSupply(0);
        uint256 totalBorrow = totalAssetBorrow();
        if (totalSupply > totalBorrow) {
            return totalSupply - totalBorrow;
        }
    }

    function avgBorrowInterestRate()
        public
        view
        returns (uint256)
    {
        return _avgBorrowInterestRate(totalAssetBorrow());
    }


    function borrowInterestRate()
        public
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(0);
    }

    function nextBorrowInterestRate(
        uint256 borrowAmount)
        public
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(borrowAmount);
    }


    function supplyInterestRate()
        public
        view
        returns (uint256)
    {
        return totalSupplyInterestRate(_totalAssetSupply(0));
    }

    function nextSupplyInterestRate(
        uint256 supplyAmount)
        public
        view
        returns (uint256)
    {
        return totalSupplyInterestRate(_totalAssetSupply(0).add(supplyAmount));
    }

    function totalSupplyInterestRate(
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        uint256 assetBorrow = totalAssetBorrow();
        if (assetBorrow != 0) {
            return _supplyInterestRate(
                assetBorrow,
                assetSupply
            );
        }
    }

    function totalAssetBorrow()
        public
        view
        returns (uint256)
    {
        return ProtocolLike(bZxContract).getTotalPrincipal(
            address(this),
            loanTokenAddress
        );
    }

    function totalAssetSupply()
        public
        view
        returns (uint256)
    {
        uint256 interestUnPaid;
        if (lastSettleTime_ != uint88(block.timestamp)) {
            (,interestUnPaid) = _getAllInterest();
        }

        return _totalAssetSupply(interestUnPaid);
    }

    function getMaxEscrowAmount(
        uint256 leverageAmount)
        public
        view
        returns (uint256)
    {
        uint256 initialMargin = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, leverageAmount);
        return marketLiquidity()
            .mul(initialMargin)
            .div(_adjustValue(
                WEI_PERCENT_PRECISION,
                2419200,
                initialMargin));
    }


    function assetBalanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return balanceOf(_owner)
            .mul(tokenPrice())
            .div(WEI_PRECISION);
    }

    function getEstimatedMarginDetails(
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress)
        public
        view
        returns (uint256 principal, uint256 collateral, uint256 interestRate)
    {
        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }

        uint256 totalDeposit = _totalDeposit(
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent
        );

        (principal, interestRate) = _getMarginBorrowAmountAndRate(
            leverageAmount,
            totalDeposit
        );
        if (principal > _underlyingBalance()) {
            return (0, 0, 0);
        }

        loanTokenSent = loanTokenSent
            .add(principal);


        collateral = ProtocolLike(bZxContract).getEstimatedMarginExposure(
            loanTokenAddress,
            collateralTokenAddress,
            loanTokenSent,
            collateralTokenSent,
            interestRate,
            principal
        );
    }

    function getDepositAmountForBorrow(
        uint256 borrowAmount,
        uint256 initialLoanDuration,
        address collateralTokenAddress)
        public
        view
        returns (uint256)
    {
        if (borrowAmount != 0) {
            (,,uint256 newBorrowAmount) = _getInterestRateAndBorrowAmount(
                borrowAmount,
                totalAssetSupply(),
                initialLoanDuration
            );

            if (newBorrowAmount <= _underlyingBalance()) {
                return ProtocolLike(bZxContract).getRequiredCollateralByParams(
                    loanParamsIds[uint256(keccak256(abi.encodePacked(
                        collateralTokenAddress,
                        true
                    )))],
                    loanTokenAddress,
                    collateralTokenAddress != address(0) ? collateralTokenAddress : wethToken,
                    newBorrowAmount,
                    true
                ).add(10);
            }
        }
    }

    function getBorrowAmountForDeposit(
        uint256 depositAmount,
        uint256 initialLoanDuration,
        address collateralTokenAddress)
        public
        view
        returns (uint256 borrowAmount)
    {
        if (depositAmount != 0) {
            borrowAmount = ProtocolLike(bZxContract).getBorrowAmountByParams(
                loanParamsIds[uint256(keccak256(abi.encodePacked(
                    collateralTokenAddress,
                    true
                )))],
                loanTokenAddress,
                collateralTokenAddress != address(0) ? collateralTokenAddress : wethToken,
                depositAmount,
                true
            );

            (,,borrowAmount) = _getInterestRateAndBorrowAmount(
                borrowAmount,
                totalAssetSupply(),
                initialLoanDuration
            );

            if (borrowAmount > _underlyingBalance()) {
                borrowAmount = 0;
            }
        }
    }




    function _mintToken(
        address receiver,
        uint256 depositAmount)
        internal
        settlesInterest
        returns (uint256 mintAmount)
    {
        require (depositAmount != 0, "17");

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(0));
        mintAmount = depositAmount
            .mul(WEI_PRECISION)
            .div(currentPrice);

        if (msg.value == 0) {
            _safeTransferFrom(loanTokenAddress, msg.sender, address(this), depositAmount, "18");
        } else {
            require(msg.value == depositAmount, "18");
            IWeth(wethToken).deposit.value(depositAmount)();
        }

        _updateCheckpoints(
            receiver,
            balances[receiver],
            _mint(receiver, mintAmount, depositAmount, currentPrice),
            currentPrice
        );
    }

    function _burnToken(
        uint256 burnAmount)
        internal
        settlesInterest
        returns (uint256 loanAmountPaid)
    {
        require(burnAmount != 0, "19");

        if (burnAmount > balanceOf(msg.sender)) {
            require(burnAmount == uint256(-1), "32");
            burnAmount = balanceOf(msg.sender);
        }

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(0));

        uint256 loanAmountOwed = burnAmount
            .mul(currentPrice)
            .div(WEI_PRECISION);
        uint256 loanAmountAvailableInContract = _underlyingBalance();

        loanAmountPaid = loanAmountOwed;
        require(loanAmountPaid <= loanAmountAvailableInContract, "37");

        _updateCheckpoints(
            msg.sender,
            balances[msg.sender],
            _burn(msg.sender, burnAmount, loanAmountPaid, currentPrice),
            currentPrice
        );
    }

    function _borrow(
        bytes32 loanId,
        uint256 withdrawAmount,
        uint256 initialLoanDuration,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address borrower,
        address receiver,
        bytes memory )
        internal
        pausable(msg.sig)
        settlesInterest
        returns (uint256, uint256)
    {
        require(withdrawAmount != 0, "6");

        require(msg.value == 0 || msg.value == collateralTokenSent, "7");
        require(collateralTokenSent != 0 || loanId != 0, "8");
        require(collateralTokenAddress != address(0) || msg.value != 0 || loanId != 0, "9");


        require(loanId == 0 || msg.sender == borrower, "13");

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "10");

        address[4] memory sentAddresses;
        uint256[5] memory sentAmounts;

        sentAddresses[0] = address(this);
        sentAddresses[1] = borrower;
        sentAddresses[2] = receiver;






        sentAmounts[4] = collateralTokenSent;


        (sentAmounts[0], sentAmounts[2], sentAmounts[1]) = _getInterestRateAndBorrowAmount(
            withdrawAmount,
            _totalAssetSupply(0),
            initialLoanDuration
        );

        return _borrowOrTrade(
            loanId,
            withdrawAmount,
            0,
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            ""
        );
    }

    function _marginTrade(
        bytes32 loanId,
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes)
        internal
        pausable(msg.sig)
        settlesInterest
        returns (uint256, uint256)
    {

        require(loanId == 0 || msg.sender == trader, "13");

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "11");

        uint256 totalDeposit = _totalDeposit(
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent
        );
        require(totalDeposit != 0, "12");

        address[4] memory sentAddresses;
        uint256[5] memory sentAmounts;

        sentAddresses[0] = address(this);
        sentAddresses[1] = trader;
        sentAddresses[2] = trader;





        sentAmounts[3] = loanTokenSent;
        sentAmounts[4] = collateralTokenSent;

        (sentAmounts[1], sentAmounts[0]) = _getMarginBorrowAmountAndRate(
            leverageAmount,
            totalDeposit
        );

        return _borrowOrTrade(
            loanId,
            0,
            leverageAmount,
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );
    }

    function _settleInterest()
        internal
    {
        uint88 ts = uint88(block.timestamp);
        if (lastSettleTime_ != ts) {
            ProtocolLike(bZxContract).withdrawAccruedInterest(
                loanTokenAddress
            );

            lastSettleTime_ = ts;
        }
    }

    function _totalDeposit(
        address collateralTokenAddress,
        uint256 collateralTokenSent,
        uint256 loanTokenSent)
        internal
        view
        returns (uint256 totalDeposit)
    {
        totalDeposit = loanTokenSent;
        if (collateralTokenSent != 0) {
            (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = FeedsLike(ProtocolLike(bZxContract).priceFeeds()).queryRate(
                collateralTokenAddress,
                loanTokenAddress
            );
            if (sourceToDestRate != 0) {
                totalDeposit = collateralTokenSent
                    .mul(sourceToDestRate)
                    .div(sourceToDestPrecision)
                    .add(totalDeposit);
            }
        }
    }

    function _getInterestRateAndBorrowAmount(
        uint256 borrowAmount,
        uint256 assetSupply,
        uint256 initialLoanDuration)
        internal
        view
        returns (uint256 interestRate, uint256 interestInitialAmount, uint256 newBorrowAmount)
    {
        interestRate = _nextBorrowInterestRate2(
            borrowAmount,
            assetSupply
        );


        newBorrowAmount = borrowAmount
            .mul(WEI_PRECISION)
            .div(
                SafeMath.sub(WEI_PRECISION,
                    interestRate
                        .mul(initialLoanDuration)
                        .mul(WEI_PRECISION)
                        .div(31536000 * WEI_PERCENT_PRECISION)
                )
            );

        interestInitialAmount = newBorrowAmount
            .sub(borrowAmount);
    }


    function _borrowOrTrade(
        bytes32 loanId,
        uint256 withdrawAmount,
        uint256 leverageAmount,
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {
        require (sentAmounts[1] <= _underlyingBalance() &&
            sentAddresses[1] != address(0),
            "24"
        );

	    if (sentAddresses[2] == address(0)) {
            sentAddresses[2] = sentAddresses[1];
        }


        uint256 msgValue = _verifyTransfers(
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            withdrawAmount
        );


        sentAmounts[3] = sentAmounts[3]
            .add(sentAmounts[1]);

        if (withdrawAmount != 0) {

            sentAmounts[3] = sentAmounts[3]
                .sub(withdrawAmount);
        }

        bool isTorqueLoan = withdrawAmount != 0 ?
            true :
            false;

        bytes32 loanParamsId = loanParamsIds[uint256(keccak256(abi.encodePacked(
            collateralTokenAddress,
            isTorqueLoan
        )))];


        if (leverageAmount != 0) {
            leverageAmount = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, leverageAmount);
        }

        (sentAmounts[1], sentAmounts[4]) = ProtocolLike(bZxContract).borrowOrTradeFromPool.value(msgValue)(
            loanParamsId,
            loanId,
            isTorqueLoan,
            leverageAmount,
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );
        require (sentAmounts[1] != 0, "25");

        return (sentAmounts[1], sentAmounts[4]);
    }










    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
        returns (uint256 msgValue)
    {
        address _wethToken = wethToken;
        address _loanTokenAddress = loanTokenAddress;
        address receiver = sentAddresses[2];
        uint256 newPrincipal = sentAmounts[1];
        uint256 loanTokenSent = sentAmounts[3];
        uint256 collateralTokenSent = sentAmounts[4];

        require(_loanTokenAddress != collateralTokenAddress, "26");

        msgValue = msg.value;

        if (withdrawalAmount != 0) {
            _safeTransfer(_loanTokenAddress, receiver, withdrawalAmount, "27");
            if (newPrincipal > withdrawalAmount) {
                _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal - withdrawalAmount, "27");
            }
        } else {
            _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, "27");
        }

        if (collateralTokenSent != 0) {
            if (collateralTokenAddress == _wethToken && msgValue != 0 && msgValue >= collateralTokenSent) {
                IWeth(_wethToken).deposit.value(collateralTokenSent)();
                _safeTransfer(collateralTokenAddress, bZxContract, collateralTokenSent, "28");
                msgValue -= collateralTokenSent;
            } else {
                _safeTransferFrom(collateralTokenAddress, msg.sender, bZxContract, collateralTokenSent, "28");
            }
        }

        if (loanTokenSent != 0) {
            _safeTransferFrom(_loanTokenAddress, msg.sender, bZxContract, loanTokenSent, "29");
        }
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 amount,
        string memory errorMsg)
        internal
    {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20(token).transfer.selector, to, amount),
            errorMsg
        );
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount,
        string memory errorMsg)
        internal
    {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20(token).transferFrom.selector, from, to, amount),
            errorMsg
        );
    }

    function _callOptionalReturn(
        address token,
        bytes memory data,
        string memory errorMsg)
        internal
    {
        (bool success, bytes memory returndata) = token.call(data);
        require(success, errorMsg);

        if (returndata.length != 0) {
            require(abi.decode(returndata, (bool)), errorMsg);
        }
    }

    function _underlyingBalance()
        internal
        view
        returns (uint256)
    {
        return IERC20(loanTokenAddress).balanceOf(address(this));
    }



    function _tokenPrice(
        uint256 assetSupply)
        internal
        view
        returns (uint256)
    {
        uint256 totalTokenSupply = totalSupply_;

        return totalTokenSupply != 0 ?
            assetSupply
                .mul(WEI_PRECISION)
                .div(totalTokenSupply) : initialPrice;
    }

    function _avgBorrowInterestRate(
        uint256 assetBorrow)
        internal
        view
        returns (uint256)
    {
        if (assetBorrow != 0) {
            (uint256 interestOwedPerDay,) = _getAllInterest();
            return interestOwedPerDay
                .mul(365 * WEI_PERCENT_PRECISION)
                .div(assetBorrow);
        }
    }


    function _supplyInterestRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        internal
        view
        returns (uint256)
    {
        if (assetBorrow != 0 && assetSupply >= assetBorrow) {
            return _avgBorrowInterestRate(assetBorrow)
                .mul(_utilizationRate(assetBorrow, assetSupply))
                .mul(SafeMath.sub(WEI_PERCENT_PRECISION, ProtocolLike(bZxContract).lendingFeePercent()))
                .div(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION);
        }
    }

    function _nextBorrowInterestRate(
        uint256 borrowAmount)
        internal
        view
        returns (uint256)
    {
        uint256 interestUnPaid;
        if (borrowAmount != 0) {
            if (lastSettleTime_ != uint88(block.timestamp)) {
                (,interestUnPaid) = _getAllInterest();
            }

            uint256 balance = _underlyingBalance()
                .add(interestUnPaid);
            if (borrowAmount > balance) {
                borrowAmount = balance;
            }
        }

        return _nextBorrowInterestRate2(
            borrowAmount,
            _totalAssetSupply(interestUnPaid)
        );
    }

    function _nextBorrowInterestRate2(
        uint256 newBorrowAmount,
        uint256 assetSupply)
        internal
        view
        returns (uint256 nextRate)
    {
        uint256 utilRate = _utilizationRate(
            totalAssetBorrow().add(newBorrowAmount),
            assetSupply
        );

        uint256 thisMinRate;
        uint256 thisMaxRate;
        uint256 thisBaseRate = baseRate;
        uint256 thisRateMultiplier = rateMultiplier;
        uint256 thisTargetLevel = targetLevel;
        uint256 thisKinkLevel = kinkLevel;
        uint256 thisMaxScaleRate = maxScaleRate;

        if (utilRate < thisTargetLevel) {

            utilRate = thisTargetLevel;
        }

        if (utilRate > thisKinkLevel) {

            uint256 thisMaxRange = WEI_PERCENT_PRECISION - thisKinkLevel;

            utilRate -= thisKinkLevel;
            if (utilRate > thisMaxRange)
                utilRate = thisMaxRange;

            thisMaxRate = thisRateMultiplier
                .add(thisBaseRate)
                .mul(thisKinkLevel)
                .div(WEI_PERCENT_PRECISION);

            nextRate = utilRate
                .mul(SafeMath.sub(thisMaxScaleRate, thisMaxRate))
                .div(thisMaxRange)
                .add(thisMaxRate);
        } else {
            nextRate = utilRate
                .mul(thisRateMultiplier)
                .div(WEI_PERCENT_PRECISION)
                .add(thisBaseRate);

            thisMinRate = thisBaseRate;
            thisMaxRate = thisRateMultiplier
                .add(thisBaseRate);

            if (nextRate < thisMinRate)
                nextRate = thisMinRate;
            else if (nextRate > thisMaxRate)
                nextRate = thisMaxRate;
        }
    }

    function _getAllInterest()
        internal
        view
        returns (
            uint256 interestOwedPerDay,
            uint256 interestUnPaid)
    {

        uint256 interestFeePercent;
        (,,interestOwedPerDay,interestUnPaid,interestFeePercent,) = ProtocolLike(bZxContract).getLenderInterestData(
            address(this),
            loanTokenAddress
        );

        interestUnPaid = interestUnPaid
            .mul(SafeMath.sub(WEI_PERCENT_PRECISION, interestFeePercent))
            .div(WEI_PERCENT_PRECISION);
    }

    function _getMarginBorrowAmountAndRate(
        uint256 leverageAmount,
        uint256 depositAmount)
        internal
        view
        returns (uint256 borrowAmount, uint256 interestRate)
    {
        uint256 initialMargin = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, leverageAmount);

        interestRate = _nextBorrowInterestRate2(
            depositAmount
                .mul(WEI_PERCENT_PRECISION)
                .div(initialMargin),
            _totalAssetSupply(0)
        );


        borrowAmount = depositAmount
            .mul(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION)
            .div(_adjustValue(
                interestRate,
                2419200,
                initialMargin))
            .div(initialMargin);
    }

    function _totalAssetSupply(
        uint256 interestUnPaid)
        internal
        view
        returns (uint256)
    {
        if (totalSupply_ != 0) {
            uint256 assetsBalance = _flTotalAssetSupply;
            if (assetsBalance == 0) {
                assetsBalance = _underlyingBalance()
                    .add(totalAssetBorrow());
            }

            return assetsBalance
                .add(interestUnPaid);
        }
    }

    function _adjustValue(
        uint256 interestRate,
        uint256 maxDuration,
        uint256 marginAmount)
        internal
        pure
        returns (uint256)
    {
        return maxDuration != 0 ?
            interestRate
                .mul(WEI_PERCENT_PRECISION)
                .mul(maxDuration)
                .div(31536000)
                .div(marginAmount)
                .add(WEI_PERCENT_PRECISION) :
            WEI_PERCENT_PRECISION;
    }

    function _utilizationRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        internal
        pure
        returns (uint256)
    {
        if (assetBorrow != 0 && assetSupply != 0) {

            return assetBorrow
                .mul(WEI_PERCENT_PRECISION)
                .div(assetSupply);
        }
    }




    function updateSettings(
        address settingsTarget,
        bytes memory callData)
        public
    {
        if (msg.sender != owner()) {
            address _lowerAdmin;
            address _lowerAdminContract;
            assembly {
                _lowerAdmin := sload(iToken_LowerAdminAddress)
                _lowerAdminContract := sload(iToken_LowerAdminContract)
            }
            require(msg.sender == _lowerAdmin && settingsTarget == _lowerAdminContract);
        }

        address currentTarget = target_;
        target_ = settingsTarget;

        (bool result,) = address(this).call(callData);

        uint256 size;
        uint256 ptr;
        assembly {
            size := returndatasize
            ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            if eq(result, 0) { revert(ptr, size) }
        }

        target_ = currentTarget;

        assembly {
            return(ptr, size)
        }
    }
}

contract LoanTokenLogicWeth is LoanTokenLogicStandard {

    constructor(
        address _newOwner)
        public
        LoanTokenLogicStandard(_newOwner)
    {}

    function mintWithEther(
        address receiver)
        external
        payable
        nonReentrant
        returns (uint256 mintAmount)
    {
        return _mintToken(
            receiver,
            msg.value
        );
    }

    function burnToEther(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 loanAmountPaid)
    {
        loanAmountPaid = _burnToken(
            burnAmount
        );

        if (loanAmountPaid != 0) {
            IWethERC20(wethToken).withdraw(loanAmountPaid);
            Address.sendValue(
                receiver,
                loanAmountPaid
            );
        }
    }












    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
        returns (uint256 msgValue)
    {
        address _wethToken = wethToken;
        address _loanTokenAddress = _wethToken;
        address receiver = sentAddresses[2];
        uint256 newPrincipal = sentAmounts[1];
        uint256 loanTokenSent = sentAmounts[3];
        uint256 collateralTokenSent = sentAmounts[4];

        require(_loanTokenAddress != collateralTokenAddress, "26");

        msgValue = msg.value;

        if (withdrawalAmount != 0) {
            IWethERC20(_wethToken).withdraw(withdrawalAmount);
            Address.sendValue(
                receiver,
                withdrawalAmount
            );
            if (newPrincipal > withdrawalAmount) {
                _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal - withdrawalAmount, "27");
            }
        } else {
            _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, "27");
        }

        if (collateralTokenSent != 0) {
            _safeTransferFrom(collateralTokenAddress, msg.sender, bZxContract, collateralTokenSent, "28");
        }

        if (loanTokenSent != 0) {
            if (msgValue != 0 && msgValue >= loanTokenSent) {
                IWeth(_wethToken).deposit.value(loanTokenSent)();
                _safeTransfer(_loanTokenAddress, bZxContract, loanTokenSent, "29");
                msgValue -= loanTokenSent;
            } else {
                _safeTransferFrom(_loanTokenAddress, msg.sender, bZxContract, loanTokenSent, "29");
            }
        }
    }
}
