pragma solidity ^0.5.2;



library SafeMath {

    function MUL349(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV494(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB222(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD957(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD515(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}




interface IERC20 {
    function TRANSFER654(address to, uint256 value) external returns (bool);

    function APPROVE690(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM635(address from, address to, uint256 value) external returns (bool);

    function TOTALSUPPLY611() external view returns (uint256);

    function BALANCEOF924(address who) external view returns (uint256);

    function ALLOWANCE449(address owner, address spender) external view returns (uint256);

    event TRANSFER887(address indexed from, address indexed to, uint256 value);

    event APPROVAL197(address indexed owner, address indexed spender, uint256 value);
}



contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;


    function TOTALSUPPLY611() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF924(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE449(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER654(address to, uint256 value) public returns (bool) {
        _TRANSFER715(msg.sender, to, value);
        return true;
    }


    function APPROVE690(address spender, uint256 value) public returns (bool) {
        _APPROVE421(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM635(address from, address to, uint256 value) public returns (bool) {
        _TRANSFER715(from, to, value);
        _APPROVE421(from, msg.sender, _allowed[from][msg.sender].SUB222(value));
        return true;
    }


    function INCREASEALLOWANCE587(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE421(msg.sender, spender, _allowed[msg.sender][spender].ADD957(addedValue));
        return true;
    }


    function DECREASEALLOWANCE809(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE421(msg.sender, spender, _allowed[msg.sender][spender].SUB222(subtractedValue));
        return true;
    }


    function _TRANSFER715(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].SUB222(value);
        _balances[to] = _balances[to].ADD957(value);
        emit TRANSFER887(from, to, value);
    }


    function _MINT763(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.ADD957(value);
        _balances[account] = _balances[account].ADD957(value);
        emit TRANSFER887(address(0), account, value);
    }


    function _BURN831(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.SUB222(value);
        _balances[account] = _balances[account].SUB222(value);
        emit TRANSFER887(account, address(0), value);
    }


    function _APPROVE421(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit APPROVAL197(owner, spender, value);
    }


    function _BURNFROM745(address account, uint256 value) internal {
        _BURN831(account, value);
        _APPROVE421(account, msg.sender, _allowed[account][msg.sender].SUB222(value));
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


    function NAME439() public view returns (string memory) {
        return _name;
    }


    function SYMBOL644() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS386() public view returns (uint8) {
        return _decimals;
    }
}




contract ERC20Burnable is ERC20 {

    function BURN559(uint256 value) public {
        _BURN831(msg.sender, value);
    }


    function BURNFROM391(address from, uint256 value) public {
        _BURNFROM745(from, value);
    }
}




contract SponbToken is ERC20, ERC20Detailed, ERC20Burnable {
    uint8 public constant decimals147 = 18;
    uint256 public constant initial_uint750 = 3500000000;
    uint256 public constant initial_supply663 = initial_uint750 * (10 ** uint256(decimals147));


    constructor () public ERC20Detailed("SponbToken", "SPO", decimals147) {
        _MINT763(msg.sender, initial_supply663);
    }
}
