



pragma solidity >= 0.6.3;

contract Context {
  constructor () internal { }
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}
contract xETHTKN is Context, Owned {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor() public {
    symbol = "2XETH";
    name = "2xETH.win";
    decimals = 18;
  }

  modifier onlyApproved {
    require(approvedAccounts[msg.sender] == true);
    _;
  }

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  string public symbol;
  string public name;
  uint256 public decimals;
  uint256 private _totalSupply;

  mapping(address => bool) public approvedAccounts;

  function setApprovedAccount(address account, bool status) public onlyOwner() {
      approvedAccounts[account] = status;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) public virtual returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }
  function mint(address account, uint256 amount) public onlyApproved() {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);

    _balances[account] = _balances[account].add(amount);

    emit Transfer(address(0), account, amount);
  }
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library SafeMath {









  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;


    return c;
  }










  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }












  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }










  function mul(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }












  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }














  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

    require(b > 0, errorMessage);
    uint256 c = a / b;


    return c;
  }












  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }














  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
