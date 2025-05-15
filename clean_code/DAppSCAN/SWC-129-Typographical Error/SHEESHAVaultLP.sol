

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SHEESHA.sol";

contract SHEESHAVaultLP is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 checkpoint;
        bool status;











    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accSheeshaPerShare;
    }


    SHEESHA public sheesha;



    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint;


    uint256 public startBlock;


    uint256 public constant sheeshaPerBlock = 1;

    uint256 public constant percentageDivider = 10000;

    uint256 public lpRewards = 20000e18;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        SHEESHA _sheesha
    ) {
        sheesha = _sheesha;
        startBlock = block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }



    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSheeshaPerShare: 0
            })
        );
    }


    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
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

        uint256 sheeshaReward = (lpRewards.mul(sheeshaPerBlock).div(percentageDivider)).mul(pool.allocPoint).div(totalAllocPoint);
        lpRewards = lpRewards.sub(sheeshaReward);
        pool.accSheeshaPerShare = pool.accSheeshaPerShare.add(sheeshaReward.mul(1e12).div(lpSupply));
    }


    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if(!isActive(_pid, msg.sender)) {
            user.checkpoint = block.timestamp;
        }
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSheeshaPerShare).div(1e12).sub(user.rewardDebt);
            safeSheeshaTransfer(msg.sender, pending);
        }


        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSheeshaPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }






    function depositFor(address _depositFor, uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_depositFor];

        updatePool(_pid);

        if(!isActive(_pid, _depositFor)) {
            user.checkpoint = block.timestamp;
        }

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSheeshaPerShare).div(1e12).sub(user.rewardDebt);
            safeSheeshaTransfer(_depositFor, pending);
        }

        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accSheeshaPerShare).div(1e12);
        emit Deposit(_depositFor, _pid, _amount);

    }


    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSheeshaPerShare).div(1e12).sub(user.rewardDebt);
        safeSheeshaTransfer(msg.sender, pending);
        if(_amount > 0) {

            uint256 feePercent = 4;

            if(user.checkpoint.add(730 days) <= block.timestamp) {

                feePercent = uint256(100).sub(getElpasedMonth(user.checkpoint).mul(4));
            }
            uint256 fees = _amount.mul(feePercent).div(100);
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(fees));
        }
        user.rewardDebt = user.amount.mul(pool.accSheeshaPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    function addRewards(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid amount");
        IERC20(sheesha).safeTransferFrom(address(msg.sender), address(this), _amount);
        lpRewards = lpRewards.add(_amount);
    }


    function safeSheeshaTransfer(address _to, uint256 _amount) internal {
        uint256 sheeshaBal = sheesha.balanceOf(address(this));
        if (_amount > sheeshaBal) {
            sheesha.transfer(_to, sheeshaBal);
        } else {
            sheesha.transfer(_to, _amount);
        }
    }


    function pendingSheesha(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSheeshaPerShare = pool.accSheeshaPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 sheeshaReward = (lpRewards.mul(sheeshaPerBlock).div(percentageDivider)).mul(pool.allocPoint).div(totalAllocPoint);
            accSheeshaPerShare = accSheeshaPerShare.add(sheeshaReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSheeshaPerShare).div(1e12).sub(user.rewardDebt);
    }

    function isActive(uint256 _pid, address _user) public view returns(bool) {
        return userInfo[_pid][_user].status;
    }

    function getElpasedMonth(uint256 checkpoint) public view returns(uint256) {
        return (block.timestamp.sub(checkpoint)).div(30 days);
    }

}
