

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./MeowToken.sol";
import "./DevelopmentFund.sol";


contract MeowMining is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    address fundedBy;
    uint256 lockedAmount;
    uint256 lastUnlockTime;
    uint256 lockTo;











  }


  struct PoolInfo {
    address stakeToken;
    uint256 allocPoint;
    uint256 lastRewardTime;
    uint256 accMeowPerShare;
  }

  uint256 private constant ACC_MEOW_PRECISION = 1e12;


  MeowToken public meow;

  address public devaddr;

  uint256 public meowPerSecond;


  PoolInfo[] public poolInfo;

  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  mapping(address => bool) public isPoolExist;

  uint256 public totalAllocPoint;

  uint256 public startTime;

  uint256 public lockPeriod = 90 days;

  uint256 public totalLock;

  uint256 public preShare;

  uint256 public lockShare;

  DevelopmentFund public developmentFund;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event Lock(address indexed user, uint256 indexed pid, uint256 amount);
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  event Unlock(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  constructor(
    MeowToken _meow,
    uint256 _meowPerSecond,
    uint256 _startTime,
    uint256 _preShare,
    uint256 _lockShare,
    address _devaddr,
    DevelopmentFund _developmentFund
  ) public {
    totalAllocPoint = 0;
    meow = _meow;
    meowPerSecond = _meowPerSecond;
    startTime = block.timestamp > _startTime ? block.timestamp : _startTime;
    preShare = _preShare;
    lockShare = _lockShare;
    devaddr = _devaddr;
    developmentFund = _developmentFund;
    meow.approve(address(_developmentFund), uint256(-1));
  }


  function setDev(address _devaddr) public {
    require(msg.sender == devaddr, "MeowMining::setDev:: Forbidden.");
    devaddr = _devaddr;
  }

  function setMeowPerSecond(uint256 _meowPerSecond) external onlyOwner {
    massUpdatePools();
    meowPerSecond = _meowPerSecond;
  }


  function addPool(uint256 _allocPoint, address _stakeToken) external onlyOwner {
    massUpdatePools();
    require(_stakeToken != address(0), "MeowMining::addPool:: not ZERO address.");
    require(!isPoolExist[_stakeToken], "MeowMining::addPool:: stakeToken duplicate.");
    uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({ stakeToken: _stakeToken, allocPoint: _allocPoint, lastRewardTime: lastRewardTime, accMeowPerShare: 0 })
    );
    isPoolExist[_stakeToken] = true;
  }


  function setPool(uint256 _pid, uint256 _allocPoint) external onlyOwner {
    massUpdatePools();
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  function canManualMint() public view returns (uint256) {
    return meow.canManualMint();
  }

  function manualMint(address _to, uint256 _amount) external onlyOwner {
    require(_amount <= (canManualMint()), "MeowMining::manualMint:: manual mint limit exceeded.");
    meow.manualMint(_to, _amount);
  }


  function pendingMeow(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accMeowPerShare = pool.accMeowPerShare;
    uint256 stakeTokenSupply = IERC20(pool.stakeToken).balanceOf(address(this));
    if (block.timestamp > pool.lastRewardTime && stakeTokenSupply > 0 && totalAllocPoint > 0) {
      uint256 time = block.timestamp.sub(pool.lastRewardTime);
      uint256 meowReward = time.mul(meowPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
      accMeowPerShare = accMeowPerShare.add(meowReward.mul(ACC_MEOW_PRECISION).div(stakeTokenSupply));
    }
    return user.amount.mul(accMeowPerShare).div(ACC_MEOW_PRECISION).sub(user.rewardDebt);
  }


  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }


  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.timestamp > pool.lastRewardTime) {
      uint256 stakeTokenSupply = IERC20(pool.stakeToken).balanceOf(address(this));
      if (stakeTokenSupply > 0 && totalAllocPoint > 0) {
        uint256 time = block.timestamp.sub(pool.lastRewardTime);
        uint256 meowReward = time.mul(meowPerSecond).mul(pool.allocPoint).div(totalAllocPoint);

        uint256 devfund = meowReward.mul(10000).div(114286);
        meow.mint(address(this), devfund);
        meow.mint(address(this), meowReward);
        safeMeowTransfer(devaddr, devfund.mul(preShare).div(10000));
        developmentFund.lock(devfund.mul(lockShare).div(10000));
        pool.accMeowPerShare = pool.accMeowPerShare.add(meowReward.mul(ACC_MEOW_PRECISION).div(stakeTokenSupply));
      }
      pool.lastRewardTime = block.timestamp;
    }
  }


  function deposit(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_for];
    if (user.fundedBy != address(0)) require(user.fundedBy == msg.sender, "MeowMining::deposit:: bad sof.");
    require(pool.stakeToken != address(0), "MeowMining::deposit:: not accept deposit.");
    updatePool(_pid);
    if (user.amount > 0) _harvest(_for, _pid);
    if (user.fundedBy == address(0)) user.fundedBy = msg.sender;
    IERC20(pool.stakeToken).safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accMeowPerShare).div(ACC_MEOW_PRECISION);
    emit Deposit(msg.sender, _pid, _amount);
  }


  function withdraw(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external nonReentrant {
    _withdraw(_for, _pid, _amount);
  }

  function withdrawAll(address _for, uint256 _pid) external nonReentrant {
    _withdraw(_for, _pid, userInfo[_pid][_for].amount);
  }

  function _withdraw(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_for];
    require(user.fundedBy == msg.sender, "MeowMining::withdraw:: only funder.");
    require(user.amount >= _amount, "MeowMining::withdraw:: not good.");
    updatePool(_pid);
    _harvest(_for, _pid);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accMeowPerShare).div(ACC_MEOW_PRECISION);
    if (user.amount == 0) user.fundedBy = address(0);
    if (pool.stakeToken != address(0)) {
      IERC20(pool.stakeToken).safeTransfer(address(msg.sender), _amount);
    }
    emit Withdraw(msg.sender, _pid, user.amount);
  }


  function harvest(uint256 _pid) external nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    _harvest(msg.sender, _pid);
    user.rewardDebt = user.amount.mul(pool.accMeowPerShare).div(ACC_MEOW_PRECISION);
  }

  function _harvest(address _to, uint256 _pid) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_to];
    require(user.amount > 0, "MeowMining::harvest:: nothing to harvest.");
    uint256 pending = user.amount.mul(pool.accMeowPerShare).div(ACC_MEOW_PRECISION).sub(user.rewardDebt);
    uint256 preAmount = pending.mul(preShare).div(10000);
    uint256 lockAmount = pending.mul(lockShare).div(10000);
    lock(_pid, _to, lockAmount);
    require(preAmount <= meow.balanceOf(address(this)), "MeowMining::harvest:: not enough Meow.");
    safeMeowTransfer(_to, preAmount);
    emit Harvest(msg.sender, _pid, preAmount);
  }


  function lock(
    uint256 _pid,
    address _holder,
    uint256 _amount
  ) internal {
    unlock(_pid, _holder);
    if (_amount > 0) {
      UserInfo storage user = userInfo[_pid][_holder];
      user.lockedAmount = user.lockedAmount.add(_amount);
      user.lockTo = block.timestamp.add(lockPeriod);
      totalLock = totalLock.add(_amount);
      emit Lock(_holder, _pid, _amount);
    }
  }


  function availableUnlock(uint256 _pid, address _holder) public view returns (uint256) {
    UserInfo storage user = userInfo[_pid][_holder];
    if (block.timestamp >= user.lockTo) {
      return user.lockedAmount;
    } else {
      uint256 releaseTime = block.timestamp.sub(user.lastUnlockTime);
      uint256 lockTime = user.lockTo.sub(user.lastUnlockTime);
      return user.lockedAmount.mul(releaseTime).div(lockTime);
    }
  }


  function unlock(uint256 _pid) public {
    unlock(_pid, msg.sender);
  }

  function unlock(uint256 _pid, address _holder) internal {
    UserInfo storage user = userInfo[_pid][_holder];
    user.lastUnlockTime = block.timestamp;
    uint256 amount = availableUnlock(_pid, _holder);
    if (amount > 0) {
      if (amount > meow.balanceOf(address(this))) {
        amount = meow.balanceOf(address(this));
      }
      user.lockedAmount = user.lockedAmount.sub(amount);
      totalLock = totalLock.sub(amount);
      safeMeowTransfer(_holder, amount);
      emit Unlock(_holder, _pid, amount);
    }
  }


  function emergencyWithdraw(uint256 _pid) external nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.fundedBy == msg.sender, "MeowMining::emergencyWithdraw:: only funder.");
    IERC20(pool.stakeToken).safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
    user.fundedBy = address(0);
  }


  function safeMeowTransfer(address _to, uint256 _amount) internal {
    uint256 meowBal = meow.balanceOf(address(this));
    if (_amount > meowBal) {
      require(meow.transfer(_to, meowBal), "MeowMining::safeMeowTransfer:: failed to transfer MEOW.");
    } else {
      require(meow.transfer(_to, _amount), "MeowMining::safeMeowTransfer:: failed to transfer MEOW.");
    }
  }
}
