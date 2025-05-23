





pragma solidity 0.6.12;














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





interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function mint(address account, uint amount) external;

    function burn(uint amount) external;

    function governance() external view returns (address);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    function minters(address account) external view returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal {}


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success,) = recipient.call{value: amount}("");
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

interface IController {
    function withdraw(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function maxAcceptAmount(address) external view returns (uint256);
    function doHardWork(address, uint256) external;
    function yfvInsuranceFund() external view returns (address);
    function performanceReward() external view returns (address);
}

interface IYFVReferral {
    function setReferrer(address farmer, address referrer) external;
    function getReferrer(address farmer) external view returns (address);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract YFVGovernanceVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    IERC20 public yfv;
    IERC20 public value;
    IERC20 public vUSD;
    IERC20 public vETH;

    uint256 public fundCap = 9500;
    uint256 public constant FUND_CAP_DENOMINATOR = 10000;

    uint256 public earnLowerlimit;

    address public governance;
    address public controller;
    address public rewardReferral;

    struct Staker {
        uint256 stake;
        uint256 payout;
        uint256 total_out;
    }

    mapping(address => Staker) public stakers;

    struct Global {
        uint256 total_stake;
        uint256 total_out;
        uint256 earnings_per_share;
    }

    Global public global;
    uint256 constant internal magnitude = 10 ** 40;

    string public getName;

    uint256 public vETH_REWARD_FRACTION_RATE = 1000;

    uint256 public constant DURATION = 7 days;
    uint8 public constant NUMBER_EPOCHS = 36;

    uint256 public constant REFERRAL_COMMISSION_PERCENT = 1;

    uint256 public currentEpochReward = 0;
    uint256 public totalAccumulatedReward = 0;
    uint8 public currentEpoch = 0;
    uint256 public starttime = 1598968800;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public valueRewardRateMultipler = 0;
    bool public isOpened;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public constant DEFAULT_EPOCH_REWARD = 230000 * (10 ** 9);
    uint256 public constant TOTAL_REWARD = DEFAULT_EPOCH_REWARD * NUMBER_EPOCHS;
    uint256 public constant DEFAULT_VALUE_EPOCH_REWARD = 23000 * (10 ** 18);

    uint256 public epochReward = DEFAULT_EPOCH_REWARD;
    uint256 public valueEpochReward = DEFAULT_VALUE_EPOCH_REWARD;
    uint256 public minStakingAmount = 0 ether;
    uint256 public unstakingFrozenTime = 40 hours;
    uint256 public minStakeTimeToClaimVaultReward = 24 hours;


    uint256 public unlockWithdrawFee = 0;

    address public yfvInsuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastStakeTimes;

    mapping(address => uint256) public accumulatedStakingPower;

    event RewardAdded(uint256 reward);
    event YfvRewardAdded(uint256 reward);
    event Burned(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 actualStakeAmount);
    event Withdrawn(address indexed user, uint256 amount, uint256 actualWithdrawAmount);
    event RewardPaid(address indexed user, uint256 reward);
    event CommissionPaid(address indexed user, uint256 reward);

    constructor (address _yfv, address _value, address _vUSD, address _vETH, uint256 _earnLowerlimit) public {
        yfv = IERC20(_yfv);
        value = IERC20(_value);
        vUSD = IERC20(_vUSD);
        vETH = IERC20(_vETH);
        getName = string(abi.encodePacked("YFV:GovVault:v2"));
        earnLowerlimit = _earnLowerlimit * 1e18;
        governance = msg.sender;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function balance() public view returns (uint256) {
        uint256 bal = yfv.balanceOf(address(this));
        if (controller != address(0)) bal = bal.add(IController(controller).balanceOf(address(yfv)));
        return bal;
    }

    function setFundCap(uint256 _fundCap) external {
        require(msg.sender == governance, "!governance");
        fundCap = _fundCap;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setRewardReferral(address _rewardReferral) external {
        require(msg.sender == governance, "!governance");
        rewardReferral = _rewardReferral;
    }

    function setIsOpened(bool _isOpened) external {
        require(msg.sender == governance, "!governance");
        isOpened = _isOpened;
    }

    function setEarnLowerlimit(uint256 _earnLowerlimit) public {
        require(msg.sender == governance, "!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    function setYfvInsuranceFund(address _yfvInsuranceFund) public {
        require(msg.sender == governance, "!governance");
        yfvInsuranceFund = _yfvInsuranceFund;
    }

    function setEpochReward(uint256 _epochReward) public {
        require(msg.sender == governance, "!governance");
        require(_epochReward <= DEFAULT_EPOCH_REWARD * 10, "Insane big _epochReward!");
        epochReward = _epochReward;
    }

    function setValueEpochReward(uint256 _valueEpochReward) public {
        require(msg.sender == governance, "!governance");
        valueEpochReward = _valueEpochReward;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) public {
        require(msg.sender == governance, "!governance");
        minStakingAmount = _minStakingAmount;
    }

    function setUnstakingFrozenTime(uint256 _unstakingFrozenTime) public {
        require(msg.sender == governance, "!governance");
        unstakingFrozenTime = _unstakingFrozenTime;
    }

    function setUnlockWithdrawFee(uint256 _unlockWithdrawFee) public {
        require(msg.sender == governance, "!governance");
        require(_unlockWithdrawFee <= 1000, "Dont be too greedy");
        unlockWithdrawFee = _unlockWithdrawFee;
    }

    function setMinStakeTimeToClaimVaultReward(uint256 _minStakeTimeToClaimVaultReward) public {
        require(msg.sender == governance, "!governance");
        minStakeTimeToClaimVaultReward = _minStakeTimeToClaimVaultReward;
    }


    function upgradeVUSDContract(address _vUSDContract) public {
        require(msg.sender == governance, "!governance");
        vUSD = IERC20(_vUSDContract);
    }


    function upgradeVETHContract(address _vETHContract) public {
        require(msg.sender == governance, "!governance");
        vETH = IERC20(_vETHContract);
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

    function lastTimeRewardApplicable() public view returns (uint256) {
        if (block.timestamp < periodFinish) return block.timestamp;
        else return periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (global.total_stake == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(global.total_stake)
        );
    }


    function earned(address account) public view returns (uint256) {
        uint256 calculatedEarned = stakers[account].stake
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
        uint256 poolBalance = vUSD.balanceOf(address(this));

        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }

    function stakingPower(address account) public view returns (uint256) {
        return accumulatedStakingPower[account].add(earned(account));
    }

    function earnedVETH(address account) public view returns (uint256) {
        return earned(account).div(vETH_REWARD_FRACTION_RATE);
    }

    function earnedValue(address account) public view returns (uint256) {
        return earned(account).mul(valueRewardRateMultipler);
    }



    function available() public view returns (uint256) {
        return yfv.balanceOf(address(this)).mul(fundCap).div(FUND_CAP_DENOMINATOR);
    }

    function doHardWork() public discountCHI {
        if (controller != address(0)) {
            uint256 _amount = available();
            uint256 _accepted = IController(controller).maxAcceptAmount(address(yfv));
            if (_amount > _accepted) _amount = _accepted;
            if (_amount > 0) {
                yfv.safeTransfer(controller, _amount);
                IController(controller).doHardWork(address(yfv), _amount);
            }
        }
    }

    function stake(uint256 amount, address referrer) public discountCHI updateReward(msg.sender) checkNextEpoch {
        require(isOpened, "Pool is not opening to stake");
        yfv.safeTransferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].stake = stakers[msg.sender].stake.add(amount);

        require(stakers[msg.sender].stake > minStakingAmount, "Cannot stake below minStakingAmount");

        if (global.earnings_per_share != 0) {
            stakers[msg.sender].payout = stakers[msg.sender].payout.add(
                global.earnings_per_share.mul(amount).sub(1).div(magnitude).add(1)
            );
        }
        global.total_stake = global.total_stake.add(amount);


        if (yfv.balanceOf(address(this)) > earnLowerlimit) {
            doHardWork();
        }

        lastStakeTimes[msg.sender] = block.timestamp;
        if (rewardReferral != address(0) && referrer != address(0)) {
            IYFVReferral(rewardReferral).setReferrer(msg.sender, referrer);
        }
    }

    function unfrozenStakeTime(address account) public view returns (uint256) {
        return lastStakeTimes[account] + unstakingFrozenTime;
    }


    function withdraw(uint256 amount) public discountCHI updateReward(msg.sender) checkNextEpoch {
        require(amount > 0, "Cannot withdraw 0");
        claim();
        require(amount <= stakers[msg.sender].stake, "!balance");
        uint256 actualWithdrawAmount = amount;


        uint256 b = yfv.balanceOf(address(this));
        if (b < actualWithdrawAmount) {
            if (controller != address(0)) {
                uint256 _withdraw = actualWithdrawAmount.sub(b);
                IController(controller).withdraw(address(yfv), _withdraw);
                uint256 _after = yfv.balanceOf(address(this));
                uint256 _diff = _after.sub(b);
                if (_diff < _withdraw) {
                    actualWithdrawAmount = b.add(_diff);
                }
            } else {
                actualWithdrawAmount = b;
            }
        }

        stakers[msg.sender].payout = stakers[msg.sender].payout.sub(
            global.earnings_per_share.mul(amount).div(magnitude)
        );

        stakers[msg.sender].stake = stakers[msg.sender].stake.sub(amount);
        global.total_stake = global.total_stake.sub(amount);


        if (block.timestamp < unfrozenStakeTime(msg.sender)) {

            if (unlockWithdrawFee == 0) revert("Coin is still frozen");


            uint256 withdrawFee = amount.mul(unlockWithdrawFee).div(10000);
            uint256 r = amount.sub(withdrawFee);
            if (actualWithdrawAmount > r) {
                withdrawFee = actualWithdrawAmount.sub(r);
                actualWithdrawAmount = r;
                if (yfvInsuranceFund != address(0)) {
                    safeTokenTransfer(yfv, yfvInsuranceFund, withdrawFee);
                    emit RewardPaid(yfvInsuranceFund, withdrawFee);
                } else {
                    yfv.burn(withdrawFee);
                    emit Burned(withdrawFee);
                }
            }
        }

        safeTokenTransfer(yfv, msg.sender, actualWithdrawAmount);
        emit Withdrawn(msg.sender, amount, actualWithdrawAmount);
    }

    function make_profit(uint256 amount) public discountCHI {
        require(amount > 0, "not 0");
        value.safeTransferFrom(msg.sender, address(this), amount);
        global.earnings_per_share = global.earnings_per_share.add(
            amount.mul(magnitude).div(global.total_stake)
        );
        global.total_out = global.total_out.add(amount);

    }

    function cal_out(address user) public view returns (uint256) {
        uint256 _cal = global.earnings_per_share.mul(stakers[user].stake).div(magnitude);
        if (_cal < stakers[user].payout) {
            return 0;
        } else {
            return _cal.sub(stakers[user].payout);
        }
    }

    function cal_out_pending(uint256 _pendingBalance, address user) public view returns (uint256) {
        uint256 _earnings_per_share = global.earnings_per_share.add(
            _pendingBalance.mul(magnitude).div(global.total_stake)
        );
        uint256 _cal = _earnings_per_share.mul(stakers[user].stake).div(magnitude);
        _cal = _cal.sub(cal_out(user));
        if (_cal < stakers[user].payout) {
            return 0;
        } else {
            return _cal.sub(stakers[user].payout);
        }
    }

    function claim() public discountCHI {
        uint256 out = cal_out(msg.sender);
        stakers[msg.sender].payout = global.earnings_per_share.mul(stakers[msg.sender].stake).div(magnitude);
        stakers[msg.sender].total_out = stakers[msg.sender].total_out.add(out);

        if (out > 0) {
            uint256 _stakeTime = now - lastStakeTimes[msg.sender];
            if (controller != address(0) && _stakeTime < minStakeTimeToClaimVaultReward) {
                uint256 actually_out = _stakeTime.mul(out).mul(1e18).div(minStakeTimeToClaimVaultReward).div(1e18);
                uint256 to_team = out.sub(actually_out);
                safeTokenTransfer(value, IController(controller).performanceReward(), to_team);
                out = actually_out;
            }
            safeTokenTransfer(value, msg.sender, out);
        }
    }

    function exit() external discountCHI {
        withdraw(stakers[msg.sender].stake);
        getReward();
    }

    function getReward() public discountCHI updateReward(msg.sender) checkNextEpoch {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            accumulatedStakingPower[msg.sender] = accumulatedStakingPower[msg.sender].add(rewards[msg.sender]);
            rewards[msg.sender] = 0;

            safeTokenTransfer(vUSD, msg.sender, reward);
            safeTokenTransfer(vETH, msg.sender, reward.div(vETH_REWARD_FRACTION_RATE));
            emit RewardPaid(msg.sender, reward);

            uint256 valueReward = reward.mul(valueRewardRateMultipler);
            uint256 actualValuePaid = valueReward.mul(100 - REFERRAL_COMMISSION_PERCENT).div(100);
            uint256 valueCommission = valueReward - actualValuePaid;

            safeTokenTransfer(value, msg.sender, actualValuePaid);

            address referrer = address(0);
            if (rewardReferral != address(0)) {
                referrer = IYFVReferral(rewardReferral).getReferrer(msg.sender);
            }
            if (referrer != address(0)) {
                safeTokenTransfer(value, referrer, valueCommission);
            } else {
                safeTokenBurn(value, valueCommission);
                emit Burned(valueCommission);
            }
        }
    }

    modifier checkNextEpoch() {
        if (block.timestamp >= periodFinish) {
            currentEpochReward = epochReward;

            if (totalAccumulatedReward.add(currentEpochReward) > TOTAL_REWARD) {
                currentEpochReward = TOTAL_REWARD.sub(totalAccumulatedReward);
            }

            if (currentEpochReward > 0) {
                if (!vUSD.minters(address(this)) || !vETH.minters(address(this))) {
                    currentEpochReward = 0;
                } else {
                    vUSD.mint(address(this), currentEpochReward);
                    vETH.mint(address(this), currentEpochReward.div(vETH_REWARD_FRACTION_RATE));
                    totalAccumulatedReward = totalAccumulatedReward.add(currentEpochReward);
                }
                currentEpoch++;
            }

            rewardRate = currentEpochReward.div(DURATION);

            if (currentEpochReward > 0) {
                value.mint(address(this), valueEpochReward);
                valueRewardRateMultipler = valueEpochReward.div(currentEpochReward);
            } else {
                valueRewardRateMultipler = 0;
            }

            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(currentEpochReward);
        }
        _;
    }

    function addValueReward(uint256 _amount) external discountCHI {
        require(periodFinish > 0, "Pool has not started yet");
        uint256 remaining = periodFinish.sub(block.timestamp);
        require(remaining > 1 days, "Too little time to distribute. Wait for next epoch");
        value.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 leftover = remaining.mul(rewardRate);
        uint256 valueLeftover = leftover.mul(valueRewardRateMultipler);
        valueRewardRateMultipler = valueLeftover.add(_amount).div(leftover);
    }


    function safeTokenTransfer(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.safeTransfer(_to, bal);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }


    function safeTokenBurn(IERC20 _token, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.burn(bal);
        } else {
            _token.burn(_amount);
        }
    }


    function emergencyWithdraw() public discountCHI {
        require(block.timestamp >= unfrozenStakeTime(msg.sender), "Wait until coin unfrozen");
        uint256 amount = stakers[msg.sender].stake;
        uint256 b = yfv.balanceOf(address(this));
        if (b < amount) amount = b;
        stakers[msg.sender].payout = stakers[msg.sender].payout.sub(
            global.earnings_per_share.mul(amount).div(magnitude)
        );
        stakers[msg.sender].stake = stakers[msg.sender].stake.sub(amount);
        global.total_stake = global.total_stake.sub(amount);
        safeTokenTransfer(yfv, msg.sender, amount);
        emit Withdrawn(msg.sender, amount, amount);
    }





    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");


        require(_token != yfv || global.total_stake.add(amount) <= yfv.balanceOf(address(this)), "cant withdraw more than stuck YFV");


        _token.safeTransfer(to, amount);
    }
}
