

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import '../interfaces/IActionTrigger.sol';
import '../interfaces/IActionPools.sol';
import '../BOOToken.sol';





contract ActionPools is Ownable, IActionPools {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 rewardDebt;
        uint256 rewardRemain;
    }


    struct PoolInfo {
        address callFrom;
        uint256 callId;
        IERC20  rewardToken;
        uint256 rewardMaxPerBlock;
        uint256 lastRewardBlock;
        uint256 lastRewardClosed;
        uint256 poolTotalRewards;
        uint256 accRewardPerShare;
        bool autoUpdate;
        bool autoClaim;
    }


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    mapping (address => mapping(uint256 => uint256[])) public poolIndex;

    mapping (address => uint256) public tokenTotalRewards;

    mapping (address => uint256) public rewardRestricted;

    mapping (address => bool) public eventSources;

    BOOToken public booToken;

    address public boodev;

    event ActionDeposit(address indexed user, uint256 indexed pid, uint256 fromAmount, uint256 toAmount);
    event ActionWithdraw(address indexed user, uint256 indexed pid, uint256 fromAmount, uint256 toAmount);
    event ActionClaim(address indexed user, uint256 indexed pid, uint256 amount);


    constructor (address _booToken, address _boodev) public {
        booToken = BOOToken(_booToken);
        require(booToken.totalSupply() >= 0, 'booToken');
        boodev = _boodev;
    }



    receive() external payable {
        revert();
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(uint256 _pid) external override view
        returns (address callFrom, uint256 callId, address rewardToken) {
        callFrom = poolInfo[_pid].callFrom;
        callId = poolInfo[_pid].callId;
        rewardToken = address(poolInfo[_pid].rewardToken);
    }

    function getPoolIndex(address _callFrom, uint256 _callId) external override view returns (uint256[] memory) {
        return poolIndex[_callFrom][_callId];
    }


    function add(address _callFrom, uint256 _callId,
                address _rewardToken, uint256 _maxPerBlock) external onlyOwner {

        (address lpToken,, uint256 totalAmount) =
                    IActionTrigger(_callFrom).getATPoolInfo(_callId);
        require(lpToken != address(0) && totalAmount >= 0, 'pool not right');
        poolInfo.push(PoolInfo({
            callFrom: _callFrom,
            callId: _callId,
            rewardToken: IERC20(_rewardToken),
            rewardMaxPerBlock: _maxPerBlock,
            lastRewardBlock: block.number,
            lastRewardClosed: 0,
            poolTotalRewards: 0,
            accRewardPerShare: 0,
            autoUpdate: true,
            autoClaim: false
        }));
        eventSources[_callFrom] = true;
        poolIndex[_callFrom][_callId].push(poolInfo.length.sub(1));
    }


    function setRewardMaxPerBlock(uint256 _pid, uint256 _maxPerBlock) external onlyOwner {
        poolInfo[_pid].rewardMaxPerBlock = _maxPerBlock;
    }

    function setAutoUpdate(uint256 _pid, bool _set) external onlyOwner {
        poolInfo[_pid].autoUpdate = _set;
    }

    function setAutoClaim(uint256 _pid, bool _set) external onlyOwner {
        poolInfo[_pid].autoClaim = _set;
    }

    function setRewardRestricted(address _hacker, uint256 _rate) external onlyOwner {
        require(_rate <= 1e9, 'max is 1e9');
        rewardRestricted[_hacker] = _rate;
    }

    function setBooDev(address _boodev) external {
        require(msg.sender == boodev, 'prev dev only');
        boodev = _boodev;
    }


    function getBlocksReward(uint256 _pid, uint256 _from, uint256 _to) public view returns (uint256 value) {
        require(_from <= _to, 'getBlocksReward error');
        PoolInfo storage pool = poolInfo[_pid];
        uint256 balance = pool.rewardToken.balanceOf(address(this));
        value = pool.rewardMaxPerBlock.mul(_to.sub(_from));
        if( address(pool.rewardToken) == address(booToken)) {
            return value;
        }
        if( pool.lastRewardClosed > balance
            || pool.lastRewardClosed > pool.poolTotalRewards) {


                return 0;
        }
        if( pool.lastRewardClosed.add(value) > balance) {
            value = balance.sub(pool.lastRewardClosed);
        }
        if( pool.lastRewardClosed.add(value) > pool.poolTotalRewards) {
            value = pool.poolTotalRewards.sub(pool.lastRewardClosed);
        }
    }


    function pendingRewards(uint256 _pid, address _account) public view returns (uint256 value) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        uint256 userAmount = IActionTrigger(pool.callFrom).getATUserAmount(pool.callId, _account);
        (,,uint256 poolTotalAmount) = IActionTrigger(pool.callFrom).getATPoolInfo(pool.callId);
        value = totalRewards(_pid, _account, userAmount, poolTotalAmount)
                    .add(user.rewardRemain)
                    .sub(user.rewardDebt);
    }

    function totalRewards(uint256 _pid, address _account, uint256 _amount, uint256 _totalAmount)
        public view returns (uint256 value) {
        _account;
        PoolInfo storage pool = poolInfo[_pid];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (block.number > pool.lastRewardBlock && _totalAmount != 0) {
            uint256 poolReward = getBlocksReward(_pid, pool.lastRewardBlock, block.number);
            accRewardPerShare = accRewardPerShare.add(poolReward.mul(1e18).div(_totalAmount));
        }
        value = _amount.mul(accRewardPerShare).div(1e18);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return ;
        }

        (,,uint256 poolTotalAmount) = IActionTrigger(pool.callFrom).getATPoolInfo(pool.callId);
        if ( pool.rewardMaxPerBlock <= 0
            || poolTotalAmount <= 0) {
            pool.lastRewardBlock = block.number;
            return ;
        }

        uint256 poolReward = getBlocksReward(_pid, pool.lastRewardBlock, block.number);
        if (poolReward > 0) {
            if( address(pool.rewardToken) == address(booToken)) {
                booToken.mint(address(this), poolReward);
                booToken.mint(boodev, poolReward.div(8));
            }
            pool.lastRewardClosed = pool.lastRewardClosed.add(poolReward);
            pool.accRewardPerShare = pool.accRewardPerShare.add(poolReward.mul(1e18).div(poolTotalAmount));
        }
        pool.lastRewardBlock = block.number;
    }

    function onAcionIn(uint256 _callId, address _account, uint256 _fromAmount, uint256 _toAmount) external override {
        if(!eventSources[msg.sender]) {
            return ;
        }
        for(uint256 u = 0; u < poolIndex[msg.sender][_callId].length; u ++) {
            uint256 pid = poolIndex[msg.sender][_callId][u];
            deposit(pid, _account, _fromAmount, _toAmount);
        }
    }

    function onAcionOut(uint256 _callId, address _account, uint256 _fromAmount, uint256 _toAmount) external override  {
        if(!eventSources[msg.sender]) {
            return ;
        }
        for(uint256 u = 0; u < poolIndex[msg.sender][_callId].length; u ++) {
            uint256 pid = poolIndex[msg.sender][_callId][u];
            withdraw(pid, _account, _fromAmount, _toAmount);
        }
    }

    function onAcionClaim(uint256 _callId, address _account) external override  {
        if(!eventSources[msg.sender]) {
            return ;
        }
        for(uint256 u = 0; u < poolIndex[msg.sender][_callId].length; u ++) {
            uint256 pid = poolIndex[msg.sender][_callId][u];
            if( !poolInfo[pid].autoClaim ) {
                continue;
            }
            _claim(pid, _account);
        }
    }

    function onAcionEmergency(uint256 _callId, address _account) external override  {
        _callId;
        _account;
    }

    function onAcionUpdate(uint256 _callId) external override  {
        if(!eventSources[msg.sender]) {
            return ;
        }
        for(uint256 u = 0; u < poolIndex[msg.sender][_callId].length; u ++) {
            uint256 pid = poolIndex[msg.sender][_callId][u];
            if( !poolInfo[pid].autoUpdate ) {
                continue;
            }
            updatePool(pid);
        }
    }

    function mintRewards(uint256 _pid) external override {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        address rewardToken = address(pool.rewardToken);
        if(rewardToken == address(booToken)) {
            return ;
        }
        uint256 balance = pool.rewardToken.balanceOf(address(this));
        if ( balance > tokenTotalRewards[rewardToken]) {
            uint256 mint = balance.sub(tokenTotalRewards[rewardToken]);
            pool.poolTotalRewards = pool.poolTotalRewards.add(mint);
            tokenTotalRewards[rewardToken] = balance;
        }
    }


    function deposit(uint256 _pid, address _account, uint256 _fromAmount, uint256 _toAmount) internal {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        (,,uint256 poolTotalAmount) = IActionTrigger(pool.callFrom).getATPoolInfo(pool.callId);
        if (_fromAmount > 0) {
            uint256 totalAmountOld = safesub(poolTotalAmount, safesub(_toAmount, _fromAmount));
            user.rewardRemain = totalRewards(_pid, _account, _fromAmount, totalAmountOld)
                                    .add(user.rewardRemain)
                                    .sub(user.rewardDebt);
        }
        user.rewardDebt = totalRewards(_pid, _account, _toAmount, poolTotalAmount);
        emit ActionDeposit(_account, _pid, _fromAmount, _toAmount);
    }


    function withdraw(uint256 _pid, address _account, uint256 _fromAmount, uint256 _toAmount) internal {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        (,,uint256 poolTotalAmount) = IActionTrigger(pool.callFrom).getATPoolInfo(pool.callId);
        if (_fromAmount > 0) {
            uint256 totalAmountOld = safesub(poolTotalAmount, safesub(_fromAmount, _toAmount));
            user.rewardRemain = totalRewards(_pid, _account, _fromAmount, totalAmountOld)
                                    .add(user.rewardRemain)
                                    .sub(user.rewardDebt);
        }
        user.rewardDebt = totalRewards(_pid, _account, _toAmount, poolTotalAmount);
        emit ActionWithdraw(_account, _pid, _fromAmount, _toAmount);
    }

    function claimAll() external returns (uint256 value) {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            value = value.add(claim(pid));
        }

    }

    function claim(uint256 _pid) public returns (uint256 value) {
        return _claim(_pid, msg.sender);
    }

    function _claim(uint256 _pid, address _account) internal returns (uint256 value) {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        value = pendingRewards(_pid, _account);
        if (value > 0) {
            userInfo[_pid][_account].rewardRemain = 0;
            if(rewardRestricted[_account] > 0) {
                value = safesub(value, value.mul(rewardRestricted[_account]).div(1e9));
            }

            (,,uint256 poolTotalAmount) = IActionTrigger(pool.callFrom).getATPoolInfo(pool.callId);
            uint256 userAmount = IActionTrigger(pool.callFrom).getATUserAmount(pool.callId, _account);
            userInfo[_pid][_account].rewardDebt = totalRewards(_pid, _account, userAmount, poolTotalAmount);

            pool.lastRewardClosed = safesub(pool.lastRewardClosed, value);
            pool.poolTotalRewards = safesub(pool.poolTotalRewards, value);
            address rewardToken = address(pool.rewardToken);
            tokenTotalRewards[rewardToken] = safesub(tokenTotalRewards[rewardToken], value);

            value = safeTokenTransfer(pool.rewardToken, _account, value);
        }

        emit ActionClaim(_account, _pid, value);
    }


    function emergencyWithdraw(uint256 _pid, address _account) internal {
        _pid;
        _account;
    }


    function safesub(uint256 _a, uint256 _b) internal pure returns (uint256 v) {
        v = 0;
        if(_a > _b) {
            v = _a.sub(_b);
        }
    }


    function safeTokenTransfer(IERC20 _token, address _to, uint256 _amount) internal returns (uint256 value) {
        uint256 balance = _token.balanceOf(address(this));
        value = _amount > balance ? balance : _amount;
        if ( value > 0 ) {

            _token.transfer(_to, value);
        }
    }
}
