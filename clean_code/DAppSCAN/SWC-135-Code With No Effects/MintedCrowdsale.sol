pragma solidity ^0.4.18;







import "../Crowdsale.sol";
import "../../token/extentions/MintableToken.sol";







contract MintedCrowdsale is Crowdsale {






  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}
