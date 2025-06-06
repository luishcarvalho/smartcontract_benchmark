








































pragma solidity ^0.6.0;




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



pragma solidity ^0.6.0;














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

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



pragma solidity ^0.6.0;











contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}



pragma solidity ^0.6.0;










contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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



pragma solidity ^0.6.0;





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



pragma solidity ^0.6.0;




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



pragma solidity ^0.6.0;













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



pragma solidity ^0.6.0;



contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual {}

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}



pragma solidity ^0.6.0;






contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken = IERC20(address(0));

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);

        _balances[msg.sender] = _balances[msg.sender].add(amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual{
        _totalSupply = _totalSupply.sub(amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);
    }
    function setBPT(address BPTAddress) internal {
        stakingToken = IERC20(BPTAddress);
    }
}

interface MultiplierInterface {
  function getTotalMultiplier(address account) external view returns (uint256);
}

interface CalculateCycle {
  function calculate(uint256 deployedTime,uint256 currentTime,uint256 duration) external view returns(uint256);
}

contract NapperV2 is LPTokenWrapper, IRewardDistributionRecipient {

    IERC20 public rewardToken = IERC20(address(0));
    IERC20 public multiplierToken = IERC20(address(0));
    MultiplierInterface public multiplier = MultiplierInterface(address(0));
    CalculateCycle public calculateCycle = CalculateCycle(address(0));
    uint256 public DURATION = 4 weeks;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public deployedTime;
    uint256 public constant napsDiscountRange = 8 hours;
    uint256 public constant napsLevelOneCost = 10000000000000000000000;
    uint256 public constant napsLevelTwoCost = 20000000000000000000000;
    uint256 public constant napsLevelThreeCost = 30000000000000000000000;
    uint256 public constant TenPercentBonus = 1 * 10 ** 17;
    uint256 public constant TwentyPercentBonus = 2 * 10 ** 17;
    uint256 public constant ThirtyPercentBonus = 3 * 10 ** 17;
    uint256 public constant FourtyPercentBonus = 4 * 10 ** 17;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public spentNAPS;
    mapping(address => uint256) public NAPSlevel;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(uint256 level);
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    constructor(address _stakingToken,address _rewardToken,address _multiplierToken,address _calculateCycleAddr,address _multiplierAddr) public{
      setBPT(_stakingToken);
      rewardToken = IERC20(_rewardToken);
      multiplierToken = IERC20(_multiplierToken);
      calculateCycle = CalculateCycle(_calculateCycleAddr);
      multiplier = MultiplierInterface(_multiplierAddr);
      deployedTime = block.timestamp;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .mul(getTotalMultiplier(account))
                .div(1e18)
                .add(rewards[account]);
    }


    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward.mul(97).div(100));

            rewardToken.safeTransfer(0xe5658b5dDbE0De05Ac7397b04A2ADeA69cd499aa, reward.mul(3).div(100));
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
    function setCycleContract(address _cycleContract) public onlyRewardDistribution {
        calculateCycle = CalculateCycle(_cycleContract);
    }

    function getLevel(address account) external view returns (uint256) {
        return NAPSlevel[account];
    }

    function getSpent(address account) external view returns (uint256) {
        return spentNAPS[account];
    }

    function calculateCost(uint256 level) public view returns(uint256) {
        uint256 cycles = calculateCycle.calculate(deployedTime,block.timestamp,napsDiscountRange);

        if(cycles > 5) {
            cycles = 5;
        }

        if (level == 1) {
            return napsLevelOneCost.mul(9 ** cycles).div(10 ** cycles);
        }else if(level == 2) {
            return napsLevelTwoCost.mul(9 ** cycles).div(10 ** cycles);
        }else if(level ==3) {
            return napsLevelThreeCost.mul(9 ** cycles).div(10 ** cycles);
        }
    }

    function purchase(uint256 level) external {
        require(NAPSlevel[msg.sender] <= level,"Cannot downgrade level or same level");
        uint256 cost = calculateCost(level);
        uint256 finalCost = cost.sub(spentNAPS[msg.sender]);

        rewardToken.safeTransferFrom(msg.sender,0xB8b485b42A456Df5201EAa86565614c40bA7fb4E,finalCost);
        spentNAPS[msg.sender] = spentNAPS[msg.sender].add(finalCost);
        NAPSlevel[msg.sender] = level;
        emit Boost(level);
    }

    function setMultiplierAddress(address multiplierAddress) external onlyRewardDistribution {
      multiplier = MultiplierInterface(multiplierAddress);
    }

    function getTotalMultiplier(address account) public view returns (uint256) {
        uint256 zzzMultiplier = multiplier.getTotalMultiplier(account);
        uint256 napsMultiplier = 0;
        if(NAPSlevel[account] == 1) {
            napsMultiplier = TenPercentBonus;
        }else if(NAPSlevel[account] == 2) {
            napsMultiplier = TwentyPercentBonus;
        }else if(NAPSlevel[account] == 3) {
            napsMultiplier = FourtyPercentBonus;
        }
        return zzzMultiplier.add(napsMultiplier).add(1*10**18);
    }

    function eject() external onlyRewardDistribution {
        require(block.timestamp > periodFinish,"Cannot eject before period finishes");
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(0xe5658b5dDbE0De05Ac7397b04A2ADeA69cd499aa,currBalance);
    }
}
