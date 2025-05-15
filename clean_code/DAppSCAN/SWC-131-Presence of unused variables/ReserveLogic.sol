
pragma solidity 0.8.7;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IStableDebtToken} from '../../../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {MathUtils} from '../math/MathUtils.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {Errors} from '../helpers/Errors.sol';
import {Helpers} from '../helpers/Helpers.sol';
import {DataTypes} from '../types/DataTypes.sol';






library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;


  event ReserveDataUpdated(
    address indexed asset,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;








  function getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;


    if (timestamp == uint40(block.timestamp)) {

      return reserve.liquidityIndex;
    }

    uint256 cumulated = MathUtils
      .calculateLinearInterest(reserve.currentLiquidityRate, timestamp)
      .rayMul(reserve.liquidityIndex);

    return cumulated;
  }








  function getNormalizedDebt(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;


    if (timestamp == uint40(block.timestamp)) {

      return reserve.variableBorrowIndex;
    }

    uint256 cumulated = MathUtils
      .calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp)
      .rayMul(reserve.variableBorrowIndex);

    return cumulated;
  }






  function updateState(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    _updateIndexes(reserve, reserveCache);
    _accrueToTreasury(reserve, reserveCache);
  }








  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount
  ) internal {
    uint256 amountToLiquidityRatio = amount.wadToRay().rayDiv(totalLiquidity.wadToRay());

    uint256 result = amountToLiquidityRatio + WadRayMath.RAY;

    result = result.rayMul(reserve.liquidityIndex);
    reserve.liquidityIndex = Helpers.castUint128(result);
  }









  function init(
    DataTypes.ReserveData storage reserve,
    address aTokenAddress,
    address stableDebtTokenAddress,
    address variableDebtTokenAddress,
    address interestRateStrategyAddress
  ) internal {
    require(reserve.aTokenAddress == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);

    reserve.liquidityIndex = uint128(WadRayMath.RAY);
    reserve.variableBorrowIndex = uint128(WadRayMath.RAY);
    reserve.aTokenAddress = aTokenAddress;
    reserve.stableDebtTokenAddress = stableDebtTokenAddress;
    reserve.variableDebtTokenAddress = variableDebtTokenAddress;
    reserve.interestRateStrategyAddress = interestRateStrategyAddress;
  }

  struct UpdateInterestRatesLocalVars {
    uint256 nextLiquidityRate;
    uint256 nextStableRate;
    uint256 nextVariableRate;
    uint256 avgStableRate;
    uint256 totalVariableDebt;
  }









  function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {
    UpdateInterestRatesLocalVars memory vars;

    vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );

    (
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      DataTypes.CalculateInterestRatesParams(
        reserveCache.reserveConfiguration.getUnbackedMintCap() > 0 ? reserve.unbacked : 0,
        liquidityAdded,
        liquidityTaken,
        reserveCache.nextTotalStableDebt,
        vars.totalVariableDebt,
        reserveCache.nextAvgStableBorrowRate,
        reserveCache.reserveFactor,
        reserveAddress,
        reserveCache.aTokenAddress
      )
    );

    reserve.currentLiquidityRate = Helpers.castUint128(vars.nextLiquidityRate);
    reserve.currentStableBorrowRate = Helpers.castUint128(vars.nextStableRate);
    reserve.currentVariableBorrowRate = Helpers.castUint128(vars.nextVariableRate);

    emit ReserveDataUpdated(
      reserveAddress,
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
  }

  struct AccrueToTreasuryLocalVars {
    uint256 prevTotalStableDebt;
    uint256 prevTotalVariableDebt;
    uint256 currTotalVariableDebt;
    uint256 avgStableRate;
    uint256 cumulatedStableInterest;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
    uint40 stableSupplyUpdatedTimestamp;
  }







  function _accrueToTreasury(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    AccrueToTreasuryLocalVars memory vars;

    if (reserveCache.reserveFactor == 0) {
      return;
    }


    vars.prevTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
      reserveCache.currVariableBorrowIndex
    );


    vars.currTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );


    vars.cumulatedStableInterest = MathUtils.calculateCompoundedInterest(
      reserveCache.currAvgStableBorrowRate,
      reserveCache.stableDebtLastUpdateTimestamp,
      reserveCache.reserveLastUpdateTimestamp
    );

    vars.prevTotalStableDebt = reserveCache.currPrincipalStableDebt.rayMul(
      vars.cumulatedStableInterest
    );


    vars.totalDebtAccrued =
      vars.currTotalVariableDebt +
      reserveCache.currTotalStableDebt -
      vars.prevTotalVariableDebt -
      vars.prevTotalStableDebt;

    vars.amountToMint = vars.totalDebtAccrued.percentMul(reserveCache.reserveFactor);

    if (vars.amountToMint != 0) {
      reserve.accruedToTreasury =
        reserve.accruedToTreasury +
        Helpers.castUint128((vars.amountToMint.rayDiv(reserveCache.nextLiquidityIndex)));
    }
  }






  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    reserveCache.nextLiquidityIndex = reserveCache.currLiquidityIndex;
    reserveCache.nextVariableBorrowIndex = reserveCache.currVariableBorrowIndex;


    if (reserveCache.currLiquidityRate > 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
        reserveCache.currLiquidityRate,
        reserveCache.reserveLastUpdateTimestamp
      );
      reserveCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
        reserveCache.currLiquidityIndex
      );
      reserve.liquidityIndex = Helpers.castUint128(reserveCache.nextLiquidityIndex);



      if (reserveCache.currScaledVariableDebt != 0) {
        uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
          reserveCache.currVariableBorrowRate,
          reserveCache.reserveLastUpdateTimestamp
        );
        reserveCache.nextVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(
          reserveCache.currVariableBorrowIndex
        );
        reserve.variableBorrowIndex = Helpers.castUint128(reserveCache.nextVariableBorrowIndex);
      }
    }


    reserve.lastUpdateTimestamp = uint40(block.timestamp);
  }






  function cache(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (DataTypes.ReserveCache memory)
  {
    DataTypes.ReserveCache memory reserveCache;

    reserveCache.reserveConfiguration = reserve.configuration;
    reserveCache.reserveFactor = reserveCache.reserveConfiguration.getReserveFactor();
    reserveCache.currLiquidityIndex = reserve.liquidityIndex;
    reserveCache.currVariableBorrowIndex = reserve.variableBorrowIndex;
    reserveCache.currLiquidityRate = reserve.currentLiquidityRate;
    reserveCache.currVariableBorrowRate = reserve.currentVariableBorrowRate;

    reserveCache.aTokenAddress = reserve.aTokenAddress;
    reserveCache.stableDebtTokenAddress = reserve.stableDebtTokenAddress;
    reserveCache.variableDebtTokenAddress = reserve.variableDebtTokenAddress;

    reserveCache.reserveLastUpdateTimestamp = reserve.lastUpdateTimestamp;

    reserveCache.currScaledVariableDebt = reserveCache.nextScaledVariableDebt = IVariableDebtToken(
      reserveCache.variableDebtTokenAddress
    ).scaledTotalSupply();

    (
      reserveCache.currPrincipalStableDebt,
      reserveCache.currTotalStableDebt,
      reserveCache.currAvgStableBorrowRate,
      reserveCache.stableDebtLastUpdateTimestamp
    ) = IStableDebtToken(reserveCache.stableDebtTokenAddress).getSupplyData();



    reserveCache.nextTotalStableDebt = reserveCache.currTotalStableDebt;
    reserveCache.nextAvgStableBorrowRate = reserveCache.currAvgStableBorrowRate;

    return reserveCache;
  }
}
