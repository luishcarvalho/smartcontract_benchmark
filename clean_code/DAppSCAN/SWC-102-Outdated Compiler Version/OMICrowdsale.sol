pragma solidity ^0.4.18;

import "./OMIToken.sol";
import "./OMITokenLock.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol";
import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";



contract OMICrowdsale is WhitelistedCrowdsale, Pausable {
  using SafeMath for uint256;




  uint256 constant crowdsaleStartTime = 1530316800;
  uint256 constant crowdsaleFinishTime = 1538351999;
  uint256 constant crowdsaleUSDGoal = 44625000;
  uint256 constant crowdsaleTokenGoal = 362500000*1e18;
  uint256 constant minimumTokenPurchase = 2500*1e18;
  uint256 constant maximumTokenPurchase = 1000000*1e18;




  OMIToken public token;
  OMITokenLock public tokenLock;

  uint256 currentDiscountAmount;
  uint256 public totalUSDRaised;
  uint256 public totalTokensSold;
  bool public isFinalized = false;

  mapping(address => uint256) public purchaseRecords;




  event RateChanged(uint256 newRate);
  event USDRaisedUpdated(uint256 newTotal);
  event CrowdsaleStarted();
  event CrowdsaleFinished();





  modifier whenNotFinalized () {
    require(!isFinalized);
    _;
  }





  function OMICrowdsale (
    uint256 _startingRate,
    address _ETHWallet,
    address _OMIToken,
    address _OMITokenLock
  )
    Crowdsale(_startingRate, _ETHWallet, ERC20(_OMIToken))
    public
  {
    token = OMIToken(_OMIToken);
    tokenLock = OMITokenLock(_OMITokenLock);
    rate = _startingRate;
  }



  function setRate(uint256 _newRate)
    public
    onlyOwner
    whenNotFinalized
    returns(bool)
  {
    require(_newRate > 0);
    rate = _newRate;
    RateChanged(rate);
    return true;
  }


  function setUSDRaised(uint256 _total)
    public
    onlyOwner
    whenNotFinalized
  {
    require(_total > 0);
    totalUSDRaised = _total;
    USDRaisedUpdated(_total);
  }



  function getPurchaseRecord(address _beneficiary)
    public
    view
    isWhitelisted(_beneficiary)
    returns(uint256)
  {
    return purchaseRecords[_beneficiary];
  }







  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
    internal
   {
    super._preValidatePurchase(_beneficiary, _weiAmount);


    require(!paused);


    require(!isFinalized);

    uint256 _tokenAmount = _getTokenAmount(_weiAmount);

    uint256 _totalPurchased = purchaseRecords[_beneficiary].add(_tokenAmount);
    require(_totalPurchased >= minimumTokenPurchase);
    require(_totalPurchased <= maximumTokenPurchase);


    require(msg.sender == _beneficiary);


    require(now >= crowdsaleStartTime);
  }




  function _processPurchase(address _beneficiary, uint256 _tokenAmount)
    internal
  {

    uint day = 86400;
    tokenLock.lockTokens(_beneficiary, day.mul(7), _tokenAmount);
  }




  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
    internal
  {
    uint256 _tokenAmount = _getTokenAmount(_weiAmount);


    purchaseRecords[_beneficiary] = purchaseRecords[_beneficiary].add(_tokenAmount);


    totalTokensSold = totalTokensSold.add(_tokenAmount);



    if (crowdsaleTokenGoal.sub(totalTokensSold) < minimumTokenPurchase) {
      _finalization();
    }

    if (totalUSDRaised >= crowdsaleUSDGoal) {
      _finalization();
    }

    if (now > crowdsaleFinishTime) {
      _finalization();
    }
  }


  function _finalization()
    internal
    whenNotFinalized
  {
    isFinalized = true;
    tokenLock.finishCrowdsale();
    CrowdsaleFinished();
  }
}
