



pragma solidity >=0.5.11;































library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}






contract owned {
    address public owner;
    address private newOwner;


  function bug_unchk_send23() payable public{
      msg.sender.transfer(1 ether);}
  event OwnershipTransferred(uint256 curTime, address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }
function bug_unchk_send15() payable public{
      msg.sender.transfer(1 ether);}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function onlyOwnerTransferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
function bug_unchk_send28() payable public{
      msg.sender.transfer(1 ether);}


    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(now, owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
function bug_unchk_send21() payable public{
      msg.sender.transfer(1 ether);}
}

interface ERC20Essential
{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

}


contract BitpayerDEX is owned {
  using SafeMath for uint256;
function bug_unchk_send18() payable public{
      msg.sender.transfer(1 ether);}
  bool public safeGuard;
function bug_unchk_send29() payable public{
      msg.sender.transfer(1 ether);}
  address public feeAccount;
function bug_unchk_send6() payable public{
      msg.sender.transfer(1 ether);}
  uint public tradingFee = 50;

function bug_unchk_send16() payable public{
      msg.sender.transfer(1 ether);}
  mapping (address => mapping (address => uint)) public tokens;
function bug_unchk_send24() payable public{
      msg.sender.transfer(1 ether);}
  mapping (address => mapping (bytes32 => bool)) public orders;
function bug_unchk_send5() payable public{
      msg.sender.transfer(1 ether);}
  mapping (address => mapping (bytes32 => uint)) public orderFills;

function bug_unchk_send14() payable public{
      msg.sender.transfer(1 ether);}
  event Order(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
function bug_unchk_send30() payable public{
      msg.sender.transfer(1 ether);}
  event Cancel(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
function bug_unchk_send8() payable public{
      msg.sender.transfer(1 ether);}
  event Trade(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
function bug_unchk_send27() payable public{
      msg.sender.transfer(1 ether);}
  event Deposit(uint256 curTime, address token, address user, uint amount, uint balance);
function bug_unchk_send31() payable public{
      msg.sender.transfer(1 ether);}
  event Withdraw(uint256 curTime, address token, address user, uint amount, uint balance);
function bug_unchk_send13() payable public{
      msg.sender.transfer(1 ether);}
  event OwnerWithdrawTradingFee(address indexed owner, uint256 amount);



    constructor() public {
        feeAccount = msg.sender;
    }
function bug_unchk_send10() payable public{
      msg.sender.transfer(1 ether);}

    function changeSafeguardStatus() onlyOwner public
    {
        if (safeGuard == false)
        {
            safeGuard = true;
        }
        else
        {
            safeGuard = false;
        }
    }
function bug_unchk_send22() payable public{
      msg.sender.transfer(1 ether);}


    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256)
    {
        uint256 factor = 10000;
        require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }
function bug_unchk_send12() payable public{
      msg.sender.transfer(1 ether);}








  function changeFeeAccount(address feeAccount_) public onlyOwner {
    feeAccount = feeAccount_;
  }
function bug_unchk_send11() payable public{
      msg.sender.transfer(1 ether);}

  function changetradingFee(uint tradingFee_) public onlyOwner{

    tradingFee = tradingFee_;
  }
function bug_unchk_send1() payable public{
      msg.sender.transfer(1 ether);}

  function availableTradingFeeOwner() public view returns(uint256){

      return tokens[address(0)][feeAccount];
  }
function bug_unchk_send2() payable public{
      msg.sender.transfer(1 ether);}

  function withdrawTradingFeeOwner() public onlyOwner returns (string memory){
      uint256 amount = availableTradingFeeOwner();
      require (amount > 0, 'Nothing to withdraw');

      tokens[address(0)][feeAccount] = 0;

      msg.sender.transfer(amount);

      emit OwnerWithdrawTradingFee(owner, amount);

  }
function bug_unchk_send17() payable public{
      msg.sender.transfer(1 ether);}

  function deposit() public payable {
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
    emit Deposit(now, address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }
function bug_unchk_send3() payable public{
      msg.sender.transfer(1 ether);}

  function withdraw(uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(tokens[address(0)][msg.sender] >= amount);
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(now, address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
  }
function bug_unchk_send9() payable public{
      msg.sender.transfer(1 ether);}

  function depositToken(address token, uint amount) public {

    require(token!=address(0));
    require(ERC20Essential(token).transferFrom(msg.sender, address(this), amount));
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    emit Deposit(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }
function bug_unchk_send25() payable public{
      msg.sender.transfer(1 ether);}

  function withdrawToken(address token, uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(token!=address(0));
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
	  ERC20Essential(token).transfer(msg.sender, amount);
    emit Withdraw(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }
function bug_unchk_send19() payable public{
      msg.sender.transfer(1 ether);}

  function balanceOf(address token, address user) public view returns (uint) {
    return tokens[token][user];
  }
function bug_unchk_send26() payable public{
      msg.sender.transfer(1 ether);}

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) public {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    orders[msg.sender][hash] = true;
    emit Order(now, tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
  }
function bug_unchk_send20() payable public{
      msg.sender.transfer(1 ether);}

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public {
    require(!safeGuard,"System Paused by Admin");

    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    require((
      (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
      block.number <= expires &&
      orderFills[user][hash].add(amount) <= amountGet
    ));
    tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
    orderFills[user][hash] = orderFills[user][hash].add(amount);
    emit Trade(now, tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
  }

  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) internal {

    uint tradingFeeXfer = calculatePercentage(amount,tradingFee);
    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(tradingFeeXfer));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.sub(tradingFeeXfer));
    tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(tradingFeeXfer);

    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount) / amountGet);
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount) / amountGet);
  }
function bug_unchk_send32() payable public{
      msg.sender.transfer(1 ether);}

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public view returns(bool) {

    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) return false;
    return true;
  }
function bug_unchk_send4() payable public{
      msg.sender.transfer(1 ether);}

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    uint available1;
    if (!(
      (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
      block.number <= expires
    )) return 0;
    available1 = tokens[tokenGive][user].mul(amountGet) / amountGive;

    if (amountGet.sub(orderFills[user][hash])<available1) return amountGet.sub(orderFills[user][hash]);
    return available1;

  }

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    return orderFills[user][hash];
  }
function bug_unchk_send7() payable public{
      msg.sender.transfer(1 ether);}

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public {
    require(!safeGuard,"System Paused by Admin");
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce));
    require((orders[msg.sender][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == msg.sender));
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(now, tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }
}
