





pragma solidity 0.5.17;





library Math {



    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }




    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }





    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }






   function sqrt(uint256 x) internal pure returns (uint256) {
       uint256 n = x / 2;
       uint256 lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2;
       }
       return uint256(n);
   }
}














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }














    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }














    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity 0.5.17;





library Address {











    function isContract(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}





pragma solidity 0.5.17;






interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity 0.5.17;













library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



pragma solidity 0.5.17;



interface ITreasury {
    function defaultToken() external view returns (IERC20);
    function deposit(IERC20 token, uint256 amount) external;
    function withdraw(uint256 amount, address withdrawAddress) external;
}



pragma solidity 0.5.17;



interface IVault {
    function want() external view returns (IERC20);
    function transferFundsToStrategy(address strategy, uint256 amount) external;
    function availableFunds() external view returns (uint256);
}



pragma solidity 0.5.17;



interface IVaultRewards {
    function want() external view returns (IERC20);
    function notifyRewardAmount(uint256 reward) external;
}



pragma solidity 0.5.17;






interface IController {
    function currentEpochTime() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function rewards(address token) external view returns (IVaultRewards);
    function vault(address token) external view returns (IVault);
    function allowableAmount(address) external view returns (uint256);
    function treasury() external view returns (ITreasury);
    function approvedStrategies(address, address) external view returns (bool);
    function getHarvestInfo(address strategy, address user)
        external view returns (
        uint256 vaultRewardPercentage,
        uint256 hurdleAmount,
        uint256 harvestPercentage
    );
    function withdraw(address, uint256) external;
    function earn(address, uint256) external;
    function increaseHurdleRate(address token) external;
}






pragma solidity ^0.5.17;




contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 _stakeToken) public {
        stakeToken = _stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

    }
}


























pragma solidity 0.5.17;







contract BoostVaultRewards is LPTokenWrapper, IVaultRewards {
    struct EpochRewards {
        uint256 rewardsAvailable;
        uint256 rewardsClaimed;
        uint256 rewardPerToken;
    }

    IERC20 public boostToken;
    IERC20 public want;
    IController public controller;
    address public gov;

    EpochRewards public previousEpoch;
    EpochRewards public currentEpoch;
    mapping(address => uint256) public previousEpochUserRewardPerTokenPaid;
    mapping(address => uint256) public currentEpochUserRewardPerTokenPaid;
    mapping(address => uint256) public previousEpochRewardsClaimable;
    mapping(address => uint256) public currentEpochRewardsClaimable;

    uint256 public constant EPOCH_DURATION = 1 weeks;
    uint256 public currentEpochTime;
    uint256 public unclaimedRewards;



    uint256 public boostedTotalSupply;
    uint256 public lastBoostPurchase;
    mapping(address => uint256) public boostedBalances;
    mapping(address => uint256) public numBoostersBought;
    mapping(address => uint256) public nextBoostPurchaseTime;
    mapping(address => uint256) public lastActionTime;

    uint256 public globalBoosterPrice = 1e18;
    uint256 public scaleFactor = 125;
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant DENOM = 10000;
    uint256 internal constant TREASURY_FEE = 250;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        IERC20 _stakeToken,
        IERC20 _boostToken,
        IController _controller,
        address _gov
    ) public LPTokenWrapper(_stakeToken) {
        boostToken = _boostToken;
        want = IVault(address(_stakeToken)).want();
        controller = _controller;
        gov = _gov;
        currentEpochTime = controller.currentEpochTime();
        lastBoostPurchase = block.timestamp;
    }

    modifier updateEpochRewards() {
        if (block.timestamp > currentEpochTime.add(EPOCH_DURATION)) {
            currentEpochTime = currentEpochTime.add(EPOCH_DURATION);

            unclaimedRewards = unclaimedRewards.add(
                previousEpoch.rewardsAvailable.sub(previousEpoch.rewardsClaimed)
            );

            previousEpoch = currentEpoch;

            currentEpoch = EpochRewards({
                rewardsAvailable: 0,
                rewardsClaimed: 0,
                rewardPerToken: 0
            });
        }
        _;
    }

    function earned(address user) external view returns (uint256) {
        return (block.timestamp > currentEpochTime + EPOCH_DURATION) ?
            _earned(user, true) :
            _earned(user, false).add(_earned(user, true));
    }

    function setGovernance(address _gov) external updateEpochRewards {
        require(tx.origin == gov, "not gov");

        gov = _gov;
    }

    function setController(IController _controller) external updateEpochRewards {
        require(tx.origin == gov, "not gov");

        controller = _controller;
    }

    function getReward(address user) external updateEpochRewards {
        updateClaimUserRewardAndBooster(user);
    }

    function sendUnclaimedRewards() external updateEpochRewards {
        uint256 pendingRewards = unclaimedRewards;
        unclaimedRewards = 0;
        want.safeTransfer(address(controller.vault(address(want))), pendingRewards);
    }

    function sendTreasuryBoost() external updateEpochRewards {

        uint256 boosterAmount = boostToken.balanceOf(address(this));
        boostToken.safeApprove(address(controller.treasury()), boosterAmount);
        controller.treasury().deposit(boostToken, boosterAmount);
    }

    function boost() external updateEpochRewards {
        require(
            block.timestamp > nextBoostPurchaseTime[msg.sender],
            "early boost purchase"
        );
        updateClaimUserRewardAndBooster(msg.sender);



        (uint256 boosterAmount, uint256 newBoostBalance) = getBoosterPrice(msg.sender);

        applyBoost(msg.sender, newBoostBalance);


        controller.increaseHurdleRate(address(want));

        boostToken.safeTransferFrom(msg.sender, address(this), boosterAmount);
    }



    function notifyRewardAmount(uint256 reward)
        external
        updateEpochRewards
    {
        require(
            msg.sender == address(stakeToken) ||
            controller.approvedStrategies(address(want), msg.sender),
            "!authorized"
        );


        uint256 rewardAmount = reward.mul(TREASURY_FEE).div(DENOM);
        want.safeApprove(address(controller.treasury()), rewardAmount);
        controller.treasury().deposit(want, rewardAmount);


        rewardAmount = reward.sub(rewardAmount);
        currentEpoch.rewardsAvailable = currentEpoch.rewardsAvailable.add(rewardAmount);
        currentEpoch.rewardPerToken = currentEpoch.rewardPerToken.add(
            (boostedTotalSupply == 0) ?
            rewardAmount :
            rewardAmount.mul(PRECISION).div(boostedTotalSupply)
        );
        emit RewardAdded(reward);
    }

    function getBoosterPrice(address user)
        public view returns (uint256 boosterPrice, uint256 newBoostBalance)
    {
        if (boostedTotalSupply == 0) return (0,0);


        uint256 boostersBought = numBoostersBought[user];
        boosterPrice = globalBoosterPrice.mul(boostersBought.mul(5).add(100)).div(100);


        boostersBought = boostersBought.add(1);



        uint256 numIterations = (block.timestamp.sub(lastBoostPurchase)).div(2 hours);
        numIterations = Math.min(8, numIterations);
        boosterPrice = pow(boosterPrice, 975, 1000, numIterations);



        newBoostBalance = balanceOf(user)
            .mul(boostersBought.mul(5).add(100))
            .div(100);
        uint256 boostBalanceIncrease = newBoostBalance.sub(boostedBalances[user]);
        boosterPrice = boosterPrice
            .mul(boostBalanceIncrease)
            .mul(scaleFactor)
            .div(boostedTotalSupply);
    }


    function stake(uint256 amount) public updateEpochRewards {
        require(amount > 0, "Cannot stake 0");
        updateClaimUserRewardAndBooster(msg.sender);
        super.stake(amount);


        boostedBalances[msg.sender] = boostedBalances[msg.sender].add(amount);
        boostedTotalSupply = boostedTotalSupply.add(amount);


        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public updateEpochRewards {
        require(amount > 0, "Cannot withdraw 0");
        updateClaimUserRewardAndBooster(msg.sender);
        super.withdraw(amount);


        updateBoostBalanceAndSupply(msg.sender, 0);
        stakeToken.safeTransfer(msg.sender, amount);
    }



    function emergencyWithdraw(uint256 amount) public {
        super.withdraw(amount);

        numBoostersBought[msg.sender] = 0;

        updateBoostBalanceAndSupply(msg.sender, 0);

        stakeToken.safeTransfer(msg.sender, amount);
    }

    function exit() public updateEpochRewards {
        withdraw(balanceOf(msg.sender));
    }

    function updateBoostBalanceAndSupply(address user, uint256 newBoostBalance) internal {

        boostedTotalSupply = boostedTotalSupply.sub(boostedBalances[user]);



        if (newBoostBalance == 0) {

            newBoostBalance = balanceOf(user).mul(numBoostersBought[user].mul(5).add(100)).div(100);
        }


        boostedBalances[user] = newBoostBalance;


        boostedTotalSupply = boostedTotalSupply.add(newBoostBalance);
    }

    function updateClaimUserRewardAndBooster(address user) internal {

        if (lastActionTime[user].add(EPOCH_DURATION) <= currentEpochTime) {
            previousEpochRewardsClaimable[user] = 0;
            previousEpochUserRewardPerTokenPaid[user] = 0;
            numBoostersBought[user] = 0;
        }

        if (lastActionTime[user] <= currentEpochTime) {
            previousEpochRewardsClaimable[user] = _earned(user, false);
            previousEpochUserRewardPerTokenPaid[user] = previousEpoch.rewardPerToken;
            numBoostersBought[user] = 0;
        }

        currentEpochRewardsClaimable[user] = _earned(user, true);
        currentEpochUserRewardPerTokenPaid[user] = currentEpoch.rewardPerToken;


        previousEpoch.rewardsClaimed = previousEpoch.rewardsClaimed.add(previousEpochRewardsClaimable[user]);
        uint256 reward = previousEpochRewardsClaimable[user];
        previousEpochRewardsClaimable[user] = 0;


        currentEpoch.rewardsClaimed = currentEpoch.rewardsClaimed.add(currentEpochRewardsClaimable[user]);
        reward = reward.add(currentEpochRewardsClaimable[user]);
        currentEpochRewardsClaimable[user] = 0;

        if (reward > 0) {
            want.safeTransfer(user, reward);
            emit RewardPaid(user, reward);
        }


        lastActionTime[user] = block.timestamp;
    }

    function applyBoost(address user, uint256 newBoostBalance) internal {

        numBoostersBought[user] = numBoostersBought[user].add(1);

        updateBoostBalanceAndSupply(user, newBoostBalance);


        nextBoostPurchaseTime[user] = block.timestamp.add(3600);


        globalBoosterPrice = globalBoosterPrice.mul(101).div(100);

        lastBoostPurchase = block.timestamp;
    }

    function _earned(address account, bool isCurrentEpoch) internal view returns (uint256) {
        uint256 rewardPerToken;
        uint256 userRewardPerTokenPaid;
        uint256 rewardsClaimable;

        if (isCurrentEpoch) {
            rewardPerToken = currentEpoch.rewardPerToken;
            userRewardPerTokenPaid = currentEpochUserRewardPerTokenPaid[account];
            rewardsClaimable = currentEpochRewardsClaimable[account];
        } else {
            rewardPerToken = previousEpoch.rewardPerToken;
            userRewardPerTokenPaid = previousEpochUserRewardPerTokenPaid[account];
            rewardsClaimable = previousEpochRewardsClaimable[account];
        }
        return
            boostedBalances[account]
                .mul(rewardPerToken.sub(userRewardPerTokenPaid))
                .div(1e18)
                .add(rewardsClaimable);
    }




   function pow(uint256 a, uint256 b, uint256 c, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return a;
        }
        else if (exponent == 1) {
            return a.mul(b).div(c);
        }
        else if (a == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = a.mul(b).div(c);
            for (uint256 i = 1; i < exponent; i++)
                z = z.mul(b).div(c);
            return z;
        }
    }
}
