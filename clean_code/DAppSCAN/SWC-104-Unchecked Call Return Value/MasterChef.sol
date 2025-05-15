pragma solidity 0.6.7;

import "./lib/enumerableSet.sol";
import "./lib/safe-math.sol";
import "./lib/erc20.sol";
import "./lib/ownable.sol";
import "./interfaces/strategy.sol";
import "./pud-token.sol";








contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 shares;
        uint256 rewardDebt;











    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accPudPerShare;
        address strategy;
        uint256 totalShares;
    }


    PudToken public pud;

    uint256 public devFundDivRate = 10;

    address public devaddr;

    address public treasury;

    uint256 public bonusEndBlock;

    uint256 public pudPerBlock;

    uint256 public constant BONUS_MULTIPLIER = 10;


    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;


    event Recovered(address token, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        PudToken _pud,
        address _devaddr,
        address _treasury,
        uint256 _pudPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        pud = _pud;
        devaddr = _devaddr;
        treasury = _treasury;
        pudPerBlock = _pudPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }




    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate,
        address _strategy
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPudPerShare: 0,
                strategy: _strategy,
                totalShares: 0
            })
        );
    }



    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }


    function pendingPud(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPudPerShare = pool.accPudPerShare;
        uint256 lpSupply = pool.totalShares;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && pool.allocPoint > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);

            uint256 pudReward =
                multiplier.mul(pudPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accPudPerShare = accPudPerShare.add(
                pudReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.shares.mul(accPudPerShare).div(1e12).sub(user.rewardDebt);
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
            return;
        }
        uint256 lpSupply = pool.totalShares;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 pudReward = 0;
        if (pool.allocPoint > 0){
            pudReward =
                multiplier.mul(pudPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            if (pudReward > 0){
                pud.mint(devaddr, pudReward.div(devFundDivRate));
                pud.mint(address(this), pudReward);
            }
        }
        pool.accPudPerShare = pool.accPudPerShare.add(
            pudReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }



    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        if (user.shares > 0) {
            uint256 pending =
                user.shares.mul(pool.accPudPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safePudTransfer(msg.sender, pending);
        }


        uint256 _pool = balance(_pid);
        if (_amount > 0) {
            uint256 _before = pool.lpToken.balanceOf(pool.strategy);

            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                pool.strategy,
                _amount
            );

            uint256 _after = pool.lpToken.balanceOf(pool.strategy);
            _amount = _after.sub(_before);
        }
        uint256 shares = 0;
        if (pool.totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(pool.totalShares)).div(_pool);
        }

        user.shares = user.shares.add(shares);
        user.rewardDebt = user.shares.mul(pool.accPudPerShare).div(1e12);
        pool.totalShares = pool.totalShares.add(shares);

        emit Deposit(msg.sender, _pid, _amount);
    }



    function withdraw(uint256 _pid, uint256 _shares) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.shares >= _shares, "withdraw: not good");
        updatePool(_pid);

        uint256 r = (balance(_pid).mul(_shares)).div(pool.totalShares);
        uint256 pending =
            user.shares.mul(pool.accPudPerShare).div(1e12).sub(
                user.rewardDebt
            );

        safePudTransfer(msg.sender, pending);
        user.shares = user.shares.sub(_shares);
        user.rewardDebt = user.shares.mul(pool.accPudPerShare).div(1e12);
        pool.totalShares = pool.totalShares.sub(_shares);


        if (r > 0) {
            uint256 b = pool.lpToken.balanceOf(address(this));

            IStrategy(pool.strategy).withdraw(r);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < r) {
                r = b.add(_diff);
            }

            pool.lpToken.safeTransfer(address(msg.sender), r);

        }

        emit Withdraw(msg.sender, _pid, r);
    }



    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 r = (balance(_pid).mul(user.shares)).div(pool.totalShares);


        uint256 b = pool.lpToken.balanceOf(address(this));

        IStrategy(pool.strategy).withdraw(r);
        uint256 _after = pool.lpToken.balanceOf(address(this));
        uint256 _diff = _after.sub(b);
        if (_diff < r) {
            r = b.add(_diff);
        }

        pool.lpToken.safeTransfer(address(msg.sender), r);
        emit EmergencyWithdraw(msg.sender, _pid, user.shares);
        user.shares = 0;
        user.rewardDebt = 0;
    }



    function safePudTransfer(address _to, uint256 _amount) internal {
        uint256 pudBal = pud.balanceOf(address(this));
        if (_amount > pudBal) {
            pud.transfer(_to, pudBal);
        } else {
            pud.transfer(_to, _amount);
        }
    }


    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }


    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setPudPerBlock(uint256 _pudPerBlock) public onlyOwner {
        require(_pudPerBlock > 0, "!pudPerBlock-0");

        pudPerBlock = _pudPerBlock;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; ++_pid) {
            PoolInfo storage pool = poolInfo[_pid];
            pool.lastRewardBlock = startBlock;
        }
    }

    function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }

    function setDevFundDivRate(uint256 _devFundDivRate) public onlyOwner {
        require(_devFundDivRate > 0, "!devFundDivRate-0");
        devFundDivRate = _devFundDivRate;
    }


    function balance(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return IStrategy(pool.strategy).balanceOf();
    }


    function setPoolStrategy(uint256 _pid,address _strategy) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        IStrategy(pool.strategy).harvest();
        IStrategy(pool.strategy).withdrawAll(_strategy);
        pool.strategy = _strategy;
    }
}
