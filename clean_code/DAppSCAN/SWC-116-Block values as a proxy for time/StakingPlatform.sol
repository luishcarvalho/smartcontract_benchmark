
pragma solidity =0.8.9;

import "./IStakingPlatform.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



contract StakingPlatform is IStakingPlatform, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    uint8 public immutable fixedAPY;

    uint public immutable stakingDuration;
    uint public immutable lockupDuration;
    uint public immutable stakingMax;

    uint public startPeriod;
    uint public lockupPeriod;
    uint public endPeriod;

    uint private totalStaked;
    uint internal precision = 1E6;

    mapping(address => uint) public staked;
    mapping(address => uint) private rewardsToClaim;
    mapping(address => uint) private userStartTime;





    constructor(
        address _token,
        uint8 _fixedAPY,
        uint _durationInDays,
        uint _lockDurationInDays,
        uint _maxAmountStaked
    ) {
        stakingDuration = _durationInDays * 1 days;
        lockupDuration = _lockDurationInDays * 1 days;
        token = IERC20(_token);
        fixedAPY = _fixedAPY;
        stakingMax = _maxAmountStaked;
    }





    function startStaking() external override onlyOwner {
        require(startPeriod == 0, "Staking has already started");
        startPeriod = block.timestamp;

        lockupPeriod = block.timestamp + lockupDuration;
        endPeriod = block.timestamp + stakingDuration;
        emit StartStaking(startPeriod, endPeriod);
    }







    function deposit(uint amount) external override {
        require(
            endPeriod == 0 || endPeriod > block.timestamp,
            "Staking period ended"
        );
        require(
            totalStaked + amount <= stakingMax,
            "Amount staked exceeds MaxStake"
        );
        require(amount >= 1E18, "Amount must be greater than 1E18");

        if (userStartTime[_msgSender()] == 0) {
            userStartTime[_msgSender()] = block.timestamp;
        }

        _updateRewards();

        staked[_msgSender()] += amount;
        totalStaked += amount;
        token.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposit(_msgSender(), amount);
    }





    function withdraw() external override {
        require(
            block.timestamp >= lockupPeriod,
            "No withdraw until lockup ends"
        );

        _updateRewards();
        if (rewardsToClaim[_msgSender()] > 0) {
            _claimRewards();
        }

        userStartTime[_msgSender()] = 0;
        totalStaked -= staked[_msgSender()];
        uint stakedBalance = staked[_msgSender()];
        staked[_msgSender()] = 0;
        token.safeTransfer(_msgSender(), stakedBalance);

        emit Withdraw(_msgSender(), stakedBalance);
    }







    function withdrawResidualBalance() external onlyOwner {
        require(
            block.timestamp >= endPeriod + (365 * 1 days),
            "Withdraw 1year after endPeriod"
        );

        uint balance = token.balanceOf(address(this));
        uint residualBalance = balance - (totalStaked);
        require(residualBalance > 0, "No residual Balance to withdraw");
        token.safeTransfer(owner(), residualBalance);
    }






    function amountStaked(address stakeHolder)
        external
        view
        override
        returns (uint)
    {
        return staked[stakeHolder];
    }






    function totalDeposited() external view override returns (uint) {
        return totalStaked;
    }







    function rewardOf(address stakeHolder)
        external
        view
        override
        returns (uint)
    {
        return _calculateRewards(stakeHolder);
    }





    function claimRewards() external override {
        _claimRewards();
    }







    function _calculateRewards(address stakeHolder)
        internal
        view
        returns (uint)
    {
        if (startPeriod == 0 || staked[stakeHolder] == 0) {
            return 0;
        }

        return
            (((staked[stakeHolder] * fixedAPY) *
                _percentageTimeRemaining(stakeHolder)) / (precision * 100)) +
            rewardsToClaim[stakeHolder];
    }






    function _percentageTimeRemaining(address stakeHolder)
        internal
        view
        returns (uint)
    {
        bool early = startPeriod > userStartTime[stakeHolder];
        uint startTime;
        if (endPeriod > block.timestamp) {
            startTime = early ? startPeriod : userStartTime[stakeHolder];
            uint timeRemaining = stakingDuration -
                (block.timestamp - startTime);
            return
                (precision * (stakingDuration - timeRemaining)) /
                stakingDuration;
        }
        startTime = early
            ? 0
            : stakingDuration - (endPeriod - userStartTime[stakeHolder]);
        return (precision * (stakingDuration - startTime)) / stakingDuration;
    }





    function _claimRewards() private {
        _updateRewards();

        uint _rewardsToClaim = rewardsToClaim[_msgSender()];
        require(_rewardsToClaim > 0, "Nothing to claim");

        rewardsToClaim[_msgSender()] = 0;
        token.safeTransfer(_msgSender(), _rewardsToClaim);
        emit Claim(_msgSender(), _rewardsToClaim);
    }






    function _updateRewards() private {
        rewardsToClaim[_msgSender()] = _calculateRewards(_msgSender());
        userStartTime[_msgSender()] = (block.timestamp >= endPeriod)
            ? endPeriod
            : block.timestamp;
    }
}
