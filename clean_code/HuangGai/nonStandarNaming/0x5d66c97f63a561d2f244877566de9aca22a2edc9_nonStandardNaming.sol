pragma solidity ^0.5.8;




interface IERC20 {

    function TOTALSUPPLY24() external view returns (uint256);


    function BALANCEOF234(address account) external view returns (uint256);


    function TRANSFER72(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE257(address owner, address spender) external view returns (uint256);


    function APPROVE45(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM346(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER728(address indexed from, address indexed to, uint256 value);


    event APPROVAL558(address indexed owner, address indexed spender, uint256 value);
}




contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    function NAME136() public view returns (string memory) {
        return _name;
    }


    function SYMBOL217() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS964() public view returns (uint8) {
        return _decimals;
    }
}




library SafeMath {

    function ADD825(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB689(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function MUL868(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV452(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }


    function MOD717(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}




contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;


    function TOTALSUPPLY24() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF234(address account) public view returns (uint256) {
        return _balances[account];
    }


    function TRANSFER72(address recipient, uint256 amount) public returns (bool) {
        _TRANSFER437(msg.sender, recipient, amount);
        return true;
    }


    function ALLOWANCE257(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE45(address spender, uint256 value) public returns (bool) {
        _APPROVE89(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM346(address sender, address recipient, uint256 amount) public returns (bool) {
        _TRANSFER437(sender, recipient, amount);
        _APPROVE89(sender, msg.sender, _allowances[sender][msg.sender].SUB689(amount));
        return true;
    }


    function INCREASEALLOWANCE86(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE89(msg.sender, spender, _allowances[msg.sender][spender].ADD825(addedValue));
        return true;
    }


    function DECREASEALLOWANCE981(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE89(msg.sender, spender, _allowances[msg.sender][spender].SUB689(subtractedValue));
        return true;
    }


    function _TRANSFER437(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB689(amount);
        _balances[recipient] = _balances[recipient].ADD825(amount);
        emit TRANSFER728(sender, recipient, amount);
    }


    function _MINT126(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD825(amount);
        _balances[account] = _balances[account].ADD825(amount);
        emit TRANSFER728(address(0), account, amount);
    }


    function _BURN761(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.SUB689(value);
        _balances[account] = _balances[account].SUB689(value);
        emit TRANSFER728(account, address(0), value);
    }


    function _APPROVE89(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit APPROVAL558(owner, spender, value);
    }


    function _BURNFROM912(address account, uint256 amount) internal {
        _BURN761(account, amount);
        _APPROVE89(account, msg.sender, _allowances[account][msg.sender].SUB689(amount));
    }
}




library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }


    function ADD825(Role storage role, address account) internal {
        require(!HAS200(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }


    function REMOVE879(Role storage role, address account) internal {
        require(HAS200(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }


    function HAS200(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}



contract MinterRole {
    using Roles for Roles.Role;

    event MINTERADDED281(address indexed account);
    event MINTERREMOVED788(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _ADDMINTER695(msg.sender);
    }

    modifier ONLYMINTER448() {
        require(ISMINTER103(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function ISMINTER103(address account) public view returns (bool) {
        return _minters.HAS200(account);
    }

    function ADDMINTER340(address account) public ONLYMINTER448 {
        _ADDMINTER695(account);
    }

    function RENOUNCEMINTER82() public {
        _REMOVEMINTER969(msg.sender);
    }

    function _ADDMINTER695(address account) internal {
        _minters.ADD825(account);
        emit MINTERADDED281(account);
    }

    function _REMOVEMINTER969(address account) internal {
        _minters.REMOVE879(account);
        emit MINTERREMOVED788(account);
    }
}




contract ERC20Mintable is ERC20, MinterRole {

    function MINT699(address account, uint256 amount) public ONLYMINTER448 returns (bool) {
        _MINT126(account, amount);
        return true;
    }
}




contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;


    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }


    function CAP280() public view returns (uint256) {
        return _cap;
    }


    function _MINT126(address account, uint256 value) internal {
        require(TOTALSUPPLY24().ADD825(value) <= _cap, "ERC20Capped: cap exceeded");
        super._MINT126(account, value);
    }
}




contract ERC20Burnable is ERC20 {

    function BURN558(uint256 amount) public {
        _BURN761(msg.sender, amount);
    }


    function BURNFROM709(address account, uint256 amount) public {
        _BURNFROM912(account, amount);
    }
}




contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED785(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED785(address(0), _owner);
    }


    function OWNER790() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER785() {
        require(ISOWNER48(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER48() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP92() public ONLYOWNER785 {
        emit OWNERSHIPTRANSFERRED785(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP413(address newOwner) public ONLYOWNER785 {
        _TRANSFEROWNERSHIP978(newOwner);
    }


    function _TRANSFEROWNERSHIP978(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED785(_owner, newOwner);
        _owner = newOwner;
    }
}




contract TokenRecover is Ownable {


    function RECOVERERC20723(address tokenAddress, uint256 tokenAmount) public ONLYOWNER785 {
        IERC20(tokenAddress).TRANSFER72(OWNER790(), tokenAmount);
    }
}



contract OperatorRole {
    using Roles for Roles.Role;

    event OPERATORADDED875(address indexed account);
    event OPERATORREMOVED255(address indexed account);

    Roles.Role private _operators;

    constructor() internal {
        _ADDOPERATOR101(msg.sender);
    }

    modifier ONLYOPERATOR594() {
        require(ISOPERATOR640(msg.sender));
        _;
    }

    function ISOPERATOR640(address account) public view returns (bool) {
        return _operators.HAS200(account);
    }

    function ADDOPERATOR763(address account) public ONLYOPERATOR594 {
        _ADDOPERATOR101(account);
    }

    function RENOUNCEOPERATOR674() public {
        _REMOVEOPERATOR451(msg.sender);
    }

    function _ADDOPERATOR101(address account) internal {
        _operators.ADD825(account);
        emit OPERATORADDED875(account);
    }

    function _REMOVEOPERATOR451(address account) internal {
        _operators.REMOVE879(account);
        emit OPERATORREMOVED255(account);
    }
}




contract BaseERC20Token is ERC20Detailed, ERC20Capped, ERC20Burnable, OperatorRole, TokenRecover {

    event MINTFINISHED767();
    event TRANSFERENABLED385();


    bool private _mintingFinished = false;


    bool private _transferEnabled = false;


    modifier CANMINT798() {
        require(!_mintingFinished);
        _;
    }


    modifier CANTRANSFER140(address from) {
        require(_transferEnabled || ISOPERATOR640(from));
        _;
    }


    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        uint256 initialSupply
    )
        public
        ERC20Detailed(name, symbol, decimals)
        ERC20Capped(cap)
    {
        if (initialSupply > 0) {
            _MINT126(OWNER790(), initialSupply);
        }
    }


    function MINTINGFINISHED780() public view returns (bool) {
        return _mintingFinished;
    }


    function TRANSFERENABLED7() public view returns (bool) {
        return _transferEnabled;
    }


    function MINT699(address to, uint256 value) public CANMINT798 returns (bool) {
        return super.MINT699(to, value);
    }


    function TRANSFER72(address to, uint256 value) public CANTRANSFER140(msg.sender) returns (bool) {
        return super.TRANSFER72(to, value);
    }


    function TRANSFERFROM346(address from, address to, uint256 value) public CANTRANSFER140(from) returns (bool) {
        return super.TRANSFERFROM346(from, to, value);
    }


    function FINISHMINTING211() public ONLYOWNER785 CANMINT798 {
        _mintingFinished = true;

        emit MINTFINISHED767();
    }


    function ENABLETRANSFER141() public ONLYOWNER785 {
        _transferEnabled = true;

        emit TRANSFERENABLED385();
    }


    function REMOVEOPERATOR532(address account) public ONLYOWNER785 {
        _REMOVEOPERATOR451(account);
    }


    function REMOVEMINTER389(address account) public ONLYOWNER785 {
        _REMOVEMINTER969(account);
    }
}




contract ERC20Token is BaseERC20Token {

    string public builtOn = "https:

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        uint256 initialSupply
    )
        public
        BaseERC20Token(name, symbol, decimals, cap, initialSupply)
    {}
}
