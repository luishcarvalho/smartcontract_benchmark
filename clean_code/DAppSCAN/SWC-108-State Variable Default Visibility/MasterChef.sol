

pragma solidity ^0.8.0;

import "./NSDXBar.sol";
import "./NSDXToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";








contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;




    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accNSDXPerShare;
    }


    NSDXToken immutable nsdx;


    NSDXBar immutable bar;


    uint256 public nsdxPerBlock;


    uint256 public BONUS_MULTIPLIER = 1;


    PoolInfo[] public poolInfo;


    mapping (uint256 => mapping (address => UserInfo)) public userInfo;


    uint256 public totalAllocPoint = 0;


    uint256 public startBlock;


    uint256 public nsdxTotalMinted;


    uint256 public nsdxMaxMint;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, ERC20 lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accNSDXPerShare);
    event SetMaxMint(uint256 _nsdxMaxMint);
    event SetPerBLock(uint256 _nsdxPerBlock);
    event UpdateMultiplier(uint256 multiplierNumber);

    constructor(
        NSDXToken _nsdx,
        uint256 _nsdxPerBlock,
        uint256 _startBlock,
        uint256 _nsdxMaxMint
    ) {
        require(address(_nsdx) != address(0), "the _nsdx address is zero");
        nsdx = _nsdx;
        nsdxPerBlock = _nsdxPerBlock;
        startBlock = _startBlock;
        nsdxMaxMint = _nsdxMaxMint;


        bar = new NSDXBar(_nsdx);


        poolInfo.push(PoolInfo({
            lpToken: _nsdx,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accNSDXPerShare: 0
        }));

        totalAllocPoint = 1000;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
        emit UpdateMultiplier(multiplierNumber);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }



    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accNSDXPerShare: 0
        }));
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }
        if (_allocPoint != poolInfo[_pid].allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
            poolInfo[_pid].allocPoint = _allocPoint;
        }
    }


    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }




    function updatePool(uint256 _pid) public returns (PoolInfo memory pool){
        pool = poolInfo[_pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 nsdxReward = multiplier.mul(nsdxPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
                nsdxReward = safeNSDXMint(address(bar), nsdxReward);
                pool.accNSDXPerShare = pool.accNSDXPerShare.add(nsdxReward.mul(1e12).div(lpSupply));
            }
            pool.lastRewardBlock = block.number;
            poolInfo[_pid] = pool;
            emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accNSDXPerShare);
        }
    }



    function pendingNSDX(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNSDXPerShare = pool.accNSDXPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nsdxReward = multiplier.mul(nsdxPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accNSDXPerShare = accNSDXPerShare.add(nsdxReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accNSDXPerShare).div(1e12).sub(user.rewardDebt);
    }




    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_amount > 0, "deposit: amount must greater than zero");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accNSDXPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeNSDXTransfer(msg.sender, pending);
            }
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accNSDXPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }




    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNSDXPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeNSDXTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNSDXPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }



    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }



    function setMaxMint(uint256 _nsdxMaxMint) public onlyOwner {
        require(_nsdxMaxMint > nsdxTotalMinted, "setMaxMint: the new max mint must be greater than current minted");
        nsdxMaxMint = _nsdxMaxMint;
        emit SetMaxMint(_nsdxMaxMint);
    }




    function setPerBlock(uint256 _nsdxPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        nsdxPerBlock = _nsdxPerBlock;
        emit SetPerBLock(_nsdxPerBlock);
    }





    function transferNSDXOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "transferNSDXOwnership: new NSDX token owner is the zero address");
        nsdx.transferOwnership(_newOwner);
    }


    function safeNSDXTransfer(address _to, uint256 _amount) internal {
        bar.safeNSDXTransfer(_to, _amount);
    }


    function safeNSDXMint(address _to, uint256 _amount) internal returns(uint256 minted) {
        uint256 allow = nsdxMaxMint.sub(nsdxTotalMinted);
        if (_amount > allow) {
            minted = allow;
        } else {
            minted = _amount;
        }
        if (minted > 0) {
            nsdxTotalMinted = nsdxTotalMinted.add(minted);
            nsdx.mint(_to, minted);
        }
    }
}
