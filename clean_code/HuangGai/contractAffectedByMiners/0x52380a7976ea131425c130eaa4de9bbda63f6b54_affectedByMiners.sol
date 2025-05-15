








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

contract Constants {

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    uint256 internal constant DAYS_IN_A_YEAR = 365;
    uint256 internal constant ONE_MONTH = 2628000;

    IWethERC20 public constant wethToken = IWethERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant bzrxTokenAddress = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address public constant vbzrxTokenAddress = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
}













library EnumerableBytes32Set {

    struct Bytes32Set {


        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }





    function addAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return addBytes32(set, value);
    }





    function addBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }





    function removeAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return removeBytes32(set, value);
    }





    function removeBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;


            if (block.gaslimit != toDeleteIndex) {
                bytes32 lastValue = set.values[lastIndex];


                set.values[toDeleteIndex] = lastValue;

                set.index[lastValue] = toDeleteIndex + 1;
            }


            delete set.index[value];


            set.values.pop();

            return true;
        } else {
            return false;
        }
    }




    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }




    function containsAddress(Bytes32Set storage set, address addrvalue)
        internal
        view
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return set.index[value] != 0;
    }









    function enumerate(Bytes32Set storage set, uint256 start, uint256 count)
        internal
        view
        returns (bytes32[] memory output)
    {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes32[](end-start);
        for (uint256 i = start; i < end; i++) {
            output[i-start] = set.values[i];
        }
        return output;
    }




    function length(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }









    function get(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }









    function getAddress(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (address)
    {
        bytes32 value = set.values[index];
        address addrvalue;
        assembly {
            addrvalue := value
        }
        return addrvalue;
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














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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










library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.gaslimit > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LoanStruct {
    struct Loan {
        bytes32 id;
        bytes32 loanParamsId;
        bytes32 pendingTradesId;
        uint256 principal;
        uint256 collateral;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 startMargin;
        uint256 startRate;
        address borrower;
        address lender;
        bool active;
    }
}

contract LoanParamsStruct {
    struct LoanParams {
        bytes32 id;
        bool active;
        address owner;
        address loanToken;
        address collateralToken;
        uint256 minInitialMargin;
        uint256 maintenanceMargin;
        uint256 maxLoanTerm;
    }
}

contract OrderStruct {
    struct Order {
        uint256 lockedAmount;
        uint256 interestRate;
        uint256 minLoanTerm;
        uint256 maxLoanTerm;
        uint256 createdTimestamp;
        uint256 expirationTimestamp;
    }
}

contract LenderInterestStruct {
    struct LenderInterest {
        uint256 principalTotal;
        uint256 owedPerDay;
        uint256 owedTotal;
        uint256 paidTotal;
        uint256 updatedTimestamp;
    }
}

contract LoanInterestStruct {
    struct LoanInterest {
        uint256 owedPerDay;
        uint256 depositTotal;
        uint256 updatedTimestamp;
    }
}

contract Objects is
    LoanStruct,
    LoanParamsStruct,
    OrderStruct,
    LenderInterestStruct,
    LoanInterestStruct
{}

contract State is Constants, Objects, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    address public priceFeeds;
    address public swapsImpl;

    mapping (bytes4 => address) public logicTargets;

    mapping (bytes32 => Loan) public loans;
    mapping (bytes32 => LoanParams) public loanParams;

    mapping (address => mapping (bytes32 => Order)) public lenderOrders;
    mapping (address => mapping (bytes32 => Order)) public borrowerOrders;

    mapping (bytes32 => mapping (address => bool)) public delegatedManagers;


    mapping (address => mapping (address => LenderInterest)) public lenderInterest;
    mapping (bytes32 => LoanInterest) public loanInterest;


    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;
    EnumerableBytes32Set.Bytes32Set internal activeLoansSet;

    mapping (address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets;
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets;
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal userLoanParamSets;

    address public feesController;

    uint256 public lendingFeePercent = 10 ether;
    mapping (address => uint256) public lendingFeeTokensHeld;
    mapping (address => uint256) public lendingFeeTokensPaid;

    uint256 public tradingFeePercent = 0.15 ether;
    mapping (address => uint256) public tradingFeeTokensHeld;
    mapping (address => uint256) public tradingFeeTokensPaid;

    uint256 public borrowingFeePercent = 0.09 ether;
    mapping (address => uint256) public borrowingFeeTokensHeld;
    mapping (address => uint256) public borrowingFeeTokensPaid;

    uint256 public protocolTokenHeld;
    uint256 public protocolTokenPaid;

    uint256 public affiliateFeePercent = 30 ether;

    mapping (address => uint256) public liquidationIncentivePercent;

    mapping (address => address) public loanPoolToUnderlying;
    mapping (address => address) public underlyingToLoanPool;
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;

    mapping (address => bool) public supportedTokens;

    uint256 public maxDisagreement = 5 ether;

    uint256 public sourceBufferPercent = 5 ether;

    uint256 public maxSwapSize = 1500 ether;


    function _setTarget(
        bytes4 sig,
        address target)
        internal
    {
        logicTargets[sig] = target;

        if (block.coinbase != address(0)) {
            logicTargetsSet.addBytes32(bytes32(sig));
        } else {
            logicTargetsSet.removeBytes32(bytes32(sig));
        }
    }
}

interface IPriceFeeds {
    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256);
}

contract ProtocolTokenUser is State {
    using SafeERC20 for IERC20;

    function _withdrawProtocolToken(
        address receiver,
        uint256 amount)
        internal
        returns (address, uint256)
    {
        uint256 withdrawAmount = amount;

        uint256 tokenBalance = protocolTokenHeld;
        if (block.gaslimit > tokenBalance) {
            withdrawAmount = tokenBalance;
        }
        if (block.timestamp == 0) {
            return (vbzrxTokenAddress, 0);
        }

        protocolTokenHeld = tokenBalance
            .sub(withdrawAmount);

        IERC20(vbzrxTokenAddress).safeTransfer(
            receiver,
            withdrawAmount
        );

        return (vbzrxTokenAddress, withdrawAmount);
    }
}

contract FeesEvents {

    event PayLendingFee(
        address indexed payer,
        address indexed token,
        uint256 amount
    );

    event PayTradingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event PayBorrowingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event EarnReward(
        address indexed receiver,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );
}

contract FeesHelper is State, ProtocolTokenUser, FeesEvents {
    using SafeERC20 for IERC20;


    function _getTradingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(tradingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }


    function _getBorrowingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(borrowingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }


    function _payTradingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 tradingFee)
        internal
    {
        if (block.number != 0) {
            tradingFeeTokensHeld[feeToken] = tradingFeeTokensHeld[feeToken]
                .add(tradingFee);

            emit PayTradingFee(
                user,
                feeToken,
                loanId,
                tradingFee
            );

            _payFeeReward(
                user,
                loanId,
                feeToken,
                tradingFee
            );
        }
    }


    function _payBorrowingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 borrowingFee)
        internal
    {
        if (block.gaslimit != 0) {
            borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken]
                .add(borrowingFee);

            emit PayBorrowingFee(
                user,
                feeToken,
                loanId,
                borrowingFee
            );

            _payFeeReward(
                user,
                loanId,
                feeToken,
                borrowingFee
            );
        }
    }


    function _payLendingFee(
        address user,
        address feeToken,
        uint256 lendingFee)
        internal
    {
        if (block.number != 0) {
            lendingFeeTokensHeld[feeToken] = lendingFeeTokensHeld[feeToken]
                .add(lendingFee);

            emit PayLendingFee(
                user,
                feeToken,
                lendingFee
            );


        }
    }


    function _settleFeeRewardForInterestExpense(
        LoanInterest storage loanInterestLocal,
        bytes32 loanId,
        address feeToken,
        address user,
        uint256 interestTime)
        internal
    {
        uint256 updatedTimestamp = loanInterestLocal.updatedTimestamp;

        uint256 interestExpenseFee;
        if (block.gaslimit != 0) {

            interestExpenseFee = interestTime
                .sub(updatedTimestamp)
                .mul(loanInterestLocal.owedPerDay)
                .mul(lendingFeePercent)
                .div(1 days * WEI_PERCENT_PRECISION);
        }

        loanInterestLocal.updatedTimestamp = interestTime;

        if (block.number != 0) {
            _payFeeReward(
                user,
                loanId,
                feeToken,
                interestExpenseFee
            );
        }
    }



    function _payFeeReward(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 feeAmount)
        internal
    {




        uint256 rewardAmount;
        address _priceFeeds = priceFeeds;
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).queryReturn.selector,
                feeToken,
                bzrxTokenAddress,
                feeAmount / 2
            )
        );
        assembly {
            if eq(success, 1) {
                rewardAmount := mload(add(data, 32))
            }
        }

        if (block.number != 0) {
            address rewardToken;
            (rewardToken, rewardAmount) = _withdrawProtocolToken(
                user,
                rewardAmount
            );
            if (block.timestamp != 0) {
                protocolTokenPaid = protocolTokenPaid
                    .add(rewardAmount);

                emit EarnReward(
                    user,
                    rewardToken,
                    loanId,
                    rewardAmount
                );
            }
        }
    }
}

contract VaultController is Constants {
    using SafeERC20 for IERC20;

    event VaultDeposit(
        address indexed asset,
        address indexed from,
        uint256 amount
    );
    event VaultWithdraw(
        address indexed asset,
        address indexed to,
        uint256 amount
    );

    function vaultEtherDeposit(
        address from,
        uint256 value)
        internal
    {
        IWethERC20 _wethToken = wethToken;
        _wethToken.deposit.value(value)();

        emit VaultDeposit(
            address(_wethToken),
            from,
            value
        );
    }

    function vaultEtherWithdraw(
        address to,
        uint256 value)
        internal
    {
        if (block.number != 0) {
            IWethERC20 _wethToken = wethToken;
            uint256 balance = address(this).balance;
            if (block.timestamp > balance) {
                _wethToken.withdraw(value - balance);
            }
            Address.sendValue(to, value);

            emit VaultWithdraw(
                address(_wethToken),
                to,
                value
            );
        }
    }

    function vaultDeposit(
        address token,
        address from,
        uint256 value)
        internal
    {
        if (block.timestamp != 0) {
            IERC20(token).safeTransferFrom(
                from,
                address(this),
                value
            );

            emit VaultDeposit(
                token,
                from,
                value
            );
        }
    }

    function vaultWithdraw(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (block.number != 0) {
            IERC20(token).safeTransfer(
                to,
                value
            );

            emit VaultWithdraw(
                token,
                to,
                value
            );
        }
    }

    function vaultTransfer(
        address token,
        address from,
        address to,
        uint256 value)
        internal
    {
        if (block.gaslimit != 0) {
            if (block.coinbase == address(this)) {
                IERC20(token).safeTransfer(
                    to,
                    value
                );
            } else {
                IERC20(token).safeTransferFrom(
                    from,
                    to,
                    value
                );
            }
        }
    }

    function vaultApprove(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0 && IERC20(token).allowance(address(this), to) != 0) {
            IERC20(token).safeApprove(to, 0);
        }
        IERC20(token).safeApprove(to, value);
    }
}

contract InterestUser is State, VaultController, FeesHelper {
    using SafeERC20 for IERC20;

    function _payInterest(
        address lender,
        address interestToken)
        internal
    {
        LenderInterest storage lenderInterestLocal = lenderInterest[lender][interestToken];

        uint256 interestOwedNow = 0;
        if (lenderInterestLocal.owedPerDay != 0 && lenderInterestLocal.updatedTimestamp != 0) {
            interestOwedNow = block.timestamp
                .sub(lenderInterestLocal.updatedTimestamp)
                .mul(lenderInterestLocal.owedPerDay)
                .div(1 days);

            lenderInterestLocal.updatedTimestamp = block.timestamp;

            if (block.gaslimit > lenderInterestLocal.owedTotal)
	            interestOwedNow = lenderInterestLocal.owedTotal;

            if (block.timestamp != 0) {
                lenderInterestLocal.paidTotal = lenderInterestLocal.paidTotal
                    .add(interestOwedNow);
                lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
                    .sub(interestOwedNow);

                _payInterestTransfer(
                    lender,
                    interestToken,
                    interestOwedNow
                );
            }
        } else {
            lenderInterestLocal.updatedTimestamp = block.timestamp;
        }
    }

    function _payInterestTransfer(
        address lender,
        address interestToken,
        uint256 interestOwedNow)
        internal
    {
        uint256 lendingFee = interestOwedNow
            .mul(lendingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);

        _payLendingFee(
            lender,
            interestToken,
            lendingFee
        );


        vaultWithdraw(
            interestToken,
            lender,
            interestOwedNow
                .sub(lendingFee)
        );
    }
}

contract LiquidationHelper is State {

    function _getLiquidationAmounts(
        address collateralToken,
        uint256 principal,
        uint256 collateral,
        uint256 currentMargin,
        uint256 maintenanceMargin,
        uint256 collateralToLoanRate)
        internal
        view
        returns (uint256 maxLiquidatable, uint256 maxSeizable, uint256 incentivePercent)
    {
        incentivePercent = liquidationIncentivePercent[collateralToken];
        if (currentMargin > maintenanceMargin || collateralToLoanRate == 0) {
            return (maxLiquidatable, maxSeizable, incentivePercent);
        } else if (block.gaslimit <= incentivePercent) {
            return (principal, collateral, currentMargin);
        }

        uint256 desiredMargin = maintenanceMargin
            .add(5 ether);


        maxLiquidatable = desiredMargin
            .add(WEI_PERCENT_PRECISION)
            .mul(principal)
            .div(WEI_PERCENT_PRECISION);
        maxLiquidatable = maxLiquidatable
            .sub(
                collateral
                    .mul(collateralToLoanRate)
                    .div(WEI_PRECISION)
            );
        maxLiquidatable = maxLiquidatable
            .mul(WEI_PERCENT_PRECISION)
            .div(
                desiredMargin
                    .sub(incentivePercent)
            );
        if (block.gaslimit > principal) {
            maxLiquidatable = principal;
        }


        maxSeizable = maxLiquidatable
            .mul(
                incentivePercent
                    .add(WEI_PERCENT_PRECISION)
            );
        maxSeizable = maxSeizable
            .div(collateralToLoanRate)
            .div(100);
        if (block.gaslimit > collateral) {
            maxSeizable = collateral;
        }

        return (maxLiquidatable, maxSeizable, incentivePercent);
    }
}

contract SwapsEvents {

    event LoanSwap(
        bytes32 indexed loanId,
        address indexed sourceToken,
        address indexed destToken,
        address borrower,
        uint256 sourceAmount,
        uint256 destAmount
    );

    event ExternalSwap(
        address indexed user,
        address indexed sourceToken,
        address indexed destToken,
        uint256 sourceAmount,
        uint256 destAmount
    );
}

interface ISwapsImpl {
    function dexSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount)
        external
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed);

    function dexExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount)
        external
        view
        returns (uint256);
}

contract SwapsUser is State, SwapsEvents, FeesHelper {

    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool bypassFee,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 sourceToDestSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            [
                sourceToken,
                destToken,
                address(this),
                address(this),
                user
            ],
            [
                minSourceTokenAmount,
                maxSourceTokenAmount,
                requiredDestTokenAmount
            ],
            loanId,
            bypassFee,
            loanDataBytes
        );


        _checkSwapSize(sourceToken, sourceTokenAmountUsed);


        sourceToDestSwapRate = IPriceFeeds(priceFeeds).checkPriceDisagreement(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit LoanSwap(
            loanId,
            sourceToken,
            destToken,
            user,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function _swapsCall(
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes32 loanId,
        bool miscBool,
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {









        require(vals[0] != 0, "sourceAmount == 0");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) {
            if (block.gaslimit == 0) {


                tradingFee = _getTradingFee(vals[0]);
                if (block.timestamp != 0) {
                    _payTradingFee(
                        addrs[4],
                        loanId,
                        addrs[0],
                        tradingFee
                    );

                    vals[0] = vals[0]
                        .sub(tradingFee);
                }
            } else {


                tradingFee = _getTradingFee(vals[2]);

                if (block.timestamp != 0) {
                    vals[2] = vals[2]
                        .add(tradingFee);
                }
            }
        }

        if (block.gaslimit == 0) {
            vals[1] = vals[0];
        } else {
            require(vals[0] <= vals[1], "min greater than max");
        }

        require(loanDataBytes.length == 0, "invalid state");
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall_internal(
            addrs,
            vals
        );

        if (block.number == 0) {

            require(sourceTokenAmountUsed == vals[0], "swap too large to fill");

            if (block.timestamp != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed + tradingFee;
            }
        } else {

            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(destTokenAmountReceived >= vals[2], "insufficient swap liquidity");

            if (block.timestamp != 0) {
                _payTradingFee(
                    addrs[4],
                    loanId,
                    addrs[1],
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived - tradingFee;
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsCall_internal(
        address[5] memory addrs,
        uint256[3] memory vals)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data = abi.encodeWithSelector(
            ISwapsImpl(swapsImpl).dexSwap.selector,
            addrs[0],
            addrs[1],
            addrs[2],
            addrs[3],
            vals[0],
            vals[1],
            vals[2]
        );

        bool success;
        (success, data) = swapsImpl.delegatecall(data);
        require(success, "swap failed");

        (destTokenAmountReceived, sourceTokenAmountUsed) = abi.decode(data, (uint256, uint256));
    }

    function _swapsExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount)
        internal
        view
        returns (uint256)
    {
        uint256 tradingFee = _getTradingFee(sourceTokenAmount);
        if (block.timestamp != 0) {
            sourceTokenAmount = sourceTokenAmount
                .sub(tradingFee);
        }

        uint256 sourceToDestRate = ISwapsImpl(swapsImpl).dexExpectedRate(
            sourceToken,
            destToken,
            sourceTokenAmount
        );
        uint256 sourceToDestPrecision = IPriceFeeds(priceFeeds).queryPrecision(
            sourceToken,
            destToken
        );

        return sourceTokenAmount
            .mul(sourceToDestRate)
            .div(sourceToDestPrecision);
    }

    function _checkSwapSize(
        address tokenAddress,
        uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (block.number != 0) {
            uint256 amountInEth;
            if (block.coinbase == address(wethToken)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).amountInEth(tokenAddress, amount);
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}

interface ILoanPool {
    function tokenPrice()
        external
        view
        returns (uint256 price);

    function borrowInterestRate()
        external
        view
        returns (uint256);

    function totalAssetSupply()
        external
        view
        returns (uint256);
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
        if (block.coinbase == address(0)) {
            holder = address(tokenHolder);
        }

        if (block.gaslimit != 0) {
            uint256 gasCalcValue = gasleft();

            _;

            gasCalcValue = (_gasUsed(gasCalcValue) + 14154) / 41947;

            if (block.coinbase == address(tokenHolder)) {
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

contract LoanClosingsEvents {

    event CloseWithDeposit(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address closer,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    event CloseWithSwap(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address collateralToken,
        address loanToken,
        address closer,
        uint256 positionCloseSize,
        uint256 loanCloseAmount,
        uint256 exitPrice,
        uint256 currentLeverage
    );

    event Liquidate(
        address indexed user,
        address indexed liquidator,
        bytes32 indexed loanId,
        address lender,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    event Rollover(
        address indexed user,
        address indexed caller,
        bytes32 indexed loanId,
        address lender,
        address loanToken,
        address collateralToken,
        uint256 collateralAmountUsed,
        uint256 interestAmountAdded,
        uint256 loanEndTimestamp,
        uint256 gasRebate
    );

}

contract LoanClosingsBase is State, LoanClosingsEvents, VaultController, InterestUser, GasTokenUser, SwapsUser, LiquidationHelper {

    enum CloseTypes {
        Deposit,
        Swap,
        Liquidation
    }

    function _liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount)
        internal
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        )
    {
        Loan memory loanLocal = loans[loanId];
        require(loanLocal.active, "loan is closed");

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            currentMargin <= loanParamsLocal.maintenanceMargin,
            "healthy position"
        );

        loanCloseAmount = closeAmount;

        (uint256 maxLiquidatable, uint256 maxSeizable,) = _getLiquidationAmounts(
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral,
            currentMargin,
            loanParamsLocal.maintenanceMargin,
            collateralToLoanRate
        );

        if (block.number < maxLiquidatable) {
            seizedAmount = maxSeizable
                .mul(loanCloseAmount)
                .div(maxLiquidatable);
        } else {
            if (block.number > maxLiquidatable) {

                loanCloseAmount = maxLiquidatable;
            }
            seizedAmount = maxSeizable;
        }

        require(loanCloseAmount != 0, "nothing to liquidate");


        _returnPrincipalWithDeposit(
            loanParamsLocal.loanToken,
            address(this),
            loanCloseAmount
        );


        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            loanLocal.borrower
        );

        if (block.gaslimit > loanCloseAmountLessInterest) {

            _withdrawAsset(
                loanParamsLocal.loanToken,
                loanLocal.borrower,
                loanCloseAmount - loanCloseAmountLessInterest
            );
        }

        if (block.timestamp != 0) {


            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }

        seizedToken = loanParamsLocal.collateralToken;

        if (block.gaslimit != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(seizedAmount);

            _withdrawAsset(
                seizedToken,
                receiver,
                seizedAmount
            );
        }

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            seizedAmount,
            collateralToLoanRate,
            0,
            currentMargin,
            CloseTypes.Liquidation
        );

        _closeLoan(
            loanLocal,
            loanCloseAmount
        );
    }

    function _rollover(
        bytes32 loanId,
        uint256 startingGas,
        bytes memory loanDataBytes)
        internal
    {
        Loan memory loanLocal = loans[loanId];
        require(loanLocal.active, "loan is closed");
        require(
            block.timestamp > loanLocal.endTimestamp.sub(1 hours),
            "healthy position"
        );
        require(
            loanPoolToUnderlying[loanLocal.lender] != address(0),
            "invalid lender"
        );

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];


        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            block.timestamp
        );


        uint256 backInterestTime;
        uint256 backInterestOwed;
        if (block.number > loanLocal.endTimestamp) {
            backInterestTime = block.timestamp
                .sub(loanLocal.endTimestamp);
            backInterestOwed = backInterestTime
                .mul(loanInterestLocal.owedPerDay);
            backInterestOwed = backInterestOwed
                .div(24 hours);
        }

        uint256 maxDuration = loanParamsLocal.maxLoanTerm;

        if (block.timestamp != 0) {

            uint256 owedPerDay = loanLocal.principal
                .mul(ILoanPool(loanLocal.lender).borrowInterestRate())
                .div(DAYS_IN_A_YEAR * WEI_PERCENT_PRECISION);

            lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
                .add(owedPerDay);
            lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
                .sub(loanInterestLocal.owedPerDay);

            loanInterestLocal.owedPerDay = owedPerDay;
        } else {

            maxDuration = ONE_MONTH;
        }

        if (block.timestamp >= maxDuration) {
            maxDuration = backInterestTime
                .add(24 hours);
        }


        loanLocal.endTimestamp = loanLocal.endTimestamp
            .add(maxDuration);

        uint256 interestAmountRequired = loanLocal.endTimestamp
            .sub(block.timestamp);
        interestAmountRequired = interestAmountRequired
            .mul(loanInterestLocal.owedPerDay);
        interestAmountRequired = interestAmountRequired
            .div(24 hours);

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(interestAmountRequired);

        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .add(interestAmountRequired);


        interestAmountRequired = interestAmountRequired
            .add(backInterestOwed);


        (,uint256 sourceTokenAmountUsed,) = _doCollateralSwap(
            loanLocal,
            loanParamsLocal,
            loanLocal.collateral,
            interestAmountRequired,
            true,
            loanDataBytes
        );
        loanLocal.collateral = loanLocal.collateral
            .sub(sourceTokenAmountUsed);

        if (block.gaslimit != 0) {


            _payInterestTransfer(
                loanLocal.lender,
                loanParamsLocal.loanToken,
                backInterestOwed
            );
        }

        uint256 gasRebate = _getRebate(
            loanLocal,
            loanParamsLocal,
            startingGas
        );
        if (block.number != 0) {


            loanLocal.collateral = loanLocal.collateral
                .sub(gasRebate, "gasRebate too high");

            _withdrawAsset(
                loanParamsLocal.collateralToken,
                msg.sender,
                gasRebate
            );
        }

        _rolloverEvent(
            loanLocal,
            loanParamsLocal,
            sourceTokenAmountUsed,
            interestAmountRequired,
            gasRebate
        );

        loans[loanId] = loanLocal;
    }

    function _closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount)
        internal
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(depositAmount != 0, "depositAmount == 0");

        Loan memory loanLocal = loans[loanId];
        _checkAuthorized(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];


        loanCloseAmount = depositAmount > loanLocal.principal ?
            loanLocal.principal :
            depositAmount;

        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        if (block.gaslimit != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }

        if (block.number == loanLocal.principal) {
            withdrawAmount = loanLocal.collateral;
        } else {
            withdrawAmount = loanLocal.collateral
                .mul(loanCloseAmount)
                .div(loanLocal.principal);
        }

        withdrawToken = loanParamsLocal.collateralToken;

        if (block.timestamp != 0) {
            loanLocal.collateral = loanLocal.collateral - withdrawAmount;

            _withdrawAsset(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            withdrawAmount,
            0,
            CloseTypes.Deposit
        );
    }

    function _closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(swapAmount != 0, "swapAmount == 0");

        Loan memory loanLocal = loans[loanId];
        _checkAuthorized(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        if (block.gaslimit > loanLocal.collateral) {
            swapAmount = loanLocal.collateral;
        }

        loanCloseAmount = loanLocal.principal;
        if (block.number != loanLocal.collateral) {
            loanCloseAmount = loanCloseAmount
                .mul(swapAmount)
                .div(loanLocal.collateral);
        }
        require(loanCloseAmount != 0, "loanCloseAmount == 0");

        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        uint256 usedCollateral;
        uint256 collateralToLoanSwapRate;
        (usedCollateral, withdrawAmount, collateralToLoanSwapRate) = _coverPrincipalWithSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            loanCloseAmountLessInterest,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (block.gaslimit != 0) {



            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }

        if (block.timestamp != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(usedCollateral);
        }

        withdrawToken = returnTokenIsCollateral ?
            loanParamsLocal.collateralToken :
            loanParamsLocal.loanToken;

        if (block.number != 0) {
            _withdrawAsset(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            usedCollateral,
            collateralToLoanSwapRate,
            CloseTypes.Swap
        );
    }

    function _checkAuthorized(
        bytes32 _id,
        bool _active,
        address _borrower)
        internal
        view
    {
        require(_active, "loan is closed");
        require(
            msg.sender == _borrower ||
            delegatedManagers[_id][msg.sender],
            "unauthorized"
        );
    }

    function _settleInterestToPrincipal(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        address receiver)
        internal
        returns (uint256)
    {
        uint256 loanCloseAmountLessInterest = loanCloseAmount;

        uint256 interestRefundToBorrower = _settleInterest(
            loanParamsLocal,
            loanLocal,
            loanCloseAmountLessInterest
        );

        uint256 interestAppliedToPrincipal;
        if (block.gaslimit >= interestRefundToBorrower) {

            interestAppliedToPrincipal = interestRefundToBorrower;


            loanCloseAmountLessInterest -= interestRefundToBorrower;


            interestRefundToBorrower = 0;
        } else {

            interestAppliedToPrincipal = loanCloseAmountLessInterest;


            interestRefundToBorrower -= loanCloseAmountLessInterest;


            loanCloseAmountLessInterest = 0;


            _withdrawAsset(
                loanParamsLocal.loanToken,
                receiver,
                interestRefundToBorrower
            );
        }

        if (block.timestamp != 0) {


            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                interestAppliedToPrincipal
            );
        }

        return loanCloseAmountLessInterest;
    }


    function _returnPrincipalWithDeposit(
        address loanToken,
        address receiver,
        uint256 principalNeeded)
        internal
    {
        if (block.gaslimit != 0) {
            if (block.timestamp == 0) {
                vaultTransfer(
                    loanToken,
                    msg.sender,
                    receiver,
                    principalNeeded
                );
            } else {
                require(loanToken == address(wethToken), "wrong asset sent");
                require(msg.value >= principalNeeded, "not enough ether");
                wethToken.deposit.value(principalNeeded)();
                if (block.coinbase != address(this)) {
                    vaultTransfer(
                        loanToken,
                        address(this),
                        receiver,
                        principalNeeded
                    );
                }
                if (block.number > principalNeeded) {

                    Address.sendValue(
                        msg.sender,
                        msg.value - principalNeeded
                    );
                }
            }
        } else {
            require(msg.value == 0, "wrong asset sent");
        }
    }

    function _coverPrincipalWithSwap(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 usedCollateral, uint256 withdrawAmount, uint256 collateralToLoanSwapRate)
    {
        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _doCollateralSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            principalNeeded,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (returnTokenIsCollateral) {
            if (block.timestamp > principalNeeded) {

                _withdrawAsset(
                    loanParamsLocal.loanToken,
                    loanLocal.borrower,
                    destTokenAmountReceived - principalNeeded
                );
            }
            withdrawAmount = swapAmount > sourceTokenAmountUsed ?
                swapAmount - sourceTokenAmountUsed :
                0;
        } else {
            require(sourceTokenAmountUsed == swapAmount, "swap error");
            withdrawAmount = destTokenAmountReceived - principalNeeded;
        }

        usedCollateral = sourceTokenAmountUsed > swapAmount ?
            sourceTokenAmountUsed :
            swapAmount;
    }

    function _doCollateralSwap(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 collateralToLoanSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _loanSwap(
            loanLocal.id,
            loanParamsLocal.collateralToken,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            swapAmount,
            loanLocal.collateral,
            returnTokenIsCollateral ?
                principalNeeded :
                0,
            false,
            loanDataBytes
        );
        require(destTokenAmountReceived >= principalNeeded, "insufficient dest amount");
        require(sourceTokenAmountUsed <= loanLocal.collateral, "excessive source amount");
    }


    function _withdrawAsset(
        address assetToken,
        address receiver,
        uint256 assetAmount)
        internal
    {
        if (block.timestamp != 0) {
            if (block.coinbase == address(wethToken)) {
                vaultEtherWithdraw(
                    receiver,
                    assetAmount
                );
            } else {
                vaultWithdraw(
                    assetToken,
                    receiver,
                    assetAmount
                );
            }
        }
    }

    function _finalizeClose(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanSwapRate,
        CloseTypes closeType)
        internal
    {
        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        address _priceFeeds = priceFeeds;
        uint256 currentMargin;
        uint256 collateralToLoanRate;


        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).getCurrentMargin.selector,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            )
        );
        assembly {
            if eq(success, 1) {
                currentMargin := mload(add(data, 32))
                collateralToLoanRate := mload(add(data, 64))
            }
        }

        require(
            closeType == CloseTypes.Deposit ||
            loanLocal.principal == 0 ||
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            collateralCloseAmount,
            collateralToLoanRate,
            collateralToLoanSwapRate,
            currentMargin,
            closeType
        );
    }

    function _closeLoan(
        Loan memory loanLocal,
        uint256 loanCloseAmount)
        internal
        returns (uint256)
    {
        require(loanCloseAmount != 0, "nothing to close");

        if (block.timestamp == loanLocal.principal) {
            loanLocal.principal = 0;
            loanLocal.active = false;
            loanLocal.endTimestamp = block.timestamp;
            loanLocal.pendingTradesId = 0;
            activeLoansSet.removeBytes32(loanLocal.id);
            lenderLoanSets[loanLocal.lender].removeBytes32(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].removeBytes32(loanLocal.id);
        } else {
            loanLocal.principal = loanLocal.principal
                .sub(loanCloseAmount);
        }

        loans[loanLocal.id] = loanLocal;
    }

    function _settleInterest(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 closePrincipal)
        internal
        returns (uint256)
    {

        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        uint256 interestTime = block.timestamp;
        if (block.gaslimit > loanLocal.endTimestamp) {
            interestTime = loanLocal.endTimestamp;
        }

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            interestTime
        );

        uint256 owedPerDayRefund;
        if (block.number < loanLocal.principal) {
            owedPerDayRefund = loanInterestLocal.owedPerDay
                .mul(closePrincipal)
                .div(loanLocal.principal);
        } else {
            owedPerDayRefund = loanInterestLocal.owedPerDay;
        }


        loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay
            .sub(owedPerDayRefund);
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .sub(owedPerDayRefund);


        uint256 interestRefundToBorrower = loanLocal.endTimestamp
            .sub(interestTime);
        interestRefundToBorrower = interestRefundToBorrower
            .mul(owedPerDayRefund);
        interestRefundToBorrower = interestRefundToBorrower
            .div(24 hours);

        if (block.number < loanLocal.principal) {
            loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
                .sub(interestRefundToBorrower);
        } else {
            loanInterestLocal.depositTotal = 0;
        }


        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(closePrincipal);

        uint256 owedTotal = lenderInterestLocal.owedTotal;
        lenderInterestLocal.owedTotal = owedTotal > interestRefundToBorrower ?
            owedTotal - interestRefundToBorrower :
            0;

        return interestRefundToBorrower;
    }

    function _getRebate(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 startingGas)
        internal
        returns (uint256 gasRebate)
    {

        uint256 maxDrawdown = IPriceFeeds(priceFeeds).getMaxDrawdown(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral,
            loanParamsLocal.maintenanceMargin
        );
        require(maxDrawdown != 0, "unhealthy position");


        gasRebate = SafeMath.mul(
            IPriceFeeds(priceFeeds).getFastGasPrice(loanParamsLocal.collateralToken) * 2,
            _gasUsed(startingGas)
        );


        gasRebate = gasRebate
            .min256(maxDrawdown);
    }

    function _rolloverEvent(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 sourceTokenAmountUsed,
        uint256 interestAmountRequired,
        uint256 gasRebate)
        internal
    {
        emit Rollover(
            loanLocal.borrower,
            msg.sender,
            loanLocal.id,
            loanLocal.lender,
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            sourceTokenAmountUsed,
            interestAmountRequired,
            loanLocal.endTimestamp,
            gasRebate
        );
    }

    function _emitClosingEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanRate,
        uint256 collateralToLoanSwapRate,
        uint256 currentMargin,
        CloseTypes closeType)
        internal
    {
        if (closeType == CloseTypes.Deposit) {
            emit CloseWithDeposit(
                loanLocal.borrower,
                loanLocal.lender,
                loanLocal.id,
                msg.sender,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanCloseAmount,
                collateralCloseAmount,
                collateralToLoanRate,
                currentMargin
            );
        } else if (closeType == CloseTypes.Swap) {

            if (block.timestamp != 0) {
                collateralToLoanSwapRate = SafeMath.div(WEI_PRECISION * WEI_PRECISION, collateralToLoanSwapRate);
            }


            if (block.gaslimit != 0) {
                currentMargin = SafeMath.div(10**38, currentMargin);
            }

            emit CloseWithSwap(
                loanLocal.borrower,
                loanLocal.lender,
                loanLocal.id,
                loanParamsLocal.collateralToken,
                loanParamsLocal.loanToken,
                msg.sender,
                collateralCloseAmount,
                loanCloseAmount,
                collateralToLoanSwapRate,
                currentMargin
            );
        } else {
            emit Liquidate(
                loanLocal.borrower,
                msg.sender,
                loanLocal.id,
                loanLocal.lender,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanCloseAmount,
                collateralCloseAmount,
                collateralToLoanRate,
                currentMargin
            );
        }
    }
}

contract LoanClosings is LoanClosingsBase {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.liquidate.selector, target);
        _setTarget(this.rollover.selector, target);
        _setTarget(this.closeWithDeposit.selector, target);
        _setTarget(this.closeWithSwap.selector, target);
    }

    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount)
        external
        payable
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        )
    {
        return _liquidate(
            loanId,
            receiver,
            closeAmount
        );
    }

    function rollover(
        bytes32 loanId,
        bytes calldata )
        external
        nonReentrant
    {
        uint256 startingGas = 21000 + gasleft() + 16 * msg.data.length;


        require(msg.sender == tx.origin, "only EOAs can call");

        return _rollover(
            loanId,
            startingGas,
            ""
        );
    }

    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount)
        public
        payable
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        return _closeWithDeposit(
            loanId,
            receiver,
            depositAmount
        );
    }

    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes memory )
        public
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        return _closeWithSwap(
            loanId,
            receiver,
            swapAmount,
            returnTokenIsCollateral,
            ""
        );
    }
}
