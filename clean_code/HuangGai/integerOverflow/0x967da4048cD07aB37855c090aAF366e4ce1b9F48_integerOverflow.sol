



pragma solidity 0.5.3;






interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}





library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}













contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }







    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }






    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }










    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }











    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }











    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }







    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }








    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }







    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }









    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}





library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }




    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }




    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }





    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
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





contract ERC20Mintable is ERC20, MinterRole {






    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}





contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    constructor (uint256 cap) public {
        require(cap > 0);
        _cap = cap;
    }




    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap);
        super._mint(account, value);
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




    function name() public view returns (string memory) {
        return _name;
    }




    function symbol() public view returns (string memory) {
        return _symbol;
    }




    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}





contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }




    modifier whenNotPaused() {
        require(!_paused);
        _;
    }




    modifier whenPaused() {
        require(_paused);
        _;
    }




    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }




    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}





contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}






contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner());
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }







    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}






contract OceanToken is Ownable, ERC20Pausable, ERC20Detailed, ERC20Capped {

    using SafeMath for uint256;

    uint8 constant DECIMALS = 18;
    uint256 constant CAP = 1410000000;
    uint256 TOTALSUPPLY = CAP.mul(uint256(10) ** DECIMALS);


    address[] private accounts = new address[](0);
    mapping(address => bool) private tokenHolders;





    constructor(
        address contractOwner
    )
    public
    ERC20Detailed('Ocean Token', 'OCEAN', DECIMALS)
    ERC20Capped(TOTALSUPPLY)
    Ownable()
    {
        addPauser(contractOwner);
        renouncePauser();
        addMinter(contractOwner);
        renounceMinter();
        transferOwnership(contractOwner);
    }







    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        bool success = super.transfer(_to, _value);
        if (success) {
            updateTokenHolders(msg.sender, _to);
        }
        return success;
    }








    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        bool success = super.transferFrom(_from, _to, _value);
        if (success) {
            updateTokenHolders(_from, _to);
        }
        return success;
    }







    function getAccounts(
        uint256 _start,
        uint256 _end
    )
    external
    view
    onlyOwner
    returns (address[] memory, uint256[] memory)
    {
        require(
            _start <= _end && _end < accounts.length,
            'Array index out of bounds'
        );

        uint256 length = _end.sub(_start).add(1);

        address[] memory _tokenHolders = new address[](length);
        uint256[] memory _tokenBalances = new uint256[](length);

        for (uint256 i = _start; i <= _end; i++)
        {
            address account = accounts[i];
            uint256 accountBalance = super.balanceOf(account);
            if (accountBalance > 0)
            {
                _tokenBalances[i] = accountBalance;
                _tokenHolders[i] = account;
            }
        }

        return (_tokenHolders, _tokenBalances);
    }




    function getAccountsLength()
    external
    view
    onlyOwner
    returns (uint256)
    {
        return accounts.length;
    }




    function kill()
    external
    onlyOwner
    {
        selfdestruct(address(uint160(owner())));
    }




    function()
    external
    payable
    {
        revert('Invalid ether transfer');
    }





    function tryToAddTokenHolder(
        address account
    )
    private
    {
        if (!tokenHolders[account] && super.balanceOf(account) > 0)
        {
            accounts.push(account);
            tokenHolders[account] = true;
        }
    }






    function updateTokenHolders(
        address sender,
        address receiver
    )
    private
    {
        tryToAddTokenHolder(sender);
        tryToAddTokenHolder(receiver);
    }
}
