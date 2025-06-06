

pragma solidity ^0.4.21;





contract ReentrancyGuard {













    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function ReentrancyGuard() internal {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED);

        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}

contract Owned {
    address public owner;
    address public nominatedOwner;

    function Owned(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner);
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner);
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

contract Pausable is Owned {
    uint256 public lastPauseTime;
    bool public paused;

    function Pausable() internal {

        require(owner != address(0));

    }





    function setPaused(bool _paused) external onlyOwner {

        if (_paused == paused) {
            return;
        }


        paused = _paused;

        if (paused) {
            lastPauseTime = now;
        }

        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused);
        _;
    }
}

library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


interface CDEXTokenContract {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

}


interface CDEXRankingContract {

    function insert(uint _key, address _value) external;
    function remove(uint _key, address _value) external;

}

contract CDEXStakingPool is ReentrancyGuard, Pausable {
    using SafeMath for uint256;


    CDEXTokenContract public CDEXToken;
    CDEXRankingContract public CDEXRanking;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;


    uint256 public loyaltyTier1 = 100000000 * 1e8;
    uint256 public loyaltyTier2 = 10000000 * 1e8;
    uint256 public loyaltyTier3 = 1000000 * 1e8;


    uint256 public loyaltyTier1Bonus = 125;
    uint256 public loyaltyTier2Bonus = 100;
    uint256 public loyaltyTier3Bonus = 50;
    uint256 public loyaltyBonusTotal = 275;
    uint256 public depositedLoyaltyBonus;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint256 public depositedRewardTokens;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 public totalMembers;






    function CDEXStakingPool(
        address _owner,
        address _CDEXTokenContractAddress,
        address _rankingContractAddress
    ) public Owned(_owner) {
        CDEXToken = CDEXTokenContract(_CDEXTokenContractAddress);
        CDEXRanking = CDEXRankingContract(_rankingContractAddress);
    }





    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }




    function lastTimeRewardApplicable() public view returns (uint256) {
        return min(block.timestamp, periodFinish);
    }


    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e8)
                    .div(_totalSupply)
            );
    }



    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e8)
                .add(rewards[account]);
    }


    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }




    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }


    function getLoyaltyTiers() external view returns(uint256 tier1, uint256 tier2, uint256 tier3)
    {
        return(loyaltyTier1, loyaltyTier2, loyaltyTier3);
    }




    function getLoyaltyTiersBonus() external view returns(uint256 tier1Bonus, uint256 tier2Bonus, uint256 tier3Bonus)
    {
        return(loyaltyTier1Bonus, loyaltyTier2Bonus, loyaltyTier3Bonus);
    }






    function stake(uint256 amount)
        external
        nonReentrant
        notPaused
        updateReward(msg.sender)
    {
        require(amount > 0);

        _totalSupply = _totalSupply.add(amount);

        if(_balances[msg.sender] == 0) {

            totalMembers += 1;

            CDEXRanking.insert(amount, msg.sender);
        } else {

            CDEXRanking.remove(_balances[msg.sender], msg.sender);

            CDEXRanking.insert(_balances[msg.sender].add(amount), msg.sender);
        }

        _balances[msg.sender] = _balances[msg.sender].add(amount);


        CDEXToken.transferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }




    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0);

        _totalSupply = _totalSupply.sub(amount);

        CDEXRanking.remove(_balances[msg.sender], msg.sender);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        if(_balances[msg.sender] == 0) {
            totalMembers -= 1;
        } else {

            CDEXRanking.insert(_balances[msg.sender], msg.sender);
        }


        CDEXToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }



    function getReward()
        public
        nonReentrant
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        uint256 loyaltyBonus;

        if (reward > 0 && depositedRewardTokens >= reward) {

            rewards[msg.sender] = 0;

            depositedRewardTokens = depositedRewardTokens.sub(reward);

            if (_balances[msg.sender] >= loyaltyTier1) {
                loyaltyBonus = reward.mul(loyaltyTier1Bonus).div(10000);
            } else if (_balances[msg.sender] >= loyaltyTier2) {
                loyaltyBonus = reward.mul(loyaltyTier2Bonus).div(10000);
            } else if (_balances[msg.sender] >= loyaltyTier3) {
                loyaltyBonus = reward.mul(loyaltyTier3Bonus).div(10000);
            }

            depositedLoyaltyBonus = depositedLoyaltyBonus.sub(loyaltyBonus);

            CDEXToken.transfer(msg.sender, reward.add(loyaltyBonus));

            emit RewardPaid(msg.sender, reward);

            if(loyaltyBonus > 0) {
                emit LoyaltyBonusPaid(msg.sender, loyaltyBonus);
            }
        }
    }


    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }






    function setTokenContract(address _contractAddress) public onlyOwner {
        CDEXToken = CDEXTokenContract(_contractAddress);
    }




    function setRankingContract(address _contractAddress) public onlyOwner {
        CDEXRanking = CDEXRankingContract(_contractAddress);
    }








    function depositTokens(uint256 amount) public onlyOwner {

        amount = amount.mul(1e8);

        depositedLoyaltyBonus = depositedLoyaltyBonus.add(amount.mul(loyaltyBonusTotal).div(10000));

        depositedRewardTokens = depositedRewardTokens.add(amount);

        CDEXToken.transferFrom(owner, address(this), amount);

        emit RewardsDeposited(owner, address(this), amount);
    }





    function notifyRewardAmount(uint256 reward)
        public
        onlyOwner
        updateReward(address(0))
    {

        reward = reward.mul(1e8);


        require(reward <= depositedRewardTokens.sub(reward.mul(loyaltyBonusTotal).div(10000)));


        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }




        require(rewardRate <= depositedRewardTokens.div(rewardsDuration));

        lastUpdateTime = block.timestamp;

        periodFinish = block.timestamp.add(rewardsDuration);

        emit RewardAdded(reward);
    }




    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {

        require(block.timestamp > periodFinish);

        rewardsDuration = _rewardsDuration;

        emit RewardsDurationUpdated(rewardsDuration);
    }





    function setLoyaltyTiers(
        uint256 _loyaltyTier1,
        uint256 _loyaltyTier2,
        uint256 _loyaltyTier3
    ) external onlyOwner
    {

        loyaltyTier1 = _loyaltyTier1.mul(1e8);
        loyaltyTier2 = _loyaltyTier2.mul(1e8);
        loyaltyTier3 = _loyaltyTier3.mul(1e8);

        emit LoyaltyTiersUpdated(loyaltyTier1, loyaltyTier2, loyaltyTier3);
    }







    function setLoyaltyTiersBonus(
        uint256 _loyaltyTier1Bonus,
        uint256 _loyaltyTier2Bonus,
        uint256 _loyaltyTier3Bonus
    ) external onlyOwner
    {


        require(_loyaltyTier1Bonus.add(_loyaltyTier2Bonus).add(_loyaltyTier3Bonus) < 10000);

        loyaltyTier1Bonus = _loyaltyTier1Bonus;
        loyaltyTier2Bonus = _loyaltyTier2Bonus;
        loyaltyTier3Bonus = _loyaltyTier3Bonus;

        loyaltyBonusTotal = loyaltyTier1Bonus.add(loyaltyTier2Bonus).add(loyaltyTier3Bonus);

        emit LoyaltyTiersBonussUpdated(loyaltyTier1Bonus, loyaltyTier2Bonus, loyaltyTier3Bonus);
    }





    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }



    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event LoyaltyBonusPaid(address indexed user, uint256 loyaltyBonus);
    event RewardsDurationUpdated(uint256 newDuration);

    event Recovered(address token, uint256 amount);
    event RewardsDeposited(address sender, address receiver, uint256 reward);
    event LoyaltyTiersUpdated(uint256 loyaltyTier1, uint256 loyaltyTier2, uint256 loyaltyTier3);
    event LoyaltyTiersBonussUpdated(uint256 loyaltyTier1Bonus, uint256 loyaltyTier2Bonus, uint256 loyaltyTier3Bonus);
}
