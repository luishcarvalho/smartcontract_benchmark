pragma solidity ^0.4.18;





























import "./BasicMathLib.sol";
import "./TokenLib.sol";
import "./CrowdsaleToken.sol";

library CrowdsaleLib {
  using BasicMathLib for uint256;

  struct CrowdsaleStorage {
  	address owner;

  	uint256 tokensPerEth;
  	uint256 startTime;
  	uint256 endTime;
    uint256 ownerBalance;
    uint256 startingTokenBalance;
    uint256[] milestoneTimes;
    uint8 currentMilestone;
    uint8 percentBurn;
    bool tokensSet;


    mapping (uint256 => uint256[2]) saleData;


  	mapping (address => uint256) hasContributed;


  	mapping (address => uint256) withdrawTokensMap;


    mapping (address => uint256) leftoverWei;

  	CrowdsaleToken token;
  }


  event LogTokensWithdrawn(address indexed _bidder, uint256 Amount);


  event LogWeiWithdrawn(address indexed _bidder, uint256 Amount);


  event LogOwnerEthWithdrawn(address indexed owner, uint256 amount, string Msg);


  event LogNoticeMsg(address _buyer, uint256 value, string Msg);


  event LogErrorMsg(uint256 amount, string Msg);










  function init(CrowdsaleStorage storage self,
                address _owner,
                uint256[] _saleData,
                uint256 _endTime,
                uint8 _percentBurn,
                CrowdsaleToken _token)
                public
  {
  	require(self.owner == 0);
    require(_saleData.length > 0);
    require((_saleData.length%3) == 0);
    require(_saleData[0] > (now + 2 hours));
    require(_endTime > _saleData[0]);
    require(_owner > 0);
    require(_percentBurn <= 100);
    self.owner = _owner;
    self.startTime = _saleData[0];
    self.endTime = _endTime;
    self.token = _token;
    self.percentBurn = _percentBurn;

    uint256 _tempTime;
    for(uint256 i = 0; i < _saleData.length; i += 3){
      require(_saleData[i] > _tempTime);
      require(_saleData[i + 1] > 0);
      require((_saleData[i + 2] == 0) || (_saleData[i + 2] >= 100));
      self.milestoneTimes.push(_saleData[i]);
      self.saleData[_saleData[i]][0] = _saleData[i + 1];
      self.saleData[_saleData[i]][1] = _saleData[i + 2];
      _tempTime = _saleData[i];
    }
    changeTokenPrice(self, _saleData[1]);
  }




  function crowdsaleActive(CrowdsaleStorage storage self) public view returns (bool) {
  	return (now >= self.startTime && now <= self.endTime);
  }




  function crowdsaleEnded(CrowdsaleStorage storage self) public view returns (bool) {
  	return now > self.endTime;
  }




  function validPurchase(CrowdsaleStorage storage self) internal returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    if (crowdsaleActive(self) && nonZeroPurchase) {
      return true;
    } else {
      LogErrorMsg(msg.value, "Invalid Purchase! Check start time and amount of ether.");
      return false;
    }
  }




  function withdrawTokens(CrowdsaleStorage storage self) public returns (bool) {
    bool ok;

    if (self.withdrawTokensMap[msg.sender] == 0) {
      LogErrorMsg(0, "Sender has no tokens to withdraw!");
      return false;
    }

    if (msg.sender == self.owner) {
      if(!crowdsaleEnded(self)){
        LogErrorMsg(0, "Owner cannot withdraw extra tokens until after the sale!");
        return false;
      } else {
        if(self.percentBurn > 0){
          uint256 _burnAmount = (self.withdrawTokensMap[msg.sender] * self.percentBurn)/100;
          self.withdrawTokensMap[msg.sender] = self.withdrawTokensMap[msg.sender] - _burnAmount;
          ok = self.token.burnToken(_burnAmount);
          require(ok);
        }
      }
    }

    var total = self.withdrawTokensMap[msg.sender];
    self.withdrawTokensMap[msg.sender] = 0;
    ok = self.token.transfer(msg.sender, total);
    require(ok);
    LogTokensWithdrawn(msg.sender, total);
    return true;
  }




  function withdrawLeftoverWei(CrowdsaleStorage storage self) public returns (bool) {
    if (self.leftoverWei[msg.sender] == 0) {
      LogErrorMsg(0, "Sender has no extra wei to withdraw!");
      return false;
    }

    var total = self.leftoverWei[msg.sender];
    self.leftoverWei[msg.sender] = 0;
    msg.sender.transfer(total);
    LogWeiWithdrawn(msg.sender, total);
    return true;
  }





  function withdrawOwnerEth(CrowdsaleStorage storage self) public returns (bool) {
    if ((!crowdsaleEnded(self)) && (self.token.balanceOf(this)>0)) {
      LogErrorMsg(0, "Cannot withdraw owner ether until after the sale!");
      return false;
    }

    require(msg.sender == self.owner);
    require(self.ownerBalance > 0);

    uint256 amount = self.ownerBalance;
    self.ownerBalance = 0;
    self.owner.transfer(amount);
    LogOwnerEthWithdrawn(msg.sender,amount,"Crowdsale owner has withdrawn all funds!");

    return true;
  }





  function changeTokenPrice(CrowdsaleStorage storage self,
                            uint256 _tokensPerEth)
                            internal
                            returns (bool)
  {
  	require(_tokensPerEth > 0);

    self.tokensPerEth = _tokensPerEth;

    return true;
  }




  function setTokens(CrowdsaleStorage storage self) public returns (bool) {
    require(msg.sender == self.owner);
    require(!self.tokensSet);
    require(now < self.endTime);

    uint256 _tokenBalance;

    _tokenBalance = self.token.balanceOf(this);
    self.withdrawTokensMap[msg.sender] = _tokenBalance;
    self.startingTokenBalance = _tokenBalance;
    self.tokensSet = true;

    return true;
  }





  function getSaleData(CrowdsaleStorage storage self, uint256 timestamp)
                       public
                       view
                       returns (uint256[3])
  {
    uint256[3] memory _thisData;
    uint256 index;

    while((index < self.milestoneTimes.length) && (self.milestoneTimes[index] < timestamp)) {
      index++;
    }
    if(index == 0)
      index++;

    _thisData[0] = self.milestoneTimes[index - 1];
    _thisData[1] = self.saleData[_thisData[0]][0];
    _thisData[2] = self.saleData[_thisData[0]][1];
    return _thisData;
  }




  function getTokensSold(CrowdsaleStorage storage self) public view returns (uint256) {
    return self.startingTokenBalance - self.withdrawTokensMap[self.owner];
  }
}
