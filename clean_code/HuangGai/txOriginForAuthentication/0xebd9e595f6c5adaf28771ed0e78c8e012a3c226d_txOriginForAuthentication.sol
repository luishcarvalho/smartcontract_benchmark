



pragma solidity ^0.5.17;

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

contract ERC20Interface {

  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);


}


contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public Admininstrator;


  constructor() public {
    Admininstrator = msg.sender;

  }

  modifier onlyAdmin {
    require(tx.origin == Admininstrator, "Only authorized personnels");

    _;
  }

}

contract SALESCONTRACT is Owned{


  using SafeMath for uint;

  address public token;

  uint public minBuy = 0.5 ether;
  uint public maxBuy = 5 ether;
  address payable saleswallet;

  bool public startSales = true;
  uint public buyvalue;
  uint public price = 0.05 ether;
  uint _qtty;
  uint decimal = 10**18;


  mapping(address => uint) public buyamount;




  constructor() public { Admininstrator = msg.sender; }




 function setSalesWallet(address payable _salewallet) public onlyAdmin{saleswallet = _salewallet;}
 function setToken(address _tokenaddress) public onlyAdmin{token = _tokenaddress;}

 function AllowSales(bool _status) public onlyAdmin{startSales = _status;}


 function () external payable {

     require(startSales == true, "Sales has not been initialized yet");

    require(msg.value >= minBuy && msg.value <= maxBuy, "Invalid buy amount, confirm the maximum and minimum buy amounts");
    require(token != 0x0000000000000000000000000000000000000000, "Selling token not yet configured");
    require((buyamount[msg.sender] + msg.value) <= maxBuy, "You have reached your buy cap");

    buyvalue = msg.value;
    _qtty = buyvalue.div(price);
    require(ERC20Interface(token).balanceOf(address(this)) >= _qtty*decimal, "Insufficient tokens in the contract");

    saleswallet.transfer(msg.value);
    buyamount[msg.sender] += msg.value;
    require(ERC20Interface(token).transfer(msg.sender, _qtty*decimal), "Transaction failed");



  }


  function RetrieveToken() public onlyAdmin returns(bool){

      uint bal = ERC20Interface(token).balanceOf(address(this));
      require(ERC20Interface(token).transfer(saleswallet, bal), "Transaction failed");

  }


}
