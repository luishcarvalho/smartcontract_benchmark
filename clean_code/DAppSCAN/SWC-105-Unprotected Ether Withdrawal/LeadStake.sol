

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

contract LeadStake is Ownable {


    using SafeMath for uint;


    address public lead;

    uint public totalStaked;

    uint public stakingTaxRate;

    uint public registrationTax;

    uint8 public dailyROI;

    uint public unstakingTaxRate;

    uint public minimumStakeValue;

    uint public referralTaxAllocation;

    uint index;

    bool active = true;

    mapping(uint => address) public userIndex;

    mapping(address => uint) public stakes;

    mapping(address => uint) public stakeRewards;

    mapping(address => uint) public referralCount;

    mapping(address => uint) public referralRewards;

    mapping(address => uint) public lastClock;

    mapping(address => bool) public registered;


    event OnWithdrawal(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnDeposit(address sender, uint amount, uint time);
    event OnRegisterAndStake(address stakeholder, uint amount, uint totalTax , address _referrer);




    constructor(
        address _token,
        uint8 _stakingTaxRate,
        uint8 _unstakingTaxRate,
        uint8 _dailyROI,
        uint _registrationTax,
        uint _referralTaxAllocation,
        uint _minimumStakeValue) public {


        lead = _token;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        registrationTax = _registrationTax;
        referralTaxAllocation = _referralTaxAllocation;
        minimumStakeValue = _minimumStakeValue;
    }


    modifier onlyRegistered() {
        require(registered[msg.sender] == true, "Staker must be registered");
        _;
    }


    modifier onlyUnregistered() {
        require(registered[msg.sender] == false, "Staker is already registered");
        _;
    }


    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }








    function registerAndStake(uint _amount, address _referrer) external onlyUnregistered() whenActive() {

        require(msg.sender != _referrer, "Cannot refer self");

        require(registered[_referrer] || address(0x0) == _referrer, "Referrer must be registered");

        require(IERC20(lead).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");

        require(IERC20(lead).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");

        require(_amount >= registrationTax.add(minimumStakeValue), "Must send at least enough LEAD to pay registration fee.");

        uint referralBonus = (registrationTax.mul(referralTaxAllocation)).div(100);

        uint finalAmount = _amount.sub(registrationTax);

        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);

        if(_referrer != address(0x0)) {

            referralCount[_referrer]++;

            referralRewards[_referrer] = referralRewards[_referrer].add(referralBonus);
        }

        stakes[msg.sender] = stakes[msg.sender].add(finalAmount).sub(stakingTax);

        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);

        registered[msg.sender] = true;
        userIndex[index] = msg.sender;
        index++;

        lastClock[msg.sender] = now;

        emit OnRegisterAndStake(msg.sender, _amount, registrationTax.add(stakingTax), _referrer);
    }


    function calculateEarnings(address _stakeholder) public view returns(uint) {

        uint activeDays = (now.sub(lastClock[_stakeholder])).div(86400);

        return (stakes[_stakeholder].mul(dailyROI).mul(activeDays)).div(10000);
    }








    function stake(uint _amount) external onlyRegistered() whenActive() {

        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");

        require(IERC20(lead).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");

        require(IERC20(lead).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");

        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);

        uint afterTax = _amount.sub(stakingTax);

        totalStaked = totalStaked.add(afterTax);

        stakeRewards[msg.sender] = stakeRewards[msg.sender].add(calculateEarnings(msg.sender));

        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);

        lastClock[msg.sender] = now.sub(remainder);

        stakes[msg.sender] = stakes[msg.sender].add(afterTax);

        emit OnStake(msg.sender, afterTax, stakingTax);
    }









    function unstake(uint _amount) external onlyRegistered() {

        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');

        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);

        uint afterTax = _amount.sub(unstakingTax);

        uint unstakePlusAllEarnings = stakeRewards[msg.sender].add(referralRewards[msg.sender]).add(afterTax).add(calculateEarnings(msg.sender));

        IERC20(lead).transfer(msg.sender, unstakePlusAllEarnings);

        stakes[msg.sender] = stakes[msg.sender].sub(_amount);

        stakeRewards[msg.sender] = 0;

        referralRewards[msg.sender] = 0;

        referralCount[msg.sender] = 0;

        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);

        lastClock[msg.sender] = now.sub(remainder);

        totalStaked = totalStaked.sub(_amount);

        if(stakes[msg.sender] == 0) {

            _removeStakeholder(msg.sender);
        }

        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }





    function isStakeholder(address _address) public view returns(bool, uint) {

        for (uint i = 0; i < index; i += 1){

            if (_address == userIndex[i]) {

                return (true, i);
            }
        }

        return (false, 0);
    }


    function _removeStakeholder(address _stakeholder) internal {

        registered[msg.sender] = false;

        (bool _isStakeholder, uint i) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            delete userIndex[i];
        }
    }


    function withdrawEarnings() external onlyRegistered() whenActive() {

        uint totalReward = referralRewards[msg.sender].add(stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));

        require(totalReward > 0, 'No reward to withdraw');

        IERC20(lead).transfer(msg.sender, totalReward);

        stakeRewards[msg.sender] = 0;

        referralRewards[msg.sender] = 0;

        referralCount[msg.sender] = 0;

        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);

        lastClock[msg.sender] = now.sub(remainder);

        emit OnWithdrawal(msg.sender, totalReward);
    }

    function changeActiveStatus() external onlyOwner() {
        if(active = true) {
            active == false;
        } else {
            active == true;
        }
    }


    function setStakingTaxRate(uint8 _stakingTaxRate) external onlyOwner() {
        stakingTaxRate = _stakingTaxRate;
    }


    function setUnstakingTaxRate(uint8 _unstakingTaxRate) external onlyOwner() {
        unstakingTaxRate = _unstakingTaxRate;
    }


    function setDailyROI(uint8 _dailyROI) external onlyOwner() {
        for(uint i = 0; i < index; i++){

            stakeRewards[userIndex[i]] = stakeRewards[userIndex[i]].add(calculateEarnings(userIndex[i]));

            uint remainder = (now.sub(lastClock[userIndex[i]])).mod(86400);

            lastClock[userIndex[i]] = now.sub(remainder);
        }
        dailyROI = _dailyROI;
    }


    function setRegistrationTax(uint _registrationTax) external onlyOwner() {
        registrationTax = _registrationTax;
    }


    function setReferralTaxAllocation(uint _referralTaxAllocation) external onlyOwner() {
        referralTaxAllocation = _referralTaxAllocation;
    }


    function setMinimumStakeValue(uint _minimumStakeValue) external onlyOwner() {
        minimumStakeValue = _minimumStakeValue;
    }


    function adminWithdraw(address _address, uint _amount) external onlyOwner {

        require(IERC20(lead).balanceOf(address(this)) >= _amount, 'Insufficient LEAD balance in smart contract');

        IERC20(lead).transfer(_address, _amount);

        emit OnWithdrawal(_address, _amount);
    }


    function supplyPool() external onlyOwner() {

        uint totalClaimable;

        for(uint i = 0; i < index; i++){

            totalClaimable = stakeRewards[userIndex[i]].add(referralRewards[userIndex[i]]).add(stakes[userIndex[i]]).add(calculateEarnings(userIndex[i]));
        }

        require(totalClaimable > IERC20(lead).balanceOf(address(this)), 'Still have enough pool reserve');

        uint difference = totalClaimable.sub(IERC20(lead).balanceOf(address(this)));

        require(IERC20(lead).balanceOf(msg.sender) >= difference, 'Insufficient LEAD balance in owner wallet');

        IERC20(lead).transferFrom(msg.sender, address(this), difference);

        emit OnDeposit(msg.sender, difference, now);
    }
}
