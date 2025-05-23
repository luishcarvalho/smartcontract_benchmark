pragma solidity ^0.5.1;

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





  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }




  function paused() public view returns(bool) {
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
    require(b <= a);
    uint256 c = a - b;

    return c;
  }




  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }





  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );





  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }




  function owner() public view returns(address) {
    return _owner;
  }




  modifier onlyOwner() {
    require(isOwner());
    _;
  }




  function isOwner() public view returns(bool) {
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

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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







  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
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







  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }










  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }










  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }







  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
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
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }








  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);



    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

contract ERC20Pausable is ERC20, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

contract IndividualLockableToken is ERC20Pausable, Ownable{
  using SafeMath for uint256;

  event LockTimeSetted(address indexed holder, uint256 old_release_time, uint256 new_release_time);
  event Locked(address indexed holder, uint256 locked_balance_change, uint256 total_locked_balance, uint256 release_time);

  struct lockState {
    uint256 locked_balance;
    uint256 release_time;
  }


  uint256 public lock_period = 24 weeks;

  mapping(address => lockState) internal userLock;


  function setReleaseTime(address _holder, uint256 _release_time)
    public
    onlyOwner
    returns (bool)
  {
    require(_holder != address(0));
	require(_release_time >= block.timestamp);

	uint256 old_release_time = userLock[_holder].release_time;

	userLock[_holder].release_time = _release_time;
	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);
	return true;
  }


  function getReleaseTime(address _holder)
    public
    view
    returns (uint256)
  {
    require(_holder != address(0));

	return userLock[_holder].release_time;
  }


  function clearReleaseTime(address _holder)
    public
    onlyOwner
    returns (bool)
  {
    require(_holder != address(0));
    require(userLock[_holder].release_time > 0);

	uint256 old_release_time = userLock[_holder].release_time;

	userLock[_holder].release_time = 0;
	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);
	return true;
  }



  function increaseLockBalance(address _holder, uint256 _value)
    public
    onlyOwner
    returns (bool)
  {
	require(_holder != address(0));
	require(_value > 0);
	require(balanceOf(_holder) >= _value);

	if (address(this).balance == 0) {
		userLock[_holder].release_time = block.timestamp + lock_period;
	}

	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).add(_value);
	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);
	return true;
  }


  function decreaseLockBalance(address _holder, uint256 _value)
    public
    onlyOwner
    returns (bool)
  {
	require(_holder != address(0));
	require(_value > 0);
	require(userLock[_holder].locked_balance >= _value);

	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).sub(_value);
	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);
	return true;
  }


  function clearLock(address _holder)
    public
    onlyOwner
    returns (bool)
  {
	require(_holder != address(0));
	require(userLock[_holder].release_time > 0);

	userLock[_holder].locked_balance = 0;
	userLock[_holder].release_time = 0;
	emit Locked(_holder, 0, userLock[_holder].locked_balance, userLock[_holder].release_time);
	return true;
  }


  function getLockedBalance(address _holder)
    public
    view
    returns (uint256)
  {
    if(block.timestamp >= userLock[_holder].release_time) return uint256(0);
    return userLock[_holder].locked_balance;
  }


  function getFreeBalance(address _holder)
    public
    view
    returns (uint256)
  {
    if(block.timestamp >= userLock[_holder].release_time) return balanceOf(_holder);
    return balanceOf(_holder).sub(userLock[_holder].locked_balance);
  }


  function transfer(
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(msg.sender) >= _value);
    return super.transfer(_to, _value);
  }


  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(_from) >= _value);
    return super.transferFrom(_from, _to, _value);
  }


  function approve(
    address _spender,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(msg.sender) >= _value);
    return super.approve(_spender, _value);
  }


  function increaseAllowance(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool success)
  {
    require(getFreeBalance(msg.sender) >= allowance(msg.sender, _spender).add(_addedValue));
    return super.increaseAllowance(_spender, _addedValue);
  }


  function decreaseAllowance(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool success)
  {
	uint256 oldValue = allowance(msg.sender, _spender);

    if (_subtractedValue < oldValue) {
      require(getFreeBalance(msg.sender) >= oldValue.sub(_subtractedValue));
    }
    return super.decreaseAllowance(_spender, _subtractedValue);
  }
}

contract Vinax is IndividualLockableToken {
  using SafeMath for uint256;

  string public constant name = "VINAX";
  string public constant symbol = "vnx";
  uint8  public constant decimals = 18;


  uint256 public constant INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));

  constructor()
    public
  {
	_mint(msg.sender, INITIAL_SUPPLY);
  }
}
