




pragma solidity ^0.7.0;

interface ERC20 {


  function balanceOf(address _owner) external returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  function allowance(address _owner, address _spender) external returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}






library SafeMath {
  function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal  pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal  pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract xGemPresale  {
  using SafeMath for uint256;

  receive() payable external{
      buyTokens(msg.sender);
  }

  address public owner;


  ERC20 public token;


  address payable  public  tokenAddress = 0x3E60f39208aC7b8E80eaaFF8BF2Ae71949A9aA85;




  address payable  public  wallet = msg.sender;

  uint256 public tokensSold;

  uint256 public minInvestment= 0.2 * 10**18;




  uint256 public cap =  50_000 * 10**18;


  uint256 public rate = 500;

  bool public isFinalized = false;


  uint256 public salesStartTimeStamp = 1602446400;


  bool paused;








  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);




  event Finalized();




  constructor()  {

    require(wallet != address(0));
    require(minInvestment >= 0);
    token= ERC20(tokenAddress);
  }

 modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }




  modifier whenNotPaused() {
    require(!paused);
    _;
  }




  modifier whenPaused {
    require(paused);
    _;
  }




  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    return true;
  }




  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    return true;
  }







  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());


    uint256 weiAmount = msg.value;

    uint256 tokens = weiAmount.mul(rate);


    require(tokensSold.add(tokens)<=cap,"Not enough tokens left");


    tokensSold=tokensSold.add(tokens);


    token.transfer(beneficiary, tokens);

    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }


  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


  function validPurchase() internal returns (bool) {

    bool notSmallAmount = msg.value >= minInvestment;
    bool salesActive = ( block.timestamp >= salesStartTimeStamp);
    return (notSmallAmount && salesActive && !isFinalized);
  }


  function finalize() public onlyOwner {
    require(!isFinalized);

    emit Finalized();

    uint256 leftoverTokens = token.balanceOf(address(this));
    token.transfer(address(this),leftoverTokens);

    isFinalized = true;
  }
}
