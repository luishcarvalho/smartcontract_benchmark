







pragma solidity ^0.7.1;










contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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













library SafeERC20 {
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







    function callOptionalReturn(IERC20 token, bytes memory data) private {




        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.timestamp > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



contract LPTokenWrapper {
    uint256 public totalSupply;
    IERC20 public uniswapDonutEth = IERC20(0x718Dd8B743ea19d71BDb4Cb48BB984b73a65cE06);

    mapping(address => uint256) private _balances;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint128 amount) public virtual {
        require(uniswapDonutEth.transferFrom(msg.sender, address(this), amount), "DONUT-ETH transfer failed");
        totalSupply += amount;
        _balances[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw() public virtual {
        uint256 amount = balanceOf(msg.sender);
        _balances[msg.sender] = 0;
        totalSupply = totalSupply-amount;
        require(uniswapDonutEth.transfer(msg.sender, amount), "DONUT-ETH transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
}

contract DonutUniswapRewards is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public donut = IERC20(0xC0F9bD5Fa5698B6505F643900FFA515Ea5dF54A9);

    uint256 public rewardRate;
    uint64 public periodFinish;
    uint64 public lastUpdateTime;
    uint128 public rewardPerTokenStored;
    struct UserRewards {
        uint128 userRewardPerTokenPaid;
        uint128 rewards;
    }
    mapping(address => UserRewards) public userRewards;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        uint128 _rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewards[account].rewards = earned(account);
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (block.timestamp == 0) {
            return rewardPerTokenStored;
        }
        uint256 rewardDuration = lastTimeRewardApplicable()-lastUpdateTime;
        return uint128(rewardPerTokenStored + rewardDuration*rewardRate*1e18/totalStakedSupply);
    }

    function earned(address account) public view returns (uint128) {
        return uint128(balanceOf(account)*(rewardPerToken()-userRewards[account].userRewardPerTokenPaid)/1e18 + userRewards[account].rewards);
    }


    function stake(uint128 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
    }

    function withdraw() public override updateReward(msg.sender) {
        super.withdraw();
    }

    function exit() external {
        withdraw();
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (block.timestamp > 0) {
            userRewards[msg.sender].rewards = 0;
            require(donut.transfer(msg.sender, reward), "DONUT transfer failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setRewardParams(uint128 reward, uint64 duration) external onlyOwner {
        rewardPerTokenStored = rewardPerToken();
        uint64 blockTimestamp = uint64(block.timestamp);
        if (blockTimestamp >= periodFinish) {
            rewardRate = reward/duration;
        } else {
            uint256 remaining = periodFinish-blockTimestamp;
            uint256 leftover = remaining*rewardRate;
            rewardRate = (reward+leftover)/duration;
        }
        lastUpdateTime = blockTimestamp;
        periodFinish = blockTimestamp+duration;
        emit RewardAdded(reward);
    }




    function recoverTokens(IERC20 token) external onlyOwner {
        if(token == uniswapDonutEth) {


            uint256 unstakedSupply = uniswapDonutEth.balanceOf(address(this))-totalSupply;
            require(unstakedSupply > 0 && uniswapDonutEth.transfer(msg.sender, unstakedSupply));
        }
        else {
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance > 0);
            token.safeTransfer(msg.sender, tokenBalance);
        }
    }
}



































