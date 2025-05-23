pragma solidity ^0.5.7;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
        if (a == 0)
		{
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b != 0);
        return a % b;
    }
}

interface IERC20
{
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20
{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256)
    {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferBulk(address[] memory _toAccounts, uint256[] memory _tokenAmount) public returns (bool)
    {
        require(_toAccounts.length == _tokenAmount.length);
        for(uint i=0; i<_toAccounts.length; i++)
        {
            _transfer(msg.sender, _toAccounts[i], _tokenAmount[i]);
        }
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool)
    {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal
    {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal
    {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);

        require(_balances[account].add(value) <= 11111111111000000000000000000, "Cant mint > then 11111111111111");

        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal
    {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);

        require(_totalSupply.sub(value) > _totalSupply.div(2), "Cant burn > 50% of total supply");

        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal
    {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

library Roles
{
    struct Role
    {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal
    {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal
    {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool)
    {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;
    address private _owner;

    constructor () internal {
        _owner = msg.sender;
        _addMinter(msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function renounceMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract ERC20Detailed is IERC20
{
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public
    {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory)
    {
        return _name;
    }

    function symbol() public view returns (string memory)
    {
        return _symbol;
    }

    function decimals() public view returns (uint8)
    {
        return _decimals;
    }
}

contract ERC20Burnable is ERC20, MinterRole
{
    function burn(uint256 value) public onlyMinter
    {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public onlyMinter
    {
        _burnFrom(from, value);
    }
}

contract ERC20Mintable is ERC20, MinterRole
{
    function mint(address to, uint256 value) public onlyMinter returns (bool)
    {
        _mint(to, value);
        return true;
    }
}

contract Token is ERC20, MinterRole, ERC20Detailed, ERC20Mintable, ERC20Burnable
{
    address payable private _wallet;
    uint256 private _weiRaised;

    constructor (address payable wallet) public ERC20Detailed("CryptoWars Token", "CWT", 18)
    {
        _wallet = wallet;
	}

	function () external payable
    {
        uint256 weiAmount = msg.value;
        require(msg.sender != address(0));
        require(weiAmount != 0);
        _weiRaised = _weiRaised.add(weiAmount);
        _wallet.call.gas(2301).value(msg.value)("");
    }

    function wallet() public view returns (address payable)
    {
        return _wallet;
    }

    function weiRaised() public view returns (uint256)
    {
        return _weiRaised;
    }
}
