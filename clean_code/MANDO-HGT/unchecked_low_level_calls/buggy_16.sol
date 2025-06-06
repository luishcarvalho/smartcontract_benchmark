







pragma solidity ^0.5.11;




library SafeMath {




    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }




   function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }




    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }




    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
}


contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
function bug_unchk_send18() payable public{
      msg.sender.transfer(1 ether);}
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
function bug_unchk_send29() payable public{
      msg.sender.transfer(1 ether);}
    function transfer(address to, uint256 tokens) public returns (bool success);
function bug_unchk_send6() payable public{
      msg.sender.transfer(1 ether);}
    function approve(address spender, uint256 tokens) public returns (bool success);
function bug_unchk_send16() payable public{
      msg.sender.transfer(1 ether);}
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
function bug_unchk_send24() payable public{
      msg.sender.transfer(1 ether);}

  function bug_unchk_send14() payable public{
      msg.sender.transfer(1 ether);}
  event Transfer(address indexed from, address indexed to, uint256 tokens);
  function bug_unchk_send30() payable public{
      msg.sender.transfer(1 ether);}
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


contract Owned {
    address payable public owner;
  function bug_unchk_send8() payable public{
      msg.sender.transfer(1 ether);}
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor() public {
        owner = msg.sender;
    }
function bug_unchk_send5() payable public{
      msg.sender.transfer(1 ether);}




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }





    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
function bug_unchk_send15() payable public{
      msg.sender.transfer(1 ether);}

}

contract ExclusivePlatform is ERC20Interface, Owned {

    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public name = "Exclusive Platform";
    string public symbol = "XPL";
    uint256 public decimals = 8;
    uint256 public _totalSupply;

    uint256 public XPLPerEther = 8000000e8;
    uint256 public minimumBuy = 1 ether / 100;
    bool public crowdsaleIsOn = true;



    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    constructor () public {
        _totalSupply = 10000000000e8;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
function bug_unchk_send28() payable public{
      msg.sender.transfer(1 ether);}

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
function bug_unchk_send21() payable public{
      msg.sender.transfer(1 ether);}

    function updateXPLPerEther(uint _XPLPerEther) public onlyOwner {
        emit NewPrice(owner, XPLPerEther, _XPLPerEther);
        XPLPerEther = _XPLPerEther;
    }
function bug_unchk_send10() payable public{
      msg.sender.transfer(1 ether);}

    function switchCrowdsale() public onlyOwner {
        crowdsaleIsOn = !(crowdsaleIsOn);
    }
function bug_unchk_send22() payable public{
      msg.sender.transfer(1 ether);}

    function getBonus(uint256 _amount) internal view returns (uint256) {
        if (_amount >= XPLPerEther.mul(5)) {



            return ((20 * _amount).div(100)).add(_amount);
        } else if (_amount >= XPLPerEther) {



            return ((5 * _amount).div(100)).add(_amount);
        }
        return _amount;
    }
function bug_unchk_send12() payable public{
      msg.sender.transfer(1 ether);}

    function () payable external {
        require(crowdsaleIsOn && msg.value >= minimumBuy);

        uint256 totalBuy =  (XPLPerEther.mul(msg.value)).div(1 ether);
        totalBuy = getBonus(totalBuy);

        doTransfer(owner, msg.sender, totalBuy);
    }
function bug_unchk_send11() payable public{
      msg.sender.transfer(1 ether);}

    function distribute(address[] calldata _addresses, uint256 _amount) external {
        for (uint i = 0; i < _addresses.length; i++) {transfer(_addresses[i], _amount);}
    }
function bug_unchk_send1() payable public{
      msg.sender.transfer(1 ether);}

    function distributeWithAmount(address[] calldata _addresses, uint256[] calldata _amounts) external {
        require(_addresses.length == _amounts.length);
        for (uint i = 0; i < _addresses.length; i++) {transfer(_addresses[i], _amounts[i]);}
    }
function bug_unchk_send2() payable public{
      msg.sender.transfer(1 ether);}






    function doTransfer(address _from, address _to, uint _amount) internal {

        require((_to != address(0)));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
function bug_unchk_send17() payable public{
      msg.sender.transfer(1 ether);}

    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }
function bug_unchk_send3() payable public{
      msg.sender.transfer(1 ether);}

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }
function bug_unchk_send9() payable public{
      msg.sender.transfer(1 ether);}

    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        doTransfer(_from, _to, _amount);
        return true;
    }
function bug_unchk_send25() payable public{
      msg.sender.transfer(1 ether);}






    function approve(address _spender, uint256 _amount) public returns (bool success) {




        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
function bug_unchk_send19() payable public{
      msg.sender.transfer(1 ether);}

    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }
function bug_unchk_send26() payable public{
      msg.sender.transfer(1 ether);}

    function transferEther(address payable _receiver, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        emit TransferEther(address(this), _receiver, _amount);
        _receiver.transfer(_amount);
    }
function bug_unchk_send20() payable public{
      msg.sender.transfer(1 ether);}

    function withdrawFund() onlyOwner public {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
function bug_unchk_send32() payable public{
      msg.sender.transfer(1 ether);}

    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
function bug_unchk_send4() payable public{
      msg.sender.transfer(1 ether);}


    function getForeignTokenBalance(address tokenAddress, address who) view public returns (uint){
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint bal = token.balanceOf(who);
        return bal;
    }
function bug_unchk_send7() payable public{
      msg.sender.transfer(1 ether);}

    function withdrawForeignTokens(address tokenAddress) onlyOwner public returns (bool) {
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
function bug_unchk_send23() payable public{
      msg.sender.transfer(1 ether);}

  function bug_unchk_send27() payable public{
      msg.sender.transfer(1 ether);}
  event TransferEther(address indexed _from, address indexed _to, uint256 _value);
  function bug_unchk_send31() payable public{
      msg.sender.transfer(1 ether);}
  event NewPrice(address indexed _changer, uint256 _lastPrice, uint256 _newPrice);
  function bug_unchk_send13() payable public{
      msg.sender.transfer(1 ether);}
  event Burn(address indexed _burner, uint256 value);

}
