

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Ownable {
    using SafeMath for uint256;




    struct UserInfo {
        uint256 totalAmount;
        uint256 rewardDebt;
        uint256 lastClaimTime;
        uint256 stakeRecords;
    }


    struct UserStakeInfo {
        uint256 amount;
        uint256 stakedTime;
        uint256 unstakedTime;
        uint256 unlockTime;
    }


    mapping (address => UserInfo) public userInfo;

    mapping (uint256 => mapping (address => UserStakeInfo)) public userStakeInfo;

    IERC20 public tngToken;
    IERC20 public lpToken;
    uint256 public accTngPerShare;
    uint256 public lastRewardTime = block.timestamp;
    uint256 public lockTime;
    uint256 public tngPerSecond = 1 * 10**18;
    uint256 public lpTokenDeposited;
    uint256 public pendingTngRewards;

    uint256 private constant ACC_TNG_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 sid, uint256 amount);
    event Harvest(address indexed user, uint256 amount);
    event LogTngPerSecond(uint256 tngPerSecond);

    constructor(IERC20 _tngToken, IERC20 _lpToken, uint256 _lockTime) {
        tngToken = _tngToken;
        lpToken = _lpToken;
        lockTime = _lockTime;
    }

    function deposit(uint256 amount) external {

        updatePool();

        UserInfo storage user = userInfo[msg.sender];
        UserStakeInfo storage stakeInfo = userStakeInfo[user.stakeRecords][msg.sender];
        require(tngToken.balanceOf(msg.sender) >= amount, "Insufficient tokens");


        user.totalAmount = user.totalAmount.add(amount);
        user.rewardDebt = user.rewardDebt.add(amount.mul(accTngPerShare) / ACC_TNG_PRECISION);
        user.stakeRecords = user.stakeRecords.add(1);


        stakeInfo.amount = amount;
        stakeInfo.stakedTime = block.timestamp;
        stakeInfo.unlockTime = block.timestamp + lockTime;


        lpTokenDeposited = lpTokenDeposited.add(amount);



        lpToken.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

    function harvest() external {

        updatePool();

        UserInfo storage user = userInfo[msg.sender];
        uint256 accumulatedTng = user.totalAmount.mul(accTngPerShare) / ACC_TNG_PRECISION;
        uint256 _pendingTng = accumulatedTng.sub(user.rewardDebt);
        require(_pendingTng > 0, "No pending rewards");
        require(lpToken.balanceOf(address(this)) >= _pendingTng, "Insufficient tokens in contract");


        user.rewardDebt = accumulatedTng;
        user.lastClaimTime = block.timestamp;


        payTngReward(_pendingTng, msg.sender);

        emit Harvest(msg.sender, _pendingTng);
    }



    function withdraw(uint256 sid) external {

        updatePool();

        UserInfo storage user = userInfo[msg.sender];
        UserStakeInfo storage stakeInfo = userStakeInfo[sid][msg.sender];

        uint256 _amount = stakeInfo.amount;
        require(_amount > 0, "No stakes found");
        require(block.timestamp >= stakeInfo.unlockTime, "Lock period not ended");
        require(lpToken.balanceOf(address(this)) >= _amount, "Insufficient tokens in contract, please contact admin");

        uint256 accumulatedTng = user.totalAmount.mul(accTngPerShare) / ACC_TNG_PRECISION;
        uint256 _pendingTng = accumulatedTng.sub(user.rewardDebt);


        user.rewardDebt = accumulatedTng.sub(_amount.mul(accTngPerShare) / ACC_TNG_PRECISION);
        user.totalAmount = user.totalAmount.sub(_amount);


        stakeInfo.amount = 0;
        stakeInfo.unstakedTime = block.timestamp;


        lpTokenDeposited = lpTokenDeposited.sub(_amount);



        lpToken.transfer(msg.sender, _amount);


        if (_pendingTng != 0) {
            user.lastClaimTime = block.timestamp;
            payTngReward(_pendingTng, msg.sender);
        }

        emit Withdraw(msg.sender, sid, _amount);
    }

    function pendingTng(address _user) external view returns (uint256 pending) {
        UserInfo storage user = userInfo[_user];
        uint256 _accTngPerShare = accTngPerShare;

        if (block.timestamp > lastRewardTime && lpTokenDeposited != 0) {
            uint256 time = block.timestamp.sub(lastRewardTime);
            uint256 tngReward = getTngRewardForTime(time);

            _accTngPerShare = accTngPerShare.add(tngReward.mul(ACC_TNG_PRECISION) / lpTokenDeposited);
        }
        pending = (user.totalAmount.mul(_accTngPerShare) / ACC_TNG_PRECISION).sub(user.rewardDebt);
    }

    function updatePool() public {

        if (block.timestamp > lastRewardTime) {

            if (lpTokenDeposited > 0) {
                uint256 time = block.timestamp.sub(lastRewardTime);
                uint256 tngReward = getTngRewardForTime(time);

                trackPendingTngReward(tngReward);
                accTngPerShare = accTngPerShare.add(tngReward.mul(ACC_TNG_PRECISION) / lpTokenDeposited);
            }

            lastRewardTime = block.timestamp;
        }
    }

    function payTngReward(uint256 _pendingTng, address _to) internal {

        tngToken.transfer(_to, _pendingTng);
        pendingTngRewards = pendingTngRewards.sub(_pendingTng);
    }

    function getTngRewardForTime(uint256 _time) public view returns (uint256) {
        uint256 tngReward = _time.mul(tngPerSecond);

        return tngReward;
    }

    function trackPendingTngReward(uint256 amount) internal {
        pendingTngRewards = pendingTngRewards.add(amount);
    }


    function setTngToken(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Zero address");
        tngToken = IERC20(newAddress);
    }

    function setLockTime(uint256 epoch) external onlyOwner {
        lockTime = epoch;
    }

    function setTngPerSecond(uint256 _tngPerSecond) external onlyOwner {
        tngPerSecond = _tngPerSecond;
        emit LogTngPerSecond(_tngPerSecond);
    }

    function rescueToken(address _token, address _to) external onlyOwner {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));

        IERC20(_token).transfer(_to, _contractBalance);
    }

	function clearStuckBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    receive() external payable {}
}
