
pragma solidity ^0.4.18;




























import "./BasicMathLib.sol";
import "./TokenLib.sol";
import "./CrowdsaleToken.sol";
import "./CrowdsaleLib.sol";
import "./LinkedListLib.sol";

library InteractiveCrowdsaleLib {
  using BasicMathLib for uint256;
  using TokenLib for TokenLib.TokenStorage;
  using LinkedListLib for LinkedListLib.LinkedList;
  using CrowdsaleLib for CrowdsaleLib.CrowdsaleStorage;


  uint256 constant NULL = 0;
  uint256 constant HEAD = 0;
  bool constant PREV = false;
  bool constant NEXT = true;

  struct InteractiveCrowdsaleStorage {

    CrowdsaleLib.CrowdsaleStorage base;


    LinkedListLib.LinkedList valuationsList;


    TokenLib.TokenStorage tokenInfo;

    uint256 endWithdrawalTime;



    uint256 totalValuation;





    uint256 valueCommitted;



    uint256 currentBucket;



    uint256 q;


    uint256 minimumRaise;


    uint8 percentBeingSold;



    uint256 priceBonusPercent;


    bool isFinalized;


    bool isCanceled;


    mapping (address => uint256) pricePurchasedAt;


    mapping (uint256 => uint256) valuationSums;


    mapping (uint256 => uint256) numBidsAtValuation;


    mapping (address => uint256) personalCaps;


    mapping (address => bool) hasManuallyWithdrawn;
  }


  event LogBidAccepted(address indexed bidder, uint256 amount, uint256 personalValuation);


  event LogBidWithdrawn(address indexed bidder, uint256 amount, uint256 personalValuation);


  event LogBidRemoved(address indexed bidder, uint256 personalValuation);


  event LogErrorMsg(uint256 amount, string Msg);


  event LogTokenPriceChange(uint256 amount, string Msg);



  event BucketAndValuationAndCommitted(uint256 bucket, uint256 valuation, uint256 committed);
















  function init(InteractiveCrowdsaleStorage storage self,
                address _owner,
                uint256[] _saleData,
                uint256 _priceBonusPercent,
                uint256 _minimumRaise,
                uint256 _endWithdrawalTime,
                uint256 _endTime,
                uint8 _percentBeingSold,
                string _tokenName,
                string _tokenSymbol,
                uint8 _tokenDecimals,
                bool _allowMinting) public
  {
    self.base.init(_owner,
                _saleData,
                _endTime,
                0,
                CrowdsaleToken(0));

    require(_endWithdrawalTime < _endTime);
    require(_endWithdrawalTime > _saleData[0]);
    require(_minimumRaise > 0);
    require(_percentBeingSold > 0);
    require(_percentBeingSold <= 100);
    require(_priceBonusPercent > 0);

    self.minimumRaise = _minimumRaise;
    self.endWithdrawalTime = _endWithdrawalTime;
    self.percentBeingSold = _percentBeingSold;
    self.priceBonusPercent = _priceBonusPercent;

    self.tokenInfo.name = _tokenName;
    self.tokenInfo.symbol = _tokenSymbol;
    self.tokenInfo.decimals = _tokenDecimals;
    self.tokenInfo.stillMinting = _allowMinting;
  }




  function numDigits(uint256 _number) public pure returns (uint256) {
    uint256 _digits = 0;
    while (_number != 0) {
      _number /= 10;
      _digits++;
    }
    return _digits;
  }







  function calculateTokenPurchase(uint256 _amount,
                                  uint256 _price)
                                  internal
                                  pure
                                  returns (uint256,uint256)
  {
    uint256 remainder = 0;

    bool err;
    uint256 numTokens;
    uint256 weiTokens;


    (err,weiTokens) = _amount.times(_price);
    require(!err);

    numTokens = weiTokens / 1000000000000000000;
    remainder = weiTokens % 1000000000000000000;
    remainder = remainder / _price;

    return (numTokens,remainder);
  }




  function getCurrentBonus(InteractiveCrowdsaleStorage storage self) internal view returns (uint256){

    uint256 bonusTime = self.endWithdrawalTime - self.base.startTime;

    uint256 elapsed = now - self.base.startTime;
    uint256 percentElapsed = (elapsed * 100)/bonusTime;

    bool err;
    uint256 currentBonus;
    (err,currentBonus) = self.priceBonusPercent.minus(((percentElapsed * self.priceBonusPercent)/100));
    require(!err);

    return currentBonus;
  }







  function submitBid(InteractiveCrowdsaleStorage storage self,
                      uint256 _amount,
                      uint256 _personalCap,
                      uint256 _valuePredict) public returns (bool)
  {
    require(msg.sender != self.base.owner);
    require(self.base.validPurchase());

    require((self.personalCaps[msg.sender] == 0) && (self.base.hasContributed[msg.sender] == 0));

    uint256 _bonusPercent;

    if (now < self.endWithdrawalTime) {
      require(_personalCap > _amount);
      _bonusPercent = getCurrentBonus(self);
    } else {


      require(_personalCap >= self.totalValuation + _amount);
    }




    uint256 digits = numDigits(_personalCap);
    if(digits > 3) {
      require((_personalCap % (10**(digits - 3))) == 0);
    }



    uint256 _listSpot;
    if(!self.valuationsList.nodeExists(_personalCap)){
        _listSpot = self.valuationsList.getSortedSpot(_valuePredict,_personalCap,NEXT);
        self.valuationsList.insert(_listSpot,_personalCap,PREV);
    }


    self.personalCaps[msg.sender] = _personalCap;


    self.valuationSums[_personalCap] += _amount;
    self.numBidsAtValuation[_personalCap] += 1;


    self.base.hasContributed[msg.sender] += _amount;


    uint256 _proposedCommit;
    uint256 _currentBucket;
    bool loop;
    bool exists;


    if(_personalCap > self.currentBucket){



      if (self.totalValuation == self.currentBucket) {


        _proposedCommit = (self.valueCommitted - self.valuationSums[self.currentBucket]) + _amount;
        if(_proposedCommit > self.currentBucket){ loop = true; }
      } else {


        _proposedCommit = self.totalValuation + _amount;
        loop = true;
      }

      if(loop){

        (exists,_currentBucket) = self.valuationsList.getAdjacent(self.currentBucket, NEXT);

        while(_proposedCommit >= _currentBucket){


          _proposedCommit = _proposedCommit - self.valuationSums[_currentBucket];
          (exists,_currentBucket) = self.valuationsList.getAdjacent(_currentBucket, NEXT);
        }

        (exists, _currentBucket) = self.valuationsList.getAdjacent(_currentBucket, PREV);
        self.currentBucket = _currentBucket;
      } else {

        _currentBucket = self.currentBucket;
      }

      if(_proposedCommit <= _currentBucket){

        _proposedCommit += self.valuationSums[_currentBucket];

        self.totalValuation = _currentBucket;
      } else {

        self.totalValuation = _proposedCommit;
      }

      self.valueCommitted = _proposedCommit;
    } else if(_personalCap == self.totalValuation){
      self.valueCommitted += _amount;
    }

    self.pricePurchasedAt[msg.sender] = (self.base.tokensPerEth * (100 + _bonusPercent))/100;
    LogBidAccepted(msg.sender, _amount, _personalCap);
    BucketAndValuationAndCommitted(self.currentBucket, self.totalValuation, self.valueCommitted);
    return true;
  }






  function withdrawBid(InteractiveCrowdsaleStorage storage self) public returns (bool) {

    require(self.personalCaps[msg.sender] > 0);

    uint256 refundWei;


    if (now >= self.endWithdrawalTime) {
      require(self.personalCaps[msg.sender] < self.totalValuation);


      refundWei = self.base.hasContributed[msg.sender];

    } else {
      require(!self.hasManuallyWithdrawn[msg.sender]);












      uint256 multiplierPercent = (100 * (self.endWithdrawalTime - now)) /
                                  (self.endWithdrawalTime - self.base.startTime);
      refundWei = (multiplierPercent * self.base.hasContributed[msg.sender]) / 100;

      self.valuationSums[self.personalCaps[msg.sender]] -= refundWei;
      self.numBidsAtValuation[self.personalCaps[msg.sender]] -= 1;

      self.pricePurchasedAt[msg.sender] = self.pricePurchasedAt[msg.sender] -
                                          ((self.pricePurchasedAt[msg.sender] - self.base.tokensPerEth) / 3);

      self.hasManuallyWithdrawn[msg.sender] = true;

    }


    self.base.leftoverWei[msg.sender] += refundWei;


    self.base.hasContributed[msg.sender] -= refundWei;


    uint256 _proposedCommit;
    uint256 _proposedValue;
    uint256 _currentBucket;
    bool loop;
    bool exists;



    if(self.personalCaps[msg.sender] >= self.totalValuation){


      _proposedCommit = self.valueCommitted - refundWei;


      if(_proposedCommit <= self.currentBucket){

        if(self.totalValuation > self.currentBucket){
          _proposedCommit += self.valuationSums[self.currentBucket];
        }

        if(_proposedCommit >= self.currentBucket){
          _proposedValue = self.currentBucket;
        } else {

          loop = true;
        }
      } else {
        if(self.totalValuation == self.currentBucket){
          _proposedValue = self.totalValuation;
        } else {
          _proposedValue = _proposedCommit;
        }
      }

      if(loop){

        (exists,_currentBucket) = self.valuationsList.getAdjacent(self.currentBucket, PREV);
        while(_proposedCommit <= _currentBucket){

          _proposedCommit += self.valuationSums[_currentBucket];

          if(_proposedCommit >= _currentBucket){
            _proposedValue = _currentBucket;
          } else {
            (exists,_currentBucket) = self.valuationsList.getAdjacent(_currentBucket, PREV);
          }
        }

        if(_proposedValue == 0) { _proposedValue = _proposedCommit; }

        self.currentBucket = _currentBucket;
      }

      self.totalValuation = _proposedValue;
      self.valueCommitted = _proposedCommit;
    }

    LogBidWithdrawn(msg.sender, refundWei, self.personalCaps[msg.sender]);
    BucketAndValuationAndCommitted(self.currentBucket, self.totalValuation, self.valueCommitted);
    return true;
  }




  function finalizeSale(InteractiveCrowdsaleStorage storage self) public returns (bool) {
    require(now >= self.base.endTime);
    require(!self.isFinalized);
    require(setCanceled(self));

    self.isFinalized = true;
    require(launchToken(self));

    uint256 computedValue;

    if(!self.isCanceled){
      if(self.totalValuation == self.currentBucket){

        self.q = (100*(self.valueCommitted - self.totalValuation)/(self.valuationSums[self.totalValuation])) + 1;
        computedValue = self.valueCommitted - self.valuationSums[self.totalValuation];
        computedValue += (self.q * self.valuationSums[self.totalValuation])/100;
      } else {

        computedValue = self.totalValuation;
      }
      self.base.ownerBalance = computedValue;
    }
  }





  function launchToken(InteractiveCrowdsaleStorage storage self) internal returns (bool) {

    uint256 _fullValue = (self.totalValuation*100)/uint256(self.percentBeingSold);

    uint256 _bonusValue = ((self.totalValuation * (100 + self.priceBonusPercent))/100) - self.totalValuation;

    uint256 _supply = (_fullValue * self.base.tokensPerEth)/1000000000000000000;

    uint256 _bonusTokens = (_bonusValue * self.base.tokensPerEth)/1000000000000000000;

    uint256 _ownerTokens = _supply - ((_supply * uint256(self.percentBeingSold))/100);

    uint256 _totalSupply = _supply + _bonusTokens;


    self.base.token = new CrowdsaleToken(address(this),
                                         self.tokenInfo.name,
                                         self.tokenInfo.symbol,
                                         self.tokenInfo.decimals,
                                         _totalSupply,
                                         self.tokenInfo.stillMinting);


    if(!self.isCanceled){
      self.base.token.transfer(self.base.owner, _ownerTokens);
    } else {
      self.base.token.transfer(self.base.owner, _supply);
      self.base.token.burnToken(_bonusTokens);
    }

    self.base.token.changeOwner(self.base.owner);
    self.base.startingTokenBalance = _supply - _ownerTokens;

    return true;
  }






  function setCanceled(InteractiveCrowdsaleStorage storage self) internal returns(bool){
    bool canceled = (self.totalValuation < self.minimumRaise) ||
                    ((now > (self.base.endTime + 30 days)) && !self.isFinalized);

    if(canceled) {self.isCanceled = true;}

    return true;
  }





  function retreiveFinalResult(InteractiveCrowdsaleStorage storage self) public returns (bool) {
    require(now > self.base.endTime);
    require(self.personalCaps[msg.sender] > 0);

    uint256 numTokens;
    uint256 remainder;

    if(!self.isFinalized){
      require(setCanceled(self));
      require(self.isCanceled);
    }

    if (self.isCanceled) {

      self.base.leftoverWei[msg.sender] += self.base.hasContributed[msg.sender];
      self.base.hasContributed[msg.sender] = 0;
      LogErrorMsg(self.totalValuation, "Sale is canceled, all bids have been refunded!");
      return true;
    }

    if (self.personalCaps[msg.sender] < self.totalValuation) {


      self.base.leftoverWei[msg.sender] += self.base.hasContributed[msg.sender];


      self.base.hasContributed[msg.sender] = 0;

      return self.base.withdrawLeftoverWei();

    } else if (self.personalCaps[msg.sender] == self.totalValuation) {


      uint256 refundAmount = (self.q*self.base.hasContributed[msg.sender])/100;


      self.base.leftoverWei[msg.sender] += refundAmount;


      self.base.hasContributed[msg.sender] -= refundAmount;
    }

    LogErrorMsg(self.base.hasContributed[msg.sender],"contribution");
    LogErrorMsg(self.pricePurchasedAt[msg.sender],"price");
    LogErrorMsg(self.q,"percentage");

    (numTokens, remainder) = calculateTokenPurchase(self.base.hasContributed[msg.sender],
                                                    self.pricePurchasedAt[msg.sender]);


    self.base.withdrawTokensMap[msg.sender] += numTokens;
    self.valueCommitted = self.valueCommitted - remainder;
    self.base.leftoverWei[msg.sender] += remainder;


    uint256 _fullBonus;
    uint256 _fullBonusPrice = (self.base.tokensPerEth*(100 + self.priceBonusPercent))/100;
    (_fullBonus, remainder) = calculateTokenPurchase(self.base.hasContributed[msg.sender], _fullBonusPrice);
    uint256 _leftoverBonus = _fullBonus - numTokens;
    self.base.token.burnToken(_leftoverBonus);

    self.base.hasContributed[msg.sender] = 0;


    self.base.withdrawTokens();

    self.base.withdrawLeftoverWei();

  }
































