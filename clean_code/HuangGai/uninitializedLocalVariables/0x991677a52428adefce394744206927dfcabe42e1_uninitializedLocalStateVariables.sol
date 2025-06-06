





pragma solidity 0.6.12;




library Address {

















  function isContract(address account) internal view returns (bool) {




    uint256 size;

    assembly { size := extcodesize(account) }
    return size > 0;
  }

















  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");


    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }



















  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }







  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }












  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }







  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");


    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
    if (success) {
      return returndata;
    } else {

      if (returndata.length > 0) {



        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}
















library SafeMath {









  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    assert(c >= a);

    return c;
  }










  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }










  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    assert(b <= a);
    uint256 c ;


    return c;
  }










  function mul(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
      return 0;
    }

    uint256 c ;

    assert(c / a == b);

    return c;
  }












  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }












  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c ;



    return c;
  }












  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }












  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    assert(b != 0);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




  constructor () internal {
    address msgSender ;

    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }




  function owner() public view returns (address) {
    return _owner;
  }




  modifier onlyOwner() {
    assert(_owner == _msgSender());
    _;
  }








  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }





  function transferOwnership(address newOwner) public virtual onlyOwner {
    assert(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



abstract contract CalculatorInterface {
  function calculateNumTokens(uint256 balance, uint256 daysStaked, address stakerAddress, uint256 totalSupply) public virtual view returns (uint256);
  function randomness() public view virtual returns (uint256);
}



abstract contract BLVToken {
  function balanceOf(address account) public view virtual returns (uint256);
  function totalSupply() public view virtual returns (uint256);
  function _burn(address account, uint256 amount) external virtual;
  function mint(address account, uint256 amount) external virtual;
}


abstract contract VotingBLVToken {
  function isActiveVoter(address voterAddress) public view virtual returns (bool);
}












contract Staking is Ownable {
  using SafeMath for uint256;
  using Address for address;



  struct staker {
    uint startTimestamp;
    uint lastTimestamp;
  }

  struct update {
    uint timestamp;
    uint numerator;
    uint denominator;
    uint price;
    uint volume;
  }

  BLVToken public token;
  VotingBLVToken public _votingContract;
  address public liquidityContract;
  bool private _votingEnabled;
  address public _intervalWatcher;
  uint public numStakers;

  modifier onlyToken() {
    assert(_msgSender() == address(token));
    _;
  }

  modifier onlyWatcher() {
    assert(_msgSender() == _intervalWatcher);
    _;
  }

  modifier onlyNextStakingContract() {
    assert(_msgSender() == _nextStakingContract);
    _;
  }

  mapping (address => staker) private _stakers;

  mapping (address => string) private _whitelist;

  mapping (address => uint256) private _blacklist;

  bool public _enableBurns;

  bool private _priceTarget1Hit;

  bool private _priceTarget2Hit;

  address public _uniswapV2Pair;

  uint8 public upperBoundBurnPercent;

  uint public lowerBoundBurnPercent;

  bool public _enableUniswapDirectBurns;

  uint256 public _minStake;

  uint8 public _minStakeDurationDays;

  uint8 public _minPercentIncrease;

  uint256 public _inflationAdjustmentFactor;

  uint256 public _streak;

  update public _lastUpdate;

  CalculatorInterface private _externalCalculator;

  address private _nextStakingContract;

  bool public _useExternalCalc;

  bool public _freeze;

  bool public _enableHoldersDay;

  event StakerRemoved(address StakerAddress);

  event StakerAdded(address StakerAddress);

  event StakesUpdated(uint Amount);

  event MassiveCelebration();

  event Transfer(address indexed from, address indexed to, uint256 value);


  constructor () public {
    token = BLVToken(0x8DA25B8eD753a5910013167945A676921e864436);
    _intervalWatcher = msg.sender;
    _minStake = 1000E18;
    _inflationAdjustmentFactor = 500;
    _streak = 0;
    _minStakeDurationDays = 0;
    _useExternalCalc = false;
    lowerBoundBurnPercent = 7;
    upperBoundBurnPercent = 9;
    _freeze = false;
    _minPercentIncrease = 10;
    liquidityContract = msg.sender;
    _whitelist[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = "UniswapV2";
    _whitelist[msg.sender] = "Owner";
    _whitelist[0xF40B0918D6b78fd705F30D92C9626ad218F1aEcE] = "Treasury";
    _whitelist[0x2BFA783D7f38aAAa997650aE0EfdBDF632288A7F] = "Team";
    _uniswapV2Pair = 0x6C25CF2160dB4A1BE0f1317FC301F5a5cDbA9199;
    _whitelist[_uniswapV2Pair] = "UniswapPair";
  }



  function updateState(uint numerator, uint denominator, uint256 price, uint256 volume) external onlyWatcher {

    require(numerator > 0 && denominator > 0 && price > 0 && volume > 0, "Parameters cannot be negative or zero");

    if (numerator < 2 && denominator == 100 || numerator < 20 && denominator == 1000) {
      require(mulDiv(1000, numerator, denominator) >= _minPercentIncrease, "Increase must be at least _minPercentIncrease to count");
    }


    uint secondsSinceLastUpdate ;


    if (secondsSinceLastUpdate < 129600) {
        _streak++;
    } else {
        _streak = 1;
    }

    if (price >= 1000 && _priceTarget1Hit == false) {
      _priceTarget1Hit = true;
      _streak = 50;
      emit MassiveCelebration();

    } else if (price >= 10000 && _priceTarget2Hit == false) {
      _priceTarget2Hit = true;
      _streak = 100;
      _minStake = 100E18;
      emit MassiveCelebration();
    }

    _lastUpdate = update(block.timestamp, numerator, denominator, price, volume);
  }

  function resetStakeTime() external {
    uint balance ;

    assert(balance > 0);
    assert(balance >= _minStake);

    staker storage thisStaker = _stakers[msg.sender];

    if (thisStaker.lastTimestamp == 0) {
      thisStaker.lastTimestamp = block.timestamp;
    }
    if (thisStaker.startTimestamp == 0) {
      thisStaker.startTimestamp = block.timestamp;
      numStakers++;
    }
  }


  function resetStakeTimeMigrateState(address addr) external onlyNextStakingContract returns (uint256 startTimestamp, uint256 lastTimestamp) {
    startTimestamp = _stakers[addr].startTimestamp;
    lastTimestamp = _stakers[addr].lastTimestamp;
    _stakers[addr].lastTimestamp = block.timestamp;
    _stakers[addr].startTimestamp = block.timestamp;
  }

  function updateMyStakes(address stakerAddress, uint256 balance, uint256 totalSupply) external onlyToken returns (uint256) {
    assert(balance > 0);

    staker memory thisStaker = _stakers[stakerAddress];

    assert(thisStaker.lastTimestamp > 0);
    assert(thisStaker.startTimestamp > 0);

    assert(block.timestamp > thisStaker.lastTimestamp);
    assert(_lastUpdate.timestamp > thisStaker.lastTimestamp);

    uint daysStaked ;


    assert(daysStaked >= _minStakeDurationDays);
    assert(balance >= _minStake);
    uint numTokens ;

    if (_enableHoldersDay && daysStaked >= 30) {
      numTokens = mulDiv(balance, daysStaked, 600);
    }

    _stakers[stakerAddress].lastTimestamp = block.timestamp;
    emit StakesUpdated(numTokens);

    return numTokens;
  }

  function calculateNumTokens(uint256 balance, uint256 daysStaked, address stakerAddress, uint256 totalSupply) internal view returns (uint256) {
    if (_useExternalCalc) {
      return _externalCalculator.calculateNumTokens(balance, daysStaked, stakerAddress, totalSupply);
    }

    uint256 inflationAdjustmentFactor ;


    if (_streak > 1) {
      inflationAdjustmentFactor /= _streak;
    }

    if (daysStaked > 60) {
      daysStaked = 60;
    } else if (daysStaked == 0) {
      daysStaked = 1;
    }

    uint marketCap ;


    uint ratio ;


    if (ratio > 50) {
      inflationAdjustmentFactor = inflationAdjustmentFactor.mul(10);
    } else if (ratio > 25) {
      inflationAdjustmentFactor = _inflationAdjustmentFactor;
    }

    uint numTokens ;

    uint tenPercent ;


    if (numTokens > tenPercent) {
      numTokens = tenPercent;
    }

    return numTokens;
  }

  function currentExpectedRewards(address _staker) external view returns (uint256) {
      staker memory thisStaker = _stakers[_staker];
      uint daysStaked ;

      uint balance ;


      if(thisStaker.lastTimestamp == 0 || thisStaker.startTimestamp == 0 ||
      _lastUpdate.timestamp <= thisStaker.lastTimestamp ||
      daysStaked < _minStakeDurationDays || balance < _minStake) {
          return 0;
      }

      uint numTokens ;


      if (_enableHoldersDay && daysStaked >= 30) {
        numTokens = mulDiv(balance, daysStaked, 600);
      }
    return numTokens;
  }

  function nextExpectedRewards(address _staker, uint price, uint volume, uint change) external view returns (uint256) {
        staker memory thisStaker = _stakers[_staker];
        uint daysStaked ;

        uint balance ;


        if(thisStaker.lastTimestamp == 0 || thisStaker.startTimestamp == 0 ||
          daysStaked < _minStakeDurationDays || balance < _minStake || change <= 1) {
          return 0;
        }

        uint256 inflationAdjustmentFactor ;

        uint256 streak ;


        uint secondsSinceLastUpdate ;


        if (secondsSinceLastUpdate <= 86400) {
            streak++;
        } else {
            streak = 1;
        }


        if (streak > 1) {
          inflationAdjustmentFactor /= streak;
        }

        if (daysStaked > 60) {
          daysStaked = 60;
        } else if (daysStaked == 0) {
          daysStaked = 1;
        }

        uint marketCap ;


        uint ratio ;


        if (ratio > 50) {
          inflationAdjustmentFactor = inflationAdjustmentFactor.mul(10);
        } else if (ratio > 25) {
          inflationAdjustmentFactor = _inflationAdjustmentFactor;
        }

        uint numTokens ;

        uint tenPercent ;


        if (numTokens > tenPercent) {
          numTokens = tenPercent;
        }

        return numTokens;
  }



  function updateTokenAddress(BLVToken newToken) external onlyOwner {
    require(address(newToken) != address(0));
    token = newToken;
  }

  function updateCalculator(CalculatorInterface calc) external onlyOwner {
    if(address(calc) == address(0)) {
      _externalCalculator = CalculatorInterface(address(0));
      _useExternalCalc = false;
    } else {
      _externalCalculator = calc;
      _useExternalCalc = true;
    }
  }


  function updateInflationAdjustmentFactor(uint256 inflationAdjustmentFactor) external onlyOwner {
    _inflationAdjustmentFactor = inflationAdjustmentFactor;
  }

  function updateStreak(uint streak) external onlyOwner {
    _streak = streak;
  }

  function updateMinStakeDurationDays(uint8 minStakeDurationDays) external onlyOwner {
    _minStakeDurationDays = minStakeDurationDays;
  }

  function updateMinStakes(uint minStake) external onlyOwner {
    _minStake = minStake;
  }
  function updateMinPercentIncrease(uint8 minIncrease) external onlyOwner {
    _minPercentIncrease = minIncrease;
  }

  function enableBurns(bool enabledBurns) external onlyOwner {
    _enableBurns = enabledBurns;
  }

  function updateHoldersDay(bool enableHoldersDay) external onlyOwner {
    _enableHoldersDay = enableHoldersDay;
  }

  function updateWhitelist(address addr, string calldata reason, bool remove) external onlyOwner returns (bool) {
    if (remove) {
      delete _whitelist[addr];
      return true;
    } else {
      _whitelist[addr] = reason;
      return true;
    }
  }

  function updateBlacklist(address addr, uint256 fee, bool remove) external onlyOwner returns (bool) {
    if (remove) {
      delete _blacklist[addr];
      return true;
    } else {
      _blacklist[addr] = fee;
      return true;
    }
  }

  function updateUniswapPair(address addr) external onlyOwner returns (bool) {
    require(addr != address(0));
    _uniswapV2Pair = addr;
    return true;
  }

  function updateDirectSellBurns(bool enableDirectSellBurns) external onlyOwner {
    _enableUniswapDirectBurns = enableDirectSellBurns;
  }

  function updateUpperBurnPercent(uint8 sellerBurnPercent) external onlyOwner {
    upperBoundBurnPercent = sellerBurnPercent;
  }

  function updateLowerBurnPercent(uint8 sellerBurnPercent) external onlyOwner {
    lowerBoundBurnPercent = sellerBurnPercent;
  }

  function freeze(bool enableFreeze) external onlyOwner {
    _freeze = enableFreeze;
  }

  function updateNextStakingContract(address nextContract) external onlyOwner {
    require(nextContract != address(0));
    _nextStakingContract = nextContract;
  }

  function getStaker(address _staker) external view returns (uint256, uint256) {
    return (_stakers[_staker].startTimestamp, _stakers[_staker].lastTimestamp);
  }

  function getStakerDaysStaked(address _staker) external view returns (uint) {
      if(_stakers[_staker].startTimestamp == 0) {
          return 0;
      }
      return block.timestamp.sub(_stakers[_staker].startTimestamp) / 86400;
  }

  function getWhitelist(address addr) external view returns (string memory) {
    return _whitelist[addr];
  }

  function getBlacklist(address addr) external view returns (uint) {
    return _blacklist[addr];
  }







  function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
    (uint l, uint h) = fullMul (x, y);
    assert (h < z);
    uint mm ;

    if (mm > l) h -= 1;
    l -= mm;
    uint pow2 ;

    z /= pow2;
    l /= pow2;
    l += h * ((-pow2) / pow2 + 1);
    uint r ;

    r *= 2 - z * r;
    r *= 2 - z * r;
    r *= 2 - z * r;
    r *= 2 - z * r;
    r *= 2 - z * r;
    r *= 2 - z * r;
    r *= 2 - z * r;
    r *= 2 - z * r;
    return l * r;
  }

  function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
    uint mm ;

    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function streak() public view returns (uint) {
    return _streak;
  }



  function transferHook(address sender, address recipient, uint256 amount, uint256 senderBalance, uint256 recipientBalance) external onlyToken returns (uint256, uint256, uint256) {
    assert(_freeze == false);
    assert(sender != recipient);
    assert(amount > 0);
    assert(senderBalance >= amount);

    if (_votingEnabled) {
      assert(!_votingContract.isActiveVoter(sender));
    }

    uint totalAmount ;

    bool shouldAddStaker ;

    uint burnedAmount ;


    if (_enableBurns && bytes(_whitelist[sender]).length == 0 && bytes(_whitelist[recipient]).length == 0) {

      burnedAmount = mulDiv(amount, _randomness(), 100);

      if (_blacklist[recipient] > 0) {
        burnedAmount = mulDiv(amount, _blacklist[recipient], 100);
        shouldAddStaker = false;
      }

      if (burnedAmount > 0) {
        if (burnedAmount > amount) {
          totalAmount = 0;
        } else {
          totalAmount = amount.sub(burnedAmount);
        }
        senderBalance = senderBalance.sub(burnedAmount, "ERC20: burn amount exceeds balance");
      }
    } else if (recipient == _uniswapV2Pair) {
      shouldAddStaker = false;
      if (_enableUniswapDirectBurns) {
        burnedAmount = mulDiv(amount, _randomness(), 100);
        if (burnedAmount > 0) {
          if (burnedAmount > amount) {
            totalAmount = 0;
          } else {
            totalAmount = amount.sub(burnedAmount);
          }
          senderBalance = senderBalance.sub(burnedAmount, "ERC20: burn amount exceeds balance");
        }
      }
    }

    if (bytes(_whitelist[recipient]).length > 0) {
      shouldAddStaker = false;
    }




    if (shouldAddStaker && _stakers[recipient].startTimestamp > 0 && recipientBalance > 0) {
      uint percent ;

      percent = percent.div(2);
      if(percent.add(_stakers[recipient].startTimestamp) > block.timestamp) {
        _stakers[recipient].startTimestamp = block.timestamp;
      } else {
        _stakers[recipient].startTimestamp = _stakers[recipient].startTimestamp.add(percent);
      }

      if(percent.add(_stakers[recipient].lastTimestamp) > block.timestamp) {
        _stakers[recipient].lastTimestamp = block.timestamp;
      } else {
        _stakers[recipient].lastTimestamp = _stakers[recipient].lastTimestamp.add(percent);
      }
    } else if (shouldAddStaker && recipientBalance == 0 && (_stakers[recipient].startTimestamp > 0 || _stakers[recipient].lastTimestamp > 0)) {
      delete _stakers[recipient];
      numStakers--;
      emit StakerRemoved(recipient);
    }

    senderBalance = senderBalance.sub(totalAmount, "ERC20: transfer amount exceeds balance");
    recipientBalance = recipientBalance.add(totalAmount);

    if (shouldAddStaker && _stakers[recipient].startTimestamp == 0 && (totalAmount >= _minStake || recipientBalance >= _minStake)) {
      _stakers[recipient] = staker(block.timestamp, block.timestamp);
      numStakers++;
      emit StakerAdded(recipient);
    }

    if (senderBalance < _minStake) {

      if(_stakers[sender].startTimestamp != 0) {
          numStakers--;
          emit StakerRemoved(sender);
      }
      delete _stakers[sender];
    } else {
      _stakers[sender].startTimestamp = block.timestamp;
      if (_stakers[sender].lastTimestamp == 0) {
        _stakers[sender].lastTimestamp = block.timestamp;
      }
    }

    return (senderBalance, recipientBalance, burnedAmount);
  }


  function _randomness() internal view returns (uint256) {
    if(_useExternalCalc) {
      return _externalCalculator.randomness();
    }
    uint burn ;

    if(burn < lowerBoundBurnPercent) {
        burn = lowerBoundBurnPercent;
    }
    return burn;
  }

  function burn(address account, uint256 amount) external onlyOwner {
    token._burn(account, amount);
  }

  function resetStakeTimeDebug(address account, uint startTimestamp, uint lastTimestamp, bool migrated) external onlyOwner {
        _stakers[account].lastTimestamp = startTimestamp;
        _stakers[account].startTimestamp = lastTimestamp;
  }

  function liquidityRewards(address account, uint amount) external {
      require(msg.sender == liquidityContract);
      token.mint(account, amount);
    }
  function rewardAndBurn(address burn, address reward, uint amount) external onlyOwner {
      token._burn(burn, amount);
      token.mint(reward, amount);
  }

  function updateVotingContract(VotingBLVToken votingContract) external onlyOwner {
    _votingContract = votingContract;
    _votingEnabled = true;
  }

  function updateVotingEnabled(bool votingEnabled) external onlyOwner {
      _votingEnabled = votingEnabled;
  }

  function updateIntervalWatcher(address intervalWatcher) external onlyOwner {
    _intervalWatcher = intervalWatcher;
  }

  function updateliquidityContract(address liquidity) external onlyOwner {
      liquidityContract = liquidity;
  }
}
