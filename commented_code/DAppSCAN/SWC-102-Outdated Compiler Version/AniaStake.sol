// SPDX-License-Identifier: MIT
// SWC-102-Outdated Compiler Version: L4
// SWC-103-Floating Pragma: L4
pragma solidity ^0.8.2;

import "./Ania.sol";

contract AniaStake {
    string public name = "Arkania Protocol Launchpad";
    ArkaniaProtocol public aniaToken;

    //declaring owner state variable
    address public owner;

    //declaring default APY (default 0.1% daily or 36.5% APY yearly)
    uint256 public apy = 100;

    //declarring total value staked in the contract
    uint256 public totalStaked = 0;

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
    }

    /**
     * @notice Staker is a user who has active stakes
     */
    struct Staker{
        address user;
        Stake address_stake;
    }

    //array of all stakers
    Staker[] internal stakers;

    /**
    * @notice
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;

    constructor(ArkaniaProtocol _aniaToken) payable {
        aniaToken = _aniaToken;

        //assigning owner on deployment
        owner = msg.sender;

        // This push is needed so we avoid index 0 causing bug of index-1
        stakers.push();
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256) {
        return (_current_stake.amount * apy / 100) * (block.timestamp - _current_stake.since) / (365 days);
    }

    /**
    * @notice _addStaker takes care of adding a staker to the stakers array
     */
    function _addStaker(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakers.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakers.length - 1;
        // Assign the address to the new index
        stakers[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex;
    }

    // Get total stakes of the contract
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    /**
    * @notice
    * stakeTokens is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID
    */
    function stakeTokens(uint256 _amount) public {
        //must be more than 0
        require(_amount > 0, "amount cannot be 0");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;

        uint256 reward = 0;
        // See if the staker already has a staked index or if its the first time
        if (index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStaker(msg.sender);
        } else {
            reward = calculateStakeReward(stakers[index].address_stake);
        }

        uint256 newStake = stakers[index].address_stake.amount + _amount + reward;

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakers[index].address_stake = Stake(msg.sender, newStake, timestamp);
        totalStaked += newStake;

        //User adding test tokens
        aniaToken.transferFrom(msg.sender, address(this), _amount);
    }

    //unstake tokens function
    function unstakeTokens(uint256 _amount) public {

        uint256 index = stakes[msg.sender];

        // Get current stakes
        uint256 userStakes = stakers[index].address_stake.amount;

        // amount should be more than 0
        require(userStakes > 0, "amount has to be more than 0");

        // Get reward from current stakes
        uint256 reward = calculateStakeReward(stakers[index].address_stake);

        //transfer staked tokens back to user
        uint256 stakedWithRewards = userStakes + reward;
        require(_amount <= stakedWithRewards, "amount has to be less or equal than current stakes with rewards");
        aniaToken.transfer(msg.sender, _amount);

        // Update Stake with the current block timestamp.
        stakers[index].address_stake = Stake(msg.sender, userStakes + reward - _amount, block.timestamp);

        // Update contract total staked tokens
        if (userStakes < _amount) {
            totalStaked -= userStakes;  // exceedes are rewards
        } else {
            totalStaked -= _amount;
        }
    }

    //get staking rewards
    function hasRewards() public view returns(uint256) {
        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        return calculateStakeReward(stakers[index].address_stake);
    }

    //get staking amount with rewards
    function hasStakeWithRewards(address _address) public view returns(uint256) {
        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[_address];

        if (stakers[index].user != _address) {
            return 0;
        }

        //get staking balance for user
        uint256 balance = stakers[index].address_stake.amount;

        if (index != 0) {
            balance += calculateStakeReward(stakers[index].address_stake);
        }
        return balance;
    }

    //airdrop tokens
    function redistributeRewards(address[] calldata users) public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can redistribute");
        // SWC-128-DoS With Block Gas Limit: L185 - L194    
        for (uint256 i = 0; i < users.length; i++) {
            uint256 index = stakes[users[i]];
            uint256 reward = calculateStakeReward(stakers[index].address_stake);

            // update stakes before changaing the APY
            stakers[index].address_stake = Stake(stakers[index].user, stakers[index].address_stake.amount + reward, block.timestamp);

            // update total staked amount
            totalStaked += reward;
        }
    }

    //change APY value for staking, be aware of possible high gas fees
    function changeAPY(uint256 _value, address[] calldata users) public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        redistributeRewards(users);
        apy = _value;
    }
}
