pragma solidity ^0.5.10;




library SafeMath {

    function ADD174(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB458(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function MUL842(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV712(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }


    function MOD1000(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}




interface IERC20 {

    function TOTALSUPPLY713() external view returns (uint256);


    function BALANCEOF597(address account) external view returns (uint256);


    function TRANSFER875(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE411(address owner, address spender) external view returns (uint256);


    function APPROVE183(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM17(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER72(address indexed from, address indexed to, uint256 value);


    event APPROVAL424(address indexed owner, address indexed spender, uint256 value);
}




contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED585(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED585(address(0), _owner);
    }


    function OWNER749() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER904() {
        require(ISOWNER531(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER531() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP876() public ONLYOWNER904 {
        emit OWNERSHIPTRANSFERRED585(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP672(address newOwner) public ONLYOWNER904 {
        _TRANSFEROWNERSHIP705(newOwner);
    }


    function _TRANSFEROWNERSHIP705(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED585(_owner, newOwner);
        _owner = newOwner;
    }
}




contract TokenRecover is Ownable {


    function RECOVERERC20610(address tokenAddress, uint256 tokenAmount) public ONLYOWNER904 {
        IERC20(tokenAddress).TRANSFER875(OWNER749(), tokenAmount);
    }
}




library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }


    function ADD174(Role storage role, address account) internal {
        require(!HAS393(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }


    function REMOVE440(Role storage role, address account) internal {
        require(HAS393(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }


    function HAS393(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}



contract OperatorRole {
    using Roles for Roles.Role;

    event OPERATORADDED296(address indexed account);
    event OPERATORREMOVED455(address indexed account);

    Roles.Role private _operators;

    constructor() internal {
        _ADDOPERATOR180(msg.sender);
    }

    modifier ONLYOPERATOR220() {
        require(ISOPERATOR589(msg.sender));
        _;
    }

    function ISOPERATOR589(address account) public view returns (bool) {
        return _operators.HAS393(account);
    }

    function ADDOPERATOR496(address account) public ONLYOPERATOR220 {
        _ADDOPERATOR180(account);
    }

    function RENOUNCEOPERATOR579() public {
        _REMOVEOPERATOR220(msg.sender);
    }

    function _ADDOPERATOR180(address account) internal {
        _operators.ADD174(account);
        emit OPERATORADDED296(account);
    }

    function _REMOVEOPERATOR220(address account) internal {
        _operators.REMOVE440(account);
        emit OPERATORREMOVED455(account);
    }
}




contract Contributions is OperatorRole, TokenRecover {
    using SafeMath for uint256;

    struct Contributor {
        uint256 weiAmount;
        uint256 tokenAmount;
        bool exists;
    }


    uint256 private _totalSoldTokens;


    uint256 private _totalWeiRaised;


    address[] private _addresses;


    mapping(address => Contributor) private _contributors;

    constructor() public {}


    function TOTALSOLDTOKENS700() public view returns (uint256) {
        return _totalSoldTokens;
    }


    function TOTALWEIRAISED967() public view returns (uint256) {
        return _totalWeiRaised;
    }


    function GETCONTRIBUTORADDRESS38(uint256 index) public view returns (address) {
        return _addresses[index];
    }


    function GETCONTRIBUTORSLENGTH778() public view returns (uint) {
        return _addresses.length;
    }


    function WEICONTRIBUTION247(address account) public view returns (uint256) {
        return _contributors[account].weiAmount;
    }


    function TOKENBALANCE103(address account) public view returns (uint256) {
        return _contributors[account].tokenAmount;
    }


    function CONTRIBUTOREXISTS747(address account) public view returns (bool) {
        return _contributors[account].exists;
    }


    function ADDBALANCE147(address account, uint256 weiAmount, uint256 tokenAmount) public ONLYOPERATOR220 {
        if (!_contributors[account].exists) {
            _addresses.push(account);
            _contributors[account].exists = true;
        }

        _contributors[account].weiAmount = _contributors[account].weiAmount.ADD174(weiAmount);
        _contributors[account].tokenAmount = _contributors[account].tokenAmount.ADD174(tokenAmount);

        _totalWeiRaised = _totalWeiRaised.ADD174(weiAmount);
        _totalSoldTokens = _totalSoldTokens.ADD174(tokenAmount);
    }


    function REMOVEOPERATOR69(address account) public ONLYOWNER904 {
        _REMOVEOPERATOR220(account);
    }
}
