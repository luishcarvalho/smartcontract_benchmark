





pragma solidity 0.6.12;






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




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}












library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



interface IStrategy {
    function approve(IERC20 _token) external;

    function approveForSpender(IERC20 _token, address spender) external;


    function deposit(address _vault, uint256 _amount) external;


    function claim(address _vault) external;


    function harvest(uint256 _bankPoolId) external;


    function withdraw(address _vault, uint256 _amount) external;


    function getTargetToken() external view returns(address);

    function balanceOf(address _vault) external view returns (uint256);

    function pendingReward(address _vault) external view returns (uint256);

    function expectedAPY(address _vault) external view returns (uint256);

    function governanceRescueToken(IERC20 _token) external returns (uint256);
}



interface IValueVaultMaster {
    function minorPool() view external returns(address);
    function performanceReward() view external returns(address);
    function minStakeTimeToClaimVaultReward() view external returns(uint256);
}

interface IValueVault {
    function balanceOf(address account) view external returns(uint256);
    function getStrategyCount() external view returns(uint256);
    function depositAvailable() external view returns(bool);
    function strategies(uint256 _index) view external returns(IStrategy);
    function mintByBank(IERC20 _token, address _to, uint256 _amount) external;
    function burnByBank(IERC20 _token, address _account, uint256 _amount) external;
    function harvestAllStrategies(uint256 _bankPoolId) external;
    function harvestStrategy(IStrategy _strategy, uint256 _bankPoolId) external;
}

interface IValueMinorPool {
    function depositOnBehalf(address farmer, uint256 _pid, uint256 _amount, address _referrer) external;
    function withdrawOnBehalf(address farmer, uint256 _pid, uint256 _amount) external;
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract ValueVaultBank {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    address public governance;
    IValueVaultMaster public vaultMaster;


    struct PoolInfo {
        IERC20 token;
        IValueVault vault;
        uint256 minorPoolId;
        uint256 startTime;
        uint256 individualCap;
        uint256 totalCap;
    }


    mapping(uint256 => PoolInfo) public poolMap;

    struct Staker {
        uint256 stake;
        uint256 payout;
        uint256 total_out;
    }

    mapping(uint256 => mapping(address => Staker)) public stakers;

    struct Global {
        uint256 total_stake;
        uint256 total_out;
        uint256 earnings_per_share;
    }

    mapping(uint256 => Global) public global;

    mapping(uint256 => mapping(address => uint256)) public lastStakeTimes;
    uint256 constant internal magnitude = 10 ** 40;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event Claim(address indexed user, uint256 indexed poolId);

    constructor() public {
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVaultMaster(IValueVaultMaster _vaultMaster) external {
        require(msg.sender == governance, "!governance");
        vaultMaster = _vaultMaster;
    }

    function setPoolInfo(uint256 _poolId, IERC20 _token, IValueVault _vault, uint256 _minorPoolId, uint256 _startTime, uint256 _individualCap, uint256 _totalCap) public {
        require(msg.sender == governance, "!governance");
        poolMap[_poolId].token = _token;
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].minorPoolId = _minorPoolId;
        poolMap[_poolId].startTime = _startTime;
        poolMap[_poolId].individualCap = _individualCap;
        poolMap[_poolId].totalCap = _totalCap;
    }

    function setPoolCap(uint256 _poolId, uint256 _individualCap, uint256 _totalCap) public {
        require(msg.sender == governance, "!governance");
        require(_totalCap == 0 || _totalCap >= _individualCap, "_totalCap < _individualCap");
        poolMap[_poolId].individualCap = _individualCap;
        poolMap[_poolId].totalCap = _totalCap;
    }

    function depositAvailable(uint256 _poolId) external view returns(bool) {
        return poolMap[_poolId].vault.depositAvailable();
    }


    function deposit(uint256 _poolId, uint256 _amount, bool _farmMinorPool, address _referrer) public discountCHI {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "deposit: after startTime");
        require(_amount > 0, "!_amount");
        require(address(pool.vault) != address(0), "pool.vault = 0");
        require(pool.individualCap == 0 || stakers[_poolId][msg.sender].stake.add(_amount) <= pool.individualCap, "Exceed pool.individualCap");
        require(pool.totalCap == 0 || global[_poolId].total_stake.add(_amount) <= pool.totalCap, "Exceed pool.totalCap");

        pool.token.safeTransferFrom(msg.sender, address(pool.vault), _amount);
        pool.vault.mintByBank(pool.token, msg.sender, _amount);
        if (_farmMinorPool && address(vaultMaster) != address(0)) {
            address minorPool = vaultMaster.minorPool();
            if (minorPool != address(0)) {
                IValueMinorPool(minorPool).depositOnBehalf(msg.sender, pool.minorPoolId, pool.vault.balanceOf(msg.sender), _referrer);
            }
        }

        _handleDepositStakeInfo(_poolId, _amount);
        emit Deposit(msg.sender, _poolId, _amount);
    }

    function _handleDepositStakeInfo(uint256 _poolId, uint256 _amount) internal {
        stakers[_poolId][msg.sender].stake = stakers[_poolId][msg.sender].stake.add(_amount);
        if (global[_poolId].earnings_per_share != 0) {
            stakers[_poolId][msg.sender].payout = stakers[_poolId][msg.sender].payout.add(
                global[_poolId].earnings_per_share.mul(_amount).sub(1).div(magnitude).add(1)
            );
        }
        global[_poolId].total_stake = global[_poolId].total_stake.add(_amount);
        lastStakeTimes[_poolId][msg.sender] = block.timestamp;
    }


    function withdraw(uint256 _poolId, uint256 _amount, bool _farmMinorPool) public discountCHI {
        PoolInfo storage pool = poolMap[_poolId];
        require(address(pool.vault) != address(0), "pool.vault = 0");
        require(now >= pool.startTime, "withdraw: after startTime");
        require(_amount <= stakers[_poolId][msg.sender].stake, "!balance");

        claimProfit(_poolId);

        if (_farmMinorPool && address(vaultMaster) != address(0)) {
            address minorPool = vaultMaster.minorPool();
            if (minorPool != address(0)) {
                IValueMinorPool(minorPool).withdrawOnBehalf(msg.sender, pool.minorPoolId, _amount);
            }
        }
        pool.vault.burnByBank(pool.token, msg.sender, _amount);
        pool.token.safeTransfer(msg.sender, _amount);

        _handleWithdrawStakeInfo(_poolId, _amount);
        emit Withdraw(msg.sender, _poolId, _amount);
    }

    function _handleWithdrawStakeInfo(uint256 _poolId, uint256 _amount) internal {
        stakers[_poolId][msg.sender].payout = stakers[_poolId][msg.sender].payout.sub(
            global[_poolId].earnings_per_share.mul(_amount).div(magnitude)
        );
        stakers[_poolId][msg.sender].stake = stakers[_poolId][msg.sender].stake.sub(_amount);
        global[_poolId].total_stake = global[_poolId].total_stake.sub(_amount);
    }

    function exit(uint256 _poolId, bool _farmMinorPool) external discountCHI {
        withdraw(_poolId, stakers[_poolId][msg.sender].stake, _farmMinorPool);
    }


    function emergencyWithdraw(uint256 _poolId) public {
        uint256 amount = stakers[_poolId][msg.sender].stake;
        poolMap[_poolId].token.safeTransfer(address(msg.sender), amount);
        stakers[_poolId][msg.sender].stake = 0;
        global[_poolId].total_stake = global[_poolId].total_stake.sub(amount);
    }

    function harvestVault(uint256 _poolId) external discountCHI {
        poolMap[_poolId].vault.harvestAllStrategies(_poolId);
    }

    function harvestStrategy(uint256 _poolId, IStrategy _strategy) external discountCHI {
        poolMap[_poolId].vault.harvestStrategy(_strategy, _poolId);
    }

    function make_profit(uint256 _poolId, uint256 _amount) public {
        require(_amount > 0, "not 0");
        PoolInfo storage pool = poolMap[_poolId];
        pool.token.safeTransferFrom(msg.sender, address(this), _amount);
        if (global[_poolId].total_stake > 0) {
            global[_poolId].earnings_per_share = global[_poolId].earnings_per_share.add(
                _amount.mul(magnitude).div(global[_poolId].total_stake)
            );
        }
        global[_poolId].total_out = global[_poolId].total_out.add(_amount);

    }

    function cal_out(uint256 _poolId, address user) public view returns (uint256) {
        uint256 _cal = global[_poolId].earnings_per_share.mul(stakers[_poolId][user].stake).div(magnitude);
        if (_cal < stakers[_poolId][user].payout) {
            return 0;
        } else {
            return _cal.sub(stakers[_poolId][user].payout);
        }
    }

    function cal_out_pending(uint256 _pendingBalance, uint256 _poolId, address user) public view returns (uint256) {
        uint256 _earnings_per_share = global[_poolId].earnings_per_share.add(
            _pendingBalance.mul(magnitude).div(global[_poolId].total_stake)
        );
        uint256 _cal = _earnings_per_share.mul(stakers[_poolId][user].stake).div(magnitude);
        _cal = _cal.sub(cal_out(_poolId, user));
        if (_cal < stakers[_poolId][user].payout) {
            return 0;
        } else {
            return _cal.sub(stakers[_poolId][user].payout);
        }
    }

    function claimProfit(uint256 _poolId) public discountCHI {
        uint256 out = cal_out(_poolId, msg.sender);
        stakers[_poolId][msg.sender].payout = global[_poolId].earnings_per_share.mul(stakers[_poolId][msg.sender].stake).div(magnitude);
        stakers[_poolId][msg.sender].total_out = stakers[_poolId][msg.sender].total_out.add(out);

        if (out > 0) {
            PoolInfo storage pool = poolMap[_poolId];
            uint256 _stakeTime = now - lastStakeTimes[_poolId][msg.sender];
            if (address(vaultMaster) != address(0) && _stakeTime < vaultMaster.minStakeTimeToClaimVaultReward()) {
                uint256 actually_out = _stakeTime.mul(out).mul(1e18).div(vaultMaster.minStakeTimeToClaimVaultReward()).div(1e18);
                uint256 earlyClaimCost = out.sub(actually_out);
                safeTokenTransfer(pool.token, vaultMaster.performanceReward(), earlyClaimCost);
                out = actually_out;
            }
            safeTokenTransfer(pool.token, msg.sender, out);
        }
    }


    function safeTokenTransfer(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.safeTransfer(_to, bal);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }




    function governanceRescueFromStrategy(IERC20 _token, IStrategy _strategy) external {
        require(msg.sender == governance, "!governance");
        _strategy.governanceRescueToken(_token);
    }







    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.safeTransfer(to, amount);
    }
}
