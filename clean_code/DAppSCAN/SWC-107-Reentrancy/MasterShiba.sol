
pragma solidity 0.6.12;

import "./libs/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "./libs/Ownable.sol";

import "./ShibaBonusAggregator.sol";
import "./libs/ShibaBEP20.sol";



contract MasterShiba is Ownable, IMasterBonus {
    using SafeMath for uint256;
    using SafeBEP20 for ShibaBEP20;
    using SafeBEP20 for IBEP20;


    struct UserInfo {
        uint256 amount;
        uint256 amountWithBonus;
        uint256 rewardDebt;











    }


    struct PoolInfo {
        IBEP20 lpToken;
        uint256 lpSupply;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accNovaPerShare;
        uint256 depositFeeBP;
        bool isSNovaRewards;
    }

    ShibaBonusAggregator public bonusAggregator;

    ShibaBEP20 public Nova;

    ShibaBEP20 public sNova;

    address public devaddr;

    uint256 public NovaPerBlock;

    address public feeAddress;


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public immutable startBlock;


    uint256 public immutable initialEmissionRate;

    uint256 public minimumEmissionRate = 500 finney;

    uint256 public immutable emissionReductionPeriodBlocks = 14400;

    uint256 public immutable emissionReductionRatePerPeriod = 200;

    uint256 public lastReductionPeriodIndex = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);

    constructor(
        ShibaBEP20 _Nova,
        ShibaBEP20 _sNova,
        ShibaBonusAggregator _bonusAggregator,
        address _devaddr,
        address _feeAddress,
        uint256 _NovaPerBlock,
        uint256 _startBlock
    ) public {
        Nova = _Nova;
        sNova = _sNova;
        bonusAggregator = _bonusAggregator;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        NovaPerBlock = _NovaPerBlock;
        startBlock = _startBlock;
        initialEmissionRate = _NovaPerBlock;


        poolInfo.push(PoolInfo({
            lpToken: _Nova,
            lpSupply: 0,
            allocPoint: 800,
            lastRewardBlock: _startBlock,
            accNovaPerShare: 0,
            depositFeeBP: 0,
            isSNovaRewards: false
        }));
        totalAllocPoint = 800;
    }

    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePool: pool exists?");
        _;
    }

    modifier onlyAggregator() {
        require(msg.sender == address(bonusAggregator), "Ownable: caller is not the owner");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function userBonus(uint256 _pid, address _user) public view returns (uint256){
        return bonusAggregator.getBonusOnFarmsForUser(_user, _pid);
    }


    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }


    function add(uint256 _allocPoint, IBEP20 _lpToken, uint256 _depositFeeBP, bool _isSNovaRewards, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lpSupply: 0,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accNovaPerShare: 0,
            depositFeeBP : _depositFeeBP,
            isSNovaRewards: _isSNovaRewards
        }));
    }


    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFeeBP, bool _isSNovaRewards, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].isSNovaRewards = _isSNovaRewards;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }


    function pendingNova(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNovaPerShare = pool.accNovaPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 NovaReward = multiplier.mul(NovaPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accNovaPerShare = accNovaPerShare.add(NovaReward.mul(1e12).div(lpSupply));
        }
        uint256 userRewards = user.amountWithBonus.mul(accNovaPerShare).div(1e12).sub(user.rewardDebt);
        if(!pool.isSNovaRewards){

            userRewards = userRewards.mul(98).div(100);
        }
        return userRewards;
    }


    function updateEmissionRate() internal {
        if(startBlock > 0 && block.number <= startBlock){
            return;
        }
        if(NovaPerBlock <= minimumEmissionRate){
            return;
        }

        uint256 currentIndex = block.number.sub(startBlock).div(emissionReductionPeriodBlocks);
        if (currentIndex <= lastReductionPeriodIndex) {
            return;
        }

        uint256 newEmissionRate = NovaPerBlock;
        for (uint256 index = lastReductionPeriodIndex; index < currentIndex; ++index) {
            newEmissionRate = newEmissionRate.mul(1e4 - emissionReductionRatePerPeriod).div(1e4);
        }

        newEmissionRate = newEmissionRate < minimumEmissionRate ? minimumEmissionRate : newEmissionRate;
        if (newEmissionRate >= NovaPerBlock) {
            return;
        }

        lastReductionPeriodIndex = currentIndex;
        uint256 previousEmissionRate = NovaPerBlock;
        NovaPerBlock = newEmissionRate;
        emit EmissionRateUpdated(msg.sender, previousEmissionRate, newEmissionRate);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public validatePool(_pid) {
        updateEmissionRate();
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 NovaReward = multiplier.mul(NovaPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 devMintAmount = NovaReward.div(10);
        Nova.mint(devaddr, devMintAmount);
        if (pool.isSNovaRewards){
            sNova.mint(address(this), NovaReward);
        }
        else{
            Nova.mint(address(this), NovaReward);
        }
        pool.accNovaPerShare = pool.accNovaPerShare.add(NovaReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }


    function updateUserBonus(address _user, uint256 _pid, uint256 bonus) external virtual override validatePool(_pid) onlyAggregator{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amountWithBonus.mul(pool.accNovaPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if(pool.isSNovaRewards){
                    safeSNovaTransfer(_user, pending);
                }
                else{
                    safeNovaTransfer(_user, pending);
                }
            }
        }
        pool.lpSupply = pool.lpSupply.sub(user.amountWithBonus);
        user.amountWithBonus =  user.amount.mul(bonus.add(10000)).div(10000);
        pool.lpSupply = pool.lpSupply.add(user.amountWithBonus);
        user.rewardDebt = user.amountWithBonus.mul(pool.accNovaPerShare).div(1e12);
    }


    function deposit(uint256 _pid, uint256 _amount) external validatePool(_pid) {
        address _user = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amountWithBonus.mul(pool.accNovaPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if(pool.isSNovaRewards){
                    safeSNovaTransfer(_user, pending);
                }
                else{
                    safeNovaTransfer(_user, pending);
                }
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(_user), address(this), _amount);
            if (address(pool.lpToken) == address(Nova)) {
                uint256 transferTax = _amount.mul(2).div(100);
                _amount = _amount.sub(transferTax);
            }
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                uint256 _bonusAmount = _amount.sub(depositFee).mul(userBonus(_pid, _user).add(10000)).div(10000);
                user.amountWithBonus = user.amountWithBonus.add(_bonusAmount);
                pool.lpSupply = pool.lpSupply.add(_bonusAmount);
            } else {
                user.amount = user.amount.add(_amount);
                uint256 _bonusAmount = _amount.mul(userBonus(_pid, _user).add(10000)).div(10000);
                user.amountWithBonus = user.amountWithBonus.add(_bonusAmount);
                pool.lpSupply = pool.lpSupply.add(_bonusAmount);
            }
        }
        user.rewardDebt = user.amountWithBonus.mul(pool.accNovaPerShare).div(1e12);
        emit Deposit(_user, _pid, _amount);
    }


    function withdraw(uint256 _pid, uint256 _amount) external validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amountWithBonus.mul(pool.accNovaPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if(pool.isSNovaRewards){
                safeSNovaTransfer(msg.sender, pending);
            }
            else{
                safeNovaTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 _bonusAmount = _amount.mul(userBonus(_pid, msg.sender).add(10000)).div(10000);
            user.amountWithBonus = user.amountWithBonus.sub(_bonusAmount);

            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_bonusAmount);
        }
        user.rewardDebt = user.amountWithBonus.mul(pool.accNovaPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }


    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        pool.lpSupply = pool.lpSupply.sub(user.amountWithBonus);
        user.amount = 0;
        user.rewardDebt = 0;
        user.amountWithBonus = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function getPoolInfo(uint256 _pid) external view
    returns(address lpToken, uint256 allocPoint, uint256 lastRewardBlock,
            uint256 accNovaPerShare, uint256 depositFeeBP, bool isSNovaRewards) {
        return (
            address(poolInfo[_pid].lpToken),
            poolInfo[_pid].allocPoint,
            poolInfo[_pid].lastRewardBlock,
            poolInfo[_pid].accNovaPerShare,
            poolInfo[_pid].depositFeeBP,
            poolInfo[_pid].isSNovaRewards
        );
    }


    function safeNovaTransfer(address _to, uint256 _amount) internal {
        uint256 NovaBal = Nova.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > NovaBal) {
            transferSuccess = Nova.transfer(_to, NovaBal);
        } else {
            transferSuccess = Nova.transfer(_to, _amount);
        }
        require(transferSuccess, "safeNovaTransfer: Transfer failed");
    }


    function safeSNovaTransfer(address _to, uint256 _amount) internal {
        uint256 sNovaBal = sNova.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > sNovaBal) {
            transferSuccess = sNova.transfer(_to, sNovaBal);
        } else {
            transferSuccess = sNova.transfer(_to, _amount);
        }
        require(transferSuccess, "safeSNovaTransfer: Transfer failed");
    }


    function dev(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function updateMinimumEmissionRate(uint256 _minimumEmissionRate) external onlyOwner{
        require(minimumEmissionRate > _minimumEmissionRate, "must be lower");
        minimumEmissionRate = _minimumEmissionRate;
        if(NovaPerBlock == minimumEmissionRate){
            lastReductionPeriodIndex = block.number.sub(startBlock).div(emissionReductionPeriodBlocks);
        }
    }

}
