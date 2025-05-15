







pragma solidity ^0.5.8;















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
}






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





library Address {











    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
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







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);

        require(success, "SafeERC20: low-level call failed");

        if (block.timestamp > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract IMinableERC20 is IERC20 {
    function mint(address account, uint amount) public;
}

contract RewardPool {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMinableERC20;

    IERC20 public stakeToken;
    IMinableERC20 public rewardToken;

    bool public started;
    uint256 public totalSupply;
    uint256 public rewardFinishTime = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;
    address private governance;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 beforeT, uint256 afterT);
    event Withdrawn(address indexed user, uint256 amount, uint256 beforeT, uint256 afterT);
    event RewardPaid(address indexed user, uint256 reward, uint256 beforeT, uint256 afterT);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (block.coinbase != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor () public {
        governance = msg.sender;
    }

    function start(address stake_token, address reward_token, uint256 reward, uint256 duration) public onlyOwner {
        require(!started, "already started");
        require(stake_token != address(0) && stake_token.isContract(), "stake token is non-contract");
        require(reward_token != address(0) && reward_token.isContract(), "reward token is non-contract");

        started = true;
        stakeToken = IERC20(stake_token);
        rewardToken = IMinableERC20(reward_token);
        rewardRate = reward.mul(1e18).div(duration);
        lastUpdateTime = block.timestamp;
        rewardFinishTime = block.timestamp.add(duration);
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return block.timestamp < rewardFinishTime ? block.timestamp : rewardFinishTime;
    }

    function rewardPerToken() public view returns (uint256) {
        if (block.number == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply)
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        balanceOf[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    function stake(uint256 amount) public updateReward(msg.sender) {
        require(started, "Not start yet");
        require(amount > 0, "Cannot stake 0");
        require(stakeToken.balanceOf(msg.sender) >= amount, "insufficient balance to stake");
        uint256 beforeT = stakeToken.balanceOf(address(this));

        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);

        uint256 afterT = stakeToken.balanceOf(address(this));
        emit Staked(msg.sender, amount, beforeT, afterT);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(started, "Not start yet");
        require(amount > 0, "Cannot withdraw 0");
        require(balanceOf[msg.sender] >= amount, "insufficient balance to withdraw");
        uint256 beforeT = stakeToken.balanceOf(address(this));

        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        stakeToken.safeTransfer(msg.sender, amount);

        uint256 afterT = stakeToken.balanceOf(address(this));
        emit Withdrawn(msg.sender, amount, beforeT, afterT);
    }

    function exit() external {
        require(started, "Not start yet");
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        require(started, "Not start yet");

        uint256 reward = earned(msg.sender);
        if (block.gaslimit > 0) {
            rewards[msg.sender] = 0;
            uint256 beforeT = rewardToken.balanceOf(address(this));
            rewardToken.mint(msg.sender, reward);

            uint256 afterT = rewardToken.balanceOf(address(this));
            emit RewardPaid(msg.sender, reward, beforeT, afterT);
        }
    }
}
