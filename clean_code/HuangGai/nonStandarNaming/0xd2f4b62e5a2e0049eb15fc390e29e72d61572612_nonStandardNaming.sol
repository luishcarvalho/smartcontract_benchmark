pragma solidity 0.5.9;


library SafeMath {

    function MUL605(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV657(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB818(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD758(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD448(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


interface IERC20 {
    function TRANSFER631(address to, uint256 value) external returns (bool);

    function APPROVE666(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM769(address from, address to, uint256 value) external returns (bool);

    function TOTALSUPPLY761() external view returns (uint256);

    function BALANCEOF683(address who) external view returns (uint256);

    function ALLOWANCE981(address owner, address spender) external view returns (uint256);

    event TRANSFER920(address indexed from, address indexed to, uint256 value);

    event APPROVAL971(address indexed owner, address indexed spender, uint256 value);
}


contract Claimable {
    address public owner;
    address public pendingOwner;

    event OWNERSHIPTRANSFERRED96(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() public {
        owner = msg.sender;
    }


    modifier ONLYOWNER329() {
        require(msg.sender == owner);
        _;
    }


    modifier ONLYPENDINGOWNER713() {
        require(msg.sender == pendingOwner);
        _;
    }


    function TRANSFEROWNERSHIP498(address newOwner) public ONLYOWNER329 {
        pendingOwner = newOwner;
    }


    function CLAIMOWNERSHIP631() public ONLYPENDINGOWNER713 {
        emit OWNERSHIPTRANSFERRED96(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


contract Keeper is Claimable {
    using SafeMath for uint256;
    IERC20 public token;

    uint256 public unFreezeStartDate;

    uint256 public totalUnFreezeDate;

    mapping(address => uint256) public balances;

    mapping(address => uint256) public withdrawnBalances;

    uint256 public totalBalance;

    constructor(
        IERC20 _token,
        uint256 _unFreezeStartDate,
        uint256 _totalUnFreezeDate
    ) public {

        require(_unFreezeStartDate >= block.timestamp);
        require(_totalUnFreezeDate > _unFreezeStartDate);
        token = _token;
        unFreezeStartDate = _unFreezeStartDate;
        totalUnFreezeDate = _totalUnFreezeDate;
    }


    function ADDBALANCE553(address _to, uint256 _value) public ONLYOWNER329 {
        require(_to != address(0));
        require(_value > 0);
        require(totalBalance.ADD758(_value)
                <= token.BALANCEOF683(address(this)), "not enough tokens");
        balances[_to] = balances[_to].ADD758(_value);
        totalBalance = totalBalance.ADD758(_value);
    }


    function WITHDRAW512(address _to, uint256 _value) public {
        require(_to != address(0));
        require(_value > 0);
        require(unFreezeStartDate < now, "not unfrozen yet");
        require(
            (GETUNFROZENAMOUNT640(msg.sender).SUB818(withdrawnBalances[msg.sender]))
            >= _value
        );
        withdrawnBalances[msg.sender] = withdrawnBalances[msg.sender].ADD758(_value);
        totalBalance = totalBalance.SUB818(_value);
        token.TRANSFER631(_to, _value);
    }


    function GETUNFROZENAMOUNT640(address _holder) public view returns (uint256) {
        if (now > unFreezeStartDate) {
            if (now > totalUnFreezeDate) {
                return balances[_holder];
            }
            uint256 partialFreezePeriodLen =
                totalUnFreezeDate.SUB818(unFreezeStartDate);
            uint256 secondsSincePeriodStart = now.SUB818(unFreezeStartDate);
            uint256 amount = balances[_holder]
                .MUL605(secondsSincePeriodStart)
                .DIV657(partialFreezePeriodLen);
            return amount;
        }
        return 0;
    }
}
