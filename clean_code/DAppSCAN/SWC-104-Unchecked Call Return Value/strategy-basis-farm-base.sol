
pragma solidity ^0.6.7;

import "./strategy-base.sol";

abstract contract StrategyBasisFarmBase is StrategyBase {

    address public token1;
    address public token2;
    address public rewards;
    address public pool;
    address[] public path;



    uint256 public keepRewards = 0;
    uint256 public constant keepRewardsMax = 10000;

    uint256 public poolId;

    constructor(
        address _rewards,
        address _pool,
        address _controller,
        address _token1,
        address _token2,
        address[] memory _path,
        address _lp,
        address _strategist,
        uint256 _poolId
    )
        public
        StrategyBase(_lp, _strategist, _controller)
    {
        token1 = _token1;
        token2 = _token2;
        rewards = _rewards;
        path = _path;
        pool = _pool;
        poolId = _poolId;
    }



    function setKeep(uint256 _keep) external {
        require(msg.sender == strategist, "!strategist");
        keepRewards = _keep;
    }


    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(pool).balanceOf(poolId,address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(pool).rewardEarned(poolId,address(this));
    }

    function deposit() public override {
        uint256 _lp = IERC20(lp).balanceOf(address(this));
        if (_lp > 0) {
            IERC20(lp).safeApprove(pool, 0);
            IERC20(lp).safeApprove(pool, _lp);
            IStakingRewards(pool).deposit(poolId,_lp);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(pool).withdraw(poolId,_amount);
        return _amount;
    }


    function harvest() public override onlyBenevolent {





        address[] memory _path = new address[](2);


        IStakingRewards(pool).claimReward(poolId);
        uint256 _rewards = IERC20(rewards).balanceOf(address(this));
        uint256 _token1 = 0;

        if (_rewards > 0) {

            uint256 _keepRewards =
                _rewards.mul(keepRewards).div(keepRewardsMax);
            IERC20(rewards).safeTransfer(
                IController(controller).treasury(),
                _keepRewards
            );

            if (rewards == token1){
                _token1 = _rewards.sub(_keepRewards);
            } else {

                _swapUniswapWithPath(path, _rewards.sub(_keepRewards));
                _token1 = IERC20(token1).balanceOf(address(this));
            }
        }



        if (_token1 > 0) {
            _path[0] = token1;
            _path[1] = token2;
            _swapUniswapWithPath(_path, _token1.div(2));
        }


        _token1 = IERC20(token1).balanceOf(address(this));
        uint256 _token2 = IERC20(token2).balanceOf(address(this));

        if (_token1 > 0 && _token2 > 0) {
            IERC20(token1).safeApprove(univ2Router2, 0);
            IERC20(token1).safeApprove(univ2Router2, _token1);

            IERC20(token2).safeApprove(univ2Router2, 0);
            IERC20(token2).safeApprove(univ2Router2, _token2);

            UniswapRouterV2(univ2Router2).addLiquidity(
                token1,
                token2,
                _token1,
                _token2,
                0,
                0,
                address(this),
                now + 60
            );


            IERC20(token1).transfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
            IERC20(token2).safeTransfer(
                IController(controller).treasury(),
                IERC20(token2).balanceOf(address(this))
            );
        }


        _distributePerformanceFeesAndDeposit();
    }
}
