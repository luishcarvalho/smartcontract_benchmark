





pragma solidity ^0.4.8;

import "./CrowdsaleBase.sol";











contract AllocatedCrowdsaleMixin is CrowdsaleBase {








  function AllocatedCrowdsaleMixin(address _beneficiary) {
    beneficiary = _beneficiary;
  }





  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
    if(tokenAmount > getTokensLeft()) {
      return true;
    } else {
      if (weiAmount < 10**17) {
        return true;
      }
      else {
        return false;
      }
    }
  }




  function isCrowdsaleFull() public constant returns (bool) {
    return getTokensLeft() == 0;
  }




  function getTokensLeft() public constant returns (uint) {
    return token.allowance(owner, this);
  }






  function assignTokens(address receiver, uint tokenAmount) internal {
    if(!token.transferFrom(beneficiary, receiver, tokenAmount)) throw;
  }
}
