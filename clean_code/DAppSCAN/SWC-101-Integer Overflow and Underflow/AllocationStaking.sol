
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./interfaces/ISalesFactory.sol";
import "./interfaces/IAdmin.sol";

contract AllocationStaking is OwnableUpgradeable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 tokensUnlockTime;
        address [] salesRegistered;
    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
        uint256 accERC20PerShare;
        uint256 totalDeposits;
    }


    IERC20 public erc20;

    uint256 public paidOut;

    uint256 public rewardPerSecond;

    uint256 public totalRewards;

    uint256 public depositFeePrecision;

    uint256 public depositFeePercent;

    uint256 public totalXavaRedistributed;

    ISalesFactory public salesFactory;

    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint;

    uint256 public startTimestamp;

    uint256 public endTimestamp;

    mapping (address => uint256) public totalBurnedFromUser;

    uint256 public postSaleWithdrawPenaltyLength;

    uint256 public postSaleWithdrawPenaltyPercent;

    uint256 public postSaleWithdrawPenaltyPrecision;

    mapping (bytes32 => bool) public isNonceUsed;

    mapping (bytes => bool) public isSignatureUsed;

    IAdmin public admin;

    mapping (uint256 => mapping (address => address)) stakeOwnershipTransferApprovals;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFeeSet(uint256 depositFeePercent, uint256 depositFeePrecision);
    event CompoundedEarnings(address indexed user, uint256 indexed pid, uint256 amountAdded, uint256 totalDeposited);
    event FeeTaken(address indexed user, uint256 indexed pid, uint256 amount);
    event PostSaleWithdrawFeeCharged(address user, uint256 amountStake, uint256 amountRewards);
    event StakeOwnershipTransferred(address indexed from, address indexed to, uint256 pid);


    modifier onlyVerifiedSales {
        require(salesFactory.isSaleCreatedThroughFactory(msg.sender), "Sale not created through factory.");
        _;
    }

    function initialize(
        IERC20 _erc20,
        uint256 _rewardPerSecond,
        uint256 _startTimestamp,
        address _salesFactory,
        uint256 _depositFeePercent,
        uint256 _depositFeePrecision
    )
    initializer
    public
    {
        __Ownable_init();

        erc20 = _erc20;
        rewardPerSecond = _rewardPerSecond;
        startTimestamp = _startTimestamp;
        endTimestamp = _startTimestamp;

        salesFactory = ISalesFactory(_salesFactory);

        setDepositFeeInternal(_depositFeePercent, _depositFeePrecision);
    }


    function setSalesFactory(address _salesFactory) external onlyOwner {
        require(_salesFactory != address(0));
        salesFactory = ISalesFactory(_salesFactory);
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }



    function fund(uint256 _amount) public {
        require(block.timestamp < endTimestamp, "fund: too late, the farm is closed");
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        endTimestamp += _amount.div(rewardPerSecond);
        totalRewards = totalRewards.add(_amount);
    }



    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accERC20PerShare: 0,
                totalDeposits: 0
            })
        );
    }


    function setDepositFee(uint256 _depositFeePercent, uint256 _depositFeePrecision) public onlyOwner {
        setDepositFeeInternal(_depositFeePercent, _depositFeePrecision);
    }


    function setDepositFeeInternal(uint256 _depositFeePercent, uint256 _depositFeePrecision) internal {
        require(_depositFeePercent >= _depositFeePrecision.div(100)  && _depositFeePercent <= _depositFeePrecision);
        depositFeePercent = _depositFeePercent;
        depositFeePrecision=  _depositFeePrecision;
        emit DepositFeeSet(depositFeePercent, depositFeePrecision);
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function deposited(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }


    function pending(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accERC20PerShare = pool.accERC20PerShare;

        uint256 lpSupply = pool.totalDeposits;


        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 lastTimestamp = block.timestamp < endTimestamp ? block.timestamp : endTimestamp;
            uint256 nrOfSeconds = lastTimestamp.sub(pool.lastRewardTimestamp);
            uint256 erc20Reward = nrOfSeconds.mul(rewardPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
            accERC20PerShare = accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
        }
        return user.amount.mul(accERC20PerShare).div(1e36).sub(user.rewardDebt);
    }






    function totalPending() external view returns (uint256) {
        if (block.timestamp <= startTimestamp) {
            return 0;
        }

        uint256 lastTimestamp = block.timestamp < endTimestamp ? block.timestamp : endTimestamp;
        return rewardPerSecond.mul(lastTimestamp - startTimestamp).sub(paidOut);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function setTokensUnlockTime(uint256 _pid, address _user, uint256 _tokensUnlockTime) external onlyVerifiedSales {
        UserInfo storage user = userInfo[_pid][_user];



        if(user.tokensUnlockTime < _tokensUnlockTime) {
            user.tokensUnlockTime = _tokensUnlockTime;
        }


        user.salesRegistered.push(msg.sender);
    }


    function redistributeXava(uint256 _pid, address _user, uint256 _amountToRedistribute) external
    onlyVerifiedSales
    {
        if(_amountToRedistribute > 0) {
            UserInfo storage user = userInfo[_pid][_user];
            PoolInfo storage pool = poolInfo[_pid];

            updatePoolWithFee(_pid, _amountToRedistribute);

            uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);

            user.amount = user.amount.add(pendingAmount);

            user.amount = user.amount.sub(_amountToRedistribute);

            emit CompoundedEarnings(_user, _pid, pendingAmount, user.amount);

            user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);

            pool.totalDeposits = pool.totalDeposits.add(pendingAmount).sub(_amountToRedistribute);

            burnFromUser(_user, _pid, _amountToRedistribute);
        }
    }


    function updatePool(uint256 _pid) public {
        updatePoolWithFee(_pid, 0);
    }


    function updatePoolWithFee(
        uint256 _pid,
        uint256 _depositFee
    )
    internal
    {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastTimestamp = block.timestamp < endTimestamp ? block.timestamp : endTimestamp;

        if (lastTimestamp <= pool.lastRewardTimestamp) {
            lastTimestamp = pool.lastRewardTimestamp;
        }

        uint256 lpSupply = pool.totalDeposits;

        if (lpSupply == 0) {
            pool.lastRewardTimestamp = lastTimestamp;
            return;
        }

        uint256 nrOfSeconds = lastTimestamp.sub(pool.lastRewardTimestamp);


        uint256 reward = nrOfSeconds.mul(rewardPerSecond);
        uint256 erc20Reward = reward.mul(pool.allocPoint).div(totalAllocPoint).add(_depositFee);

        pool.accERC20PerShare = pool.accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));

        pool.lastRewardTimestamp = lastTimestamp;
    }


    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 depositFee = 0;
        uint256 depositAmount = _amount;


        if(_pid == 0) {
            depositFee = _amount.mul(depositFeePercent).div(depositFeePrecision);
            depositAmount = _amount.sub(depositFee);

            burnFromUser(msg.sender, _pid, depositFee);
        }


        updatePoolWithFee(_pid, depositFee);


        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
            erc20Transfer(msg.sender, pendingAmount);
        }


        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        pool.totalDeposits = pool.totalDeposits.add(depositAmount);

        user.amount = user.amount.add(depositAmount);

        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);

        emit Deposit(msg.sender, _pid, depositAmount);
    }

    function verifySignature(
        string memory functionName,
        uint256 nonce,
        bytes32 hash,
        bytes memory signature
    ) internal returns (bool) {


        bytes32 nonceHash = keccak256(abi.encodePacked(functionName, nonce));
        require(!isNonceUsed[nonceHash], "Nonce already used.");

        isNonceUsed[nonceHash] = true;


        require(!isSignatureUsed[signature], "Signature already used.");

        isSignatureUsed[signature] = true;

        return admin.isAdmin(hash.recover(signature));
    }


    function withdraw(
        uint256 _pid,
        uint256 _amount,
        uint256 nonce,
        uint256 signatureExpirationTimestamp,
        bytes calldata signature
    ) external {

        if(_amount > 0) {

            bytes32 hash = keccak256(
                abi.encodePacked(msg.sender, _pid, _amount, nonce, signatureExpirationTimestamp)
            ).toEthSignedMessageHash();

            require(
                verifySignature("withdraw", nonce, hash, signature),
                "Invalid signature."
            );

            require(
                block.timestamp < signatureExpirationTimestamp, "Signature expired."
            );
        }

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.tokensUnlockTime <= block.timestamp, "Last sale you registered for is not finished yet.");
        require(user.amount >= _amount, "withdraw: can't withdraw more than deposit");


        updatePool(_pid);


        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);


        uint256 withdrawalFeeDepositAmount;
        uint256 withdrawalFeePending;


        if(_pid == 0) {
            (withdrawalFeeDepositAmount, withdrawalFeePending) = getWithdrawFeeInternal(
                _amount,
                pendingAmount,
                user.tokensUnlockTime
            );
        }


        erc20Transfer(msg.sender, pendingAmount.sub(withdrawalFeePending));
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);


        pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(withdrawalFeeDepositAmount));
        pool.totalDeposits = pool.totalDeposits.sub(_amount);


        if(withdrawalFeeDepositAmount > 0) {

            burnFromUser(msg.sender, _pid, withdrawalFeeDepositAmount.add(withdrawalFeePending));

            updatePoolWithFee(_pid, withdrawalFeeDepositAmount.add(withdrawalFeePending));

            emit PostSaleWithdrawFeeCharged(
                msg.sender,
                withdrawalFeeDepositAmount,
                withdrawalFeePending
            );
        } else {
            if(_amount > 0) {

                user.tokensUnlockTime = 0;
            }
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }


    function compound(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];


        require(user.amount > 0, "User does not have anything staked.");


        updatePool(_pid);


        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
        uint256 fee = pendingAmount.mul(depositFeePercent).div(depositFeePrecision);
        uint256 amountCompounding = pendingAmount.sub(fee);


        burnFromUser(msg.sender, _pid, fee);

        updatePoolWithFee(_pid, fee);


        user.amount = user.amount.add(amountCompounding);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);


        pool.totalDeposits = pool.totalDeposits.add(amountCompounding);
        emit CompoundedEarnings(msg.sender, _pid, amountCompounding, user.amount);
    }



    function erc20Transfer(address _to, uint256 _amount) internal {
        erc20.transfer(_to, _amount);
        paidOut += _amount;
    }


    function burnFromUser(address user, uint256 _pid, uint256 amount) internal {
        totalBurnedFromUser[user] = totalBurnedFromUser[user].add(amount);
        totalXavaRedistributed = totalXavaRedistributed.add(amount);
        emit FeeTaken(user, _pid, amount);
    }


    function getWithdrawFeeInternal(
        uint256 amountStaking,
        uint256 amountPending,
        uint256 stakeUnlocksAt
    )
    internal
    view
    returns (uint256, uint256)
    {

        if(stakeUnlocksAt.add(postSaleWithdrawPenaltyLength) <= block.timestamp) {
            return (0,0);
        }


        uint256 timeLeft = stakeUnlocksAt.add(postSaleWithdrawPenaltyLength).sub(block.timestamp);


        uint256 percentToTake = timeLeft.mul(postSaleWithdrawPenaltyPercent).div(postSaleWithdrawPenaltyLength);

        return (
            percentToTake.mul(amountStaking).div(postSaleWithdrawPenaltyPrecision),
            percentToTake.mul(amountPending).div(postSaleWithdrawPenaltyPrecision)
        );
    }


    function getWithdrawFee(address userAddress, uint256 amountToWithdraw, uint256 _pid) external view returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][userAddress];
        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
        return getWithdrawFeeInternal(amountToWithdraw, pendingAmount, user.tokensUnlockTime);
    }


    function getPendingAndDepositedForUsers(address [] memory users, uint pid)
    external
    view
    returns (uint256 [] memory , uint256 [] memory)
    {
        uint256 [] memory deposits = new uint256[](users.length);
        uint256 [] memory earnings = new uint256[](users.length);


        for(uint i=0; i < users.length; i++) {
            deposits[i] = deposited(pid , users[i]);
            earnings[i] = pending(pid, users[i]);
        }

        return (deposits, earnings);
    }


    function setPostSaleWithdrawPenaltyPercentAndLength(
        uint256 _postSaleWithdrawPenaltyPercent,
        uint256 _postSaleWithdrawPenaltyLength,
        uint256 _postSaleWithdrawPenaltyPrecision
    )
    public
    onlyOwner
    {

        require(
            _postSaleWithdrawPenaltyPercent >= _postSaleWithdrawPenaltyPrecision.div(100)  &&
            _postSaleWithdrawPenaltyPercent <= _postSaleWithdrawPenaltyPrecision
        );


        postSaleWithdrawPenaltyLength = _postSaleWithdrawPenaltyLength;
        postSaleWithdrawPenaltyPercent = _postSaleWithdrawPenaltyPercent;
        postSaleWithdrawPenaltyPrecision = _postSaleWithdrawPenaltyPrecision;
    }


    function approveStakeOwnershipTransfer(address newOwner, uint256 pid) external {
        stakeOwnershipTransferApprovals[pid][msg.sender] = newOwner;
    }


    function claimApprovedStakeOwnership(address wallet, uint256 pid) external {
        require(stakeOwnershipTransferApprovals[pid][wallet] == msg.sender, "Stake transfer not approved.");
        require(userInfo[pid][msg.sender].amount == 0, "Wallet already staking.");
        userInfo[pid][msg.sender] = userInfo[pid][wallet];
        delete userInfo[pid][wallet];
        emit StakeOwnershipTransferred(wallet, msg.sender, pid);
    }


    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot set zero address as admin.");
        admin = IAdmin(_admin);
    }
}
