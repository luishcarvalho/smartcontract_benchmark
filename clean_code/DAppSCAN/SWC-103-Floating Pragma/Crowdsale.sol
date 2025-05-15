





pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import "./Haltable.sol";
import "./PricingStrategy.sol";
import "./FinalizeAgent.sol";
import "./FractionalERC20.sol";














contract Crowdsale is Haltable {




























































  bool public requiredSignedAddress;





























  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}


  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);


  event Refund(address investor, uint weiAmount);


  event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);


  event Whitelisted(address addr, bool status);


  event EndsAtChanged(uint newEndsAt);


  event BaseEthCapChanged(uint newBaseEthCap);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _baseEthCap) {

    owner = msg.sender;

    baseEthCap = _baseEthCap;

    token = FractionalERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if (multisigWallet == 0) {
        revert();
    }

    if (_start == 0) {
        revert();
    }

    startsAt = _start;

    if (_end == 0) {
        revert();
    }

    endsAt = _end;


    if (startsAt >= endsAt) {
        revert();
    }


    minimumFundingGoal = _minimumFundingGoal;
  }

  function() payable {
    buy();
  }











  function investInternal(address receiver, uint128 customerId) stopInEmergency private {


    if (getState() == State.PreFunding) {

      if (!earlyParticipantWhitelist[receiver]) {
        revert();
      }
    } else if (getState() == State.Funding) {

      if (!whitelist[receiver]) {
        revert();
      }


    } else {

      revert();
    }

    uint weiAmount = msg.value;

    uint currentEthCap = getCurrentEthCap();
    if (weiAmount > currentEthCap) {

      revert();
    }


    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());

    if (tokenAmount == 0) {

      revert();
    }

    if (investedAmountOf[receiver] == 0) {

       investorCount++;
    }


    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);

    if (investedAmountOf[receiver] > currentEthCap) {

      revert();
    }

    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);



    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    if (pricingStrategy.isPresalePurchase(receiver)) {
        presaleWeiRaised = presaleWeiRaised.add(weiAmount);
    }


    if (isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      revert();
    }

    assignTokens(receiver, tokenAmount);


    if (!multisigWallet.send(weiAmount))
      revert();


    Invested(receiver, weiAmount, tokenAmount, customerId);
  }

  function getCurrentEthCap() public constant returns (uint) {
    if (block.timestamp < startsAt)
      return 0;
    uint timeSinceStart = block.timestamp.sub(startsAt);
    uint currentPeriod = timeSinceStart.div(TIME_PERIOD_IN_SEC).add(1);
    uint ethCap = baseEthCap.mul((2**currentPeriod).sub(1));
    return ethCap;
  }
















  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

    uint tokenAmount = fullTokens * 10**token.decimals();
    uint weiAmount = weiPrice * fullTokens;

    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

    assignTokens(receiver, tokenAmount);


    Invested(receiver, weiAmount, tokenAmount, 0);
  }




  function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
     bytes32 hash = sha256(addr);
     if (ecrecover(hash, v, r, s) != signerAddress)
      revert();
     if (customerId == 0)
      revert();
     investInternal(addr, customerId);
  }




  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if (requiredSignedAddress)
      revert();
    if (customerId == 0)
      revert();
    investInternal(addr, customerId);
  }




  function invest(address addr) public payable {
    if (requireCustomerId)
      revert();
    if (requiredSignedAddress)
      revert();
    investInternal(addr, 0);
  }





  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
    investWithSignedAddress(msg.sender, customerId, v, r, s);
  }





  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }






  function buy() public payable {
    invest(msg.sender);
  }






  function finalize() public inState(State.Success) onlyOwner stopInEmergency {


    if (finalized) {
      revert();
    }


    if (address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }






  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;


    if (!finalizeAgent.isFinalizeAgent()) {
      revert();
    }
  }





  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }







  function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
    requiredSignedAddress = value;
    signerAddress = _signerAddress;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }




  function setEarlyParticipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }




  function addToWhitelist(address addr, bool status) onlyOwner {
    whitelist[addr] = status;
    Whitelisted(addr, status);
  }




  function addAllToWhitelist(address[] addresses, bool status) onlyOwner {
    for (uint index = 0; index < addresses.length; index++) {
      addToWhitelist(addresses[index], status);
    }
  }




  function setBaseEthCap(uint _baseEthCap) onlyOwner {
    if (_baseEthCap == 0)
      revert();
    baseEthCap = _baseEthCap;
    BaseEthCapChanged(baseEthCap);
  }











  function setEndsAt(uint time) onlyOwner {
    if (now > time) {
      revert();
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }






  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;


    if (!pricingStrategy.isPricingStrategy()) {
      revert();
    }
  }








  function setMultisig(address addr) public onlyOwner {


    if (investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      revert();
    }

    multisigWallet = addr;
  }






  function loadRefund() public payable inState(State.Failure) {
    if (msg.value == 0)
      revert();
    loadedRefund = loadedRefund.add(msg.value);
  }







  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0)
      revert();
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.add(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue))
      revert();
  }




  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }




  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }




  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }






  function getState() public constant returns (State) {
    if (finalized)
      return State.Finalized;
    else if (address(finalizeAgent) == 0)
      return State.Preparing;
    else if (!finalizeAgent.isSane())
      return State.Preparing;
    else if (!pricingStrategy.isSane(address(this)))
      return State.Preparing;
    else if (block.timestamp < startsAt)
      return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull())
      return State.Funding;
    else if (isMinimumGoalReached())
      return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
      return State.Refunding;
    else
      return State.Failure;
  }










































  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);




  function isCrowdsaleFull() public constant returns (bool);




  function assignTokens(address receiver, uint tokenAmount) private;
}
