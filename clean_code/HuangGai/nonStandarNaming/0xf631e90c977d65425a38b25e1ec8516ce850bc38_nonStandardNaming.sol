

pragma solidity ^0.5.7;


library SafeMath {

    function ADD107(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }


    function SUB463(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    function MUL691(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }


    function DIV78(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }


    function MOD635(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



interface IERC20{
    function NAME279() external view returns (string memory);
    function SYMBOL160() external view returns (string memory);
    function DECIMALS981() external view returns (uint256);
    function TOTALSUPPLY34() external view returns (uint256);
    function BALANCEOF441(address owner) external view returns (uint256);
    function TRANSFER28(address to, uint256 value) external returns (bool);
    function TRANSFERFROM551(address from, address to, uint256 value) external returns (bool);
    function APPROVE505(address spender, uint256 value) external returns (bool);
    function ALLOWANCE331(address owner, address spender) external view returns (uint256);
    event TRANSFER884(address indexed from, address indexed to, uint256 value);
    event APPROVAL336(address indexed owner, address indexed spender, uint256 value);
}



contract Ownable {
    address internal _owner;

    event OWNERSHIPTRANSFERRED839(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED839(address(0), _owner);
    }


    function OWNER665() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER540() {
        require(msg.sender == _owner);
        _;
    }


    function TRANSFEROWNERSHIP744(address newOwner) external ONLYOWNER540 {
        require(newOwner != address(0));
        _owner = newOwner;
        emit OWNERSHIPTRANSFERRED839(_owner, newOwner);
    }


    function RESCUETOKENS997(address tokenAddr, address receiver, uint256 amount) external ONLYOWNER540 {
        IERC20 _token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 balance = _token.BALANCEOF441(address(this));

        require(balance >= amount);
        assert(_token.TRANSFER28(receiver, amount));
    }


    function WITHDRAWETHER684(address payable to, uint256 amount) external ONLYOWNER540 {
        require(to != address(0));

        uint256 balance = address(this).balance;

        require(balance >= amount);
        to.transfer(amount);
    }
}


contract Pausable is Ownable {
    bool private _paused;

    event PAUSED954(address account);
    event UNPAUSED286(address account);

    constructor () internal {
        _paused = false;
    }


    function PAUSED229() public view returns (bool) {
        return _paused;
    }


    modifier WHENNOTPAUSED225() {
        require(!_paused);
        _;
    }


    modifier WHENPAUSED333() {
        require(_paused);
        _;
    }


    function PAUSE345() external ONLYOWNER540 WHENNOTPAUSED225 {
        _paused = true;
        emit PAUSED954(msg.sender);
    }


    function UNPAUSE328() external ONLYOWNER540 WHENPAUSED333 {
        _paused = false;
        emit UNPAUSED286(msg.sender);
    }
}


contract ChainOfFaith is Ownable, Pausable, IERC20 {
    using SafeMath for uint256;

    string private _name = "ChainOfFaith";
    string private _symbol = "XKY";
    uint256 private _decimals = 18;
    uint256 private _cap = 2000000000 * 10 **_decimals;
    uint256 private _totalSupply;

    mapping (address => bool) private _minter;
    event MINT409(address indexed to, uint256 value);
    event MINTERCHANGED454(address account, bool state);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event DONATE221(address indexed account, uint256 amount);


    constructor() public {
        _minter[msg.sender] = true;
    }


    function () external payable {
        emit DONATE221(msg.sender, msg.value);
    }



    function NAME279() public view returns (string memory) {
        return _name;
    }


    function SYMBOL160() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS981() public view returns (uint256) {
        return _decimals;
    }


    function CAP336() public view returns (uint256) {
        return _cap;
    }


    function TOTALSUPPLY34() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF441(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE331(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER28(address to, uint256 value) public WHENNOTPAUSED225 returns (bool) {

        _TRANSFER463(msg.sender, to, value);
        return true;
    }


    function APPROVE505(address spender, uint256 value) public returns (bool) {
        _APPROVE461(msg.sender, spender, value);
        return true;
    }


    function INCREASEALLOWANCE237(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE461(msg.sender, spender, _allowed[msg.sender][spender].ADD107(addedValue));
        return true;
    }


    function DECREASEALLOWANCE179(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE461(msg.sender, spender, _allowed[msg.sender][spender].SUB463(subtractedValue));
        return true;
    }

    function TRANSFERFROM551(address from, address to, uint256 value) public WHENNOTPAUSED225 returns (bool) {
        require(_allowed[from][msg.sender] >= value);
        _TRANSFER463(from, to, value);
        _APPROVE461(from, msg.sender, _allowed[from][msg.sender].SUB463(value));
        return true;
    }


    function _TRANSFER463(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].SUB463(value);
        _balances[to] = _balances[to].ADD107(value);
        emit TRANSFER884(from, to, value);
    }


    function _APPROVE461(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowed[owner][spender] = value;
        emit APPROVAL336(owner, spender, value);
    }



    modifier ONLYMINTER928() {
        require(_minter[msg.sender]);
        _;
    }


    function ISMINTER255(address account) public view returns (bool) {
        return _minter[account];
    }


    function SETMINTERSTATE291(address account, bool state) external ONLYOWNER540 {
        _minter[account] = state;
        emit MINTERCHANGED454(account, state);
    }


    function MINT898(address to, uint256 value) public ONLYMINTER928 returns (bool) {
        _MINT906(to, value);
        return true;
    }


    function _MINT906(address account, uint256 value) internal {
        require(_totalSupply.ADD107(value) <= _cap);
        require(account != address(0));

        _totalSupply = _totalSupply.ADD107(value);
        _balances[account] = _balances[account].ADD107(value);
        emit MINT409(account, value);
        emit TRANSFER884(address(0), account, value);
    }
}
