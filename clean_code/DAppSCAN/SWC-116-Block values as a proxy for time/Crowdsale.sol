pragma solidity ^0.4.8;
import "./SafeMath.sol";
import "./RLC.sol";
import "./PullPayment.sol";
import "./Pausable.sol";














contract Crowdsale is SafeMath, PullPayment, Pausable {

  	struct Backer {
  	  uint weiReceived;
	  string btc_address;
	  uint satoshiReceived;
	  uint rlcToSend;
	  uint rlcSent;
	}

	RLC 	public rlc;
	address public owner;
	address public multisigETH;
	address public BTCproxy;

	uint public RLCPerETH;
	uint public RLCPerSATOSHI;
	uint public ETHReceived;
	uint public BTCReceived;
	uint public RLCSentToETH;
	uint public RLCSentToBTC;
	uint public RLCEmitted;
	uint public startBlock;
	uint public endBlock;
	uint public minCap;
	uint public maxCap;
	bool public maxCapReached;
	uint public minInvestETH;
	uint public minInvestBTC;
	bool public crowdsaleClosed;

	address public bounty;
	address public reserve;
	address public team;

	uint public rlc_bounty;
	uint public rlc_reserve;
	uint public rlc_team;

	mapping(address => Backer) public backers;



	modifier onlyBy(address a){
	    if (msg.sender != a) throw;
	    _;
	}

	modifier minCapNotReached() {
		if ((now<endBlock) || isMinCapReached() || (now > endBlock + 15 days)) throw;
		_;
	}





	function closeCrowdsaleForRefund() {
		endBlock = now;
	}

	function finalizeTEST() onlyBy(owner) {

		if (!multisigETH.send(this.balance)) throw;

	    if (!transferRLC(team,rlc_team)) throw;
	    if (!transferRLC(reserve,rlc_reserve)) throw;
	    if (!transferRLC(bounty,rlc_bounty)) throw;
	    rlc.burn(rlc.totalSupply() - RLCEmitted);
		crowdsaleClosed = true;
	}






	event ReceivedETH(address addr, uint value);
	event ReceivedBTC(address addr, string from, uint value);
	event RefundBTC(string to, uint value);
	event Logs(address indexed from, uint amount, string value);

	function Crowdsale(address _token, address _btcproxy) {


	  owner = msg.sender;
	  BTCproxy = _btcproxy;
	  rlc = RLC(_token);
	  multisigETH = 0x8cd6B3D8713df6aA35894c8beA200c27Ebe92550;
	  team = 0x1000000000000000000000000000000000000000;
	  reserve = 0x2000000000000000000000000000000000000000;
	  bounty = 0x3000000000000000000000000000000000000000;
	  RLCSentToETH = 0;
	  RLCSentToBTC = 0;
	  minInvestETH = 100 finney;
	  minInvestBTC = 100000;
	  startBlock = now ;
	  endBlock =  now + 30 days;
	  RLCPerETH = 5000000000000;
	  RLCPerSATOSHI = 50000;
	  minCap=12000000000000000;
	  maxCap=60000000000000000;
	  rlc_bounty=1700000000000000;

	  rlc_reserve=1700000000000000;
	  rlc_team=12000000000000000;
	  RLCEmitted = rlc_bounty + rlc_reserve + rlc_team;
	}




	function() payable	{
	  receiveETH(msg.sender);
	}




	function receiveETH(address beneficiary) stopInEmergency payable {


	  if (msg.value < minInvestETH) throw;


	  if ((now < startBlock) || (now > endBlock )) throw;


	  uint rlcToSend = bonus((msg.value*RLCPerETH)/(1 ether));



	  if ((rlcToSend + RLCSentToETH + RLCSentToBTC) > maxCap) throw;


	  Backer backer = backers[beneficiary];

	  if (!transferRLC(beneficiary, rlcToSend)) throw;

	  backer.rlcSent = safeAdd(backer.rlcSent, rlcToSend);
	  backer.weiReceived = safeAdd(backer.weiReceived, msg.value);
	  ETHReceived = safeAdd(ETHReceived, msg.value);
	  RLCSentToETH = safeAdd(RLCSentToETH, rlcToSend);

	  emitRLC(rlcToSend);

	  ReceivedETH(beneficiary,ETHReceived);
	}







	function receiveBTC(address beneficiary, string btc_address, uint value) stopInEmergency onlyBy(BTCproxy){

	  if (value < minInvestBTC) throw;


	  if ((now < startBlock) || (now > endBlock )) throw;


	  uint rlcToSend = bonus((value*RLCPerSATOSHI));


	  if ((rlcToSend + RLCSentToETH + RLCSentToBTC) > maxCap) throw;


	  Backer backer = backers[beneficiary];



	  if (!transferRLC(beneficiary, rlcToSend)) throw;

	  backer.rlcSent = safeAdd(backer.rlcSent , rlcToSend);
	  backer.btc_address = btc_address;
	  backer.satoshiReceived = safeAdd(backer.satoshiReceived, value);
	  BTCReceived =  safeAdd(BTCReceived, value);
	  RLCSentToBTC = safeAdd(RLCSentToBTC, rlcToSend);
	  emitRLC(rlcToSend);

	  ReceivedBTC(beneficiary, btc_address, BTCReceived);
	}

	function isMinCapReached() internal returns (bool) {
		return (RLCSentToETH + RLCSentToBTC ) > minCap;
	}

	function isMaxCapReached() internal returns (bool) {
		return (RLCSentToETH + RLCSentToBTC ) == maxCap;
	}


	function emitRLC(uint amount) internal {
		Logs(msg.sender ,amount, "emitRLC");
		rlc_bounty+=amount/10;
		rlc_team+=amount/20;
		rlc_reserve+=amount/10;
		RLCEmitted+=amount + amount/4;
	}




	function bonus(uint amount) internal returns (uint) {
	  if (now < (startBlock + 10 days)) return (amount + amount/5);
	  if (now < startBlock + 20 days) return (amount + amount/10);
	  return amount;
	}





	function transferRLC(address to, uint amount) internal returns (bool) {
	  return rlc.transfer(to, amount);
	}






    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData, bytes _extraData2) minCapNotReached public {
        if (msg.sender != address(rlc)) throw;
        if (_extraData.length != 0) throw;
        if (_extraData2.length != 0) throw;
        if (_value != backers[_from].rlcSent) throw;
        if (!rlc.transferFrom(_from, address(this), _value)) throw ;
		uint ETHToSend = backers[_from].weiReceived;
		backers[_from].weiReceived=0;
		uint BTCToSend = backers[_from].satoshiReceived;
		backers[_from].satoshiReceived = 0;
		if (ETHToSend > 0) {
			asyncSend(_from,ETHToSend);
		}
		if (BTCToSend > 0)
			RefundBTC(backers[_from].btc_address ,BTCToSend);
    }


























	function setRLCPerETH(uint rate) onlyBy(BTCproxy) {
		RLCPerETH=rate;
	}




	function finalize() onlyBy(owner) {

		if (now < endBlock + 15 days ) throw;

		if (!multisigETH.send(this.balance)) throw;

	    if (!transferRLC(team,rlc_team)) throw;
	    if (!transferRLC(reserve,rlc_reserve)) throw;
	    if (!transferRLC(bounty,rlc_bounty)) throw;
	    rlc.burn(rlc.totalSupply() - RLCEmitted);
		crowdsaleClosed = true;
	}
}

