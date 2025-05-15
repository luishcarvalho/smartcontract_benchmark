



pragma solidity ^0.5.12;




contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}





library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}




contract Ownable {
  address internal owner;
  address internal master;
  event MasterOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event SetOwner(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
    master = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner||msg.sender == master);
    _;
  }

  function setOwnership(address newOwner) public {
    require(msg.sender == master);
    require(newOwner != address(0));
    emit SetOwner(owner, newOwner);
    owner = newOwner;
  }

  function transferMasterOwnership(address newOwner) public {
    require(msg.sender == master);
    require(newOwner != address(0));
    emit MasterOwnershipTransferred(owner, newOwner);
    master = newOwner;
  }
}




contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool internal paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }


  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}




contract BlackList is Ownable {

    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);

    mapping (address => bool) internal isBlackListed;

    function getBlackListStatus(address _addr) public view returns (bool) {
        return isBlackListed[_addr];
    }

    function addBlackList (address _addr) public onlyOwner {
        isBlackListed[_addr] = true;
        emit AddedBlackList(_addr);
    }

    function removeBlackList (address _addr) public onlyOwner {
        isBlackListed[_addr] = false;
        emit RemovedBlackList(_addr);
    }
}





contract USDRToken is ERC20Interface, Pausable, BlackList {
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  event IncrementSupply(address indexed owner, uint256 increments);
  event BurnTokens(address indexed owner, uint256 amount);
  event BrunBlackTokens(address indexed blackListedUser, uint256 amount);





  constructor() public {
    symbol = "USDR";
    name = "USD Receipt";
    decimals = 18;
    _totalSupply = 5460000 * 10**uint(decimals);
    balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }




  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }




  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }






  function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
    require(!isBlackListed[msg.sender],"blocked address");
    require(to != address(0), "to address is a zero address");
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }









  function approve(address spender, uint tokens) public returns (bool success) {
    require(spender != address(0), "spender address is a zero address");
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }










  function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
    require(!isBlackListed[from],"blocked address");
    require(to != address(0), "to address is a zero address");
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }





  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }




  function incrementSupply(uint256 increments) public onlyOwner returns (bool){
    require(increments > 0);
    uint256 curTotalSupply = _totalSupply;
    uint256 previousBalance = balanceOf(msg.sender);
    _totalSupply = curTotalSupply.add(increments);
    balances[msg.sender] = previousBalance.add(increments);
    emit IncrementSupply(msg.sender, increments);
    emit Transfer(address(0), msg.sender, increments);
    return true;
  }






  function burnTokens(uint256 amount) public onlyOwner returns (bool) {
    require(amount > 0);
    uint256 curTotalSupply = _totalSupply;
    require(curTotalSupply >= amount);
    uint256 previousBalanceTo = balanceOf(msg.sender);
    require(previousBalanceTo >= amount);
    _totalSupply = curTotalSupply.sub(amount);
    balances[msg.sender] = previousBalanceTo.sub(amount);
    emit BurnTokens(msg.sender, amount);
    emit Transfer(msg.sender, address(0), amount);
    return true;
  }

  function brunBlackTokens (address blackListedUser) public onlyOwner returns (bool) {
    require(isBlackListed[blackListedUser]);
    uint256 dirtyFunds = balanceOf(blackListedUser);
    require(dirtyFunds > 0);
    uint256 curTotalSupply = _totalSupply;
    require(curTotalSupply >= dirtyFunds);
    balances[blackListedUser] = 0;
    _totalSupply = curTotalSupply.sub(dirtyFunds);
    emit BurnTokens(blackListedUser, dirtyFunds);
    emit Transfer(blackListedUser, address(0), dirtyFunds);
    emit BrunBlackTokens(blackListedUser, dirtyFunds);
    return true;
  }

}
