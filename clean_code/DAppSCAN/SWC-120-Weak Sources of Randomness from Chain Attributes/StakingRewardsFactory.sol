
pragma solidity >=0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./StakingRewards.sol";

contract StakingRewardsFactory is Ownable {

    uint256 public stakingRewardsGenesis;


    address[] public stakingTokens;


    struct StakingRewardsInfo {
        address stakingRewards;
        address[] poolRewardToken;
        uint256[] poolRewardAmount;
    }





    mapping(address => StakingRewardsInfo)
        public stakingRewardsInfoByStakingToken;


    mapping(address => uint256) public rewardTokenQuantities;


    constructor(uint256 _stakingRewardsGenesis) public Ownable() {
        require(
            _stakingRewardsGenesis >= block.timestamp,
            "StakingRewardsFactory::constructor: genesis too soon"
        );
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }





    function deploy(
        address stakingToken,
        address[] memory rewardTokens,
        uint256[] memory rewardAmounts
    ) public onlyOwner {
        StakingRewardsInfo storage info =
            stakingRewardsInfoByStakingToken[stakingToken];
        require(
            info.stakingRewards == address(0),
            "StakingRewardsFactory::deploy: already deployed"
        );
        info.stakingRewards = address(
            new StakingRewards(














































































































