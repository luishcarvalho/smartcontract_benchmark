

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract EDAINStaking is Initializable, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;






    struct Stake {
        address user;
        uint256 amount;
        uint256 timestamp;
        uint256 claimable;
    }




    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }




    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    uint256 internal maxInterestRate;

    Stakeholder[] internal stakeholders;

    mapping(address => uint256) internal stakes;




    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp
    );

    function __EDAINStaking_init() public initializer {

        stakeholders.push();


        maxInterestRate = uint256(10**17);
    }





    function _stake(uint256 _amount) internal {

        require(_amount > 0, "Cannot stake nothing");

        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;

        if (index == 0) {



            index = _addStakeholder(msg.sender);
        }



        stakeholders[index].address_stakes.push(
            Stake(msg.sender, _amount, timestamp, 0)
        );

        emit Staked(msg.sender, _amount, index, timestamp);
    }




    function _addStakeholder(address staker) internal returns (uint256) {

        stakeholders.push();

        uint256 userIndex = stakeholders.length - 1;

        stakeholders[userIndex].user = staker;

        stakes[staker] = userIndex;
        return userIndex;
    }






    function _calculateStakeReward(Stake memory _current_stake)
        internal
        view
        returns (uint256)
    {

        uint256 _coinAge = (block.timestamp - _current_stake.timestamp).div(
            1 days
        );
        if (_coinAge <= 0) return 0;

        uint256 interest = _getAnnualInterest();
        uint256 currentReward = _coinAge * interest * _current_stake.amount;
        uint256 yearlyReward = 365 * 10**18;

        return currentReward / yearlyReward;
    }

    function _getAnnualInterest() internal view returns (uint256) {
        return maxInterestRate;
    }







    function _withdrawStake(uint256 amount, uint256 index)
        internal
        returns (uint256)
    {

        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(
            current_stake.amount >= amount,
            "Staking: Cannot withdraw more than you have staked"
        );


        uint256 reward = _calculateStakeReward(current_stake);

        current_stake.amount = current_stake.amount - amount;

        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[index];
        } else {

            stakeholders[user_index]
                .address_stakes[index]
                .amount = current_stake.amount;

            stakeholders[user_index].address_stakes[index].timestamp = block
                .timestamp;
        }

        return amount + reward;
    }






    function hasStake(address _staker)
        external
        view
        returns (StakingSummary memory)
    {

        uint256 totalStakeAmount;

        StakingSummary memory summary = StakingSummary(
            0,
            stakeholders[stakes[_staker]].address_stakes
        );

        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = _calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount += summary.stakes[s].amount;
        }

        summary.total_amount = totalStakeAmount;
        return summary;
    }
}
