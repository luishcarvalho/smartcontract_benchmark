

pragma solidity ^0.8.7;

import "../interfaces/external/uniswap/IUniswapV3Router.sol";
import "../interfaces/external/aave/IAave.sol";

import "./GenericLenderBase.sol";





contract GenericAave is GenericLenderBase {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 internal constant _SECONDS_IN_YEAR = 365 days;
    uint16 internal constant _DEFAULT_REFERRAL = 179;



    IProtocolDataProvider public constant protocolDataProvider =
        IProtocolDataProvider(address(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d));
    IAToken public aToken;
    IStakedAave public constant stkAave = IStakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant AAVE = address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IUniswapV3Router public uniswapRouter;



    bytes public path;
    bool public isIncentivised;
    uint16 internal _customReferral;




    constructor(
        address _strategy,
        string memory name,
        IUniswapV3Router _uniswapRouter,
        IAToken _aToken,
        bool _isIncentivised,
        bytes memory _path,
        address[] memory governorList,
        address guardian
    ) GenericLenderBase(_strategy, name, governorList, guardian) {
        require(address(aToken) == address(0), "already initialized");

        require(
            !_isIncentivised || address(_aToken.getIncentivesController()) != address(0),
            "aToken does not have incentives controller set up"
        );
        uniswapRouter = _uniswapRouter;
        isIncentivised = _isIncentivised;
        aToken = _aToken;
        path = _path;
        require(_lendingPool().getReserveData(address(want)).aTokenAddress == address(_aToken), "wrong aToken");
        IERC20(address(want)).safeApprove(address(_lendingPool()), type(uint256).max);
    }




    function deposit() external override onlyRole(STRATEGY_ROLE) {
        uint256 balance = want.balanceOf(address(this));
        _deposit(balance);
    }




    function withdraw(uint256 amount) external override onlyRole(STRATEGY_ROLE) returns (uint256) {
        return _withdraw(amount);
    }




    function emergencyWithdraw(uint256 amount) external override onlyRole(GUARDIAN_ROLE) {
        _lendingPool().withdraw(address(want), amount, address(this));

        want.safeTransfer(address(poolManager), want.balanceOf(address(this)));
    }


    function withdrawAll() external override onlyRole(STRATEGY_ROLE) returns (bool) {
        uint256 invested = _nav();
        uint256 returned = _withdraw(invested);
        return returned >= invested;
    }

    function startCooldown() external onlyRole(GUARDIAN_ROLE) {

        IStakedAave(stkAave).cooldown();
    }





    function harvest() external {
        require(_checkCooldown(), "conditions are not met");

        uint256 stkAaveBalance = IERC20(address(stkAave)).balanceOf(address(this));
        if (stkAaveBalance > 0) {
            stkAave.redeem(address(this), stkAaveBalance);
        }


        uint256 aaveBalance = IERC20(AAVE).balanceOf(address(this));
        _sellAAVEForWant(aaveBalance);


        uint256 balance = want.balanceOf(address(this));
        if (balance > 0) {
            _deposit(balance);
        }


        address[] memory assets = new address[](1);
        assets[0] = address(aToken);
        uint256 pendingRewards = _incentivesController().getRewardsBalance(assets, address(this));
        if (pendingRewards > 0) {
            _incentivesController().claimRewards(assets, pendingRewards, address(this));
        }


        if (IERC20(address(stkAave)).balanceOf(address(this)) > 0) {
            stkAave.cooldown();
        }
    }




    function nav() external view override returns (uint256) {
        return _nav();
    }


    function underlyingBalanceStored() public view returns (uint256 balance) {
        balance = aToken.balanceOf(address(this));
    }


    function apr() external view override returns (uint256) {
        return _apr();
    }


    function weightedApr() external view override returns (uint256) {
        uint256 a = _apr();
        return a * _nav();
    }



    function aprAfterDeposit(uint256 extraAmount) external view override returns (uint256) {

        DataTypes.ReserveData memory reserveData = _lendingPool().getReserveData(address(want));

        (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            ,
            ,
            ,
            uint256 averageStableBorrowRate,
            ,
            ,

        ) = protocolDataProvider.getReserveData(address(want));

        uint256 newLiquidity = availableLiquidity + extraAmount;

        (, , , , uint256 reserveFactor, , , , , ) = protocolDataProvider.getReserveConfigurationData(address(want));

        (uint256 newLiquidityRate, , ) = IReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
            .calculateInterestRates(
                address(want),
                newLiquidity,
                totalStableDebt,
                totalVariableDebt,
                averageStableBorrowRate,
                reserveFactor
            );

        return newLiquidityRate / 1e9;
    }


    function hasAssets() external view override returns (bool) {
        return aToken.balanceOf(address(this)) > 0;
    }


    function harvestTrigger() external view returns (bool) {
        return _checkCooldown();
    }




    function _apr() internal view returns (uint256) {
        uint256 liquidityRate = uint256(_lendingPool().getReserveData(address(want)).currentLiquidityRate) / 1e9;
        return liquidityRate;
    }


    function _nav() internal view returns (uint256) {
        return want.balanceOf(address(this)) + underlyingBalanceStored();
    }


    function _withdraw(uint256 amount) internal returns (uint256) {
        uint256 balanceUnderlying = aToken.balanceOf(address(this));
        uint256 looseBalance = want.balanceOf(address(this));
        uint256 total = balanceUnderlying + looseBalance;

        if (amount > total) {

            amount = total;
        }

        if (looseBalance >= amount) {
            want.safeTransfer(address(strategy), amount);
            return amount;
        }


        uint256 liquidity = want.balanceOf(address(aToken));

        if (liquidity > 1) {
            uint256 toWithdraw = amount - looseBalance;

            if (toWithdraw <= liquidity) {

                _lendingPool().withdraw(address(want), toWithdraw, address(this));
            } else {

                _lendingPool().withdraw(address(want), liquidity, address(this));
            }
        }
        looseBalance = want.balanceOf(address(this));
        want.safeTransfer(address(strategy), looseBalance);
        return looseBalance;
    }


    function _deposit(uint256 amount) internal {
        ILendingPool lp = _lendingPool();




        if (want.allowance(address(this), address(lp)) < amount) {
            IERC20(address(want)).safeApprove(address(lp), 0);
            IERC20(address(want)).safeApprove(address(lp), type(uint256).max);
        }

        uint16 referral;
        uint16 __customReferral = _customReferral;
        if (__customReferral != 0) {
            referral = __customReferral;
        } else {
            referral = _DEFAULT_REFERRAL;
        }

        lp.deposit(address(want), amount, address(this), referral);
    }


    function _lendingPool() internal view returns (ILendingPool lendingPool) {
        lendingPool = ILendingPool(protocolDataProvider.ADDRESSES_PROVIDER().getLendingPool());
    }


    function _checkCooldown() internal view returns (bool) {
        if (!isIncentivised) {
            return false;
        }

        uint256 cooldownStartTimestamp = IStakedAave(stkAave).stakersCooldowns(address(this));
        uint256 cooldownSeconds = IStakedAave(stkAave).COOLDOWN_SECONDS();
        uint256 unstakeWindow = IStakedAave(stkAave).UNSTAKE_WINDOW();
        if (block.timestamp >= cooldownStartTimestamp + cooldownSeconds) {
            return
                block.timestamp - cooldownStartTimestamp + cooldownSeconds <= unstakeWindow ||
                cooldownStartTimestamp == 0;
        } else {
            return false;
        }
    }



    function _sellAAVEForWant(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        if (IERC20(AAVE).allowance(address(this), address(uniswapRouter)) < _amount) {
            IERC20(AAVE).safeApprove(address(uniswapRouter), 0);
            IERC20(AAVE).safeApprove(address(uniswapRouter), type(uint256).max);
        }

        uniswapRouter.exactInput(ExactInputParams(path, address(this), block.timestamp, _amount, uint256(0)));
    }


    function _incentivesController() internal view returns (IAaveIncentivesController) {
        if (isIncentivised) {
            return aToken.getIncentivesController();
        } else {
            return IAaveIncentivesController(address(0));
        }
    }


    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(aToken);
        return protected;
    }





    function setIsIncentivised(bool _isIncentivised) external onlyRole(GUARDIAN_ROLE) {


        require(
            !_isIncentivised || address(aToken.getIncentivesController()) != address(0),
            "aToken does not have incentives controller set up"
        );
        isIncentivised = _isIncentivised;
    }



    function setReferralCode(uint16 __customReferral) external onlyRole(GUARDIAN_ROLE) {
        require(__customReferral != 0, "invalid referral code");
        _customReferral = __customReferral;
    }



    function setPath(bytes memory _path) external onlyRole(GUARDIAN_ROLE) {
        path = _path;
    }
}
