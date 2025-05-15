

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../interfaces/IMdexRouter.sol";
import "../../interfaces/IMdexPair.sol";
import "../../interfaces/IMdexFactory.sol";
import "../interfaces/ISafeBox.sol";
import "../interfaces/IStrategyLink.sol";
import '../interfaces/IActionPools.sol';
import '../interfaces/IActionTrigger.sol';
import "../interfaces/ITenBankHall.sol";
import "../utils/TenMath.sol";
import "./StrategyMDexPools.sol";
import "./StrategyUtils.sol";


contract StrategyMDex is StrategyMDexPools, Ownable, IStrategyLink, IActionTrigger {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 lpAmount;
        uint256 lpPoints;
        address borrowFrom;
        uint256 bid;
    }


    struct PoolInfo {
        address[] collateralToken;
        address baseToken;
        IMdexPair lpToken;
        uint256 poolId;
        uint256 lastRewardsBlock;
        uint256 totalPoints;
        uint256 totalLPAmount;
        uint256 totalLPReinvest;
        uint256 miniRewardAmount;
    }

    IMdexFactory constant factory = IMdexFactory(0xb0b670fc1F7724119963018DB0BfA86aDb22d941);
    IMdexRouter constant router = IMdexRouter(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300);


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public override userInfo;

    StrategyUtils public utils;
    address public override bank;
    IActionPools public actionPool;

    modifier onlyBank() {
        require(bank == msg.sender, 'mdex strategy only call by bank');
        _;
    }

    constructor(address _bank, address _sconfig) public {
        bank = _bank;
        utils = new StrategyUtils(address(_sconfig));
    }

    function getSource() external virtual override view returns (string memory) {
        return 'mdex';
    }

    function poolLength() external override view returns (uint256) {
        return poolInfo.length;
    }


    function getATPoolInfo(uint256 _pid) external override view
        returns (address lpToken, uint256 allocRate, uint256 totalAmount) {
            lpToken = address(poolInfo[_pid].lpToken);
            allocRate = 5e8;
            totalAmount = poolInfo[_pid].totalLPAmount;
    }

    function getATUserAmount(uint256 _pid, address _account) external override view
        returns (uint256 acctAmount) {
            acctAmount = userInfo[_pid][_account].lpAmount;
    }

    function getPoolInfo(uint256 _pid) external override view
        returns(address[] memory collateralToken, address baseToken, address lpToken,
            uint256 poolId, uint256 totalLPAmount, uint256 totalLPReinvest) {
        collateralToken = poolInfo[_pid].collateralToken;
        baseToken = address(poolInfo[_pid].baseToken);
        lpToken = address(poolInfo[_pid].lpToken);
        poolId = poolInfo[_pid].poolId;
        totalLPAmount = poolInfo[_pid].totalLPAmount;
        totalLPReinvest = poolInfo[_pid].totalLPReinvest;
    }

    function getPoolCollateralToken(uint256 _pid) external override view returns (address[] memory collateralToken) {
        collateralToken = poolInfo[_pid].collateralToken;
    }

    function getPoollpToken(uint256 _pid) external override view returns (address lpToken) {
        lpToken = address(poolInfo[_pid].lpToken);
    }

    function getBaseToken(uint256 _pid) external override view returns (address baseToken) {
        baseToken = address(poolInfo[_pid].baseToken);
    }

    function getBorrowInfo(uint256 _pid, address _account)
        external override view returns (address borrowFrom, uint256 bid) {
        borrowFrom = userInfo[_pid][_account].borrowFrom;
        bid = userInfo[_pid][_account].bid;
    }

    function getTokenBalance_this(address _token0, address _token1)
        internal view returns (uint256 a1, uint256 a2) {
        a1 = IERC20(_token0).balanceOf(address(this));
        a2 = IERC20(_token1).balanceOf(address(this));
    }



    function addPool(uint256 _poolId, address[] memory _collateralToken, address _baseToken) public onlyOwner {
        require(_collateralToken.length == 2, 'lptoken pool only');

        address lpTokenInPools = poolDepositToken(_poolId);

        poolInfo.push(PoolInfo({
            collateralToken: _collateralToken,
            baseToken: _baseToken,
            lpToken: IMdexPair(lpTokenInPools),
            poolId: _poolId,
            lastRewardsBlock: block.number,
            totalPoints: 0,
            totalLPAmount: 0,
            totalLPReinvest: 0,
            miniRewardAmount: 1e4
        }));

        uint256 pid = poolInfo.length.sub(1);
        require(utils.checkAddPoolLimit(pid, _baseToken, lpTokenInPools), 'check add pool limit');
        resetApprove(poolInfo.length.sub(1));
    }

    function resetApprove(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        address rewardToken = poolRewardToken(pool.poolId);

        IERC20(pool.collateralToken[0]).approve(address(router), uint256(-1));
        IERC20(pool.collateralToken[1]).approve(address(router), uint256(-1));
        IERC20(address(pool.lpToken)).approve(address(router), uint256(-1));
        IERC20(rewardToken).approve(address(router), uint256(-1));

        IERC20(pool.collateralToken[0]).approve(address(utils), uint256(-1));
        IERC20(pool.collateralToken[1]).approve(address(utils), uint256(-1));
        IERC20(address(pool.lpToken)).approve(address(utils), uint256(-1));
        IERC20(rewardToken).approve(address(utils), uint256(-1));

        poolTokenApprove(address(pool.lpToken), uint256(-1));
    }

    function setAcionPool(address _actionPool) external onlyOwner {
        actionPool = IActionPools(_actionPool);
    }

    function setSConfig(address _sconfig) external onlyOwner {
        utils.setSConfig(_sconfig);
    }

    function setMiniRewardAmount(uint256 _pid, uint256 _miniRewardAmount) external onlyOwner {
        poolInfo[_pid].miniRewardAmount = _miniRewardAmount;
    }


    function pendingRewards(uint256 _pid, address _account) public override view returns (uint256 value) {
        value = pendingLPAmount(_pid, _account);
        value = TenMath.safeSub(value, userInfo[_pid][_account].lpAmount);
    }


    function pendingLPAmount(uint256 _pid, address _account) public override view returns (uint256 value) {
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.totalPoints <= 0) {
            return 0;
        }
        value = userInfo[_pid][_account].lpPoints.mul(pool.totalLPReinvest).div(pool.totalPoints);
        value = TenMath.min(value, pool.totalLPReinvest);
    }

    function getBorrowAmount(uint256 _pid, address _account) public override view returns (uint256 amount) {
        amount = utils.getBorrowAmount(_pid, _account);
    }

    function getDepositAmount(uint256 _pid, address _account) external override view returns (uint256 amount) {
        uint256 lpTokenAmount = pendingLPAmount(_pid, _account);
        amount = utils.getLPToken2TokenAmount(address(poolInfo[_pid].lpToken), poolInfo[_pid].baseToken, lpTokenAmount);
    }


    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.lastRewardsBlock == block.number ||
            pool.totalLPAmount.add(pool.totalLPReinvest) == 0) {
            pool.lastRewardsBlock = block.number;
            return ;
        }

        if(address(actionPool) != address(0)) {
            actionPool.onAcionUpdate(_pid);
        }

        pool.lastRewardsBlock = block.number;

        address token0 = pool.collateralToken[0];
        address token1 = pool.collateralToken[1];
        (uint256 uBalanceBefore0, uint256 uBalanceBefore1) = getTokenBalance_this(token0, token1);
        uint256 newRewards = poolClaim(pool.poolId);
        if(newRewards < pool.miniRewardAmount) {
            return ;
        }

        address rewardToken = poolRewardToken(pool.poolId);
        if(utils.getAmountIn(rewardToken, newRewards, pool.baseToken) <= 0) {
            return ;
        }


        uint256 newRewardBase = utils.getTokenIn(rewardToken, newRewards, pool.baseToken);


        utils.makeRefundFee(_pid, newRewardBase);


        (uint256 uBalanceAfter0, uint256 uBalanceAfter1) = getTokenBalance_this(token0, token1);

        makeBalanceOptimalLiquidityByAmount(_pid,
                                uBalanceAfter0.sub(uBalanceBefore0),
                                uBalanceAfter1.sub(uBalanceBefore1));

        (uBalanceAfter0, uBalanceAfter1) = getTokenBalance_this(token0, token1);


        uint256 lpAmount = makeLiquidityAndDepositByAmount(_pid,
                        uBalanceAfter0.sub(uBalanceBefore0),
                        uBalanceAfter1.sub(uBalanceBefore1));
        (uBalanceAfter0, uBalanceAfter1) = getTokenBalance_this(token0, token1);

        pool.totalLPReinvest = pool.totalLPReinvest.add(lpAmount);
    }



    function depositLPToken(uint256 _pid, address _account, address _borrowFrom,
                            uint256 _bAmount, uint256 _desirePrice, uint256 _slippage)
                            public override onlyBank returns (uint256 lpAmount) {

        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];


        uint256 withdrawLPAmount = poolInfo[_pid].lpToken.balanceOf(address(this));

        router.removeLiquidity(token0, token1, withdrawLPAmount, 0, 0, address(this), block.timestamp.add(60));


        lpAmount = deposit(_pid, _account, _borrowFrom, _bAmount, _desirePrice, _slippage);
    }

    function deposit(uint256 _pid, address _account, address _borrowFrom,
                    uint256 _bAmount, uint256 _desirePrice, uint256 _slippage)
                    public override onlyBank returns (uint256 lpAmount) {

        UserInfo storage user = userInfo[_pid][_account];
        require(user.borrowFrom == address(0) || _bAmount == 0 ||
                user.borrowFrom == _borrowFrom,
                'borrowFrom cannot changed');
        if(user.borrowFrom == address(0)) {
            user.borrowFrom = _borrowFrom;
        }

        require(utils.checkSlippageLimit(_pid, _desirePrice, _slippage), 'check slippage error');


        updatePool(_pid);

        require(utils.checkBorrowLimit(_pid, _account, user.borrowFrom, _bAmount), 'borrow to limit');


        utils.makeDepositFee(_pid);


        makeBorrowBaseToken(_pid, _account, user.borrowFrom, _bAmount);


        makeBalanceOptimalLiquidity(_pid);


        lpAmount = makeLiquidityAndDeposit(_pid);


        require(lpAmount > 0, 'no liqu lptoken');
        require(utils.checkDepositLimit(_pid, _account, lpAmount), 'farm lptoken amount to high');


        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];
        utils.transferFromAllToken(address(this), _account, token0, token1);


        uint256 lpAmountOld = user.lpAmount;
        uint256 addPoint = lpAmount;
        if(poolInfo[_pid].totalLPReinvest > 0) {
            addPoint = lpAmount.mul(poolInfo[_pid].totalPoints).div(poolInfo[_pid].totalLPReinvest);
        }

        user.lpPoints = user.lpPoints.add(addPoint);
        poolInfo[_pid].totalPoints = poolInfo[_pid].totalPoints.add(addPoint);
        poolInfo[_pid].totalLPReinvest = poolInfo[_pid].totalLPReinvest.add(lpAmount);

        user.lpAmount = user.lpAmount.add(lpAmount);
        poolInfo[_pid].totalLPAmount = poolInfo[_pid].totalLPAmount.add(lpAmount);


        (,, uint256 borrowRate) =  makeWithdrawCalcAmount(_pid, _account);
        require(!utils.checkLiquidationLimit(_pid, _account, borrowRate), 'deposit in liquidation');

        emit StrategyDeposit(address(this), _pid, _account, lpAmount, _bAmount);

        if(address(actionPool) != address(0) && lpAmount > 0) {
            actionPool.onAcionIn(_pid, _account, lpAmountOld, user.lpAmount);
        }
    }

    function makeBorrowBaseToken(uint256 _pid, address _account, address _borrowFrom, uint256 _bAmount) internal {
        if(_borrowFrom == address(0) || _bAmount <= 0) {
            return ;
        }

        if(userInfo[_pid][_account].borrowFrom == address(0)) {
            return ;
        }

        uint256 bid = ITenBankHall(bank).makeBorrowFrom(_pid, _account, _borrowFrom, _bAmount);

        emit StrategyBorrow(address(this), _pid, _account, _bAmount);

        if(userInfo[_pid][_account].bid != 0 && bid != 0) {
            require(userInfo[_pid][_account].bid == bid, 'cannot change bid order');
        }
        userInfo[_pid][_account].bid = bid;
    }

    function makeBalanceOptimalLiquidity(uint256 _pid) internal {

        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];
        (uint256 amount0, uint256 amount1) = getTokenBalance_this(token0, token1);
        makeBalanceOptimalLiquidityByAmount(_pid, amount0, amount1);
    }

    function makeBalanceOptimalLiquidityByAmount(uint256 _pid, uint256 _amount0, uint256 _amount1) internal {
        address pairs = factory.getPair(poolInfo[_pid].collateralToken[0], poolInfo[_pid].collateralToken[1]);
        address token0 = IMdexPair(pairs).token0();
        address token1 = IMdexPair(pairs).token1();
        if(token0 != poolInfo[_pid].collateralToken[0]) {
            (_amount0, _amount1) = (_amount1, _amount0);
        }
        (uint256 swapAmt, bool isReversed) = utils.optimalDepositAmount(address(pairs), _amount0, _amount1);
        if(swapAmt <= 0) {
            return ;
        }
        if(isReversed) {
            if(utils.getAmountIn(token1, swapAmt, token0) > 0) {
                utils.getTokenIn(token1, swapAmt, token0);
            }
        } else {
            if(utils.getAmountIn(token0, swapAmt, token1) > 0) {
                utils.getTokenIn(token0, swapAmt, token1);
            }
        }
    }

    function makeLiquidityAndDeposit(uint256 _pid) internal returns (uint256 lpAmount) {

        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];
        (uint256 amount0, uint256 amount1) = getTokenBalance_this(token0, token1);
        lpAmount = makeLiquidityAndDepositByAmount(_pid, amount0, amount1);
    }

    function makeLiquidityAndDepositByAmount(uint256 _pid, uint256 _amount0, uint256 _amount1)
        internal returns (uint256 lpAmount) {


        if(_amount0 <= 0 || _amount1 <= 0) {
            return 0;
        }

        uint256 uBalanceBefore = poolInfo[_pid].lpToken.balanceOf(address(this));
        router.addLiquidity(poolInfo[_pid].collateralToken[0], poolInfo[_pid].collateralToken[1],
                        _amount0, _amount1, 0, 0,
                        address(this), block.timestamp.add(60));
        uint256 uBalanceAfter = poolInfo[_pid].lpToken.balanceOf(address(this));


        lpAmount = uBalanceAfter.sub(uBalanceBefore);
        if(lpAmount > 0) {
            poolDeposit(poolInfo[_pid].poolId, lpAmount);
        }
    }

    function withdrawLPToken(uint256 _pid, address _account, uint256 _rate) external override onlyBank {
        _withdraw(_pid, _account, _rate, true);


        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];
        makeBalanceOptimalLiquidity(_pid);
        (uint256 amount0, uint256 amount1) = getTokenBalance_this(token0, token1);
        if(amount0 != 0 && amount1 != 0) {
            router.addLiquidity(token0, token1, amount0, amount1, 0, 0, _account, block.timestamp.add(60));
        }
        utils.transferFromAllToken(address(this), _account, token0, token1);
        utils.transferFromAllToken(address(this), _account, poolInfo[_pid].baseToken, address(poolInfo[_pid].lpToken));
    }

    function withdraw(uint256 _pid, address _account, uint256 _rate) public override onlyBank {
        _withdraw(_pid, _account, _rate, false);
        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];
        utils.transferFromAllToken(address(this), _account, token0, token1);
    }

    function _withdraw(uint256 _pid, address _account, uint256 _rate, bool _fast) internal {

        updatePool(_pid);

        UserInfo storage user = userInfo[_pid][_account];


        (, uint256 rewardsRate, uint256 borrowRate) =  makeWithdrawCalcAmount(_pid, _account);
        require(poolInfo[_pid].totalPoints > 0 && poolInfo[_pid].totalLPReinvest > 0, 'empty pool');

        uint256 removedPoint = user.lpPoints.mul(_rate).div(1e9);
        uint256 withdrawLPTokenAmount = removedPoint.mul(poolInfo[_pid].totalLPReinvest).div(poolInfo[_pid].totalPoints);
        uint256 removedLPAmount = _rate >= 1e9 ? user.lpAmount : user.lpAmount.mul(_rate).div(1e9);


        withdrawLPTokenAmount = TenMath.min(withdrawLPTokenAmount, poolInfo[_pid].totalLPReinvest);
        makeWithdrawRemoveLiquidity(_pid, withdrawLPTokenAmount);

        if(borrowRate > 0) {

            utils.makeWithdrawRewardFee(_pid, borrowRate, rewardsRate);

            repayBorrow(_pid, _account, _rate, _fast);
        }


        user.lpPoints = TenMath.safeSub(user.lpPoints, removedPoint);
        poolInfo[_pid].totalPoints = TenMath.safeSub(poolInfo[_pid].totalPoints, removedPoint);
        poolInfo[_pid].totalLPReinvest = TenMath.safeSub(poolInfo[_pid].totalLPReinvest, withdrawLPTokenAmount);

        uint256 lpAmountOld = user.lpAmount;
        user.lpAmount = TenMath.safeSub(user.lpAmount, removedLPAmount);
        poolInfo[_pid].totalLPAmount = TenMath.safeSub(poolInfo[_pid].totalLPAmount, removedLPAmount);

        emit StrategyWithdraw(address(this), _pid, _account, withdrawLPTokenAmount);

        if(address(actionPool) != address(0) && removedLPAmount > 0) {
            actionPool.onAcionOut(_pid, _account, lpAmountOld, user.lpAmount);
        }
    }

    function makeWithdrawCalcAmount(uint256 _pid, address _account) public view
                returns (uint256 withdrawLPTokenAmount, uint256 rewardsRate, uint256 borrowRate) {
        UserInfo storage accountInfo = userInfo[_pid][_account];

        withdrawLPTokenAmount = pendingLPAmount(_pid, _account);

        if(withdrawLPTokenAmount > 0) {
            rewardsRate = pendingRewards(_pid, _account).mul(1e9).div(withdrawLPTokenAmount);
        }


        uint256 borrowAmount = getBorrowAmount(_pid, _account);
        uint256 withdrawBaseAmount = utils.getLPToken2TokenAmount(address(poolInfo[_pid].lpToken), poolInfo[_pid].baseToken, withdrawLPTokenAmount);
        if (withdrawBaseAmount > 0) {
            borrowRate = borrowAmount.mul(1e9).div(withdrawBaseAmount);
        }
    }

    function makeWithdrawRemoveLiquidity(uint256 _pid, uint256 _withdrawLPTokenAmount) internal {
        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];


        poolWithdraw(poolInfo[_pid].poolId, _withdrawLPTokenAmount);
        router.removeLiquidity(token0, token1, _withdrawLPTokenAmount, 0, 0, address(this), block.timestamp.add(60));
    }

    function repayBorrow(uint256 _pid, address _account, uint256 _rate, bool _fast) public override onlyBank {
        utils.makeRepay(_pid, userInfo[_pid][_account].borrowFrom, _account, _rate, _fast);
        if(getBorrowAmount(_pid, _account) == 0) {
            userInfo[_pid][_account].borrowFrom = address(0);
            userInfo[_pid][_account].bid = 0;
        }
        if(_rate == 1e9) {
            require(getBorrowAmount(_pid, _account) == 0, 'repay not clear');
        }
    }

    function emergencyWithdraw(uint256 _pid, address _account) external override onlyBank {
        _emergencyWithdraw(_pid, _account);
    }

    function _emergencyWithdraw(uint256 _pid, address _account) internal {
        UserInfo storage user = userInfo[_pid][_account];


        uint256 withdrawLPTokenAmount = pendingLPAmount(_pid, _account);


        poolInfo[_pid].totalLPReinvest = TenMath.safeSub(poolInfo[_pid].totalLPReinvest, withdrawLPTokenAmount);
        poolInfo[_pid].totalPoints = TenMath.safeSub(poolInfo[_pid].totalPoints, user.lpPoints);
        poolInfo[_pid].totalLPAmount = TenMath.safeSub(poolInfo[_pid].totalLPAmount, user.lpAmount);

        user.lpPoints = 0;
        user.lpAmount = 0;

        makeWithdrawRemoveLiquidity(_pid, withdrawLPTokenAmount);
        repayBorrow(_pid, _account, 1e9, false);

        utils.transferFromAllToken(address(this), _account,
                        poolInfo[_pid].collateralToken[0],
                        poolInfo[_pid].collateralToken[1]);
    }

    function liquidation(uint256 _pid, address _account, address _hunter, uint256 _maxDebt) external override onlyBank {
        _maxDebt;

        UserInfo storage user = userInfo[_pid][_account];


        updatePool(_pid);


        (,, uint256 borrowRate) =  makeWithdrawCalcAmount(_pid, _account);
        require(utils.checkLiquidationLimit(_pid, _account, borrowRate), 'not in liquidation');


        uint256 borrowAmount = getBorrowAmount(_pid, _account);
        if(borrowAmount <= 0) {
            return ;
        }

        uint256 lpAmountOld = user.lpAmount;
        uint256 withdrawLPTokenAmount = pendingLPAmount(_pid, _account);

        poolInfo[_pid].totalLPAmount = TenMath.safeSub(poolInfo[_pid].totalLPAmount, user.lpAmount);
        poolInfo[_pid].totalLPReinvest = TenMath.safeSub(poolInfo[_pid].totalLPReinvest, withdrawLPTokenAmount);
        poolInfo[_pid].totalPoints = TenMath.safeSub(poolInfo[_pid].totalPoints, user.lpPoints);

        user.lpPoints = 0;
        user.lpAmount = 0;


        makeWithdrawRemoveLiquidity(_pid, withdrawLPTokenAmount);

        emit StrategyLiquidation(address(this), _pid, _account, withdrawLPTokenAmount);


        makeLiquidationRepay(_pid, _account, borrowAmount);


        utils.makeLiquidationFee(_pid, poolInfo[_pid].baseToken, borrowAmount);

        utils.transferFromAllToken(address(this), _hunter,
                            poolInfo[_pid].collateralToken[0],
                            poolInfo[_pid].collateralToken[1]);

        if(address(actionPool) != address(0) && lpAmountOld > 0) {
            actionPool.onAcionOut(_pid, _account, lpAmountOld, 0);
        }
    }

    function makeLiquidationRepay(uint256 _pid, address _account, uint256 _borrowAmount) internal {
        _borrowAmount;


        address token0 = poolInfo[_pid].collateralToken[0];
        address token1 = poolInfo[_pid].collateralToken[1];
        (uint256 amount0, uint256 amount1) = getTokenBalance_this(token0, token1);
        utils.getTokenIn(token0, amount0, poolInfo[_pid].baseToken);
        utils.getTokenIn(token1, amount1, poolInfo[_pid].baseToken);


        repayBorrow(_pid, _account, 1e9, false);
        require(userInfo[_pid][_account].borrowFrom == address(0), 'debt not clear');
    }
}
