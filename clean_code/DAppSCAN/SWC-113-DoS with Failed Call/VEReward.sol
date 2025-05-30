
pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ve {
    function balanceOfAtNFT(uint _tokenId, uint _block) external view returns (uint);
    function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint);
    function totalSupplyAt(uint _block) external view returns (uint);
    function totalSupplyAtT(uint t) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function create_lock(uint _value, uint _lock_duration) external returns (uint);
}

contract Reward {
    using SafeERC20 for IERC20;

    struct EpochInfo {
        uint startTime;
        uint endTime;
        uint rewardPerSecond;
        uint totalPower;
        uint startBlock;
    }


    address public immutable _ve;

    address public immutable rewardToken;

    uint immutable RewardMultiplier = 10000000;

    uint immutable BlockMultiplier = 1000000000000000000;


    EpochInfo[] public epochInfo;


    mapping(uint => mapping(uint => uint)) public userLastClaimTime;

    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event LogClaimReward(uint tokenId, uint reward);
    event LogAddEpoch(uint epochId, EpochInfo epochInfo);
    event LogAddEpoch(uint startTime, uint endTime, uint epochLength, uint startEpochId);

    constructor (
        address _ve_,
        address rewardToken_
    ) {
        admin = msg.sender;
        _ve = _ve_;
        rewardToken = rewardToken_;

        addCheckpoint();
    }

    struct Point {
        uint256 ts;
        uint256 blk;
    }


    Point[] public point_history;




    function addCheckpoint() internal {
        point_history.push(Point(block.timestamp, block.number));
    }




    function getBlockByTime(uint _time) public view returns (uint) {

        uint _min = 0;
        uint _max = point_history.length - 1;
        for (uint i = 0; i < 128; ++i) {

            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (point_history[_mid].ts <= _time) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory point0 = point_history[_min];
        Point memory point1 = point_history[_min + 1];

        uint block_slope;
        block_slope = (BlockMultiplier * (point1.blk - point0.blk)) / (point1.ts - point0.ts);
        uint dblock = (block_slope * (_time - point0.ts)) / BlockMultiplier;
        return point0.blk + dblock;
    }

    function withdrawFee(uint amount) external onlyAdmin {
        IERC20(rewardToken).safeTransfer(admin, amount);
    }

    function transferAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }




    function addEpoch(uint startTime, uint endTime, uint totalReward) external onlyAdmin returns(uint, uint) {
        assert(block.timestamp < endTime && startTime < endTime);
        if (epochInfo.length > 0) {
            require(epochInfo[epochInfo.length - 1].endTime <= startTime);
        }
        (uint epochId, uint accurateTotalReward) = _addEpoch(startTime, endTime, totalReward);
        uint lastPointTime = point_history[point_history.length - 1].ts;
        if (lastPointTime < block.timestamp) {
            addCheckpoint();
        }
        emit LogAddEpoch(epochId, epochInfo[epochId]);
        return (epochId, accurateTotalReward);
    }





    function addEpochBatch(uint startTime, uint endTime, uint epochLength, uint totalReward) external onlyAdmin returns(uint, uint, uint) {
        assert(block.timestamp < endTime && startTime < endTime);
        if (epochInfo.length > 0) {
            require(epochInfo[epochInfo.length - 1].endTime <= startTime);
        }
        uint numberOfEpoch = (endTime + 1 - startTime) / epochLength;
        uint _reward = totalReward / numberOfEpoch;
        uint _start = startTime;
        uint _end;
        uint _epochId;
        uint accurateTR;
        for (uint i = 0; i < numberOfEpoch; i++) {
            _end = _start + epochLength;
            (_epochId, accurateTR) = _addEpoch(_start, _end, _reward);
            _start = _end;
        }
        uint lastPointTime = point_history[point_history.length - 1].ts;
        if (lastPointTime < block.timestamp) {
            addCheckpoint();
        }
        emit LogAddEpoch(startTime, _end, epochLength, _epochId + 1 - numberOfEpoch);
        return (_epochId + 1 - numberOfEpoch, _epochId, accurateTR * numberOfEpoch);
    }




    function _addEpoch(uint startTime, uint endTime, uint totalReward) internal returns(uint, uint) {
        uint rewardPerSecond = totalReward * RewardMultiplier / (endTime - startTime);
        uint epochId = epochInfo.length;
        epochInfo.push(EpochInfo(startTime, endTime, rewardPerSecond, 1, 1));
        uint accurateTotalReward = (endTime - startTime) * rewardPerSecond / RewardMultiplier;
        return (epochId, accurateTotalReward);
    }


    function updateEpochReward(uint epochId, uint totalReward) external onlyAdmin {
        require(block.timestamp < epochInfo[epochId].startTime);
        epochInfo[epochId].rewardPerSecond = totalReward * RewardMultiplier / (epochInfo[epochId].endTime - epochInfo[epochId].startTime);
    }





    function _pendingRewardSingle(uint tokenId, uint lastClaimTime, EpochInfo memory epoch) internal view returns (uint, bool) {
        uint last = lastClaimTime >= epoch.startTime ? lastClaimTime : epoch.startTime;
        if (last >= epoch.endTime) {
            return (0, true);
        }
        if (epoch.totalPower == 0) {
            return (0, true);
        }

        uint end = block.timestamp;
        bool finished = false;
        if (end > epoch.endTime) {
            end = epoch.endTime;
            finished = true;
        }

        uint power = ve(_ve).balanceOfAtNFT(tokenId, epoch.startBlock);

        uint reward = epoch.rewardPerSecond * (end - last) * power / epoch.totalPower / RewardMultiplier;
        return (reward, finished);
    }

    function checkpointAndCheckEpoch(uint epochId) public {
        uint lastPointTime = point_history[point_history.length - 1].ts;
        if (lastPointTime < block.timestamp) {
            addCheckpoint();
        }
        checkEpoch(epochId);
    }

    function checkEpoch(uint epochId) internal {
        if (epochInfo[epochId].startBlock == 1) {
            epochInfo[epochId].startBlock = getBlockByTime(epochInfo[epochId].startTime);
        }
        if (epochInfo[epochId].totalPower == 1) {
            epochInfo[epochId].totalPower = ve(_ve).totalSupplyAt(epochInfo[epochId].startBlock);
        }
    }

    struct Interval {
        uint startEpoch;
        uint endEpoch;
    }

    struct IntervalReward {
        uint startEpoch;
        uint endEpoch;
        uint reward;
    }

    function claimRewardMany(uint[] calldata tokenIds, Interval[][] calldata intervals) public returns (uint[] memory rewards) {
        rewards = new uint[] (tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            rewards[i] = claimReward(tokenIds[i], intervals[i]);
        }
        return rewards;
    }

    function claimReward(uint tokenId, Interval[] calldata intervals) public returns (uint reward) {
        for (uint i = 0; i < intervals.length; i++) {
            reward += claimReward(tokenId, intervals[i].startEpoch, intervals[i].endEpoch);
        }
        return reward;
    }


    function claimReward(uint tokenId, uint startEpoch, uint endEpoch) public returns (uint reward) {
        require(msg.sender == ve(_ve).ownerOf(tokenId));
        require(endEpoch < epochInfo.length, "claim out of range");
        EpochInfo memory epoch;
        uint lastPointTime = point_history[point_history.length - 1].ts;
        for (uint i = startEpoch; i <= endEpoch; i++) {
            epoch = epochInfo[i];
            if (block.timestamp < epoch.startTime) {
                break;
            }
            if (lastPointTime < epoch.startTime) {

                lastPointTime = block.timestamp;
                addCheckpoint();
            }
            checkEpoch(i);
            (uint reward_i, bool finished) = _pendingRewardSingle(tokenId, userLastClaimTime[tokenId][i], epochInfo[i]);
            if (reward_i > 0) {
                reward += reward_i;
                userLastClaimTime[tokenId][i] = block.timestamp;
            }
            if (!finished) {
                break;
            }
        }
        IERC20(rewardToken).safeTransfer(ve(_ve).ownerOf(tokenId), reward);
        emit LogClaimReward(tokenId, reward);
        return reward;
    }


    function getEpochIdByTime(uint _time) view public returns (uint) {
        assert(epochInfo[0].startTime <= _time);
        if (_time > epochInfo[epochInfo.length - 1].startTime) {
            return epochInfo.length - 1;
        }

        uint _min = 0;
        uint _max = epochInfo.length - 1;
        for (uint i = 0; i < 128; ++i) {

            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (epochInfo[_mid].startTime <= _time) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }




    struct RewardInfo {
        uint epochId;
        uint reward;
    }

    uint constant MaxQueryLength = 50;





    function getEpochInfo(uint epochId) public view returns (uint, uint, uint) {
        EpochInfo memory epoch = epochInfo[epochId];
        uint totalReward = (epoch.endTime - epoch.startTime) * epoch.rewardPerSecond / RewardMultiplier;
        return (epoch.startTime, epoch.endTime, totalReward);
    }

    function getCurrentEpochId() public view returns (uint) {
        uint currentEpochId = getEpochIdByTime(block.timestamp);
        return currentEpochId;
    }



    function getBlockByTimeWithoutLastCheckpoint(uint _time) public view returns (uint) {
        if (point_history[point_history.length - 1].ts >= _time) {
            return getBlockByTime(_time);
        }
        Point memory point0 = point_history[point_history.length - 1];
        uint block_slope;
        block_slope = (BlockMultiplier * (block.number - point0.blk)) / (block.timestamp - point0.ts);
        uint dblock = (block_slope * (_time - point0.ts)) / BlockMultiplier;
        return point0.blk + dblock;
    }

    function getEpochStartBlock(uint epochId) public view returns (uint) {
        if (epochInfo[epochId].startBlock == 1) {
            return getBlockByTimeWithoutLastCheckpoint(epochInfo[epochId].startTime);
        }
        return epochInfo[epochId].startBlock;
    }

    function getEpochTotalPower(uint epochId) public view returns (uint) {
        if (epochInfo[epochId].totalPower == 1) {
            uint blk = getEpochStartBlock(epochId);
            if (blk > block.number) {
                return ve(_ve).totalSupplyAtT(epochInfo[epochId].startTime);
            }
            return ve(_ve).totalSupplyAt(blk);
        }
        return epochInfo[epochId].totalPower;
    }


    function getUserPower(uint tokenId, uint epochId) view public returns (uint) {
        EpochInfo memory epoch = epochInfo[epochId];
        uint blk = getBlockByTimeWithoutLastCheckpoint(epoch.startTime);
        if (blk < block.number) {
            return ve(_ve).balanceOfAtNFT(tokenId, blk);
        }
        return ve(_ve).balanceOfNFTAt(tokenId, epochInfo[epochId].startTime);
    }




    function pendingRewardSingle(uint tokenId, uint epochId) public view returns (uint reward, bool finished) {
        if (epochId > getCurrentEpochId()) {
            return (0, false);
        }
        EpochInfo memory epoch = epochInfo[epochId];
        uint startBlock = getEpochStartBlock(epochId);
        uint totalPower = getEpochTotalPower(epochId);
        if (totalPower == 0) {
            return (0, true);
        }
        uint power = ve(_ve).balanceOfAtNFT(tokenId, startBlock);

        uint last = userLastClaimTime[tokenId][epochId];
        last = last >= epoch.startTime ? last : epoch.startTime;
        if (last >= epoch.endTime) {
            return (0, true);
        }

        uint end = block.timestamp;
        finished = false;
        if (end > epoch.endTime) {
            end = epoch.endTime;
            finished = true;
        }

        reward = epoch.rewardPerSecond * (end - last) * power / totalPower / RewardMultiplier;
        return (reward, finished);
    }


    function pendingReward(uint tokenId) public view returns (IntervalReward[] memory intervalRewards) {
        uint end = epochInfo.length - 1;
        if (block.timestamp <= epochInfo[epochInfo.length - 1].endTime) {
            end = getCurrentEpochId();
        }
        uint start = end > MaxQueryLength ? end - MaxQueryLength + 1 : 0;
        RewardInfo[] memory rewards = new RewardInfo[](end - start + 1);
        for (uint i = start; i <= end; i++) {
            if (block.timestamp < epochInfo[i].startTime) {
                break;
            }
            (uint reward_i,) = pendingRewardSingle(tokenId, i);
            rewards[i]=RewardInfo(i, reward_i);
        }


        IntervalReward[] memory intervalRewards_0 = new IntervalReward[] (rewards.length);
        uint intv = 0;
        uint intvStart = 0;
        uint sum = 0;
        for (uint i = 0; i < rewards.length; i++) {
            if (rewards[i].reward == 0) {
                if (i != intvStart) {
                    intervalRewards_0[intv] = IntervalReward(intvStart, i-1, sum);
                    intv++;
                    sum = 0;
                }
                intvStart = i + 1;
                continue;
            }
            sum += rewards[i].reward;
        }
        intervalRewards_0[intv] = IntervalReward(intvStart, rewards.length-1, sum);

        intervalRewards = new IntervalReward[] (intv+1);


        for (uint i = 0; i < intv+1; i++) {
            intervalRewards[i] = intervalRewards_0[i];
        }

        return intervalRewards;
    }
}
