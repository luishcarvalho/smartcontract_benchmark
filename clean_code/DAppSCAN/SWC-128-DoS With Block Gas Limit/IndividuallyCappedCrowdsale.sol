pragma solidity ^0.4.18;







import "../../math/SafeMath.sol";
import "../Crowdsale.sol";
import "../../ownership/Ownable.sol";






contract IndividuallyCappedCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) public contributions;
  mapping(address => uint256) public caps;






  function setUserCap(address _beneficiary, uint256 _cap) external onlyOwner {
    caps[_beneficiary] = _cap;
  }






  function setGroupCap(address[] _beneficiaries, uint256 _cap) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      caps[_beneficiaries[i]] = _cap;
    }
  }






  function getUserCap(address _beneficiary) public view returns (uint256) {
    return caps[_beneficiary];
  }






  function getUserContribution(address _beneficiary) public view returns (uint256) {
    return contributions[_beneficiary];
  }






  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(contributions[_beneficiary].add(_weiAmount) <= caps[_beneficiary]);
  }






  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

}
