pragma solidity 0.5.6;





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





library SafeMath {



  function mul(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
      return 0;
    }

    uint256 c ;

    require(c / a == b);

    return c;
  }




  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0);
    uint256 c ;



    return c;
  }




  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c ;


    return c;
  }




  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    require(c >= a);

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


    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}







library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
  internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
  internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
  internal
  {



    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
  internal
  {
    uint256 newAllowance ;

    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
  internal
  {
    uint256 newAllowance ;

    require(token.approve(spender, newAllowance));
  }
}







contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }




  function name() public view returns(string memory) {
    return _name;
  }




  function symbol() public view returns(string memory) {
    return _symbol;
  }




  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract Ownable {
  address payable public owner;




  constructor() public {
    owner = msg.sender;
  }



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}



contract GameWave is ERC20, ERC20Detailed, Ownable {

  uint paymentsTime ;

  uint totalPaymentAmount;
  uint lastTotalPaymentAmount;
  uint minted ;


  mapping (address => uint256) lastWithdrawTime;





  constructor() public ERC20Detailed("Game wave token", "GWT", 18) {
    _mint(msg.sender, minted * (10 ** uint256(decimals())));
  }






  function () payable external {
    if (msg.value == 0){
      withdrawDividends(msg.sender);
    }
  }






  function getDividends(address _holder) view public returns(uint) {
    if (paymentsTime >= lastWithdrawTime[_holder]){
      return totalPaymentAmount.mul(balanceOf(_holder)).div(minted * (10 ** uint256(decimals())));
    } else {
      return 0;
    }
  }






  function withdrawDividends(address payable _holder) public returns(uint) {
    uint dividends ;

    lastWithdrawTime[_holder] = block.timestamp;
    lastTotalPaymentAmount = lastTotalPaymentAmount.add(dividends);
    _holder.transfer(dividends);
  }






  function startPayments() public {
    require(block.timestamp >= paymentsTime + 30 days);
    owner.transfer(totalPaymentAmount.sub(lastTotalPaymentAmount));
    totalPaymentAmount = address(this).balance;
    paymentsTime = block.timestamp;
    lastTotalPaymentAmount = 0;
  }
}
