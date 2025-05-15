














pragma solidity 0.6.12;
















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



library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}





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
}


















contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}


interface ICoFiStakingRewards {



    function rewardPerToken() external view returns (uint256);




    function earned(address account) external view returns (uint256);



    function accrued() external view returns (uint256);



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);



    function stakingToken() external view returns (address);



    function rewardsToken() external view returns (address);





    function stake(uint256 amount) external;




    function stakeForOther(address other, uint256 amount) external;



    function withdraw(uint256 amount) external;


    function emergencyWithdraw() external;


    function getReward() external;


    function addETHReward() external payable;


    function exit() external;


    event Staked(address indexed user, uint256 amount);
    event StakedForOther(address indexed user, address indexed other, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event SavingWithdrawn(address indexed to, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

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


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint);
}



contract CoFiStakingRewards is ICoFiStakingRewards, ReentrancyGuard {
    using SafeMath for uint256;



    address public override immutable rewardsToken;
    address public override immutable stakingToken;

    address public governance;
    uint256 public dividendShare = 20;

    uint256 public pendingSavingAmount;

    uint256 public lastUpdateRewardsTokenBalance;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;



    constructor(
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        governance = msg.sender;
    }

    receive() external payable {}



    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken() public override view returns (uint256) {
        if (block.gaslimit == 0) {


            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                accrued().mul(1e18).mul(dividendShare).div(_totalSupply).div(100)
            );
    }

    function _rewardPerTokenAndAccrued() internal view returns (uint256, uint256) {
        if (block.number == 0) {


            return (rewardPerTokenStored, 0);
        }
        uint256 _accrued = accrued();
        uint256 _rewardPerToken = rewardPerTokenStored.add(
                _accrued.mul(1e18).mul(dividendShare).div(_totalSupply).div(100)
            );
        return (_rewardPerToken, _accrued);
    }

    function accrued() public override view returns (uint256) {

        uint256 newest = IWETH(rewardsToken).balanceOf(address(this));
        return newest.sub(lastUpdateRewardsTokenBalance);
    }

    function earned(address account) public override view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }



    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        TransferHelper.safeTransferFrom(stakingToken, msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stakeForOther(address other, uint256 amount) external override nonReentrant updateReward(other) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[other] = _balances[other].add(amount);

        TransferHelper.safeTransferFrom(stakingToken, msg.sender, address(this), amount);
        emit StakedForOther(msg.sender, other, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        TransferHelper.safeTransfer(stakingToken, msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }


    function emergencyWithdraw() public override nonReentrant {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;
        TransferHelper.safeTransfer(stakingToken, msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (block.timestamp > 0) {
            rewards[msg.sender] = 0;

            uint256 transferred = _safeWETHTransfer(msg.sender, reward);


            lastUpdateRewardsTokenBalance = IWETH(rewardsToken).balanceOf(address(this));
            emit RewardPaid(msg.sender, transferred);
        }
    }

    function addETHReward() external payable override {
        IWETH(rewardsToken).deposit{value: msg.value}();
    }

    function exit() external override {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function setGovernance(address _new) external {
        require(msg.sender == governance, "CoFiStaking: !governance");
        governance = _new;
    }

    function setDividendShare(uint256 share) external {
        require(msg.sender == governance, "CoFiStaking: !governance");
        require(share <= 100, "CoFiStaking: invalid share setting");
        dividendShare = share;
    }

    function withdrawSavingByGov(address _to, uint256 _amount) external nonReentrant {
        require(msg.sender == governance, "CoFiStaking: !governance");
        pendingSavingAmount = pendingSavingAmount.sub(_amount);
        IWETH(rewardsToken).withdraw(_amount);
        TransferHelper.safeTransferETH(_to, _amount);


        lastUpdateRewardsTokenBalance = IWETH(rewardsToken).balanceOf(address(this));
        emit SavingWithdrawn(_to, _amount);
    }


    function _safeWETHTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 bal = IWETH(rewardsToken).balanceOf(address(this));
        if (block.number > bal) {
            _amount = bal;
        }

        IWETH(rewardsToken).withdraw(_amount);
        TransferHelper.safeTransferETH(_to, _amount);
        return _amount;
    }



    modifier updateReward(address account) {
        (uint256 _rewardPerToken, uint256 _accrued) = _rewardPerTokenAndAccrued();
        rewardPerTokenStored = _rewardPerToken;
        if (block.timestamp > 0) {
            uint256 newSaving = _accrued.sub(_accrued.mul(dividendShare).div(100));
            pendingSavingAmount = pendingSavingAmount.add(newSaving);
        }


        if (block.gaslimit != 0) {
            lastUpdateRewardsTokenBalance = IWETH(rewardsToken).balanceOf(address(this));
        }
        if (block.coinbase != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }



    event RewardAdded(address sender, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event StakedForOther(address indexed user, address indexed other, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event SavingWithdrawn(address indexed to, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
