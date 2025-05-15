












pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "./interfaces/IxALPACA.sol";
import "./interfaces/IBEP20.sol";

import "./SafeToken.sol";




contract GrassHouse is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeToken for address;


  event LogSetCanCheckpointToken(bool _toggleFlag);
  event LogFeed(uint256 _amount);
  event LogCheckpointToken(uint256 _timestamp, uint256 _tokens);
  event LogClaimed(address indexed _recipient, uint256 _amount, uint256 _claimEpoch, uint256 _maxEpoch);
  event LogKilled();


  uint256 public constant WEEK = 1 weeks;
  uint256 public constant TOKEN_CHECKPOINT_DEADLINE = 1 days;

  uint256 public startWeekCursor;
  uint256 public weekCursor;
  mapping(address => uint256) public weekCursorOf;
  mapping(address => uint256) public userEpochOf;

  uint256 public lastTokenTimestamp;
  mapping(uint256 => uint256) public tokensPerWeek;

  address public xALPACA;
  address public rewardToken;
  uint256 public lastTokenBalance;


  mapping(uint256 => uint256) public totalSupplyAt;

  bool public canCheckpointToken;


  bool public isKilled;
  address public emergencyReturn;






  function initialize(
    address _xALPACA,
    uint256 _startTime,
    address _rewardToken,
    address _emergencyReturn
  ) public initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    uint256 _startTimeFloorWeek = _timestampToFloorWeek(_startTime);
    startWeekCursor = _startTimeFloorWeek;
    lastTokenTimestamp = _startTimeFloorWeek;
    weekCursor = _startTimeFloorWeek;
    rewardToken = _rewardToken;
    xALPACA = _xALPACA;
    emergencyReturn = _emergencyReturn;
  }

  modifier onlyLive() {
    require(!isKilled, "killed");
    _;
  }




  function balanceOfAt(address _user, uint256 _timestamp) external view returns (uint256) {
    uint256 _maxUserEpoch = IxALPACA(xALPACA).userPointEpoch(_user);
    if (_maxUserEpoch == 0) {
      return 0;
    }

    uint256 _epoch = _findTimestampUserEpoch(_user, _timestamp, _maxUserEpoch);
    Point memory _point = IxALPACA(xALPACA).userPointHistory(_user, _epoch);
    int128 _bias = _point.bias - _point.slope * SafeCastUpgradeable.toInt128(int256(_timestamp - _point.timestamp));
    if (_bias < 0) {
      return 0;
    }
    return SafeCastUpgradeable.toUint256(_bias);
  }


  function _checkpointToken() internal {

    uint256 _rewardTokenBalance = rewardToken.myBalance();
    uint256 _toDistribute = _rewardTokenBalance - lastTokenBalance;
    lastTokenBalance = _rewardTokenBalance;






    uint256 _timeCursor = lastTokenTimestamp;
    uint256 _deltaSinceLastTimestamp = block.timestamp - _timeCursor;
    uint256 _thisWeekCursor = _timestampToFloorWeek(_timeCursor);
    uint256 _nextWeekCursor = 0;
    lastTokenTimestamp = block.timestamp;


    for (uint256 _i = 0; _i < 20; _i++) {
      _nextWeekCursor = _thisWeekCursor + WEEK;




      if (block.timestamp < _nextWeekCursor) {
        if (_deltaSinceLastTimestamp == 0 && block.timestamp == _timeCursor) {
          tokensPerWeek[_thisWeekCursor] = tokensPerWeek[_thisWeekCursor] + _toDistribute;
        } else {
          tokensPerWeek[_thisWeekCursor] =
            tokensPerWeek[_thisWeekCursor] +
            ((_toDistribute * (block.timestamp - _timeCursor)) / _deltaSinceLastTimestamp);
        }
        break;
      } else {
        if (_deltaSinceLastTimestamp == 0 && _nextWeekCursor == _timeCursor) {
          tokensPerWeek[_thisWeekCursor] = tokensPerWeek[_thisWeekCursor] + _toDistribute;
        } else {
          tokensPerWeek[_thisWeekCursor] =
            tokensPerWeek[_thisWeekCursor] +
            ((_toDistribute * (_nextWeekCursor - _timeCursor)) / _deltaSinceLastTimestamp);
        }
      }
      _timeCursor = _nextWeekCursor;
      _thisWeekCursor = _nextWeekCursor;
    }

    emit LogCheckpointToken(block.timestamp, _toDistribute);
  }





  function checkpointToken() external nonReentrant {
    require(
      msg.sender == owner() ||
        (canCheckpointToken && (block.timestamp > lastTokenTimestamp + TOKEN_CHECKPOINT_DEADLINE)),
      "!allow"
    );
    _checkpointToken();
  }


  function _checkpointTotalSupply() internal {
    uint256 _weekCursor = weekCursor;
    uint256 _roundedTimestamp = _timestampToFloorWeek(block.timestamp);

    IxALPACA(xALPACA).checkpoint();

    for (uint256 i = 0; i < 20; i++) {
      if (_weekCursor > _roundedTimestamp) {
        break;
      } else {
        uint256 _epoch = _findTimestampEpoch(_weekCursor);
        Point memory _point = IxALPACA(xALPACA).pointHistory(_epoch);
        int128 _timeDelta = 0;
        if (_weekCursor > _point.timestamp) {
          _timeDelta = SafeCastUpgradeable.toInt128(int256(_weekCursor - _point.timestamp));
        }
        int128 _bias = _point.bias - _point.slope * _timeDelta;
        if (_bias < 0) {
          totalSupplyAt[_weekCursor] = 0;
        } else {
          totalSupplyAt[_weekCursor] = SafeCastUpgradeable.toUint256(_bias);
        }
      }
      _weekCursor = _weekCursor + WEEK;
    }

    weekCursor = _weekCursor;
  }




  function checkpointTotalSupply() external nonReentrant {
    _checkpointTotalSupply();
  }



  function _claim(address _user, uint256 _maxClaimTimestamp) internal returns (uint256) {
    uint256 _userEpoch = 0;
    uint256 _toDistribute = 0;

    uint256 _maxUserEpoch = IxALPACA(xALPACA).userPointEpoch(_user);
    uint256 _startWeekCursor = startWeekCursor;



    if (_maxUserEpoch == 0) {
      return 0;
    }

    uint256 _userWeekCursor = weekCursorOf[_user];
    if (_userWeekCursor == 0) {


      _userEpoch = _findTimestampUserEpoch(_user, _startWeekCursor, _maxUserEpoch);
    } else {

      _userEpoch = userEpochOf[_user];
    }

    if (_userEpoch == 0) {
      _userEpoch = 1;
    }

    Point memory _userPoint = IxALPACA(xALPACA).userPointHistory(_user, _userEpoch);

    if (_userWeekCursor == 0) {
      _userWeekCursor = ((_userPoint.timestamp + WEEK - 1) / WEEK) * WEEK;
    }






    if (_userWeekCursor >= _maxClaimTimestamp) {
      return 0;
    }



    if (_userWeekCursor < _startWeekCursor) {
      _userWeekCursor = _startWeekCursor;
    }

    Point memory _prevUserPoint = Point({ bias: 0, slope: 0, timestamp: 0, blockNumber: 0 });


    for (uint256 i = 0; i < 50; i++) {


      if (_userWeekCursor >= _maxClaimTimestamp) {
        break;
      }


      if (_userWeekCursor >= _userPoint.timestamp && _userEpoch <= _maxUserEpoch) {
        _userEpoch = _userEpoch + 1;
        _prevUserPoint = Point({
          bias: _userPoint.bias,
          slope: _userPoint.slope,
          timestamp: _userPoint.timestamp,
          blockNumber: _userPoint.blockNumber
        });


        if (_userEpoch > _maxUserEpoch) {
          _userPoint = Point({ bias: 0, slope: 0, timestamp: 0, blockNumber: 0 });
        } else {
          _userPoint = IxALPACA(xALPACA).userPointHistory(_user, _userEpoch);
        }
      } else {
        int128 _timeDelta = SafeCastUpgradeable.toInt128(int256(_userWeekCursor - _prevUserPoint.timestamp));
        uint256 _balanceOf = MathUpgradeable.max(
          SafeCastUpgradeable.toUint256(_prevUserPoint.bias - _timeDelta * _prevUserPoint.slope),
          0
        );
        if (_balanceOf == 0 && _userEpoch > _maxUserEpoch) {
          break;
        }
        if (_balanceOf > 0) {
          _toDistribute =
            _toDistribute +
            (_balanceOf * tokensPerWeek[_userWeekCursor]) /
            totalSupplyAt[_userWeekCursor];
        }
        _userWeekCursor = _userWeekCursor + WEEK;
      }
    }

    _userEpoch = MathUpgradeable.min(_maxUserEpoch, _userEpoch - 1);
    userEpochOf[_user] = _userEpoch;
    weekCursorOf[_user] = _userWeekCursor;

    emit LogClaimed(_user, _toDistribute, _userEpoch, _maxUserEpoch);

    return _toDistribute;
  }



  function claim(address _user) external nonReentrant onlyLive returns (uint256) {
    if (block.timestamp >= weekCursor) _checkpointTotalSupply();
    uint256 _lastTokenTimestamp = lastTokenTimestamp;

    if (canCheckpointToken && (block.timestamp > _lastTokenTimestamp + TOKEN_CHECKPOINT_DEADLINE)) {
      _checkpointToken();
      _lastTokenTimestamp = block.timestamp;
    }

    _lastTokenTimestamp = _timestampToFloorWeek(_lastTokenTimestamp);

    uint256 _amount = _claim(_user, _lastTokenTimestamp);
    if (_amount != 0) {
      lastTokenBalance = lastTokenBalance - _amount;
      rewardToken.safeTransfer(_user, _amount);
    }

    return _amount;
  }



  function claimMany(address[] calldata _users) external nonReentrant onlyLive returns (bool) {
    require(_users.length <= 20, "!over 20 users");

    if (block.timestamp >= weekCursor) _checkpointTotalSupply();

    uint256 _lastTokenTimestamp = lastTokenTimestamp;

    if (canCheckpointToken && (block.timestamp > _lastTokenTimestamp + TOKEN_CHECKPOINT_DEADLINE)) {
      _checkpointToken();
      _lastTokenTimestamp = block.timestamp;
    }

    _lastTokenTimestamp = _timestampToFloorWeek(_lastTokenTimestamp);
    uint256 _total = 0;

    for (uint256 i = 0; i < _users.length; i++) {
      require(_users[i] != address(0), "bad user");

      uint256 _amount = _claim(_users[i], _lastTokenTimestamp);
      if (_amount != 0) {
        rewardToken.safeTransfer(_users[i], _amount);
        _total = _total + _amount;
      }
    }

    if (_total != 0) {
      lastTokenBalance = lastTokenBalance - _total;
    }

    return true;
  }


  function feed(uint256 _amount) external nonReentrant onlyLive returns (bool) {
    rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

    if (canCheckpointToken && (block.timestamp > lastTokenTimestamp + TOKEN_CHECKPOINT_DEADLINE)) {
      _checkpointToken();
    }

    emit LogFeed(_amount);

    return true;
  }



  function _findTimestampEpoch(uint256 _timestamp) internal view returns (uint256) {
    uint256 _min = 0;
    uint256 _max = IxALPACA(xALPACA).epoch();

    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      Point memory _point = IxALPACA(xALPACA).pointHistory(_mid);
      if (_point.timestamp <= _timestamp) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }





  function _findTimestampUserEpoch(
    address _user,
    uint256 _timestamp,
    uint256 _maxUserEpoch
  ) internal view returns (uint256) {
    uint256 _min = 0;
    uint256 _max = _maxUserEpoch;
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      Point memory _point = IxALPACA(xALPACA).userPointHistory(_user, _mid);
      if (_point.timestamp <= _timestamp) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  function kill() external onlyOwner {
    isKilled = true;
    rewardToken.safeTransfer(emergencyReturn, rewardToken.myBalance());

    emit LogKilled();
  }



  function setCanCheckpointToken(bool _newCanCheckpointToken) external onlyOwner {
    canCheckpointToken = _newCanCheckpointToken;
    emit LogSetCanCheckpointToken(_newCanCheckpointToken);
  }



  function _timestampToFloorWeek(uint256 _timestamp) internal pure returns (uint256) {
    return (_timestamp / WEEK) * WEEK;
  }
}
