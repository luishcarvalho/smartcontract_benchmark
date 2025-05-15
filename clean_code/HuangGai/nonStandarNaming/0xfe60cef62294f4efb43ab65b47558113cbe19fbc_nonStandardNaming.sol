pragma solidity ^0.5.4;

interface IERC20 {
    function TRANSFER517(address to, uint256 value) external returns (bool);

    function APPROVE399(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM891(address from, address to, uint256 value) external returns (bool);

    function TOTALSUPPLY740() external view returns (uint256);

    function BALANCEOF13(address who) external view returns (uint256);

    function ALLOWANCE192(address owner, address spender) external view returns (uint256);

    event TRANSFER171(address indexed from, address indexed to, uint256 value);

    event APPROVAL960(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function MUL899(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV62(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB911(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD826(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD263(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;


    function TOTALSUPPLY740() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF13(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE192(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER517(address to, uint256 value) public returns (bool) {
        _TRANSFER255(msg.sender, to, value);
        return true;
    }


    function APPROVE399(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit APPROVAL960(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM891(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].SUB911(value);
        _TRANSFER255(from, to, value);
        emit APPROVAL960(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }


    function INCREASEALLOWANCE464(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].ADD826(addedValue);
        emit APPROVAL960(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function DECREASEALLOWANCE155(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].SUB911(subtractedValue);
        emit APPROVAL960(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function _TRANSFER255(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].SUB911(value);
        _balances[to] = _balances[to].ADD826(value);
        emit TRANSFER171(from, to, value);
    }


    function _MINT939(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.ADD826(value);
        _balances[account] = _balances[account].ADD826(value);
        emit TRANSFER171(address(0), account, value);
    }


    function _BURN464(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.SUB911(value);
        _balances[account] = _balances[account].SUB911(value);
        emit TRANSFER171(account, address(0), value);
    }


    function _BURNFROM886(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].SUB911(value);
        _BURN464(account, value);
        emit APPROVAL960(account, msg.sender, _allowed[account][msg.sender]);
    }
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


    function NAME528() public view returns (string memory) {
        return _name;
    }


    function SYMBOL252() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS194() public view returns (uint8) {
        return _decimals;
    }
}

contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED81(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED81(address(0), _owner);
    }


    function OWNER239() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER127() {
        require(ISOWNER809());
        _;
    }


    function ISOWNER809() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP995() public ONLYOWNER127 {
        emit OWNERSHIPTRANSFERRED81(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP522(address newOwner) public ONLYOWNER127 {
        _TRANSFEROWNERSHIP774(newOwner);
    }


    function _TRANSFEROWNERSHIP774(address newOwner) internal {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED81(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ExtraTerrestrial is ERC20Detailed, ERC20, Ownable {

    using SafeMath for uint256;

    constructor(address _tokenHolder)
        public
        ERC20Detailed("ExtraTerrestrial", "ETER", 18)
    {
        _MINT939(_tokenHolder, 30000000000000000000000000);
    }

}
