




pragma experimental ABIEncoderV2;
pragma solidity 0.6.4;

library EthAddressLib {




    function ethAddress() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}
library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {

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













    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return b - a;
        }
        return a - b;
    }
}
contract Exponential {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;

    using SafeMath for uint256;

    function getExp(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function getDiv(uint256 num, uint256 denom)
        public
        pure
        returns (uint256 rational)
    {
        rational = num.mul(expScale).div(denom);
    }

    function addExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.add(b);

    }

    function subExp(uint256 a, uint256 b) public pure returns (uint256 result) {
        result = a.sub(b);

    }

    function mulExp(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 doubleScaledProduct = a.mul(b);

        uint256 doubleScaledProductWithHalfScale = halfExpScale.add(
            doubleScaledProduct
        );

        return doubleScaledProductWithHalfScale.div(expScale);
    }

    function divExp(uint256 a, uint256 b) public pure returns (uint256) {
        return getDiv(a, b);
    }

    function mulExp3(
        uint256 a,
        uint256 b,
        uint256 c
    ) public pure returns (uint256) {
        return mulExp(mulExp(a, b), c);
    }

    function mulScalar(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256 scaled)
    {
        scaled = a.mul(scalar);
    }

    function mulScalarTruncate(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256)
    {
        uint256 product = mulScalar(a, scalar);
        return truncate(product);
    }

    function mulScalarTruncateAddUInt(
        uint256 a,
        uint256 scalar,
        uint256 addend
    ) public pure returns (uint256) {
        uint256 product = mulScalar(a, scalar);
        return truncate(product).add(addend);
    }

    function divScalarByExpTruncate(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    function divScalarByExp(uint256 scalar, uint256 divisor)
        public
        pure
        returns (uint256)
    {
        uint256 numerator = expScale.mul(scalar);
        return getExp(numerator, divisor);
    }

    function divScalar(uint256 a, uint256 scalar)
        public
        pure
        returns (uint256)
    {
        return a.div(scalar);
    }

    function truncate(uint256 exp) public pure returns (uint256) {
        return exp.div(expScale);
    }
}
interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount)
        external
        returns (bool);








    function allowance(address owner, address spender)
        external
        view
        returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    function decimals() external view returns (uint8);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface IFToken is IERC20 {
    function mint(address user, uint256 amount) external returns (bytes memory);

    function borrow(address borrower, uint256 borrowAmount)
        external
        returns (bytes memory);

    function withdraw(
        address payable withdrawer,
        uint256 withdrawTokensIn,
        uint256 withdrawAmountIn
    ) external returns (uint256, bytes memory);

    function underlying() external view returns (address);

    function accrueInterest() external;

    function getAccountState(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function MonitorEventCallback(
        address who,
        bytes32 funcName,
        bytes calldata payload
    ) external;


    function exchangeRateCurrent() external view returns (uint256 exchangeRate);

    function repay(address borrower, uint256 repayAmount)
        external
        returns (uint256, bytes memory);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateStored() external view returns (uint256 exchangeRate);

    function liquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address fTokenCollateral
    ) external returns (bytes memory);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external;

    function _addReservesFresh(uint256 addAmount) external;

    function cancellingOut(address striker)
        external
        returns (bool strikeOk, bytes memory strikeLog);

    function APR() external view returns (uint256);

    function APY() external view returns (uint256);

    function calcBalanceOfUnderlying(address owner)
        external
        view
        returns (uint256);

    function borrowSafeRatio() external view returns (uint256);

    function tokenCash(address token, address account)
        external
        view
        returns (uint256);

    function getBorrowRate() external view returns (uint256);

    function addTotalCash(uint256 _addAmount) external;
    function subTotalCash(uint256 _subAmount) external;

    function totalCash() external view returns (uint256);
}
interface IOracle {
    function get(address token) external view returns (uint256, bool);
}
library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );


        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }



















    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }







    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }








    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {




        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {


            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}
enum RewardType {
    DefaultType,
    Deposit,
    Borrow,
    Withdraw,
    Repay,
    Liquidation,
    TokenIn,
    TokenOut
}
interface IBank {
    function MonitorEventCallback(bytes32 funcName, bytes calldata payload)
        external;

    function deposit(address token, uint256 amount) external payable;

    function borrow(address token, uint256 amount) external;

    function withdraw(address underlying, uint256 withdrawTokens) external;

    function withdrawUnderlying(address underlying, uint256 amount) external;

    function repay(address token, uint256 amount) external payable;

    function liquidateBorrow(
        address borrower,
        address underlyingBorrow,
        address underlyingCollateral,
        uint256 repayAmount
    ) external payable;

    function tokenIn(address token, uint256 amountIn) external payable;

    function tokenOut(address token, uint256 amountOut) external;

    function cancellingOut(address token) external;
}
interface IRewardPool {
    function theForceToken() external view returns (address);
    function bankController() external view returns (address);
    function admin() external view returns (address);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
    function withdraw() external;

    function setTheForceToken(address _theForceToken) external;
    function setBankController(address _bankController) external;

    function reward(address who, uint256 amount) external;
}
contract Initializable {




  bool private initialized;




  bool private initializing;




  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function isConstructor() private view returns (bool) {





    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}

contract BankController is Exponential, Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Market {

        address fTokenAddress;

        bool isValid;

        uint256 collateralAbility;

        mapping(address => bool) accountsIn;

        uint256 liquidationIncentive;
    }


    mapping(address => Market) public markets;

    address public bankEntryAddress;
    address public theForceToken;


    mapping(uint256 => uint256) public rewardFactors;


    mapping(address => IFToken[]) public accountAssets;

    IFToken[] public allMarkets;

    address[] public allUnderlyingMarkets;

    IOracle public oracle;

    address public mulsig;

    modifier auth {
        require(
            msg.sender == admin || msg.sender == bankEntryAddress,
            "msg.sender need admin or bank"
        );
        _;
    }

    function setBankEntryAddress(address _newBank) external auth {
        bankEntryAddress = _newBank;
    }

    function setTheForceToken(address _theForceToken) external auth {
        theForceToken = _theForceToken;
    }

    function setRewardFactorByType(uint256 rewaradType, uint256 factor)
        external
        auth
    {
        rewardFactors[rewaradType] = factor;
    }

    function marketsContains(address fToken) public view returns (bool) {
        uint256 len = allMarkets.length;
        for (uint256 i = 0; i < len; ++i) {
            if (address(allMarkets[i]) == fToken) {
                return true;
            }
        }
        return false;
    }

    uint256 public closeFactor;

    address public admin;

    address public proposedAdmin;


    address public rewardPool;

    uint256 public transferEthGasCost;

    function initialize(address _mulsig) public initializer {
        admin = msg.sender;
        mulsig = _mulsig;
        transferEthGasCost = 5000;
    }

    modifier onlyMulSig {
        require(msg.sender == mulsig, "require admin");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "require admin");
        _;
    }

    modifier onlyFToken(address fToken) {
        require(marketsContains(fToken), "only supported fToken");
        _;
    }

    event AddTokenToMarket(address underlying, address fToken);

    function proposeNewAdmin(address admin_) external onlyMulSig {
        proposedAdmin = admin_;
    }

    function claimAdministration() external {
        require(msg.sender == proposedAdmin, "Not proposed admin.");
        admin = proposedAdmin;
        proposedAdmin = address(0);
    }


    function getFTokeAddress(address underlying) public view returns (address) {
        return markets[underlying].fTokenAddress;
    }


    function getAssetsIn(address account)
        external
        view
        returns (IFToken[] memory)
    {
        IFToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    function checkAccountsIn(address account, IFToken fToken)
        external
        view
        returns (bool)
    {
        return
            markets[IFToken(address(fToken)).underlying()].accountsIn[account];
    }

    function userEnterMarket(IFToken fToken, address borrower) internal {
        Market storage marketToJoin = markets[fToken.underlying()];

        require(marketToJoin.isValid, "Market not valid");

        if (marketToJoin.accountsIn[borrower]) {
            return;
        }

        marketToJoin.accountsIn[borrower] = true;

        accountAssets[borrower].push(fToken);
    }

    function transferCheck(
        address fToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external onlyFToken(msg.sender) {
        withdrawCheck(fToken, src, transferTokens);
        userEnterMarket(IFToken(fToken), dst);
    }

    function withdrawCheck(
        address fToken,
        address withdrawer,
        uint256 withdrawTokens
    ) public view returns (uint256) {
        require(
            markets[IFToken(fToken).underlying()].isValid,
            "Market not valid"
        );

        (uint256 sumCollaterals, uint256 sumBorrows) = getUserLiquidity(
            withdrawer,
            IFToken(fToken),
            withdrawTokens,
            0
        );
        require(sumCollaterals >= sumBorrows, "Cannot withdraw tokens");
    }


    function transferIn(
        address account,
        address underlying,
        uint256 amount
    ) public payable {
        if (underlying != EthAddressLib.ethAddress()) {
            require(msg.value == 0, "ERC20 do not accecpt ETH.");
            uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
            IERC20(underlying).safeTransferFrom(account, address(this), amount);
            uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));
            require(
                balanceAfter - balanceBefore == amount,
                "TransferIn amount not valid"
            );

        } else {

            require(msg.value >= amount, "Eth value is not enough");
            if (msg.value > amount) {

                uint256 excessAmount = msg.value.sub(amount);

                (bool result, ) = account.call{
                    value: excessAmount,
                    gas: transferEthGasCost
                }("");
                require(result, "Transfer of ETH failed");
            }
        }
    }


    function transferToUser(
        address underlying,
        address payable account,
        uint256 amount
    ) external onlyFToken(msg.sender) {
        require(
            markets[IFToken(msg.sender).underlying()].isValid,
            "TransferToUser not allowed"
        );
        transferToUserInternal(underlying, account, amount);
    }

    function transferToUserInternal(
        address underlying,
        address payable account,
        uint256 amount
    ) internal {
        if (underlying != EthAddressLib.ethAddress()) {


            IERC20(underlying).safeTransfer(account, amount);
        } else {
            (bool result, ) = account.call{
                value: amount,
                gas: transferEthGasCost
            }("");
            require(result, "Transfer of ETH failed");
        }
    }


    function calcRewardAmount(
        uint256 gasSpend,
        uint256 gasPrice,
        address _for
    ) public view returns (uint256) {
        (uint256 _ethPrice, bool _ethValid) = fetchAssetPrice(
            EthAddressLib.ethAddress()
        );
        (uint256 _forPrice, bool _forValid) = fetchAssetPrice(_for);
        if (!_ethValid || !_forValid || IERC20(_for).decimals() != 18) {
            return 0;
        }
        return gasSpend.mul(gasPrice).mul(_ethPrice).div(_forPrice);
    }



    function calcRewardAmountByFactor(
        uint256 gasSpend,
        uint256 gasPrice,
        address _for,
        uint256 factor
    ) public view returns (uint256) {
        return calcRewardAmount(gasSpend, gasPrice, _for).mul(factor).div(1e18);
    }

    function setRewardPool(address _rewardPool) external onlyAdmin {
        rewardPool = _rewardPool;
    }

    function setTransferEthGasCost(uint256 _transferEthGasCost)
        external
        onlyAdmin
    {
        transferEthGasCost = _transferEthGasCost;
    }

    function rewardForByType(
        address account,
        uint256 gasSpend,
        uint256 gasPrice,
        uint256 rewardType
    ) external auth {
        uint256 amount = calcRewardAmountByFactor(
            gasSpend,
            gasPrice,
            theForceToken,
            rewardFactors[rewardType]
        );
        amount = SafeMath.min(
            amount,
            IERC20(theForceToken).balanceOf(rewardPool)
        );
        if (amount > 0) {
            IRewardPool(rewardPool).reward(account, amount);
        }
    }


    function getCashPrior(address underlying) public view returns (uint256) {
        IFToken fToken = IFToken(getFTokeAddress(underlying));
        return fToken.totalCash();
    }


    function getCashAfter(address underlying, uint256 transferInAmount)
        external
        view
        returns (uint256)
    {
        return getCashPrior(underlying).add(transferInAmount);
    }

    function mintCheck(address underlying, address minter) external {
        require(
            markets[IFToken(msg.sender).underlying()].isValid,
            "MintCheck fails"
        );
        require(markets[underlying].isValid, "Market not valid");
        if (!markets[underlying].accountsIn[minter]) {
            userEnterMarket(IFToken(getFTokeAddress(underlying)), minter);
        }
    }

    function borrowCheck(
        address account,
        address underlying,
        address fToken,
        uint256 borrowAmount
    ) external {
        require(
            markets[IFToken(msg.sender).underlying()].isValid,
            "BorrowCheck fails"
        );
        require(markets[underlying].isValid, "Market not valid");
        (, bool valid) = fetchAssetPrice(underlying);
        require(valid, "Price is not valid");
        if (!markets[underlying].accountsIn[account]) {
            userEnterMarket(IFToken(getFTokeAddress(underlying)), account);
        }

        (uint256 sumCollaterals, uint256 sumBorrows) = getUserLiquidity(
            account,
            IFToken(fToken),
            0,
            borrowAmount
        );
        require(sumCollaterals >= sumBorrows, "insufficient liquidity");
    }

    function repayCheck(address underlying) external view {
        require(markets[underlying].isValid, "Market not valid");
    }


    function getTotalDepositAndBorrow(address account)
        public
        view
        returns (uint256, uint256)
    {
        return getUserLiquidity(account, IFToken(0), 0, 0);
    }


    function getAccountLiquidity(address account)
        public
        view
        returns (uint256 liquidity, uint256 shortfall)
    {
        (uint256 sumCollaterals, uint256 sumBorrows) = getUserLiquidity(
            account,
            IFToken(0),
            0,
            0
        );

        if (sumCollaterals > sumBorrows) {
            return (sumCollaterals - sumBorrows, 0);
        } else {
            return (0, sumBorrows - sumCollaterals);
        }
    }


    function getAccountLiquidityExcludeDeposit(address account, address token)
        public
        view
        returns (uint256, uint256)
    {
        IFToken fToken = IFToken(getFTokeAddress(token));
        (uint256 sumCollaterals, uint256 sumBorrows) = getUserLiquidity(
            account,
            fToken,
            fToken.balanceOf(account),
            0
        );


        if (sumCollaterals > sumBorrows) {
            return (sumCollaterals - sumBorrows, 0);
        } else {
            return (0, sumBorrows - sumCollaterals);
        }
    }


    function fetchAssetPrice(address token)
        public
        view
        returns (uint256, bool)
    {
        require(address(oracle) != address(0), "oracle not set");
        return oracle.get(token);
    }

    function setOracle(address _oracle) external onlyAdmin {
        oracle = IOracle(_oracle);
    }

    function _supportMarket(
        IFToken fToken,
        uint256 _collateralAbility,
        uint256 _liquidationIncentive
    ) public onlyAdmin {
        address underlying = fToken.underlying();

        require(!markets[underlying].isValid, "martket existed");

        markets[underlying] = Market({
            isValid: true,
            collateralAbility: _collateralAbility,
            fTokenAddress: address(fToken),
            liquidationIncentive: _liquidationIncentive
        });

        addTokenToMarket(underlying, address(fToken));
    }

    function addTokenToMarket(address underlying, address fToken) internal {
        for (uint256 i = 0; i < allUnderlyingMarkets.length; i++) {
            require(
                allUnderlyingMarkets[i] != underlying,
                "token exists"
            );
            require(allMarkets[i] != IFToken(fToken), "token exists");
        }
        allMarkets.push(IFToken(fToken));
        allUnderlyingMarkets.push(underlying);

        emit AddTokenToMarket(underlying, fToken);
    }

    function _setCollateralAbility(
        address underlying,
        uint256 newCollateralAbility
    ) external onlyAdmin {
        require(markets[underlying].isValid, "Market not valid");

        Market storage market = markets[underlying];

        market.collateralAbility = newCollateralAbility;
    }

    function setCloseFactor(uint256 _closeFactor) external onlyAdmin {
        closeFactor = _closeFactor;
    }

    function getAllMarkets() external view returns (IFToken[] memory) {
        return allMarkets;
    }

    function seizeCheck(address cTokenCollateral, address cTokenBorrowed)
        external
        view
        onlyFToken(msg.sender)
    {
        require(
            markets[IFToken(cTokenCollateral).underlying()].isValid &&
                markets[IFToken(cTokenBorrowed).underlying()].isValid,
            "Seize market not valid"
        );
    }

    struct LiquidityLocals {
        uint256 sumCollateral;
        uint256 sumBorrows;
        uint256 fTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRate;
        uint256 oraclePrice;
        uint256 collateralAbility;
        uint256 collateral;
    }

    function getUserLiquidity(
        address account,
        IFToken fTokenNow,
        uint256 withdrawTokens,
        uint256 borrowAmount
    ) public view returns (uint256, uint256) {

        IFToken[] memory assets = accountAssets[account];
        LiquidityLocals memory vars;

        for (uint256 i = 0; i < assets.length; i++) {
            IFToken asset = assets[i];

            (vars.fTokenBalance, vars.borrowBalance, vars.exchangeRate) = asset
                .getAccountState(account);

            vars.collateralAbility = markets[asset.underlying()]
                .collateralAbility;

            (uint256 oraclePrice, bool valid) = fetchAssetPrice(
                asset.underlying()
            );
            require(valid, "Price is not valid");
            vars.oraclePrice = oraclePrice;

            uint256 fixUnit = calcExchangeUnit(address(asset));
            uint256 exchangeRateFixed = mulScalar(vars.exchangeRate, fixUnit);

            vars.collateral = mulExp3(
                vars.collateralAbility,
                exchangeRateFixed,
                vars.oraclePrice
            );

            vars.sumCollateral = mulScalarTruncateAddUInt(
                vars.collateral,
                vars.fTokenBalance,
                vars.sumCollateral
            );

            vars.borrowBalance = vars.borrowBalance.mul(fixUnit);

            vars.sumBorrows = mulScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrows
            );


            if (asset == fTokenNow) {

                vars.sumBorrows = mulScalarTruncateAddUInt(
                    vars.collateral,
                    withdrawTokens,
                    vars.sumBorrows
                );

                borrowAmount = borrowAmount.mul(fixUnit);


                vars.sumBorrows = mulScalarTruncateAddUInt(
                    vars.oraclePrice,
                    borrowAmount,
                    vars.sumBorrows
                );
            }
        }

        return (vars.sumCollateral, vars.sumBorrows);
    }


    function getUserLiquidityExcludeToken(
        address account,
        IFToken excludeToken,
        IFToken fTokenNow,
        uint256 withdrawTokens,
        uint256 borrowAmount
    ) external view returns (uint256, uint256) {

        IFToken[] memory assets = accountAssets[account];
        LiquidityLocals memory vars;

        for (uint256 i = 0; i < assets.length; i++) {
            IFToken asset = assets[i];


            if (address(asset) == address(excludeToken)) {
                continue;
            }


            (vars.fTokenBalance, vars.borrowBalance, vars.exchangeRate) = asset
                .getAccountState(account);

            vars.collateralAbility = markets[asset.underlying()]
                .collateralAbility;

            (uint256 oraclePrice, bool valid) = fetchAssetPrice(
                asset.underlying()
            );
            require(valid, "Price is not valid");
            vars.oraclePrice = oraclePrice;

            uint256 fixUnit = calcExchangeUnit(address(asset));
            uint256 exchangeRateFixed = mulScalar(
                vars.exchangeRate,
                fixUnit
            );

            vars.collateral = mulExp3(
                vars.collateralAbility,
                exchangeRateFixed,
                vars.oraclePrice
            );

            vars.sumCollateral = mulScalarTruncateAddUInt(
                vars.collateral,
                vars.fTokenBalance,
                vars.sumCollateral
            );

            vars.sumBorrows = mulScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrows
            );


            if (asset == fTokenNow) {

                vars.sumBorrows = mulScalarTruncateAddUInt(
                    vars.collateral,
                    withdrawTokens,
                    vars.sumBorrows
                );

                borrowAmount = borrowAmount.mul(fixUnit);


                vars.sumBorrows = mulScalarTruncateAddUInt(
                    vars.oraclePrice,
                    borrowAmount,
                    vars.sumBorrows
                );
            }
        }

        return (vars.sumCollateral, vars.sumBorrows);
    }

    function tokenDecimals(address token) public view returns (uint256) {
        return
            token == EthAddressLib.ethAddress()
                ? 18
                : uint256(IERC20(token).decimals());
    }


    function calcMaxWithdrawAmount(address user, address token)
        public
        view
        returns (uint256)
    {
        (uint256 depoistValue, uint256 borrowValue) = getTotalDepositAndBorrow(
            user
        );
        if (depoistValue <= borrowValue) {
            return 0;
        }

        uint256 netValue = subExp(depoistValue, borrowValue);

        uint256 redeemValue = divExp(
            netValue,
            markets[token].collateralAbility
        );

        (uint256 oraclePrice, bool valid) = fetchAssetPrice(token);
        require(valid, "Price is not valid");

        uint fixUnit = 10 ** SafeMath.abs(18, tokenDecimals(token));
        uint256 redeemAmount = divExp(redeemValue, oraclePrice).div(fixUnit);
        IFToken fToken = IFToken(getFTokeAddress(token));

        redeemAmount = SafeMath.min(
            redeemAmount,
            fToken.calcBalanceOfUnderlying(user)
        );
        return redeemAmount;
    }

    function calcMaxBorrowAmount(address user, address token)
        public
        view
        returns (uint256)
    {
        (
            uint256 depoistValue,
            uint256 borrowValue
        ) = getAccountLiquidityExcludeDeposit(user, token);
        if (depoistValue <= borrowValue) {
            return 0;
        }
        uint256 netValue = subExp(depoistValue, borrowValue);
        (uint256 oraclePrice, bool valid) = fetchAssetPrice(token);
        require(valid, "Price is not valid");

        uint fixUnit = 10 ** SafeMath.abs(18, tokenDecimals(token));
        uint256 borrowAmount = divExp(netValue, oraclePrice).div(fixUnit);

        return borrowAmount;
    }

    function calcMaxBorrowAmountWithRatio(address user, address token)
        public
        view
        returns (uint256)
    {
        IFToken fToken = IFToken(getFTokeAddress(token));

        return
            SafeMath.mul(calcMaxBorrowAmount(user, token), fToken.borrowSafeRatio()).div(1e18);
    }

    function calcMaxCashOutAmount(address user, address token)
        public
        view
        returns (uint256)
    {
        return
            addExp(
                calcMaxWithdrawAmount(user, token),
                calcMaxBorrowAmountWithRatio(user, token)
            );
    }

    function isFTokenValid(address fToken) external view returns (bool) {
        return markets[IFToken(fToken).underlying()].isValid;
    }

    function liquidateBorrowCheck(
        address fTokenBorrowed,
        address fTokenCollateral,
        address borrower,
        address liquidator,
        uint256 repayAmount
    ) external onlyFToken(msg.sender) {
        (, uint256 shortfall) = getAccountLiquidity(borrower);
        require(shortfall != 0, "Insufficient shortfall");
        userEnterMarket(IFToken(fTokenCollateral), liquidator);

        uint256 borrowBalance = IFToken(fTokenBorrowed).borrowBalanceStored(
            borrower
        );
        uint256 maxClose = mulScalarTruncate(closeFactor, borrowBalance);
        require(repayAmount <= maxClose, "Too much repay");
    }

    function calcExchangeUnit(address fToken) public view returns (uint256) {
        uint256 fTokenDecimals = uint256(IFToken(fToken).decimals());
        uint256 underlyingDecimals = IFToken(fToken).underlying() ==
            EthAddressLib.ethAddress()
            ? 18
            : uint256(IERC20(IFToken(fToken).underlying()).decimals());

        return 10**SafeMath.abs(fTokenDecimals, underlyingDecimals);
    }

    function liquidateTokens(
        address fTokenBorrowed,
        address fTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256) {
        (uint256 borrowPrice, bool borrowValid) = fetchAssetPrice(
            IFToken(fTokenBorrowed).underlying()
        );
        (uint256 collateralPrice, bool collateralValid) = fetchAssetPrice(
            IFToken(fTokenCollateral).underlying()
        );
        require(borrowValid && collateralValid, "Price not valid");

        uint256 exchangeRate = IFToken(fTokenCollateral).exchangeRateStored();

        uint256 fixCollateralUnit = calcExchangeUnit(fTokenCollateral);
        uint256 fixBorrowlUnit = calcExchangeUnit(fTokenBorrowed);

        uint256 numerator = mulExp(
            markets[IFToken(fTokenCollateral).underlying()]
                .liquidationIncentive,
            borrowPrice
        );
        exchangeRate = exchangeRate.mul(fixCollateralUnit);

        actualRepayAmount = actualRepayAmount.mul(fixBorrowlUnit);

        uint256 denominator = mulExp(collateralPrice, exchangeRate);
        uint256 seizeTokens = mulScalarTruncate(
            divExp(numerator, denominator),
            actualRepayAmount
        );

        return seizeTokens;
    }

    function _setLiquidationIncentive(
        address underlying,
        uint256 _liquidationIncentive
    ) public onlyAdmin {
        markets[underlying].liquidationIncentive = _liquidationIncentive;
    }

    struct ReserveWithdrawalLogStruct {
        address token_address;
        uint256 reserve_withdrawed;
        uint256 cheque_token_value;
        uint256 loan_interest_rate;
        uint256 global_token_reserved;
    }

    function reduceReserves(
        address underlying,
        address payable account,
        uint256 reduceAmount
    ) external onlyMulSig {
        IFToken fToken = IFToken(getFTokeAddress(underlying));
        fToken._reduceReserves(reduceAmount);
        transferToUserInternal(underlying, account, reduceAmount);
        fToken.subTotalCash(reduceAmount);

        ReserveWithdrawalLogStruct memory rds = ReserveWithdrawalLogStruct(
            underlying,
            reduceAmount,
            fToken.exchangeRateStored(),
            fToken.getBorrowRate(),
            fToken.tokenCash(underlying, address(this))
        );

        IBank(bankEntryAddress).MonitorEventCallback(
            "ReserveWithdrawal",
            abi.encode(rds)
        );
    }

    struct ReserveDepositLogStruct {
        address token_address;
        uint256 reserve_funded;
        uint256 cheque_token_value;
        uint256 loan_interest_rate;
        uint256 global_token_reserved;
    }

    function addReserves(address underlying, uint256 addAmount) external payable {
        IFToken fToken = IFToken(getFTokeAddress(underlying));
        fToken._addReservesFresh(addAmount);
        transferIn(msg.sender, underlying, addAmount);
        fToken.addTotalCash(addAmount);

        ReserveDepositLogStruct memory rds = ReserveDepositLogStruct(
            underlying,
            addAmount,
            fToken.exchangeRateStored(),
            fToken.getBorrowRate(),
            fToken.tokenCash(underlying, address(this))
        );

        IBank(bankEntryAddress).MonitorEventCallback(
            "ReserveDeposit",
            abi.encode(rds)
        );
    }
}
