



pragma solidity 0.5.16;






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




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {






        _notEntered = true;
    }








    modifier nonReentrant() {

        require(_notEntered, "ReentrancyGuard: reentrant call");


        _notEntered = false;

        _;



        _notEntered = true;
    }
}

contract StakingTokenWrapper is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;





    constructor(address _stakingToken) internal {
        stakingToken = IERC20(_stakingToken);
    }





    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }





    function balanceOf(address _account)
        public
        view
        returns (uint256)
    {
        return _balances[_account];
    }





    function _farm(address _beneficiary, uint256 _amount)
        internal
        nonReentrant
    {
        _totalSupply = _totalSupply.add(_amount);
        _balances[_beneficiary] = _balances[_beneficiary].add(_amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    }





    function _withdraw(uint256 _amount)
        internal
        nonReentrant
    {
        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        stakingToken.safeTransfer(msg.sender, _amount);
    }
}

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;
    function getRewardToken() external view returns (IERC20);
}

contract RewardsDistributionRecipient is IRewardsDistributionRecipient {


    function notifyRewardAmount(uint256 reward) external;
    function getRewardToken() external view returns (IERC20);


    address public rewardsDistributor;


    constructor(address _rewardsDistributor) internal
    {
        rewardsDistributor = _rewardsDistributor;
    }




    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "Caller is not reward distributor");
        _;
    }
}

library StableMath {

    using SafeMath for uint256;





    uint256 private constant FULL_SCALE = 1e18;







    uint256 private constant RATIO_SCALE = 1e8;





    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }





    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }






    function scaleInteger(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return x.mul(FULL_SCALE);
    }












    function mulTruncate(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return mulTruncateScale(x, y, FULL_SCALE);
    }










    function mulTruncateScale(uint256 x, uint256 y, uint256 scale)
        internal
        pure
        returns (uint256)
    {


        uint256 z = x.mul(y);

        return z.div(scale);
    }








    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {

        uint256 scaled = x.mul(y);

        uint256 ceil = scaled.add(FULL_SCALE.sub(1));

        return ceil.div(FULL_SCALE);
    }









    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {

        uint256 z = x.mul(FULL_SCALE);

        return z.div(y);
    }













    function mulRatioTruncate(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }









    function mulRatioTruncateCeil(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256)
    {


        uint256 scaled = x.mul(ratio);

        uint256 ceil = scaled.add(RATIO_SCALE.sub(1));

        return ceil.div(RATIO_SCALE);
    }










    function divRatioPrecisely(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {

        uint256 y = x.mul(RATIO_SCALE);

        return y.div(ratio);
    }











    function min(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x > y ? y : x;
    }







    function max(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x > y ? x : y;
    }







    function clamp(uint256 x, uint256 upperBound)
        internal
        pure
        returns (uint256)
    {
        return x > upperBound ? upperBound : x;
    }
}















contract ELP is StakingTokenWrapper, RewardsDistributionRecipient {

    using StableMath for uint256;

    IERC20 internal rewardsToken;

    uint256 internal constant DURATION = 7 days;


    uint256 internal periodFinish = 0;

    uint256 internal rewardRate = 0;

    uint256 internal lastUpdateTime = 0;

    uint256 internal rewardPerTokenStored = 0;
    mapping(address => uint256) internal userRewardPerTokenPaid;
    mapping(address => uint256) internal rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, address payer);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);


    constructor(
        address _stakingToken,
        address _rewardsToken,
        address _rewardsDistributor
    )
        public
        StakingTokenWrapper(_stakingToken)
        RewardsDistributionRecipient(_rewardsDistributor)
    {
        rewardsToken = IERC20(_rewardsToken);
    }


    modifier updateReward(address _account) {

        uint256 newRewardPerToken = rewardPerToken();

        if(newRewardPerToken > 0) {
            rewardPerTokenStored = newRewardPerToken;
            lastUpdateTime = lastTimeRewardApplicable();

            if (_account != address(0)) {
                rewards[_account] = earned(_account);
                userRewardPerTokenPaid[_account] = newRewardPerToken;
            }
        }
        _;
    }









    function farm(uint256 _amount)
        external
    {
        _farm(msg.sender, _amount);
    }






    function farm(address _beneficiary, uint256 _amount)
        external
    {
        _farm(_beneficiary, _amount);
    }







    function _farm(address _beneficiary, uint256 _amount)
        internal
        updateReward(_beneficiary)
    {
        require(_amount > 0, "Cannot stake 0");
        super._farm(_beneficiary, _amount);
        emit Staked(_beneficiary, _amount, msg.sender);
    }




    function unfarm() external {
        withdraw(balanceOf(msg.sender));
        claimReward();
    }





    function withdraw(uint256 _amount)
        public
        updateReward(msg.sender)
    {
        require(_amount > 0, "Cannot withdraw 0");
        _withdraw(_amount);
        emit Withdrawn(msg.sender, _amount);
    }





    function claimReward()
        public
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }









    function getRewardToken()
        external
        view
        returns (IERC20)
    {
        return rewardsToken;
    }




    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return StableMath.min(block.timestamp, periodFinish);
    }






    function rewardPerToken()
        public
        view
        returns (uint256)
    {

        uint256 stakedTokens = totalSupply();
        if (stakedTokens == 0) {
            return rewardPerTokenStored;
        }

        uint256 rewardUnitsToDistribute = rewardRate.mul(lastTimeRewardApplicable().sub(lastUpdateTime));

        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);

        return rewardPerTokenStored.add(unitsToDistributePerToken);
    }






    function earned(address _account)
        public
        view
        returns (uint256)
    {

        uint256 userRewardDelta = rewardPerToken().sub(userRewardPerTokenPaid[_account]);

        uint256 userNewReward = balanceOf(_account).mulTruncate(userRewardDelta);

        return rewards[_account].add(userNewReward);
    }











    function notifyRewardAmount(uint256 _reward)
        external
        onlyRewardsDistributor
        updateReward(address(0))
    {
        uint256 currentTime = block.timestamp;

        if (currentTime >= periodFinish) {
            rewardRate = _reward.div(DURATION);
        }

        else {
            uint256 remaining = periodFinish.sub(currentTime);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(DURATION);
        }

        lastUpdateTime = currentTime;
        periodFinish = currentTime.add(DURATION);

        emit RewardAdded(_reward);
    }
}
