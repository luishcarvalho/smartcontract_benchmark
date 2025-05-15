





pragma solidity 0.5.17;


library Math {

    function MAX311(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function MIN896(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function AVERAGE467(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}



pragma solidity 0.5.17;


library SafeMath {

    function ADD124(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB912(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB912(a, b, "SafeMath: subtraction overflow");
    }


    function SUB912(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL612(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV645(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV645(a, b, "SafeMath: division by zero");
    }


    function DIV645(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD528(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD528(a, b, "SafeMath: modulo by zero");
    }


    function MOD528(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity 0.5.17;


contract Context {


    constructor () internal {}


    function _MSGSENDER219() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA337() internal view returns (bytes memory) {
        this;

        return msg.data;
    }
}



pragma solidity 0.5.17;


contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED705(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = _MSGSENDER219();
        emit OWNERSHIPTRANSFERRED705(address(0), _owner);
    }


    function OWNER858() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER527() {
        require(ISOWNER429(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER429() public view returns (bool) {
        return _MSGSENDER219() == _owner;
    }


    function RENOUNCEOWNERSHIP633() public ONLYOWNER527 {
        emit OWNERSHIPTRANSFERRED705(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP10(address newOwner) public ONLYOWNER527 {
        _TRANSFEROWNERSHIP120(newOwner);
    }


    function _TRANSFEROWNERSHIP120(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED705(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity 0.5.17;


interface IERC20 {

    function TOTALSUPPLY2() external view returns (uint256);


    function BALANCEOF265(address account) external view returns (uint256);


    function TRANSFER164(address recipient, uint256 amount) external returns (bool);

    function MINT263(address account, uint amount) external;

    function BURN805(uint amount) external;


    function ALLOWANCE538(address owner, address spender) external view returns (uint256);


    function APPROVE42(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM15(address sender, address recipient, uint256 amount) external returns (bool);


    function MINTERS951(address account) external view returns (bool);


    event TRANSFER380(address indexed from, address indexed to, uint256 value);


    event APPROVAL481(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity 0.5.17;


library Address {

    function ISCONTRACT794(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }


    function TOPAYABLE864(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function SENDVALUE732(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}



pragma solidity 0.5.17;





library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER450(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN337(token, abi.encodeWithSelector(token.TRANSFER164.selector, to, value));
    }

    function SAFETRANSFERFROM145(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN337(token, abi.encodeWithSelector(token.TRANSFERFROM15.selector, from, to, value));
    }

    function SAFEAPPROVE302(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE538(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN337(token, abi.encodeWithSelector(token.APPROVE42.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE445(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE538(address(this), spender).ADD124(value);
        CALLOPTIONALRETURN337(token, abi.encodeWithSelector(token.APPROVE42.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE172(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE538(address(this), spender).SUB912(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN337(token, abi.encodeWithSelector(token.APPROVE42.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN337(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT794(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



pragma solidity 0.5.17;


contract IRewardDistributionRecipient is Ownable {
    address public rewardReferral;

    function NOTIFYREWARDAMOUNT832(uint256 reward) external;

    function SETREWARDREFERRAL334(address _rewardReferral) external ONLYOWNER527 {
        rewardReferral = _rewardReferral;
    }
}



pragma solidity 0.5.17;


contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public yfv = IERC20(0x45f24BaEef268BB6d63AEe5129015d69702BCDfa);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function TOTALSUPPLY2() public view returns (uint256) {
        return _totalSupply;
    }

    function BALANCEOF265(address account) public view returns (uint256) {
        return _balances[account];
    }

    function TOKENSTAKE952(uint256 amount, uint256 actualStakeAmount) internal {
        _totalSupply = _totalSupply.ADD124(actualStakeAmount);
        _balances[msg.sender] = _balances[msg.sender].ADD124(actualStakeAmount);
        yfv.SAFETRANSFERFROM145(msg.sender, address(this), amount);
    }

    function TOKENSTAKEONBEHALF333(address stakeFor, uint256 amount, uint256 actualStakeAmount) internal {
        _totalSupply = _totalSupply.ADD124(actualStakeAmount);
        _balances[stakeFor] = _balances[stakeFor].ADD124(actualStakeAmount);
        yfv.SAFETRANSFERFROM145(msg.sender, address(this), amount);
    }

    function TOKENWITHDRAW537(uint256 amount, uint256 actualWithdrawAmount) internal {
        _totalSupply = _totalSupply.SUB912(amount);
        _balances[msg.sender] = _balances[msg.sender].SUB912(amount);
        yfv.SAFETRANSFER450(msg.sender, actualWithdrawAmount);
    }
}

interface IYFVReferral {
    function SETREFERRER414(address farmer, address referrer) external;
    function GETREFERRER855(address farmer) external view returns (address);
}

contract YFVStakeV2 is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public vUSD = IERC20(0x1B8E12F839BD4e73A47adDF76cF7F0097d74c14C);
    IERC20 public vETH = IERC20(0x76A034e76Aa835363056dd418611E4f81870f16e);

    uint256 public vETH_REWARD_FRACTION_RATE = 1000;

    uint256 public constant duration178 = 7 days;
    uint8 public constant number_epochs944 = 38;

    uint256 public constant referral_commission_percent277 = 1;

    uint256 public currentEpochReward = 0;
    uint256 public totalAccumulatedReward = 0;
    uint8 public currentEpoch = 0;
    uint256 public starttime = 1598968800;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public constant default_epoch_reward278 = 230000 * (10 ** 9);
    uint256 public constant total_reward44 = default_epoch_reward278 * number_epochs944;

    uint256 public epochReward = default_epoch_reward278;
    uint256 public minStakingAmount = 90 ether;
    uint256 public unstakingFrozenTime = 40 hours;






    uint256 public lowStakeDepositFee = 0;
    uint256 public highStakeDepositFee = 0;
    uint256 public unlockWithdrawFee = 0;

    address public yfvInsuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastStakeTimes;

    mapping(address => uint256) public accumulatedStakingPower;

    mapping(address => bool) public whitelistedPools;

    event REWARDADDED885(uint256 reward);
    event YFVREWARDADDED261(uint256 reward);
    event BURNED28(uint256 reward);
    event STAKED939(address indexed user, uint256 amount, uint256 actualStakeAmount);
    event WITHDRAWN649(address indexed user, uint256 amount, uint256 actualWithdrawAmount);
    event REWARDPAID896(address indexed user, uint256 reward);
    event COMMISSIONPAID234(address indexed user, uint256 reward);

    constructor() public {
        whitelistedPools[0x62a9fE913eb596C8faC0936fd2F51064022ba22e] = true;
        whitelistedPools[0x70b83A7f5E83B3698d136887253E0bf426C9A117] = true;
        whitelistedPools[0x1c990fC37F399C935625b815975D0c9fAD5C31A1] = true;
        whitelistedPools[0x752037bfEf024Bd2669227BF9068cb22840174B0] = true;
        whitelistedPools[0x9b74774f55C0351fD064CfdfFd35dB002C433092] = true;
        whitelistedPools[0xFBDE07329FFc9Ec1b70f639ad388B94532b5E063] = true;
        whitelistedPools[0x67FfB615EAEb8aA88fF37cCa6A32e322286a42bb] = true;
        whitelistedPools[0x196CF719251579cBc850dED0e47e972b3d7810Cd] = true;
        whitelistedPools[msg.sender] = true;
    }

    function ADDWHITELISTEDPOOL116(address _addressPool) public ONLYOWNER527 {
        whitelistedPools[_addressPool] = true;
    }

    function REMOVEWHITELISTEDPOOL972(address _addressPool) public ONLYOWNER527 {
        whitelistedPools[_addressPool] = false;
    }

    function SETYFVINSURANCEFUND27(address _yfvInsuranceFund) public ONLYOWNER527 {
        yfvInsuranceFund = _yfvInsuranceFund;
    }

    function SETEPOCHREWARD899(uint256 _epochReward) public ONLYOWNER527 {
        require(_epochReward <= default_epoch_reward278 * 10, "Insane big _epochReward!");
        epochReward = _epochReward;
    }

    function SETMINSTAKINGAMOUNT151(uint256 _minStakingAmount) public ONLYOWNER527 {
        minStakingAmount = _minStakingAmount;
    }

    function SETUNSTAKINGFROZENTIME482(uint256 _unstakingFrozenTime) public ONLYOWNER527 {
        unstakingFrozenTime = _unstakingFrozenTime;
    }

    function SETSTAKEDEPOSITFEE451(uint256 _lowStakeDepositFee, uint256 _highStakeDepositFee) public ONLYOWNER527 {
        require(_lowStakeDepositFee <= 100 || _lowStakeDepositFee == 10000, "Dont be too greedy");
        require(_highStakeDepositFee <= 100, "Dont be too greedy");
        lowStakeDepositFee = _lowStakeDepositFee;
        highStakeDepositFee = _highStakeDepositFee;
    }

    function SETUNLOCKWITHDRAWFEE126(uint256 _unlockWithdrawFee) public ONLYOWNER527 {
        require(_unlockWithdrawFee <= 1000, "Dont be too greedy");
        unlockWithdrawFee = _unlockWithdrawFee;
    }


    function UPGRADEVUSDCONTRACT293(address _vUSDContract) public ONLYOWNER527 {
        vUSD = IERC20(_vUSDContract);
    }


    function UPGRADEVETHCONTRACT116(address _vETHContract) public ONLYOWNER527 {
        vETH = IERC20(_vETHContract);
    }

    modifier UPDATEREWARD641(address account) {
        rewardPerTokenStored = REWARDPERTOKEN11();
        lastUpdateTime = LASTTIMEREWARDAPPLICABLE544();
        if (account != address(0)) {
            rewards[account] = EARNED432(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function LASTTIMEREWARDAPPLICABLE544() public view returns (uint256) {
        return Math.MIN896(block.timestamp, periodFinish);
    }

    function REWARDPERTOKEN11() public view returns (uint256) {
        if (TOTALSUPPLY2() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.ADD124(
            LASTTIMEREWARDAPPLICABLE544()
            .SUB912(lastUpdateTime)
            .MUL612(rewardRate)
            .MUL612(1e18)
            .DIV645(TOTALSUPPLY2())
        );
    }


    function EARNED432(address account) public view returns (uint256) {
        uint256 calculatedEarned = BALANCEOF265(account)
        .MUL612(REWARDPERTOKEN11().SUB912(userRewardPerTokenPaid[account]))
        .DIV645(1e18)
        .ADD124(rewards[account]);
        uint256 poolBalance = vUSD.BALANCEOF265(address(this));

        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }

    function STAKINGPOWER96(address account) public view returns (uint256) {
        return accumulatedStakingPower[account].ADD124(EARNED432(account));
    }

    function VETHBALANCE317(address account) public view returns (uint256) {
        return EARNED432(account).DIV645(vETH_REWARD_FRACTION_RATE);
    }

    function STAKE230(uint256 amount, address referrer) public UPDATEREWARD641(msg.sender) CHECKNEXTEPOCH825 {
        require(amount >= 1 szabo, "Do not stake dust");
        require(referrer != msg.sender, "You cannot refer yourself.");
        uint256 actualStakeAmount = amount;
        uint256 depositFee = 0;
        if (minStakingAmount > 0) {
            if (amount < minStakingAmount && lowStakeDepositFee < 10000) {



                if (lowStakeDepositFee == 0) require(amount >= minStakingAmount, "Cannot stake below minStakingAmount");

                else depositFee = amount.MUL612(lowStakeDepositFee).DIV645(10000);
            } else if (amount > minStakingAmount && highStakeDepositFee > 0) {

                depositFee = amount.SUB912(minStakingAmount).MUL612(highStakeDepositFee).DIV645(10000);
            }
            if (depositFee > 0) {
                actualStakeAmount = amount.SUB912(depositFee);
            }
        }
        super.TOKENSTAKE952(amount, actualStakeAmount);
        lastStakeTimes[msg.sender] = block.timestamp;
        emit STAKED939(msg.sender, amount, actualStakeAmount);
        if (depositFee > 0) {
            if (yfvInsuranceFund != address(0)) {
                yfv.SAFETRANSFER450(yfvInsuranceFund, depositFee);
                emit REWARDPAID896(yfvInsuranceFund, depositFee);
            } else {
                yfv.BURN805(depositFee);
                emit BURNED28(depositFee);
            }
        }
        if (rewardReferral != address(0) && referrer != address(0)) {
            IYFVReferral(rewardReferral).SETREFERRER414(msg.sender, referrer);
        }
    }

    function STAKEONBEHALF204(address stakeFor, uint256 amount) public UPDATEREWARD641(stakeFor) CHECKNEXTEPOCH825 {
        require(amount >= 1 szabo, "Do not stake dust");
        require(whitelistedPools[msg.sender], "Sorry hackers, you should stay away from us (YFV community signed)");
        uint256 actualStakeAmount = amount;
        uint256 depositFee = 0;
        if (minStakingAmount > 0) {
            if (amount < minStakingAmount && lowStakeDepositFee < 10000) {



                if (lowStakeDepositFee == 0) require(amount >= minStakingAmount, "Cannot stake below minStakingAmount");


                else depositFee = amount.MUL612(lowStakeDepositFee).DIV645(10000);
            } else if (amount > minStakingAmount && highStakeDepositFee > 0) {

                depositFee = amount.SUB912(minStakingAmount).MUL612(highStakeDepositFee).DIV645(10000);
            }
            if (depositFee > 0) {
                actualStakeAmount = amount.SUB912(depositFee);
            }
        }
        super.TOKENSTAKEONBEHALF333(stakeFor, amount, actualStakeAmount);
        lastStakeTimes[stakeFor] = block.timestamp;
        emit STAKED939(stakeFor, amount, actualStakeAmount);
        if (depositFee > 0) {
            actualStakeAmount = amount.SUB912(depositFee);
            if (yfvInsuranceFund != address(0)) {
                yfv.SAFETRANSFER450(yfvInsuranceFund, depositFee);
                emit REWARDPAID896(yfvInsuranceFund, depositFee);
            } else {
                yfv.BURN805(depositFee);
                emit BURNED28(depositFee);
            }
        }
    }

    function UNFROZENSTAKETIME568(address account) public view returns (uint256) {
        return lastStakeTimes[account] + unstakingFrozenTime;
    }

    function WITHDRAW21(uint256 amount) public UPDATEREWARD641(msg.sender) CHECKNEXTEPOCH825 {
        require(amount > 0, "Cannot withdraw 0");
        uint256 actualWithdrawAmount = amount;
        if (block.timestamp < UNFROZENSTAKETIME568(msg.sender)) {

            if (unlockWithdrawFee == 0) revert("Coin is still frozen");


            uint256 withdrawFee = amount.MUL612(unlockWithdrawFee).DIV645(10000);
            actualWithdrawAmount = amount.SUB912(withdrawFee);
            if (yfvInsuranceFund != address(0)) {
                yfv.SAFETRANSFER450(yfvInsuranceFund, withdrawFee);
                emit REWARDPAID896(yfvInsuranceFund, withdrawFee);
            } else {
                yfv.BURN805(withdrawFee);
                emit BURNED28(withdrawFee);
            }
        }
        super.TOKENWITHDRAW537(amount, actualWithdrawAmount);
        emit WITHDRAWN649(msg.sender, amount, actualWithdrawAmount);
    }

    function EXIT848() external {
        WITHDRAW21(BALANCEOF265(msg.sender));
        GETREWARD938();
    }

    function GETREWARD938() public UPDATEREWARD641(msg.sender) CHECKNEXTEPOCH825 {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            accumulatedStakingPower[msg.sender] = accumulatedStakingPower[msg.sender].ADD124(rewards[msg.sender]);
            rewards[msg.sender] = 0;

            vUSD.SAFETRANSFER450(msg.sender, reward);
            vETH.SAFETRANSFER450(msg.sender, reward.DIV645(vETH_REWARD_FRACTION_RATE));

            emit REWARDPAID896(msg.sender, reward);
        }
    }

    modifier CHECKNEXTEPOCH825() {
        require(periodFinish > 0, "Pool has not started");
        if (block.timestamp >= periodFinish) {
            currentEpochReward = epochReward;

            if (totalAccumulatedReward.ADD124(currentEpochReward) > total_reward44) {
                currentEpochReward = total_reward44.SUB912(totalAccumulatedReward);
            }

            if (currentEpochReward > 0) {
                if (!vUSD.MINTERS951(address(this)) || !vETH.MINTERS951(address(this))) {
                    currentEpochReward = 0;
                } else {
                    vUSD.MINT263(address(this), currentEpochReward);
                    vETH.MINT263(address(this), currentEpochReward.DIV645(vETH_REWARD_FRACTION_RATE));
                    totalAccumulatedReward = totalAccumulatedReward.ADD124(currentEpochReward);
                }
                currentEpoch++;
            }

            rewardRate = currentEpochReward.DIV645(duration178);
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.ADD124(duration178);
            emit REWARDADDED885(currentEpochReward);
        }
        _;
    }


    function NOTIFYREWARDAMOUNT832(uint256 reward) external ONLYOWNER527 UPDATEREWARD641(address(0)) {
        require(periodFinish == 0, "Only can call once to start staking");
        currentEpochReward = reward;
        if (totalAccumulatedReward.ADD124(currentEpochReward) > total_reward44) {
            currentEpochReward = total_reward44.SUB912(totalAccumulatedReward);
        }
        lastUpdateTime = block.timestamp;
        if (block.timestamp < starttime) {
            periodFinish = starttime;
            rewardRate = reward.DIV645(periodFinish.SUB912(block.timestamp));
        } else {
            periodFinish = lastUpdateTime.ADD124(duration178);
            rewardRate = reward.DIV645(duration178);
            currentEpoch++;
        }
        vUSD.MINT263(address(this), reward);
        vETH.MINT263(address(this), reward.DIV645(vETH_REWARD_FRACTION_RATE));
        totalAccumulatedReward = totalAccumulatedReward.ADD124(reward);
        emit REWARDADDED885(reward);
    }





    function GOVERNANCERECOVERUNSUPPORTED727(IERC20 _token, uint256 amount, address to) external {

        require(msg.sender == OWNER858(), "!governance");

        require(_token != yfv, "yfv");

        require(_token != vUSD, "vUSD");
        require(_token != vETH, "vETH");


        _token.SAFETRANSFER450(to, amount);
    }
}
