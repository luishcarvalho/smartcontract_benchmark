
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}

contract MasterBlid is Ownable {
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;











    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accBlidPerShare;
    }


    IERC20 public blid;

    address public expenseAddress;

    uint256 public blidPerBlock;

    uint256 public BONUS_MULTIPLIER = 1;

    IMigratorChef public migrator;


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _blid,
        address _expenseAddress,
        uint256 _blidPerBlock,
        uint256 _startBlock
    ) public {
        blid = IERC20(_blid);
        expenseAddress = _expenseAddress;
        blidPerBlock = _blidPerBlock;
        startBlock = _startBlock;


        poolInfo.push(PoolInfo({
            lpToken: IERC20(_blid),
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accBlidPerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }



    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBlidPerShare: 0
        }));
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint - prevAllocPoint + _allocPoint;
        }
    }


    function setBlidPerBlock(uint256 _blidPerBlock) public onlyOwner {
        blidPerBlock = _blidPerBlock;
    }


    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }


    function setExpenseAddress(address _expenseAddress) public onlyOwner {
        expenseAddress = _expenseAddress;
    }


    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }


    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return (_to - _from) * BONUS_MULTIPLIER;
    }


    function pendingBlid(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBlidPerShare = pool.accBlidPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 blidReward = multiplier * blidPerBlock * pool.allocPoint / totalAllocPoint;
            accBlidPerShare = accBlidPerShare + (blidReward * 1e12 / lpSupply);
        }
        return (user.amount * accBlidPerShare / 1e12) - user.rewardDebt;
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 blidReward = multiplier * blidPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accBlidPerShare = pool.accBlidPerShare + (blidReward * 1e12 / lpSupply);
        pool.lastRewardBlock = block.number;
    }


    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit BLID by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accBlidPerShare / 1e12) - user.rewardDebt;
            if(pending > 0) {
                safeBlidTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = user.amount * pool.accBlidPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }


    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw BLID by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
            uint256 pending = (user.amount * pool.accBlidPerShare / 1e12) - user.rewardDebt;
        if(pending > 0) {
            safeBlidTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount * pool.accBlidPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }


    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accBlidPerShare / 1e12) - user.rewardDebt;
            if(pending > 0) {
                safeBlidTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = user.amount * pool.accBlidPerShare / 1e12;
        emit Deposit(msg.sender, 0, _amount);
    }


    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = (user.amount * pool.accBlidPerShare / 1e12) - user.rewardDebt;
        if(pending > 0) {
            safeBlidTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount * pool.accBlidPerShare / 1e12;

        emit Withdraw(msg.sender, 0, _amount);
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    function safeBlidTransfer(address _to, uint256 _amount) internal {
        blid.safeTransferFrom(expenseAddress, _to, _amount);
    }
}
