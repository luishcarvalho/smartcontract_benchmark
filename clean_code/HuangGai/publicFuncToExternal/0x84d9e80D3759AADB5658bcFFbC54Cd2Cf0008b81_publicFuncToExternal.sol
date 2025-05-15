














pragma solidity 0.6.12;



interface ICoFiXFactory {

    event PairCreated(address indexed token, address pair, uint256);
    event NewGovernance(address _new);
    event NewController(address _new);
    event NewFeeReceiver(address _new);
    event NewVaultForLP(address _new);
    event NewVaultForTrader(address _new);
    event NewVaultForCNode(address _new);




    function createPair(
        address token
        )
        external
        returns (address pair);

    function getPair(address token) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function getTradeMiningStatus(address token) external view returns (bool status);
    function setTradeMiningStatus(address token, bool status) external;

    function setGovernance(address _new) external;
    function setController(address _new) external;
    function setFeeReceiver(address _new) external;
    function setVaultForLP(address _new) external;
    function setVaultForTrader(address _new) external;
    function setVaultForCNode(address _new) external;
    function getController() external view returns (address controller);
    function getFeeReceiver() external view returns (address feeReceiver);
    function getVaultForLP() external view returns (address vaultForLP);
    function getVaultForTrader() external view returns (address vaultForTrader);
    function getVaultForCNode() external view returns (address vaultForCNode);
}



library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


interface ICoFiXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);











    function addLiquidity(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (uint liquidity);









    function addLiquidityAndStake(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (uint liquidity);








    function removeLiquidityGetToken(
        address token,
        uint liquidity,
        uint amountTokenMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken);








    function removeLiquidityGetETH(
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountETH);










    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);










    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);











    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);










    function swapETHForExactTokens(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);










    function swapTokensForExactETH(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);
}















library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint);
}


interface ICoFiXERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);



    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


interface ICoFiXPair is ICoFiXERC20 {

    struct OraclePrice {
        uint256 ethAmount;
        uint256 erc20Amount;
        uint256 blockNum;
        uint256 K;
        uint256 theta;
    }


    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, address outToken, uint outAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address outToken,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function mint(address to) external payable returns (uint liquidity, uint oracleFeeChange);
    function burn(address outToken, address to) external payable returns (uint amountOut, uint oracleFeeChange);
    function swapWithExact(address outToken, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo);
    function swapForExact(address outToken, uint amountOutExact, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo);
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, string memory, string memory) external;





    function getNAVPerShare(uint256 ethAmount, uint256 erc20Amount) external view returns (uint256 navps);
}


interface ICoFiXVaultForLP {

    enum POOL_STATE {INVALID, ENABLED, DISABLED}

    event NewPoolAdded(address pool, uint256 index);
    event PoolEnabled(address pool);
    event PoolDisabled(address pool);

    function setGovernance(address _new) external;
    function setInitCoFiRate(uint256 _new) external;
    function setDecayPeriod(uint256 _new) external;
    function setDecayRate(uint256 _new) external;

    function addPool(address pool) external;
    function enablePool(address pool) external;
    function disablePool(address pool) external;
    function setPoolWeight(address pool, uint256 weight) external;
    function batchSetPoolWeight(address[] memory pools, uint256[] memory weights) external;
    function distributeReward(address to, uint256 amount) external;

    function getPendingRewardOfLP(address pair) external view returns (uint256);
    function currentPeriod() external view returns (uint256);
    function currentCoFiRate() external view returns (uint256);
    function currentPoolRate(address pool) external view returns (uint256 poolRate);
    function currentPoolRateByPair(address pair) external view returns (uint256 poolRate);




    function stakingPoolForPair(address pair) external view returns (address pool);

    function getPoolInfo(address pool) external view returns (POOL_STATE state, uint256 weight);
    function getPoolInfoByPair(address pair) external view returns (POOL_STATE state, uint256 weight);

    function getEnabledPoolCnt() external view returns (uint256);

    function getCoFiStakingPool() external view returns (address pool);

}


interface ICoFiXStakingRewards {




    function rewardsVault() external view returns (address);



    function lastBlockRewardApplicable() external view returns (uint256);


    function rewardPerToken() external view returns (uint256);




    function earned(address account) external view returns (uint256);



    function accrued() external view returns (uint256);



    function rewardRate() external view returns (uint256);



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);



    function stakingToken() external view returns (address);



    function rewardsToken() external view returns (address);





    function stake(uint256 amount) external;




    function stakeForOther(address other, uint256 amount) external;



    function withdraw(uint256 amount) external;


    function emergencyWithdraw() external;


    function getReward() external;

    function getRewardAndStake() external;


    function exit() external;


    function addReward(uint256 amount) external;


    event RewardAdded(address sender, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event StakedForOther(address indexed user, address indexed other, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}


interface ICoFiXVaultForTrader {

    event RouterAllowed(address router);
    event RouterDisallowed(address router);

    event ClearPendingRewardOfCNode(uint256 pendingAmount);
    event ClearPendingRewardOfLP(uint256 pendingAmount);

    function setGovernance(address gov) external;

    function setExpectedYieldRatio(uint256 r) external;
    function setLRatio(uint256 lRatio) external;
    function setTheta(uint256 theta) external;

    function allowRouter(address router) external;

    function disallowRouter(address router) external;

    function calcCoFiRate(uint256 bt_phi, uint256 xt, uint256 np) external view returns (uint256 at);

    function currentCoFiRate(address pair, uint256 np) external view returns (uint256);

    function currentThreshold(address pair, uint256 np, uint256 cofiRate) external view returns (uint256);

    function stdMiningRateAndAmount(address pair, uint256 np, uint256 thetaFee) external view returns (uint256 cofiRate, uint256 stdAmount);

    function calcDensity(uint256 _stdAmount) external view returns (uint256);

    function calcLambda(uint256 x, uint256 y) external pure returns (uint256);

    function actualMiningAmountAndDensity(address pair, uint256 thetaFee, uint256 x, uint256 y, uint256 np) external view returns (uint256 amount, uint256 density, uint256 cofiRate);

    function distributeReward(address pair, uint256 thetaFee, uint256 x, uint256 y, uint256 np, address rewardTo) external;

    function clearPendingRewardOfCNode() external;

    function clearPendingRewardOfLP(address pair) external;

    function getPendingRewardOfCNode() external view returns (uint256);

    function getPendingRewardOfLP(address pair) external view returns (uint256);

    function getCoFiRateCache(address pair) external view returns (uint256 cofiRate, uint256 updatedBlock);
}



contract CoFiXRouter is ICoFiXRouter {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'CRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {}


    function pairFor(address _factory, address token) internal view returns (address pair) {






        return ICoFiXFactory(_factory).getPair(token);
    }


    function addLiquidity(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) public override payable ensure(deadline) returns (uint liquidity)
    {

        if (ICoFiXFactory(factory).getPair(token) == address(0)) {
            ICoFiXFactory(factory).createPair(token);
        }
        require(msg.value > amountETH, "CRouter: insufficient msg.value");
        uint256 _oracleFee = msg.value.sub(amountETH);
        address pair = pairFor(factory, token);
        if (amountToken > 0 ) {
            TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        }
        if (amountETH > 0) {
            IWETH(WETH).deposit{value: amountETH}();
            assert(IWETH(WETH).transfer(pair, amountETH));
        }
        uint256 oracleFeeChange;
        (liquidity, oracleFeeChange) = ICoFiXPair(pair).mint{value: _oracleFee}(to);
        require(liquidity >= liquidityMin, "CRouter: less liquidity than expected");

        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function addLiquidityAndStake(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) public override payable ensure(deadline) returns (uint liquidity)
    {

        require(msg.value > amountETH, "CRouter: insufficient msg.value");
        uint256 _oracleFee = msg.value.sub(amountETH);
        address pair = pairFor(factory, token);
        require(pair != address(0), "CRouter: invalid pair");
        if (amountToken > 0 ) {
            TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        }
        if (amountETH > 0) {
            IWETH(WETH).deposit{value: amountETH}();
            assert(IWETH(WETH).transfer(pair, amountETH));
        }
        uint256 oracleFeeChange;
        (liquidity, oracleFeeChange) = ICoFiXPair(pair).mint{value: _oracleFee}(address(this));
        require(liquidity >= liquidityMin, "CRouter: less liquidity than expected");


        address pool = ICoFiXVaultForLP(ICoFiXFactory(factory).getVaultForLP()).stakingPoolForPair(pair);
        require(pool != address(0), "CRouter: invalid staking pool");

        ICoFiXPair(pair).approve(pool, liquidity);
        ICoFiXStakingRewards(pool).stakeForOther(to, liquidity);
        ICoFiXPair(pair).approve(pool, 0);

        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function removeLiquidityGetToken(
        address token,
        uint liquidity,
        uint amountTokenMin,
        address to,
        uint deadline
    ) public override payable ensure(deadline) returns (uint amountToken)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        ICoFiXPair(pair).transferFrom(msg.sender, pair, liquidity);
        uint oracleFeeChange;
        (amountToken, oracleFeeChange) = ICoFiXPair(pair).burn{value: msg.value}(token, to);
        require(amountToken >= amountTokenMin, "CRouter: got less than expected");

        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function removeLiquidityGetETH(
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) public override payable ensure(deadline) returns (uint amountETH)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        ICoFiXPair(pair).transferFrom(msg.sender, pair, liquidity);
        uint oracleFeeChange;
        (amountETH, oracleFeeChange) = ICoFiXPair(pair).burn{value: msg.value}(WETH, address(this));
        require(amountETH >= amountETHMin, "CRouter: got less than expected");
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);

        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) public override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > amountIn, "CRouter: insufficient msg.value");
        IWETH(WETH).deposit{value: amountIn}();
        address pair = pairFor(factory, token);
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint oracleFeeChange;
        uint256[4] memory tradeInfo;
        (_amountIn, _amountOut, oracleFeeChange, tradeInfo) = ICoFiXPair(pair).swapWithExact{
            value: msg.value.sub(amountIn)}(token, to);
        require(_amountOut >= amountOutMin, "CRouter: got less than expected");


        address vaultForTrader = ICoFiXFactory(factory).getVaultForTrader();
        if (tradeInfo[0] > 0 && rewardTo != address(0) && vaultForTrader != address(0)) {
            ICoFiXVaultForTrader(vaultForTrader).distributeReward(pair, tradeInfo[0], tradeInfo[1], tradeInfo[2], tradeInfo[3], rewardTo);
        }


        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) public override payable ensure(deadline) returns (uint _amountIn, uint _amountOut) {

        require(msg.value > 0, "CRouter: insufficient msg.value");
        address[2] memory pairs;


        pairs[0] = pairFor(factory, tokenIn);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, pairs[0], amountIn);
        uint oracleFeeChange;
        uint256[4] memory tradeInfo;
        (_amountIn, _amountOut, oracleFeeChange, tradeInfo) = ICoFiXPair(pairs[0]).swapWithExact{value: msg.value}(WETH, address(this));


        address vaultForTrader = ICoFiXFactory(factory).getVaultForTrader();
        if (tradeInfo[0] > 0 && rewardTo != address(0) && vaultForTrader != address(0)) {
            ICoFiXVaultForTrader(vaultForTrader).distributeReward(pairs[0], tradeInfo[0], tradeInfo[1], tradeInfo[2], tradeInfo[3], rewardTo);
        }


        pairs[1] = pairFor(factory, tokenOut);
        assert(IWETH(WETH).transfer(pairs[1], _amountOut));
        (, _amountOut, oracleFeeChange, tradeInfo) = ICoFiXPair(pairs[1]).swapWithExact{value: oracleFeeChange}(tokenOut, to);
        require(_amountOut >= amountOutMin, "CRouter: got less than expected");


        if (tradeInfo[0] > 0 && rewardTo != address(0) && vaultForTrader != address(0)) {
            ICoFiXVaultForTrader(vaultForTrader).distributeReward(pairs[1], tradeInfo[0], tradeInfo[1], tradeInfo[2], tradeInfo[3], rewardTo);
        }


        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) public override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountIn);
        uint oracleFeeChange;
        uint256[4] memory tradeInfo;
        (_amountIn, _amountOut, oracleFeeChange, tradeInfo) = ICoFiXPair(pair).swapWithExact{value: msg.value}(WETH, address(this));
        require(_amountOut >= amountOutMin, "CRouter: got less than expected");
        IWETH(WETH).withdraw(_amountOut);
        TransferHelper.safeTransferETH(to, _amountOut);


        address vaultForTrader = ICoFiXFactory(factory).getVaultForTrader();
        if (tradeInfo[0] > 0 && rewardTo != address(0) && vaultForTrader != address(0)) {
            ICoFiXVaultForTrader(vaultForTrader).distributeReward(pair, tradeInfo[0], tradeInfo[1], tradeInfo[2], tradeInfo[3], rewardTo);
        }


        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function swapETHForExactTokens(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        address rewardTo,
        uint deadline
    ) public override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > amountInMax, "CRouter: insufficient msg.value");
        IWETH(WETH).deposit{value: amountInMax}();
        address pair = pairFor(factory, token);
        assert(IWETH(WETH).transfer(pair, amountInMax));
        uint oracleFeeChange;
        uint256[4] memory tradeInfo;
        (_amountIn, _amountOut, oracleFeeChange, tradeInfo) = ICoFiXPair(pair).swapForExact{
            value: msg.value.sub(amountInMax) }(token, amountOutExact, to);

        require(_amountIn <= amountInMax, "CRouter: spend more than expected");


        address vaultForTrader = ICoFiXFactory(factory).getVaultForTrader();
        if (tradeInfo[0] > 0 && rewardTo != address(0) && vaultForTrader != address(0)) {
            ICoFiXVaultForTrader(vaultForTrader).distributeReward(pair, tradeInfo[0], tradeInfo[1], tradeInfo[2], tradeInfo[3], rewardTo);
        }


        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }


    function swapTokensForExactETH(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        address rewardTo,
        uint deadline
    ) public override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountInMax);
        uint oracleFeeChange;
        uint256[4] memory tradeInfo;
        (_amountIn, _amountOut, oracleFeeChange, tradeInfo) = ICoFiXPair(pair).swapForExact{
            value: msg.value}(WETH, amountOutExact, address(this));

        require(_amountIn <= amountInMax, "CRouter: got less than expected");
        IWETH(WETH).withdraw(_amountOut);


        address vaultForTrader = ICoFiXFactory(factory).getVaultForTrader();
        if (tradeInfo[0] > 0 && rewardTo != address(0) && vaultForTrader != address(0)) {
            ICoFiXVaultForTrader(vaultForTrader).distributeReward(pair, tradeInfo[0], tradeInfo[1], tradeInfo[2], tradeInfo[3], rewardTo);
        }

        TransferHelper.safeTransferETH(to, amountOutExact);

        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }
}
