
pragma solidity ^0.6.8;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  VersionedInitializable
} from '../libraries/openzeppelin-upgradeability/VersionedInitializable.sol';
import {IAToken} from '../tokenization/interfaces/IAToken.sol';
import {IStableDebtToken} from '../tokenization/interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../tokenization/interfaces/IVariableDebtToken.sol';
import {DebtTokenBase} from '../tokenization/base/DebtTokenBase.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {GenericLogic} from '../libraries/logic/GenericLogic.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {Helpers} from '../libraries/helpers/Helpers.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ISwapAdapter} from '../interfaces/ISwapAdapter.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {ValidationLogic} from '../libraries/logic/ValidationLogic.sol';
import {LendingPoolStorage} from './LendingPoolStorage.sol';








contract LendingPoolCollateralManager is VersionedInitializable, LendingPoolStorage {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;




  uint256 internal constant LIQUIDATION_CLOSE_FACTOR_PERCENT = 5000;











  event LiquidationCall(
    address indexed collateral,
    address indexed principal,
    address indexed user,
    uint256 purchaseAmount,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );










  event RepaidWithCollateral(
    address indexed collateral,
    address indexed principal,
    address indexed user,
    address liquidator,
    uint256 principalAmount,
    uint256 swappedCollateralAmount
  );

  struct LiquidationCallLocalVars {
    uint256 userCollateralBalance;
    uint256 userStableDebt;
    uint256 userVariableDebt;
    uint256 maxPrincipalAmountToLiquidate;
    uint256 actualAmountToLiquidate;
    uint256 liquidationRatio;
    uint256 maxAmountCollateralToLiquidate;
    ReserveLogic.InterestRateMode borrowRateMode;
    uint256 userStableRate;
    uint256 maxCollateralToLiquidate;
    uint256 principalAmountNeeded;
    uint256 healthFactor;
    IAToken collateralAtoken;
    bool isCollateralEnabled;
    address principalAToken;
    uint256 errorCode;
    string errorMsg;
  }

  struct SwapLiquidityLocalVars {
    uint256 healthFactor;
    uint256 amountToReceive;
    uint256 userBalanceBefore;
    IAToken fromReserveAToken;
    IAToken toReserveAToken;
    uint256 errorCode;
    string errorMsg;
  }

  struct AvailableCollateralToLiquidateLocalVars {
    uint256 userCompoundedBorrowBalance;
    uint256 liquidationBonus;
    uint256 collateralPrice;
    uint256 principalCurrencyPrice;
    uint256 maxAmountCollateralToLiquidate;
    uint256 principalDecimals;
    uint256 collateralDecimals;
  }





  function getRevision() internal override pure returns (uint256) {
    return 0;
  }










  function liquidationCall(
    address collateral,
    address principal,
    address user,
    uint256 purchaseAmount,
    bool receiveAToken
  ) external returns (uint256, string memory) {
    ReserveLogic.ReserveData storage collateralReserve = _reserves[collateral];
    ReserveLogic.ReserveData storage principalReserve = _reserves[principal];
    UserConfiguration.Map storage userConfig = _usersConfig[user];

    LiquidationCallLocalVars memory vars;

    (, , , , vars.healthFactor) = GenericLogic.calculateUserAccountData(
      user,
      _reserves,
      _usersConfig[user],
      _reservesList,
      _addressesProvider.getPriceOracle()
    );


    (vars.userStableDebt, vars.userVariableDebt) = Helpers.getUserCurrentDebt(
      user,
      principalReserve
    );

    (vars.errorCode, vars.errorMsg) = ValidationLogic.validateLiquidationCall(
      collateralReserve,
      principalReserve,
      userConfig,
      vars.healthFactor,
      vars.userStableDebt,
      vars.userVariableDebt
    );

    if (Errors.CollateralManagerErrors(vars.errorCode) != Errors.CollateralManagerErrors.NO_ERROR) {
      return (vars.errorCode, vars.errorMsg);
    }

    vars.collateralAtoken = IAToken(collateralReserve.aTokenAddress);

    vars.userCollateralBalance = vars.collateralAtoken.balanceOf(user);

    vars.maxPrincipalAmountToLiquidate = vars.userStableDebt.add(vars.userVariableDebt).percentMul(
      LIQUIDATION_CLOSE_FACTOR_PERCENT
    );

    vars.actualAmountToLiquidate = purchaseAmount > vars.maxPrincipalAmountToLiquidate
      ? vars.maxPrincipalAmountToLiquidate
      : purchaseAmount;

    (
      vars.maxCollateralToLiquidate,
      vars.principalAmountNeeded
    ) = calculateAvailableCollateralToLiquidate(
      collateralReserve,
      principalReserve,
      collateral,
      principal,
      vars.actualAmountToLiquidate,
      vars.userCollateralBalance
    );





    if (vars.principalAmountNeeded < vars.actualAmountToLiquidate) {
      vars.actualAmountToLiquidate = vars.principalAmountNeeded;
    }


    if (!receiveAToken) {
      uint256 currentAvailableCollateral = IERC20(collateral).balanceOf(
        address(vars.collateralAtoken)
      );
      if (currentAvailableCollateral < vars.maxCollateralToLiquidate) {
        return (
          uint256(Errors.CollateralManagerErrors.NOT_ENOUGH_LIQUIDITY),
          Errors.NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE
        );
      }
    }


    principalReserve.updateState();

    principalReserve.updateInterestRates(
      principal,
      principalReserve.aTokenAddress,
      vars.actualAmountToLiquidate,
      0
    );

    if (vars.userVariableDebt >= vars.actualAmountToLiquidate) {
      IVariableDebtToken(principalReserve.variableDebtTokenAddress).burn(
        user,
        vars.actualAmountToLiquidate,
        principalReserve.variableBorrowIndex
      );
    } else {
      IVariableDebtToken(principalReserve.variableDebtTokenAddress).burn(
        user,
        vars.userVariableDebt,
        principalReserve.variableBorrowIndex
      );

      IStableDebtToken(principalReserve.stableDebtTokenAddress).burn(
        user,
        vars.actualAmountToLiquidate.sub(vars.userVariableDebt)
      );
    }


    if (receiveAToken) {
      vars.collateralAtoken.transferOnLiquidation(user, msg.sender, vars.maxCollateralToLiquidate);
    } else {



      collateralReserve.updateState();
      collateralReserve.updateInterestRates(
        collateral,
        address(vars.collateralAtoken),
        0,
        vars.maxCollateralToLiquidate
      );


      vars.collateralAtoken.burn(
        user,
        msg.sender,
        vars.maxCollateralToLiquidate,
        collateralReserve.liquidityIndex
      );
    }


    IERC20(principal).safeTransferFrom(
      msg.sender,
      principalReserve.aTokenAddress,
      vars.actualAmountToLiquidate
    );

    emit LiquidationCall(
      collateral,
      principal,
      user,
      vars.actualAmountToLiquidate,
      vars.maxCollateralToLiquidate,
      msg.sender,
      receiveAToken
    );

    return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.NO_ERRORS);
  }













  function repayWithCollateral(
    address collateral,
    address principal,
    address user,
    uint256 principalAmount,
    address receiver,
    bytes calldata params
  ) external returns (uint256, string memory) {
    ReserveLogic.ReserveData storage collateralReserve = _reserves[collateral];
    ReserveLogic.ReserveData storage debtReserve = _reserves[principal];
    UserConfiguration.Map storage userConfig = _usersConfig[user];

    LiquidationCallLocalVars memory vars;

    (, , , , vars.healthFactor) = GenericLogic.calculateUserAccountData(
      user,
      _reserves,
      _usersConfig[user],
      _reservesList,
      _addressesProvider.getPriceOracle()
    );

    (vars.userStableDebt, vars.userVariableDebt) = Helpers.getUserCurrentDebt(user, debtReserve);

    (vars.errorCode, vars.errorMsg) = ValidationLogic.validateRepayWithCollateral(
      collateralReserve,
      debtReserve,
      userConfig,
      user,
      vars.healthFactor,
      vars.userStableDebt,
      vars.userVariableDebt
    );

    if (Errors.CollateralManagerErrors(vars.errorCode) != Errors.CollateralManagerErrors.NO_ERROR) {
      return (vars.errorCode, vars.errorMsg);
    }

    vars.maxPrincipalAmountToLiquidate = vars.userStableDebt.add(vars.userVariableDebt);

    vars.actualAmountToLiquidate = principalAmount > vars.maxPrincipalAmountToLiquidate
      ? vars.maxPrincipalAmountToLiquidate
      : principalAmount;

    vars.collateralAtoken = IAToken(collateralReserve.aTokenAddress);
    vars.userCollateralBalance = vars.collateralAtoken.balanceOf(user);

    (
      vars.maxCollateralToLiquidate,
      vars.principalAmountNeeded
    ) = calculateAvailableCollateralToLiquidate(
      collateralReserve,
      debtReserve,
      collateral,
      principal,
      vars.actualAmountToLiquidate,
      vars.userCollateralBalance
    );




    if (vars.principalAmountNeeded < vars.actualAmountToLiquidate) {
      vars.actualAmountToLiquidate = vars.principalAmountNeeded;
    }

    collateralReserve.updateState();

    vars.collateralAtoken.burn(
      user,
      receiver,
      vars.maxCollateralToLiquidate,
      collateralReserve.liquidityIndex
    );

    if (vars.userCollateralBalance == vars.maxCollateralToLiquidate) {
      _usersConfig[user].setUsingAsCollateral(collateralReserve.id, false);
    }

    vars.principalAToken = debtReserve.aTokenAddress;


    ISwapAdapter(receiver).executeOperation(
      collateral,
      principal,
      vars.maxCollateralToLiquidate,
      address(this),
      params
    );


    debtReserve.updateState();
    debtReserve.updateInterestRates(
      principal,
      vars.principalAToken,
      vars.actualAmountToLiquidate,
      0
    );
    IERC20(principal).transferFrom(receiver, vars.principalAToken, vars.actualAmountToLiquidate);

    if (vars.userVariableDebt >= vars.actualAmountToLiquidate) {
      IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
        user,
        vars.actualAmountToLiquidate,
        debtReserve.variableBorrowIndex
      );
    } else {
      IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
        user,
        vars.userVariableDebt,
        debtReserve.variableBorrowIndex
      );
      IStableDebtToken(debtReserve.stableDebtTokenAddress).burn(
        user,
        vars.actualAmountToLiquidate.sub(vars.userVariableDebt)
      );
    }


    collateralReserve.updateInterestRates(
      collateral,
      address(vars.collateralAtoken),
      0,
      vars.maxCollateralToLiquidate
    );

    emit RepaidWithCollateral(
      collateral,
      principal,
      user,
      msg.sender,
      vars.actualAmountToLiquidate,
      vars.maxCollateralToLiquidate
    );

    return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.NO_ERRORS);
  }









  function swapLiquidity(
    address receiverAddress,
    address fromAsset,
    address toAsset,
    uint256 amountToSwap,
    bytes calldata params
  ) external returns (uint256, string memory) {
    ReserveLogic.ReserveData storage fromReserve = _reserves[fromAsset];
    ReserveLogic.ReserveData storage toReserve = _reserves[toAsset];

    SwapLiquidityLocalVars memory vars;

    (vars.errorCode, vars.errorMsg) = ValidationLogic.validateSwapLiquidity(
      fromReserve,
      toReserve,
      fromAsset,
      toAsset
    );

    if (Errors.CollateralManagerErrors(vars.errorCode) != Errors.CollateralManagerErrors.NO_ERROR) {
      return (vars.errorCode, vars.errorMsg);
    }

    vars.fromReserveAToken = IAToken(fromReserve.aTokenAddress);
    vars.toReserveAToken = IAToken(toReserve.aTokenAddress);

    fromReserve.updateState();
    toReserve.updateState();

    if (vars.fromReserveAToken.balanceOf(msg.sender) == amountToSwap) {
      _usersConfig[msg.sender].setUsingAsCollateral(fromReserve.id, false);
    }

    fromReserve.updateInterestRates(fromAsset, address(vars.fromReserveAToken), 0, amountToSwap);

    vars.fromReserveAToken.burn(
      msg.sender,
      receiverAddress,
      amountToSwap,
      fromReserve.liquidityIndex
    );

    ISwapAdapter(receiverAddress).executeOperation(
      fromAsset,
      toAsset,
      amountToSwap,
      address(this),
      params
    );

    vars.amountToReceive = IERC20(toAsset).balanceOf(receiverAddress);
    if (vars.amountToReceive != 0) {
      IERC20(toAsset).transferFrom(
        receiverAddress,
        address(vars.toReserveAToken),
        vars.amountToReceive
      );

      if (vars.toReserveAToken.balanceOf(msg.sender) == 0) {
        _usersConfig[msg.sender].setUsingAsCollateral(toReserve.id, true);
      }

      vars.toReserveAToken.mint(msg.sender, vars.amountToReceive, toReserve.liquidityIndex);
      toReserve.updateInterestRates(
        toAsset,
        address(vars.toReserveAToken),
        vars.amountToReceive,
        0
      );
    }

    (, , , , vars.healthFactor) = GenericLogic.calculateUserAccountData(
      msg.sender,
      _reserves,
      _usersConfig[msg.sender],
      _reservesList,
      _addressesProvider.getPriceOracle()
    );

    if (vars.healthFactor < GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD) {
      return (
        uint256(Errors.CollateralManagerErrors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD),
        Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
      );
    }

    return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.NO_ERRORS);
  }












  function calculateAvailableCollateralToLiquidate(
    ReserveLogic.ReserveData storage collateralReserve,
    ReserveLogic.ReserveData storage principalReserve,
    address collateralAddress,
    address principalAddress,
    uint256 purchaseAmount,
    uint256 userCollateralBalance
  ) internal view returns (uint256, uint256) {
    uint256 collateralAmount = 0;
    uint256 principalAmountNeeded = 0;
    IPriceOracleGetter oracle = IPriceOracleGetter(_addressesProvider.getPriceOracle());

    AvailableCollateralToLiquidateLocalVars memory vars;

    vars.collateralPrice = oracle.getAssetPrice(collateralAddress);
    vars.principalCurrencyPrice = oracle.getAssetPrice(principalAddress);

    (, , vars.liquidationBonus, vars.collateralDecimals) = collateralReserve
      .configuration
      .getParams();
    vars.principalDecimals = principalReserve.configuration.getDecimals();



    vars.maxAmountCollateralToLiquidate = vars
      .principalCurrencyPrice
      .mul(purchaseAmount)
      .mul(10**vars.collateralDecimals)
      .div(vars.collateralPrice.mul(10**vars.principalDecimals))
      .percentMul(vars.liquidationBonus);

    if (vars.maxAmountCollateralToLiquidate > userCollateralBalance) {
      collateralAmount = userCollateralBalance;
      principalAmountNeeded = vars
        .collateralPrice
        .mul(collateralAmount)
        .mul(10**vars.principalDecimals)
        .div(vars.principalCurrencyPrice.mul(10**vars.collateralDecimals))
        .percentDiv(vars.liquidationBonus);
    } else {
      collateralAmount = vars.maxAmountCollateralToLiquidate;
      principalAmountNeeded = purchaseAmount;
    }
    return (collateralAmount, principalAmountNeeded);
  }
}
