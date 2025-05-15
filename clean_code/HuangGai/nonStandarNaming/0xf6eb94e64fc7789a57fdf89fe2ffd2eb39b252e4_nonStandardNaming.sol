



pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


interface IWeth {
    function DEPOSIT413() external payable;
    function WITHDRAW1000(uint256 wad) external;
}

contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function TOTALSUPPLY320() public view returns (uint256);
    function BALANCEOF760(address _who) public view returns (uint256);
    function ALLOWANCE148(address _owner, address _spender) public view returns (uint256);
    function APPROVE600(address _spender, uint256 _value) public returns (bool);
    function TRANSFER238(address _to, uint256 _value) public returns (bool);
    function TRANSFERFROM597(address _from, address _to, uint256 _value) public returns (bool);
    event TRANSFER322(address indexed from, address indexed to, uint256 value);
    event APPROVAL667(address indexed owner, address indexed spender, uint256 value);
}

contract IWethERC20 is IWeth, IERC20 {}

contract Constants {

    uint256 internal constant wei_precision427 = 10**18;
    uint256 internal constant wei_percent_precision736 = 10**20;

    uint256 internal constant days_in_a_year553 = 365;
    uint256 internal constant one_month196 = 2628000;

    string internal constant userrewardsid759 = "UserRewards";

    IWethERC20 public constant wethtoken696 = IWethERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant bzrxtokenaddress831 = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address public constant vbzrxtokenaddress602 = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
}


library EnumerableBytes32Set {

    struct Bytes32Set {


        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }


    function ADDADDRESS118(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return ADDBYTES32720(set, value);
    }


    function ADDBYTES32720(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!CONTAINS194(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }


    function REMOVEADDRESS815(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return REMOVEBYTES32129(set, value);
    }


    function REMOVEBYTES32129(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (CONTAINS194(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;


            if (lastIndex != toDeleteIndex) {
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


    function CONTAINS194(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }


    function CONTAINSADDRESS180(Bytes32Set storage set, address addrvalue)
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


    function ENUMERATE547(Bytes32Set storage set, uint256 start, uint256 count)
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


    function LENGTH537(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }


    function GET436(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }


    function GETADDRESS452(Bytes32Set storage set, uint256 index)
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



    uint256 internal constant reentrancy_guard_free973 = 1;


    uint256 internal constant reentrancy_guard_locked356 = 2;


    uint256 internal reentrancyLock = reentrancy_guard_free973;


    modifier NONREENTRANT587() {
        require(reentrancyLock == reentrancy_guard_free973, "nonReentrant");
        reentrancyLock = reentrancy_guard_locked356;
        _;
        reentrancyLock = reentrancy_guard_free973;
    }
}


contract Context {


    constructor () internal { }


    function _MSGSENDER414() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA879() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED809(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER414();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED809(address(0), msgSender);
    }


    function OWNER514() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER855() {
        require(ISOWNER719(), "unauthorized");
        _;
    }


    function ISOWNER719() public view returns (bool) {
        return _MSGSENDER414() == _owner;
    }


    function TRANSFEROWNERSHIP334(address newOwner) public ONLYOWNER855 {
        _TRANSFEROWNERSHIP592(newOwner);
    }


    function _TRANSFEROWNERSHIP592(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED809(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {

    function ADD350(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB395(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB395(a, b, "SafeMath: subtraction overflow");
    }


    function SUB395(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL0(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV729(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV729(a, b, "SafeMath: division by zero");
    }


    function DIV729(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function DIVCEIL360(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIVCEIL360(a, b, "SafeMath: division by zero");
    }


    function DIVCEIL360(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        if (a == 0) {
            return 0;
        }
        uint256 c = ((a - 1) / b) + 1;

        return c;
    }


    function MOD504(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD504(a, b, "SafeMath: modulo by zero");
    }


    function MOD504(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function MIN256991(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}


library Address {

    function ISCONTRACT390(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function TOPAYABLE724(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function SENDVALUE363(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER502(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN109(token, abi.encodeWithSelector(token.TRANSFER238.selector, to, value));
    }

    function SAFETRANSFERFROM715(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN109(token, abi.encodeWithSelector(token.TRANSFERFROM597.selector, from, to, value));
    }

    function SAFEAPPROVE311(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE148(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN109(token, abi.encodeWithSelector(token.APPROVE600.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE505(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE148(address(this), spender).ADD350(value);
        CALLOPTIONALRETURN109(token, abi.encodeWithSelector(token.APPROVE600.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE766(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE148(address(this), spender).SUB395(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN109(token, abi.encodeWithSelector(token.APPROVE600.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN109(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT390(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

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

    mapping (address => mapping (address => uint256)) public liquidationIncentivePercent;

    mapping (address => address) public loanPoolToUnderlying;
    mapping (address => address) public underlyingToLoanPool;
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;

    mapping (address => bool) public supportedTokens;

    uint256 public maxDisagreement = 5 ether;

    uint256 public sourceBufferPercent = 5 ether;

    uint256 public maxSwapSize = 1500 ether;


    function _SETTARGET405(
        bytes4 sig,
        address target)
        internal
    {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.ADDBYTES32720(bytes32(sig));
        } else {
            logicTargetsSet.REMOVEBYTES32129(bytes32(sig));
        }
    }
}

interface IPriceFeeds {
    function QUERYRATE923(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function QUERYPRECISION662(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function QUERYRETURN272(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function CHECKPRICEDISAGREEMENT80(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function AMOUNTINETH718(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function GETMAXDRAWDOWN818(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function GETCURRENTMARGINANDCOLLATERALSIZE534(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function GETCURRENTMARGIN887(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function SHOULDLIQUIDATE902(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function GETFASTGASPRICE944(
        address payToken)
        external
        view
        returns (uint256);
}

contract FeesEvents {

    event PAYLENDINGFEE908(
        address indexed payer,
        address indexed token,
        uint256 amount
    );

    event PAYTRADINGFEE956(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event PAYBORROWINGFEE80(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event EARNREWARD21(
        address indexed receiver,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );
}

contract FeesHelper is State, FeesEvents {
    using SafeERC20 for IERC20;


    function _GETTRADINGFEE787(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .MUL0(tradingFeePercent)
            .DIVCEIL360(wei_percent_precision736);
    }


    function _GETBORROWINGFEE631(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .MUL0(borrowingFeePercent)
            .DIVCEIL360(wei_percent_precision736);
    }


    function _PAYTRADINGFEE747(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 tradingFee)
        internal
    {
        if (tradingFee != 0) {
            tradingFeeTokensHeld[feeToken] = tradingFeeTokensHeld[feeToken]
                .ADD350(tradingFee);

            emit PAYTRADINGFEE956(
                user,
                feeToken,
                loanId,
                tradingFee
            );

            _PAYFEEREWARD533(
                user,
                loanId,
                feeToken,
                tradingFee
            );
        }
    }


    function _PAYBORROWINGFEE445(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 borrowingFee)
        internal
    {
        if (borrowingFee != 0) {
            borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken]
                .ADD350(borrowingFee);

            emit PAYBORROWINGFEE80(
                user,
                feeToken,
                loanId,
                borrowingFee
            );

            _PAYFEEREWARD533(
                user,
                loanId,
                feeToken,
                borrowingFee
            );
        }
    }


    function _PAYLENDINGFEE461(
        address user,
        address feeToken,
        uint256 lendingFee)
        internal
    {
        if (lendingFee != 0) {
            lendingFeeTokensHeld[feeToken] = lendingFeeTokensHeld[feeToken]
                .ADD350(lendingFee);

            emit PAYLENDINGFEE908(
                user,
                feeToken,
                lendingFee
            );


        }
    }


    function _SETTLEFEEREWARDFORINTERESTEXPENSE273(
        LoanInterest storage loanInterestLocal,
        bytes32 loanId,
        address feeToken,
        address user,
        uint256 interestTime)
        internal
    {
        uint256 updatedTimestamp = loanInterestLocal.updatedTimestamp;

        uint256 interestExpenseFee;
        if (updatedTimestamp != 0) {

            interestExpenseFee = interestTime
                .SUB395(updatedTimestamp)
                .MUL0(loanInterestLocal.owedPerDay)
                .MUL0(lendingFeePercent)
                .DIV729(1 days * wei_percent_precision736);
        }

        loanInterestLocal.updatedTimestamp = interestTime;

        if (interestExpenseFee != 0) {
            _PAYFEEREWARD533(
                user,
                loanId,
                feeToken,
                interestExpenseFee
            );
        }
    }


    function _PAYFEEREWARD533(
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
                IPriceFeeds(_priceFeeds).QUERYRETURN272.selector,
                feeToken,
                bzrxtokenaddress831,
                feeAmount / 2
            )
        );
        assembly {
            if eq(success, 1) {
                rewardAmount := mload(add(data, 32))
            }
        }

        if (rewardAmount != 0) {
            uint256 tokenBalance = protocolTokenHeld;
            if (rewardAmount > tokenBalance) {
                rewardAmount = tokenBalance;
            }
            if (rewardAmount != 0) {
                protocolTokenHeld = tokenBalance
                    .SUB395(rewardAmount);

                bytes32 slot = keccak256(abi.encodePacked(user, userrewardsid759));
                assembly {
                    sstore(slot, add(sload(slot), rewardAmount))
                }

                emit EARNREWARD21(
                    user,
                    vbzrxtokenaddress602,
                    loanId,
                    rewardAmount
                );
            }
        }
    }
}

contract VaultController is Constants {
    using SafeERC20 for IERC20;

    event VAULTDEPOSIT514(
        address indexed asset,
        address indexed from,
        uint256 amount
    );
    event VAULTWITHDRAW726(
        address indexed asset,
        address indexed to,
        uint256 amount
    );

    function VAULTETHERDEPOSIT545(
        address from,
        uint256 value)
        internal
    {
        IWethERC20 _wethToken = wethtoken696;
        _wethToken.DEPOSIT413.value(value)();

        emit VAULTDEPOSIT514(
            address(_wethToken),
            from,
            value
        );
    }

    function VAULTETHERWITHDRAW1(
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IWethERC20 _wethToken = wethtoken696;
            uint256 balance = address(this).balance;
            if (value > balance) {
                _wethToken.WITHDRAW1000(value - balance);
            }
            Address.SENDVALUE363(to, value);

            emit VAULTWITHDRAW726(
                address(_wethToken),
                to,
                value
            );
        }
    }

    function VAULTDEPOSIT722(
        address token,
        address from,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).SAFETRANSFERFROM715(
                from,
                address(this),
                value
            );

            emit VAULTDEPOSIT514(
                token,
                from,
                value
            );
        }
    }

    function VAULTWITHDRAW131(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).SAFETRANSFER502(
                to,
                value
            );

            emit VAULTWITHDRAW726(
                token,
                to,
                value
            );
        }
    }

    function VAULTTRANSFER888(
        address token,
        address from,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            if (from == address(this)) {
                IERC20(token).SAFETRANSFER502(
                    to,
                    value
                );
            } else {
                IERC20(token).SAFETRANSFERFROM715(
                    from,
                    to,
                    value
                );
            }
        }
    }

    function VAULTAPPROVE996(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0 && IERC20(token).ALLOWANCE148(address(this), to) != 0) {
            IERC20(token).SAFEAPPROVE311(to, 0);
        }
        IERC20(token).SAFEAPPROVE311(to, value);
    }
}

contract InterestUser is State, VaultController, FeesHelper {
    using SafeERC20 for IERC20;

    function _PAYINTEREST683(
        address lender,
        address interestToken)
        internal
    {
        LenderInterest storage lenderInterestLocal = lenderInterest[lender][interestToken];

        uint256 interestOwedNow = 0;
        if (lenderInterestLocal.owedPerDay != 0 && lenderInterestLocal.updatedTimestamp != 0) {
            interestOwedNow = block.timestamp
                .SUB395(lenderInterestLocal.updatedTimestamp)
                .MUL0(lenderInterestLocal.owedPerDay)
                .DIV729(1 days);

            lenderInterestLocal.updatedTimestamp = block.timestamp;

            if (interestOwedNow > lenderInterestLocal.owedTotal)
	            interestOwedNow = lenderInterestLocal.owedTotal;

            if (interestOwedNow != 0) {
                lenderInterestLocal.paidTotal = lenderInterestLocal.paidTotal
                    .ADD350(interestOwedNow);
                lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
                    .SUB395(interestOwedNow);

                _PAYINTERESTTRANSFER995(
                    lender,
                    interestToken,
                    interestOwedNow
                );
            }
        } else {
            lenderInterestLocal.updatedTimestamp = block.timestamp;
        }
    }

    function _PAYINTERESTTRANSFER995(
        address lender,
        address interestToken,
        uint256 interestOwedNow)
        internal
    {
        uint256 lendingFee = interestOwedNow
            .MUL0(lendingFeePercent)
            .DIVCEIL360(wei_percent_precision736);

        _PAYLENDINGFEE461(
            lender,
            interestToken,
            lendingFee
        );


        VAULTWITHDRAW131(
            interestToken,
            lender,
            interestOwedNow
                .SUB395(lendingFee)
        );
    }
}

contract LiquidationHelper is State {

    function _GETLIQUIDATIONAMOUNTS758(
        uint256 principal,
        uint256 collateral,
        uint256 currentMargin,
        uint256 maintenanceMargin,
        uint256 collateralToLoanRate,
        uint256 incentivePercent)
        internal
        pure
        returns (uint256 maxLiquidatable, uint256 maxSeizable)
    {
        if (currentMargin > maintenanceMargin || collateralToLoanRate == 0) {
            return (maxLiquidatable, maxSeizable);
        } else if (currentMargin <= incentivePercent) {
            return (principal, collateral);
        }

        uint256 desiredMargin = maintenanceMargin
            .ADD350(5 ether);


        maxLiquidatable = desiredMargin
            .ADD350(wei_percent_precision736)
            .MUL0(principal)
            .DIV729(wei_percent_precision736);
        maxLiquidatable = maxLiquidatable
            .SUB395(
                collateral
                    .MUL0(collateralToLoanRate)
                    .DIV729(wei_precision427)
            );
        maxLiquidatable = maxLiquidatable
            .MUL0(wei_percent_precision736)
            .DIV729(
                desiredMargin
                    .SUB395(incentivePercent)
            );
        if (maxLiquidatable > principal) {
            maxLiquidatable = principal;
        }


        maxSeizable = maxLiquidatable
            .MUL0(
                incentivePercent
                    .ADD350(wei_percent_precision736)
            );
        maxSeizable = maxSeizable
            .DIV729(collateralToLoanRate)
            .DIV729(100);
        if (maxSeizable > collateral) {
            maxSeizable = collateral;
        }

        return (maxLiquidatable, maxSeizable);
    }
}

contract SwapsEvents {

    event LOANSWAP63(
        bytes32 indexed loanId,
        address indexed sourceToken,
        address indexed destToken,
        address borrower,
        uint256 sourceAmount,
        uint256 destAmount
    );

    event EXTERNALSWAP169(
        address indexed user,
        address indexed sourceToken,
        address indexed destToken,
        uint256 sourceAmount,
        uint256 destAmount
    );
}

interface ISwapsImpl {
    function DEXSWAP890(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount)
        external
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed);

    function DEXEXPECTEDRATE181(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount)
        external
        view
        returns (uint256);
}

contract SwapsUser is State, SwapsEvents, FeesHelper {

    function _LOANSWAP802(
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
        (destTokenAmountReceived, sourceTokenAmountUsed) = _SWAPSCALL433(
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


        _CHECKSWAPSIZE456(sourceToken, sourceTokenAmountUsed);


        sourceToDestSwapRate = IPriceFeeds(priceFeeds).CHECKPRICEDISAGREEMENT80(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit LOANSWAP63(
            loanId,
            sourceToken,
            destToken,
            user,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function _SWAPSCALL433(
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
            if (vals[2] == 0) {


                tradingFee = _GETTRADINGFEE787(vals[0]);
                if (tradingFee != 0) {
                    _PAYTRADINGFEE747(
                        addrs[4],
                        loanId,
                        addrs[0],
                        tradingFee
                    );

                    vals[0] = vals[0]
                        .SUB395(tradingFee);
                }
            } else {


                tradingFee = _GETTRADINGFEE787(vals[2]);

                if (tradingFee != 0) {
                    vals[2] = vals[2]
                        .ADD350(tradingFee);
                }
            }
        }

        if (vals[1] == 0) {
            vals[1] = vals[0];
        } else {
            require(vals[0] <= vals[1], "min greater than max");
        }

        require(loanDataBytes.length == 0, "invalid state");
        (destTokenAmountReceived, sourceTokenAmountUsed) = _SWAPSCALL_INTERNAL704(
            addrs,
            vals
        );

        if (vals[2] == 0) {

            require(sourceTokenAmountUsed == vals[0], "swap too large to fill");

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed + tradingFee;
            }
        } else {

            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(destTokenAmountReceived >= vals[2], "insufficient swap liquidity");

            if (tradingFee != 0) {
                _PAYTRADINGFEE747(
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

    function _SWAPSCALL_INTERNAL704(
        address[5] memory addrs,
        uint256[3] memory vals)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data = abi.encodeWithSelector(
            ISwapsImpl(swapsImpl).DEXSWAP890.selector,
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

    function _SWAPSEXPECTEDRETURN731(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount)
        internal
        view
        returns (uint256)
    {
        uint256 tradingFee = _GETTRADINGFEE787(sourceTokenAmount);
        if (tradingFee != 0) {
            sourceTokenAmount = sourceTokenAmount
                .SUB395(tradingFee);
        }

        uint256 sourceToDestRate = ISwapsImpl(swapsImpl).DEXEXPECTEDRATE181(
            sourceToken,
            destToken,
            sourceTokenAmount
        );
        uint256 sourceToDestPrecision = IPriceFeeds(priceFeeds).QUERYPRECISION662(
            sourceToken,
            destToken
        );

        return sourceTokenAmount
            .MUL0(sourceToDestRate)
            .DIV729(sourceToDestPrecision);
    }

    function _CHECKSWAPSIZE456(
        address tokenAddress,
        uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (_maxSwapSize != 0) {
            uint256 amountInEth;
            if (tokenAddress == address(wethtoken696)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).AMOUNTINETH718(tokenAddress, amount);
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}

interface ILoanPool {
    function TOKENPRICE528()
        external
        view
        returns (uint256 price);

    function BORROWINTERESTRATE911()
        external
        view
        returns (uint256);

    function TOTALASSETSUPPLY606()
        external
        view
        returns (uint256);
}

contract ITokenHolderLike {
    function BALANCEOF760(address _who) public view returns (uint256);
    function FREEUPTO522(uint256 value) public returns (uint256);
    function FREEFROMUPTO607(address from, uint256 value) public returns (uint256);
}

contract GasTokenUser {

    ITokenHolderLike constant public gastoken34 = ITokenHolderLike(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    ITokenHolderLike constant public tokenholder491 = ITokenHolderLike(0x55Eb3DD3f738cfdda986B8Eff3fa784477552C61);

    modifier USESGASTOKEN390(address holder) {
        if (holder == address(0)) {
            holder = address(tokenholder491);
        }

        if (gastoken34.BALANCEOF760(holder) != 0) {
            uint256 gasCalcValue = gasleft();

            _;

            gasCalcValue = (_GASUSED486(gasCalcValue) + 14154) / 41947;

            if (holder == address(tokenholder491)) {
                tokenholder491.FREEUPTO522(
                    gasCalcValue
                );
            } else {
                tokenholder491.FREEFROMUPTO607(
                    holder,
                    gasCalcValue
                );
            }

        } else {
            _;
        }
    }

    function _GASUSED486(
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

    event CLOSEWITHDEPOSIT137(
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

    event CLOSEWITHSWAP232(
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

    event LIQUIDATE807(
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

    event ROLLOVER791(
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

    function _LIQUIDATE208(
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

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).GETCURRENTMARGIN887(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            currentMargin <= loanParamsLocal.maintenanceMargin,
            "healthy position"
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        loanCloseAmount = closeAmount;

        (uint256 maxLiquidatable, uint256 maxSeizable) = _GETLIQUIDATIONAMOUNTS758(
            loanLocal.principal,
            loanLocal.collateral,
            currentMargin,
            loanParamsLocal.maintenanceMargin,
            collateralToLoanRate,
            liquidationIncentivePercent[loanParamsLocal.loanToken][loanParamsLocal.collateralToken]
        );

        if (loanCloseAmount < maxLiquidatable) {
            seizedAmount = maxSeizable
                .MUL0(loanCloseAmount)
                .DIV729(maxLiquidatable);
        } else {
            if (loanCloseAmount > maxLiquidatable) {

                loanCloseAmount = maxLiquidatable;
            }
            seizedAmount = maxSeizable;
        }

        require(loanCloseAmount != 0, "nothing to liquidate");


        _RETURNPRINCIPALWITHDEPOSIT767(
            loanParamsLocal.loanToken,
            address(this),
            loanCloseAmount
        );


        uint256 loanCloseAmountLessInterest = _SETTLEINTERESTTOPRINCIPAL473(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            loanLocal.borrower
        );

        if (loanCloseAmount > loanCloseAmountLessInterest) {

            _WITHDRAWASSET523(
                loanParamsLocal.loanToken,
                loanLocal.borrower,
                loanCloseAmount - loanCloseAmountLessInterest
            );
        }

        if (loanCloseAmountLessInterest != 0) {


            VAULTWITHDRAW131(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }

        seizedToken = loanParamsLocal.collateralToken;

        if (seizedAmount != 0) {
            loanLocal.collateral = loanLocal.collateral
                .SUB395(seizedAmount);

            _WITHDRAWASSET523(
                seizedToken,
                receiver,
                seizedAmount
            );
        }

        _EMITCLOSINGEVENTS670(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            seizedAmount,
            collateralToLoanRate,
            0,
            currentMargin,
            CloseTypes.Liquidation
        );

        _CLOSELOAN770(
            loanLocal,
            loanCloseAmount
        );
    }

    function _ROLLOVER360(
        bytes32 loanId,
        uint256 startingGas,
        bytes memory loanDataBytes)
        internal
    {
        Loan memory loanLocal = loans[loanId];
        require(loanLocal.active, "loan is closed");
        require(
            block.timestamp > loanLocal.endTimestamp.SUB395(1 hours),
            "healthy position"
        );
        require(
            loanPoolToUnderlying[loanLocal.lender] != address(0),
            "invalid lender"
        );

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];


        _PAYINTEREST683(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        _SETTLEFEEREWARDFORINTERESTEXPENSE273(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            block.timestamp
        );


        uint256 backInterestTime;
        uint256 backInterestOwed;
        if (block.timestamp > loanLocal.endTimestamp) {
            backInterestTime = block.timestamp
                .SUB395(loanLocal.endTimestamp);
            backInterestOwed = backInterestTime
                .MUL0(loanInterestLocal.owedPerDay);
            backInterestOwed = backInterestOwed
                .DIV729(24 hours);
        }

        uint256 maxDuration = loanParamsLocal.maxLoanTerm;

        if (maxDuration != 0) {

            uint256 owedPerDay = loanLocal.principal
                .MUL0(ILoanPool(loanLocal.lender).BORROWINTERESTRATE911())
                .DIV729(days_in_a_year553 * wei_percent_precision736);

            lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
                .ADD350(owedPerDay);
            lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
                .SUB395(loanInterestLocal.owedPerDay);

            loanInterestLocal.owedPerDay = owedPerDay;
        } else {

            maxDuration = one_month196;
        }

        if (backInterestTime >= maxDuration) {
            maxDuration = backInterestTime
                .ADD350(24 hours);
        }


        loanLocal.endTimestamp = loanLocal.endTimestamp
            .ADD350(maxDuration);

        uint256 interestAmountRequired = loanLocal.endTimestamp
            .SUB395(block.timestamp);
        interestAmountRequired = interestAmountRequired
            .MUL0(loanInterestLocal.owedPerDay);
        interestAmountRequired = interestAmountRequired
            .DIV729(24 hours);

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .ADD350(interestAmountRequired);

        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .ADD350(interestAmountRequired);


        interestAmountRequired = interestAmountRequired
            .ADD350(backInterestOwed);


        (,uint256 sourceTokenAmountUsed,) = _DOCOLLATERALSWAP473(
            loanLocal,
            loanParamsLocal,
            loanLocal.collateral,
            interestAmountRequired,
            true,
            loanDataBytes
        );
        loanLocal.collateral = loanLocal.collateral
            .SUB395(sourceTokenAmountUsed);

        if (backInterestOwed != 0) {


            _PAYINTERESTTRANSFER995(
                loanLocal.lender,
                loanParamsLocal.loanToken,
                backInterestOwed
            );
        }

        uint256 gasRebate = _GETREBATE222(
            loanLocal,
            loanParamsLocal,
            startingGas
        );
        if (gasRebate != 0) {


            loanLocal.collateral = loanLocal.collateral
                .SUB395(gasRebate, "gasRebate too high");

            _WITHDRAWASSET523(
                loanParamsLocal.collateralToken,
                msg.sender,
                gasRebate
            );
        }

        _ROLLOVEREVENT507(
            loanLocal,
            loanParamsLocal,
            sourceTokenAmountUsed,
            interestAmountRequired,
            gasRebate
        );

        loans[loanId] = loanLocal;
    }

    function _CLOSEWITHDEPOSIT462(
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
        _CHECKAUTHORIZED85(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];


        loanCloseAmount = depositAmount > loanLocal.principal ?
            loanLocal.principal :
            depositAmount;

        uint256 loanCloseAmountLessInterest = _SETTLEINTERESTTOPRINCIPAL473(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        if (loanCloseAmountLessInterest != 0) {
            _RETURNPRINCIPALWITHDEPOSIT767(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }

        uint256 withdrawAmount;
        if (loanCloseAmount == loanLocal.principal) {

            withdrawAmount = loanLocal.collateral;
            withdrawToken = loanParamsLocal.collateralToken;
            loanLocal.collateral = 0;

            _WITHDRAWASSET523(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _FINALIZECLOSE273(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            withdrawAmount,
            0,
            CloseTypes.Deposit
        );
    }

    function _CLOSEWITHSWAP962(
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
        _CHECKAUTHORIZED85(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        if (swapAmount > loanLocal.collateral) {
            swapAmount = loanLocal.collateral;
        }

        loanCloseAmount = loanLocal.principal;
        if (swapAmount != loanLocal.collateral) {
            loanCloseAmount = loanCloseAmount
                .MUL0(swapAmount)
                .DIV729(loanLocal.collateral);
        }
        require(loanCloseAmount != 0, "loanCloseAmount == 0");

        uint256 loanCloseAmountLessInterest = _SETTLEINTERESTTOPRINCIPAL473(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        uint256 usedCollateral;
        uint256 collateralToLoanSwapRate;
        (usedCollateral, withdrawAmount, collateralToLoanSwapRate) = _COVERPRINCIPALWITHSWAP500(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            loanCloseAmountLessInterest,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (loanCloseAmountLessInterest != 0) {



            VAULTWITHDRAW131(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }

        if (usedCollateral != 0) {
            loanLocal.collateral = loanLocal.collateral
                .SUB395(usedCollateral);
        }

        withdrawToken = returnTokenIsCollateral ?
            loanParamsLocal.collateralToken :
            loanParamsLocal.loanToken;

        if (withdrawAmount != 0) {
            _WITHDRAWASSET523(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _FINALIZECLOSE273(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            usedCollateral,
            collateralToLoanSwapRate,
            CloseTypes.Swap
        );
    }

    function _CHECKAUTHORIZED85(
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

    function _SETTLEINTERESTTOPRINCIPAL473(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        address receiver)
        internal
        returns (uint256)
    {
        uint256 loanCloseAmountLessInterest = loanCloseAmount;

        uint256 interestRefundToBorrower = _SETTLEINTEREST436(
            loanParamsLocal,
            loanLocal,
            loanCloseAmountLessInterest
        );

        uint256 interestAppliedToPrincipal;
        if (loanCloseAmountLessInterest >= interestRefundToBorrower) {

            interestAppliedToPrincipal = interestRefundToBorrower;


            loanCloseAmountLessInterest -= interestRefundToBorrower;


            interestRefundToBorrower = 0;
        } else {

            interestAppliedToPrincipal = loanCloseAmountLessInterest;


            interestRefundToBorrower -= loanCloseAmountLessInterest;


            loanCloseAmountLessInterest = 0;


            _WITHDRAWASSET523(
                loanParamsLocal.loanToken,
                receiver,
                interestRefundToBorrower
            );
        }

        if (interestAppliedToPrincipal != 0) {


            VAULTWITHDRAW131(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                interestAppliedToPrincipal
            );
        }

        return loanCloseAmountLessInterest;
    }


    function _RETURNPRINCIPALWITHDEPOSIT767(
        address loanToken,
        address receiver,
        uint256 principalNeeded)
        internal
    {
        if (principalNeeded != 0) {
            if (msg.value == 0) {
                VAULTTRANSFER888(
                    loanToken,
                    msg.sender,
                    receiver,
                    principalNeeded
                );
            } else {
                require(loanToken == address(wethtoken696), "wrong asset sent");
                require(msg.value >= principalNeeded, "not enough ether");
                wethtoken696.DEPOSIT413.value(principalNeeded)();
                if (receiver != address(this)) {
                    VAULTTRANSFER888(
                        loanToken,
                        address(this),
                        receiver,
                        principalNeeded
                    );
                }
                if (msg.value > principalNeeded) {

                    Address.SENDVALUE363(
                        msg.sender,
                        msg.value - principalNeeded
                    );
                }
            }
        } else {
            require(msg.value == 0, "wrong asset sent");
        }
    }

    function _COVERPRINCIPALWITHSWAP500(
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
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _DOCOLLATERALSWAP473(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            principalNeeded,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (returnTokenIsCollateral) {
            if (destTokenAmountReceived > principalNeeded) {

                _WITHDRAWASSET523(
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

    function _DOCOLLATERALSWAP473(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 collateralToLoanSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _LOANSWAP802(
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


    function _WITHDRAWASSET523(
        address assetToken,
        address receiver,
        uint256 assetAmount)
        internal
    {
        if (assetAmount != 0) {
            if (assetToken == address(wethtoken696)) {
                VAULTETHERWITHDRAW1(
                    receiver,
                    assetAmount
                );
            } else {
                VAULTWITHDRAW131(
                    assetToken,
                    receiver,
                    assetAmount
                );
            }
        }
    }

    function _FINALIZECLOSE273(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanSwapRate,
        CloseTypes closeType)
        internal
    {
        _CLOSELOAN770(
            loanLocal,
            loanCloseAmount
        );

        address _priceFeeds = priceFeeds;
        uint256 currentMargin;
        uint256 collateralToLoanRate;


        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).GETCURRENTMARGIN887.selector,
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

        _EMITCLOSINGEVENTS670(
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

    function _CLOSELOAN770(
        Loan memory loanLocal,
        uint256 loanCloseAmount)
        internal
        returns (uint256)
    {
        require(loanCloseAmount != 0, "nothing to close");

        if (loanCloseAmount == loanLocal.principal) {
            loanLocal.principal = 0;
            loanLocal.active = false;
            loanLocal.endTimestamp = block.timestamp;
            loanLocal.pendingTradesId = 0;
            activeLoansSet.REMOVEBYTES32129(loanLocal.id);
            lenderLoanSets[loanLocal.lender].REMOVEBYTES32129(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].REMOVEBYTES32129(loanLocal.id);
        } else {
            loanLocal.principal = loanLocal.principal
                .SUB395(loanCloseAmount);
        }

        loans[loanLocal.id] = loanLocal;
    }

    function _SETTLEINTEREST436(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 closePrincipal)
        internal
        returns (uint256)
    {

        _PAYINTEREST683(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        uint256 interestTime = block.timestamp;
        if (interestTime > loanLocal.endTimestamp) {
            interestTime = loanLocal.endTimestamp;
        }

        _SETTLEFEEREWARDFORINTERESTEXPENSE273(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            interestTime
        );

        uint256 owedPerDayRefund;
        if (closePrincipal < loanLocal.principal) {
            owedPerDayRefund = loanInterestLocal.owedPerDay
                .MUL0(closePrincipal)
                .DIV729(loanLocal.principal);
        } else {
            owedPerDayRefund = loanInterestLocal.owedPerDay;
        }


        loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay
            .SUB395(owedPerDayRefund);
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .SUB395(owedPerDayRefund);


        uint256 interestRefundToBorrower = loanLocal.endTimestamp
            .SUB395(interestTime);
        interestRefundToBorrower = interestRefundToBorrower
            .MUL0(owedPerDayRefund);
        interestRefundToBorrower = interestRefundToBorrower
            .DIV729(24 hours);

        if (closePrincipal < loanLocal.principal) {
            loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
                .SUB395(interestRefundToBorrower);
        } else {
            loanInterestLocal.depositTotal = 0;
        }


        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .SUB395(closePrincipal);

        uint256 owedTotal = lenderInterestLocal.owedTotal;
        lenderInterestLocal.owedTotal = owedTotal > interestRefundToBorrower ?
            owedTotal - interestRefundToBorrower :
            0;

        return interestRefundToBorrower;
    }

    function _GETREBATE222(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 startingGas)
        internal
        returns (uint256 gasRebate)
    {

        uint256 maxDrawdown = IPriceFeeds(priceFeeds).GETMAXDRAWDOWN818(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral,
            loanParamsLocal.maintenanceMargin
        );
        require(maxDrawdown != 0, "unhealthy position");


        gasRebate = SafeMath.MUL0(
            IPriceFeeds(priceFeeds).GETFASTGASPRICE944(loanParamsLocal.collateralToken) * 2,
            _GASUSED486(startingGas)
        );


        gasRebate = gasRebate
            .MIN256991(maxDrawdown);
    }

    function _ROLLOVEREVENT507(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 sourceTokenAmountUsed,
        uint256 interestAmountRequired,
        uint256 gasRebate)
        internal
    {
        emit ROLLOVER791(
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

    function _EMITCLOSINGEVENTS670(
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
            emit CLOSEWITHDEPOSIT137(
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

            if (collateralToLoanSwapRate != 0) {
                collateralToLoanSwapRate = SafeMath.DIV729(wei_precision427 * wei_precision427, collateralToLoanSwapRate);
            }


            if (currentMargin != 0) {
                currentMargin = SafeMath.DIV729(10**38, currentMargin);
            }

            emit CLOSEWITHSWAP232(
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
            emit LIQUIDATE807(
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

contract LoanClosingsWithGasToken is LoanClosingsBase {

    function INITIALIZE821(
        address target)
        external
        ONLYOWNER855
    {
        _SETTARGET405(this.LIQUIDATEWITHGASTOKEN944.selector, target);
        _SETTARGET405(this.ROLLOVERWITHGASTOKEN936.selector, target);
        _SETTARGET405(this.CLOSEWITHDEPOSITWITHGASTOKEN57.selector, target);
        _SETTARGET405(this.CLOSEWITHSWAPWITHGASTOKEN662.selector, target);
    }

    function LIQUIDATEWITHGASTOKEN944(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 closeAmount)
        external
        payable
        USESGASTOKEN390(gasTokenUser)
        NONREENTRANT587
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        )
    {
        return _LIQUIDATE208(
            loanId,
            receiver,
            closeAmount
        );
    }

    function ROLLOVERWITHGASTOKEN936(
        bytes32 loanId,
        address gasTokenUser,
        bytes calldata                  )
        external
        USESGASTOKEN390(gasTokenUser)
        NONREENTRANT587
    {
        uint256 startingGas = 21000 + gasleft() + 16 * msg.data.length;


        require(msg.sender == tx.origin, "only EOAs can call");

        return _ROLLOVER360(
            loanId,
            startingGas,
            ""
        );
    }

    function CLOSEWITHDEPOSITWITHGASTOKEN57(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 depositAmount)
        public
        payable
        USESGASTOKEN390(gasTokenUser)
        NONREENTRANT587
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        return _CLOSEWITHDEPOSIT462(
            loanId,
            receiver,
            depositAmount
        );
    }

    function CLOSEWITHSWAPWITHGASTOKEN662(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes memory                  )
        public
        USESGASTOKEN390(gasTokenUser)
        NONREENTRANT587
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        return _CLOSEWITHSWAP962(
            loanId,
            receiver,
            swapAmount,
            returnTokenIsCollateral,
            ""
        );
    }
}
