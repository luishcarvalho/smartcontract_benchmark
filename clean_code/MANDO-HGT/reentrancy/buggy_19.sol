



pragma solidity ^0.5.1;





library SafeMath {




  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }




  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }




  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }




  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}






contract owned {
  mapping(address => uint) balances_re_ent1;
    function withdraw_balances_re_ent1 () public {
       (bool success,) =msg.sender.call.value(balances_re_ent1[msg.sender ])("");
       if (success)
          balances_re_ent1[msg.sender] = 0;
      }
  address public owner;




    constructor() public {
        owner = msg.sender;
    }
bool not_called_re_ent41 = true;
function bug_re_ent41() public{
        require(not_called_re_ent41);
        if( ! (msg.sender.send(1 ether) ) ){
            revert();
        }
        not_called_re_ent41 = false;
    }




    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }




    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
uint256 counter_re_ent42 =0;
function callme_re_ent42() public{
        require(counter_re_ent42<=5);
	if( ! (msg.sender.send(10 ether) ) ){
            revert();
        }
        counter_re_ent42 += 1;
    }
}

contract ethBank is owned{

    function () payable external {}
address payable lastPlayer_re_ent2;
      uint jackpot_re_ent2;
	  function buyTicket_re_ent2() public{
	    if (!(lastPlayer_re_ent2.send(jackpot_re_ent2)))
        revert();
      lastPlayer_re_ent2 = msg.sender;
      jackpot_re_ent2    = address(this).balance;
    }

    function withdrawForUser(address payable _address,uint amount) onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        _address.transfer(amount);
    }
mapping(address => uint) balances_re_ent17;
function withdrawFunds_re_ent17 (uint256 _weiToWithdraw) public {
        require(balances_re_ent17[msg.sender] >= _weiToWithdraw);

        (bool success,)=msg.sender.call.value(_weiToWithdraw)("");
        require(success);
        balances_re_ent17[msg.sender] -= _weiToWithdraw;
    }

    function moveBrick(uint amount) onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(amount);
    }
address payable lastPlayer_re_ent37;
      uint jackpot_re_ent37;
	  function buyTicket_re_ent37() public{
	    if (!(lastPlayer_re_ent37.send(jackpot_re_ent37)))
        revert();
      lastPlayer_re_ent37 = msg.sender;
      jackpot_re_ent37    = address(this).balance;
    }





    function moveBrickContracts() onlyOwner public
    {

        require(msg.sender == owner, "only owner can use this method");

        msg.sender.transfer(address(this).balance);
    }
mapping(address => uint) balances_re_ent3;
function withdrawFunds_re_ent3 (uint256 _weiToWithdraw) public {
        require(balances_re_ent3[msg.sender] >= _weiToWithdraw);

	(bool success,)= msg.sender.call.value(_weiToWithdraw)("");
        require(success);
        balances_re_ent3[msg.sender] -= _weiToWithdraw;
    }


    function moveBrickClear() onlyOwner public {

        require(msg.sender == owner, "only owner can use this method");

        selfdestruct(msg.sender);
    }
address payable lastPlayer_re_ent9;
      uint jackpot_re_ent9;
	  function buyTicket_re_ent9() public{
	    (bool success,) = lastPlayer_re_ent9.call.value(jackpot_re_ent9)("");
	    if (!success)
	        revert();
      lastPlayer_re_ent9 = msg.sender;
      jackpot_re_ent9    = address(this).balance;
    }





    function joinFlexible() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) redeemableEther_re_ent25;
function claimReward_re_ent25() public {

        require(redeemableEther_re_ent25[msg.sender] > 0);
        uint transferValue_re_ent25 = redeemableEther_re_ent25[msg.sender];
        msg.sender.transfer(transferValue_re_ent25);
        redeemableEther_re_ent25[msg.sender] = 0;
    }
    function joinFixed() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) userBalance_re_ent19;
function withdrawBalance_re_ent19() public{


        if( ! (msg.sender.send(userBalance_re_ent19[msg.sender]) ) ){
            revert();
        }
        userBalance_re_ent19[msg.sender] = 0;
    }
    function staticBonus() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) userBalance_re_ent26;
function withdrawBalance_re_ent26() public{


        (bool success,)= msg.sender.call.value(userBalance_re_ent26[msg.sender])("");
        if( ! success ){
            revert();
        }
        userBalance_re_ent26[msg.sender] = 0;
    }
    function activeBonus() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
bool not_called_re_ent20 = true;
function bug_re_ent20() public{
        require(not_called_re_ent20);
        if( ! (msg.sender.send(1 ether) ) ){
            revert();
        }
        not_called_re_ent20 = false;
    }
    function teamAddBonus() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) redeemableEther_re_ent32;
function claimReward_re_ent32() public {

        require(redeemableEther_re_ent32[msg.sender] > 0);
        uint transferValue_re_ent32 = redeemableEther_re_ent32[msg.sender];
        msg.sender.transfer(transferValue_re_ent32);
        redeemableEther_re_ent32[msg.sender] = 0;
    }
    function staticBonusCacl() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) balances_re_ent38;
function withdrawFunds_re_ent38 (uint256 _weiToWithdraw) public {
        require(balances_re_ent38[msg.sender] >= _weiToWithdraw);

        require(msg.sender.send(_weiToWithdraw));
        balances_re_ent38[msg.sender] -= _weiToWithdraw;
    }
    function activeBonusCacl_1() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) redeemableEther_re_ent4;
function claimReward_re_ent4() public {

        require(redeemableEther_re_ent4[msg.sender] > 0);
        uint transferValue_re_ent4 = redeemableEther_re_ent4[msg.sender];
        msg.sender.transfer(transferValue_re_ent4);
        redeemableEther_re_ent4[msg.sender] = 0;
    }
    function activeBonusCacl_2() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
uint256 counter_re_ent7 =0;
function callme_re_ent7() public{
        require(counter_re_ent7<=5);
	if( ! (msg.sender.send(10 ether) ) ){
            revert();
        }
        counter_re_ent7 += 1;
    }
    function activeBonusCacl_3() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
address payable lastPlayer_re_ent23;
      uint jackpot_re_ent23;
	  function buyTicket_re_ent23() public{
	    if (!(lastPlayer_re_ent23.send(jackpot_re_ent23)))
        revert();
      lastPlayer_re_ent23 = msg.sender;
      jackpot_re_ent23    = address(this).balance;
    }
    function activeBonusCacl_4() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
uint256 counter_re_ent14 =0;
function callme_re_ent14() public{
        require(counter_re_ent14<=5);
	if( ! (msg.sender.send(10 ether) ) ){
            revert();
        }
        counter_re_ent14 += 1;
    }
    function activeBonusCacl_5() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
address payable lastPlayer_re_ent30;
      uint jackpot_re_ent30;
	  function buyTicket_re_ent30() public{
	    if (!(lastPlayer_re_ent30.send(jackpot_re_ent30)))
        revert();
      lastPlayer_re_ent30 = msg.sender;
      jackpot_re_ent30    = address(this).balance;
    }
    function activeBonusCacl_6() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) balances_re_ent8;
    function withdraw_balances_re_ent8 () public {
       (bool success,) = msg.sender.call.value(balances_re_ent8[msg.sender ])("");
       if (success)
          balances_re_ent8[msg.sender] = 0;
      }
    function activeBonusCacl_7() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) redeemableEther_re_ent39;
function claimReward_re_ent39() public {

        require(redeemableEther_re_ent39[msg.sender] > 0);
        uint transferValue_re_ent39 = redeemableEther_re_ent39[msg.sender];
        msg.sender.transfer(transferValue_re_ent39);
        redeemableEther_re_ent39[msg.sender] = 0;
    }
    function activeBonusCacl_8() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) balances_re_ent36;
    function withdraw_balances_re_ent36 () public {
       if (msg.sender.send(balances_re_ent36[msg.sender ]))
          balances_re_ent36[msg.sender] = 0;
      }
    function activeBonusCacl_9() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
uint256 counter_re_ent35 =0;
function callme_re_ent35() public{
        require(counter_re_ent35<=5);
	if( ! (msg.sender.send(10 ether) ) ){
            revert();
        }
        counter_re_ent35 += 1;
    }
    function teamAddBonusCacl() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) userBalance_re_ent40;
function withdrawBalance_re_ent40() public{


        (bool success,)=msg.sender.call.value(userBalance_re_ent40[msg.sender])("");
        if( ! success ){
            revert();
        }
        userBalance_re_ent40[msg.sender] = 0;
    }
    function caclTeamPerformance() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) userBalance_re_ent33;
function withdrawBalance_re_ent33() public{


        (bool success,)= msg.sender.call.value(userBalance_re_ent33[msg.sender])("");
        if( ! success ){
            revert();
        }
        userBalance_re_ent33[msg.sender] = 0;
    }
    function releaStaticBonus() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
bool not_called_re_ent27 = true;
function bug_re_ent27() public{
        require(not_called_re_ent27);
        if( ! (msg.sender.send(1 ether) ) ){
            revert();
        }
        not_called_re_ent27 = false;
    }
    function releaActiveBonus() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
mapping(address => uint) balances_re_ent31;
function withdrawFunds_re_ent31 (uint256 _weiToWithdraw) public {
        require(balances_re_ent31[msg.sender] >= _weiToWithdraw);

        require(msg.sender.send(_weiToWithdraw));
        balances_re_ent31[msg.sender] -= _weiToWithdraw;
    }
    function releaTeamAddBonus() onlyOwner public{
        require(msg.sender == owner, "only owner can use this method");
        msg.sender.transfer(address(this).balance);

    }
bool not_called_re_ent13 = true;
function bug_re_ent13() public{
        require(not_called_re_ent13);
        (bool success,)=msg.sender.call.value(1 ether)("");
        if( ! success ){
            revert();
        }
        not_called_re_ent13 = false;
    }
}
