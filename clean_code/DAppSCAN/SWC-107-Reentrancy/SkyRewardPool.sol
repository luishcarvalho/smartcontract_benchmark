

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";



contract SkyRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    address public operator;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }


    struct PoolInfo {
        IERC20 token;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accSkyPerShare;
        bool isStarted;
    }

    IERC20 public sky;


    PoolInfo[] public poolInfo;


    mapping(uint256 => mapping(address => UserInfo)) public userInfo;


    uint256 public totalAllocPoint = 0;


    uint256 public poolStartTime;


    uint256 public poolEndTime;

    uint256 public rewardPerSecond = 0.00221968543 ether;
    uint256 public runningTime = 365 days;
    uint256 public constant TOTAL_REWARDS = 70000 ether;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _sky,
        uint256 _poolStartTime
    ) public {
        require(block.timestamp < _poolStartTime, "late");
        if (_sky != address(0)) sky = IERC20(_sky);
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "SkyRewardPool: caller is not the operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "SkyRewardPool: existing pool?");
        }
    }


    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {

            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {

            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accSkyPerShare : 0,
            isStarted : _isStarted
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }


    function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
    }


    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(rewardPerSecond);
            return poolEndTime.sub(_fromTime).mul(rewardPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(rewardPerSecond);
            return _toTime.sub(_fromTime).mul(rewardPerSecond);
        }
    }


    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSkyPerShare = pool.accSkyPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _skyReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accSkyPerShare = accSkyPerShare.add(_skyReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accSkyPerShare).div(1e18).sub(user.rewardDebt);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _skyReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accSkyPerShare = pool.accSkyPerShare.add(_skyReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }


    function deposit(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accSkyPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeSkyTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSkyPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }



    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accSkyPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeSkyTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSkyPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    function withdrawAll(uint256 _pid) external {
        withdraw(_pid, userInfo[_pid][msg.sender].amount);
    }

    function harvestAllRewards() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (userInfo[pid][msg.sender].amount > 0) {
                withdraw(pid, 0);
            }
        }
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }


    function safeSkyTransfer(address _to, uint256 _amount) internal {
        uint256 _skyBal = sky.balanceOf(address(this));
        if (_skyBal > 0) {
            if (_amount > _skyBal) {
                sky.safeTransfer(_to, _skyBal);
            } else {
                sky.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {

            require(_token != sky, "sky");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}
