
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./GovStakingStorage.sol";

interface govERC20 {
    function mint(address to_, uint256 amount_) external;
}

interface ICommunityRewardsManager {
    function updateAllRewards(address account) external;

    function getAllRewards(address account) external;
}

contract GovStaking is Ownable, ReentrancyGuard, Pausable {
    uint256 public opt1 = 0;
    uint256 public opt2 = 604800;
    uint256 public opt3 = 2629746;
    uint256 public opt4 = 15778476;
    uint256 public opt5 = 31556952;
    uint256 public opt6 = 94608000;

    mapping(uint256 => uint256) public rewardRates;

    IERC20 public gogo;
    govERC20 public govGogo;
    GovStakingStorage public store;
    ICommunityRewardsManager public rewards;

    struct RewardRate {
        uint256 period;
        uint256 rate;
    }

    constructor(
        address storageAddress,
        address gogoAddress,
        address govGogoAddress,
        address communityRewardsManager
    ) {
        store = GovStakingStorage(storageAddress);
        gogo = IERC20(gogoAddress);
        govGogo = govERC20(govGogoAddress);
        rewards = ICommunityRewardsManager(communityRewardsManager);


        rewardRates[opt1] = 1;
        rewardRates[opt2] = 1653439154;

        rewardRates[opt3] = 2471721604;

        rewardRates[opt4] = 4119536006;

        rewardRates[opt5] = 6971522471;

        rewardRates[opt6] = 8984441062;

    }

    event Enter(address indexed user, uint256 amount, uint256 extendingPeriod);
    event Leave(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event NewManager(address indexed oldAddress, address indexed newAddress);

    function enter(uint256 amount, uint256 extendingPeriod)
        external
        nonReentrant
        whenNotPaused
        returns (GovStakingStorage.UserInfo memory)
    {
        rewards.updateAllRewards(msg.sender);
        require(rewardRates[extendingPeriod] > 0, "wrong period");
        require(amount > 0 || extendingPeriod > 0, "invalid input");

        gogo.transferFrom(msg.sender, address(store), amount);
        GovStakingStorage.UserInfo memory user = store.getUserInformation(
            msg.sender
        );

        uint256 oldRate = user.rewardRate;

        if (user.amount == 0) {

            user.lockPeriod = extendingPeriod;
            user.lastClaimed = block.timestamp;
            user.rewardRate = rewardRates[extendingPeriod];
            store.addRewardMultiplier(
                msg.sender,
                user.rewardRate,
                extendingPeriod,
                amount
            );
        } else {

            if (user.lockStart + user.lockPeriod <= block.timestamp) {
                store.removeRewardMultiplier(msg.sender);
                user.unclaimedAmount = getClaimAmount(
                    user,
                    user.lockStart + user.lockPeriod
                );
                user.lastClaimed = block.timestamp;
                user.rewardRate = rewardRates[extendingPeriod];
                user.lockPeriod = extendingPeriod;
                store.addRewardMultiplier(
                    msg.sender,
                    user.rewardRate,
                    user.lockPeriod,
                    user.amount + amount
                );
            } else {

                uint256 oldPeriod = user.lockPeriod;
                user.unclaimedAmount = getClaimAmount(user, block.timestamp);
                user.lastClaimed = block.timestamp;
                uint256 rewardRate = getRewardForExtend(
                    msg.sender,
                    extendingPeriod,
                    amount,
                    oldRate
                );

                user.rewardRate = rewardRate;
                user.lockPeriod =
                    ((user.lockStart + user.lockPeriod) - block.timestamp) +
                    extendingPeriod;

                store.updateRewardMultiplier(
                    msg.sender,
                    oldRate,
                    user.rewardRate,
                    block.timestamp - user.lockStart,
                    oldPeriod,
                    user.lockPeriod,
                    user.amount,
                    user.amount + amount
                );
            }
        }

        user.amount += amount;
        user.lockStart = block.timestamp;
        storeUser(user);
        store.updateRewardRate(oldRate, user.rewardRate);
        store.addLockedGogo(amount);

        emit Enter(msg.sender, amount, extendingPeriod);

        return user;
    }

    function leave() external nonReentrant whenNotPaused {
        rewards.updateAllRewards(msg.sender);
        GovStakingStorage.UserInfo memory user = store.getUserInformation(
            msg.sender
        );
        require(
            block.timestamp >= user.lockPeriod + user.lockStart,
            "tokens are still locked"
        );
        _claim();
        rewards.getAllRewards(msg.sender);
        uint256 amount = user.amount;

        store.removeLockedGogo(amount);
        store.removeRewardRate(user.rewardRate);
        store.removeUser(msg.sender);

        store.transferGogo(msg.sender, amount);

        emit Leave(msg.sender, amount);
    }

    function _claim() internal {
        GovStakingStorage.UserInfo memory user = store.getUserInformation(
            msg.sender
        );
        uint256 qualifiedUntil = (
            user.lockStart + (user.lockPeriod) < block.timestamp
                ? user.lockStart + user.lockPeriod
                : block.timestamp
        );

        uint256 toClaim = getClaimAmount(user, qualifiedUntil) +
            user.unclaimedAmount;

        user.unclaimedAmount = 0;
        user.lastClaimed = qualifiedUntil;

        storeUser(user);
        if (toClaim > 0) govGogo.mint(msg.sender, toClaim);

        emit Claim(msg.sender, toClaim);
    }


    function claim() public nonReentrant whenNotPaused {
        rewards.updateAllRewards(msg.sender);
        _claim();
    }


    function claimAll() public nonReentrant whenNotPaused {
        rewards.updateAllRewards(msg.sender);
        _claim();
        rewards.getAllRewards(msg.sender);
    }

    function getRewardForExtend(
        address account,
        uint256 extendingPeriod,
        uint256 amount,
        uint256 oldRate
    ) public view returns (uint256) {
        GovStakingStorage.UserInfo memory user = store.getUserInformation(
            account
        );

        return
            extendingPeriod > 0
                ? calcExtendRate(
                    user.lockPeriod,
                    user.lockPeriod - (block.timestamp - user.lockStart),
                    oldRate,
                    getRewardRate(user.lockPeriod + extendingPeriod)
                )
                : calcRate(
                    user.amount,
                    amount,
                    oldRate,
                    getRewardRate(
                        user.lockStart + user.lockPeriod - block.timestamp
                    )
                );
    }

    function storeUser(GovStakingStorage.UserInfo memory user) internal {
        store.writeUser(
            msg.sender,
            user.amount,
            user.lockStart,
            user.lockPeriod,
            user.lastClaimed,
            user.unclaimedAmount,
            user.rewardRate
        );
    }

    function getRewardRate(uint256 period) internal view returns (uint256) {
        if (rewardRates[period] > 0) return rewardRates[period];
        if (period > opt6) return rewardRates[opt6];

        uint256 min = 0;
        uint256 max = 0;

        if (period >= opt1 && period <= opt2) {
            min = opt1;
            max = opt2;
        }
        if (period >= opt2 && period <= opt3) {
            min = opt2;
            max = opt3;
        }
        if (period >= opt3 && period <= opt4) {
            min = opt3;
            max = opt4;
        }
        if (period >= opt4 && period <= opt5) {
            min = opt4;
            max = opt5;
        }
        if (period >= opt5 && period <= opt6) {
            min = opt5;
            max = opt6;
        }

        return
            (((rewardRates[max] - rewardRates[min]) * (period - min)) /
                (max - min)) + rewardRates[min];
    }


    function earned() public view returns (uint256) {
        GovStakingStorage.UserInfo memory user = store.getUserInformation(
            msg.sender
        );
        uint256 qualifiedUntil = (
            user.lockStart + (user.lockPeriod) < block.timestamp
                ? user.lockStart + user.lockPeriod
                : block.timestamp
        );

        return getClaimAmount(user, qualifiedUntil) + user.unclaimedAmount;
    }

    function getClaimAmount(
        GovStakingStorage.UserInfo memory user,
        uint256 timestamp
    ) internal pure returns (uint256) {
        return ((timestamp - user.lastClaimed) *
            (user.amount / 1e18) *
            (user.rewardRate));
    }

    function calcRate(
        uint256 amount1,
        uint256 amount2,
        uint256 rate1,
        uint256 rate2
    ) internal pure returns (uint256) {
        return ((rate1 * amount1) + (rate2 * amount2)) / (amount1 + amount2);
    }

    function calcExtendRate(
        uint256 t1,
        uint256 t2,
        uint256 r1,
        uint256 r2
    ) internal pure returns (uint256) {
        return ((r2 - r1) * ((t2 * 1e18) / t1)) / 1e18 + r1;
    }

    function setRewardRate(uint256 period, uint256 newRate) external onlyOwner {
        require(rewardRates[period] > 0, "wrong period");
        rewardRates[period] = newRate;
    }

    function setRewardRates(RewardRate[] memory rates) external onlyOwner {
        for (uint256 i = 0; i < rates.length; i++) {
            if (rewardRates[rates[i].period] > 0)
                rewardRates[rates[i].period] = rates[i].rate;
        }
    }

    function setCommunityManager(address newManager) external onlyOwner {
        rewards = ICommunityRewardsManager(newManager);
    }

    function setStorage(address newStorage) external onlyOwner {
        store = GovStakingStorage(newStorage);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
