
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  VersionedInitializable
} from '../libraries/openzeppelin-upgradeability/VersionedInitializable.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {IAToken} from '../tokenization/interfaces/IAToken.sol';
import {Helpers} from '../libraries/helpers/Helpers.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {GenericLogic} from '../libraries/logic/GenericLogic.sol';
import {ValidationLogic} from '../libraries/logic/ValidationLogic.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {IStableDebtToken} from '../tokenization/interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../tokenization/interfaces/IVariableDebtToken.sol';
import {DebtTokenBase} from '../tokenization/base/DebtTokenBase.sol';
import {IFlashLoanReceiver} from '../flashloan/interfaces/IFlashLoanReceiver.sol';
import {ISwapAdapter} from '../interfaces/ISwapAdapter.sol';
import {LendingPoolCollateralManager} from './LendingPoolCollateralManager.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {LendingPoolStorage} from './LendingPoolStorage.sol';
import {IReserveInterestRateStrategy} from '../interfaces/IReserveInterestRateStrategy.sol';





contract LendingPool is VersionedInitializable, ILendingPool, LendingPoolStorage {
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;


  uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 4000;
  uint256 public constant REBALANCE_UP_USAGE_RATIO_THRESHOLD = 0.95 * 1e27;
  uint256 public constant MAX_STABLE_RATE_BORROW_SIZE_PERCENT = 2500;
  uint256 public constant FLASHLOAN_PREMIUM_TOTAL = 9;
  uint256 public constant MAX_NUMBER_RESERVES = 128;
  uint256 public constant LENDINGPOOL_REVISION = 0x2;




  function _onlyLendingPoolConfigurator() internal view {
    require(
      _addressesProvider.getLendingPoolConfigurator() == msg.sender,
      Errors.CALLER_NOT_LENDING_POOL_CONFIGURATOR
    );
  }







  function _whenNotPaused() internal view {
    require(!_paused, Errors.IS_PAUSED);
  }

  function getRevision() internal override pure returns (uint256) {
    return LENDINGPOOL_REVISION;
  }






  function initialize(ILendingPoolAddressesProvider provider) public initializer {
    _addressesProvider = provider;
  }









  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external override {
    _whenNotPaused();
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    ValidationLogic.validateDeposit(reserve, amount);

    address aToken = reserve.aTokenAddress;

    reserve.updateState();
    reserve.updateInterestRates(asset, aToken, amount, 0);

    bool isFirstDeposit = IAToken(aToken).balanceOf(onBehalfOf) == 0;
    if (isFirstDeposit) {
      _usersConfig[onBehalfOf].setUsingAsCollateral(reserve.id, true);
    }

    IAToken(aToken).mint(onBehalfOf, amount, reserve.liquidityIndex);


    IERC20(asset).safeTransferFrom(msg.sender, aToken, amount);

    emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
  }






  function withdraw(address asset, uint256 amount) external override {
    _whenNotPaused();
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    address aToken = reserve.aTokenAddress;

    uint256 userBalance = IAToken(aToken).balanceOf(msg.sender);

    uint256 amountToWithdraw = amount;


    if (amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(
      asset,
      amountToWithdraw,
      userBalance,
      _reserves,
      _usersConfig[msg.sender],
      _reservesList,
      _addressesProvider.getPriceOracle()
    );

    reserve.updateState();

    reserve.updateInterestRates(asset, aToken, 0, amountToWithdraw);

    if (amountToWithdraw == userBalance) {
      _usersConfig[msg.sender].setUsingAsCollateral(reserve.id, false);
    }

    IAToken(aToken).burn(msg.sender, msg.sender, amountToWithdraw, reserve.liquidityIndex);

    emit Withdraw(asset, msg.sender, amount);
  }









  function getBorrowAllowance(
    address fromUser,
    address toUser,
    address asset,
    uint256 interestRateMode
  ) external override view returns (uint256) {
    return
      _borrowAllowance[_reserves[asset].getDebtTokenAddress(interestRateMode)][fromUser][toUser];
  }








  function delegateBorrowAllowance(
    address asset,
    address user,
    uint256 interestRateMode,
    uint256 amount
  ) external override {
    _whenNotPaused();
    address debtToken = _reserves[asset].getDebtTokenAddress(interestRateMode);

    _borrowAllowance[debtToken][msg.sender][user] = amount;
    emit BorrowAllowanceDelegated(asset, msg.sender, user, interestRateMode, amount);
  }










  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external override {
    _whenNotPaused();
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    if (onBehalfOf != msg.sender) {
      address debtToken = reserve.getDebtTokenAddress(interestRateMode);

      _borrowAllowance[debtToken][onBehalfOf][msg
        .sender] = _borrowAllowance[debtToken][onBehalfOf][msg.sender].sub(
        amount,
        Errors.BORROW_ALLOWANCE_ARE_NOT_ENOUGH
      );
    }
    _executeBorrow(
      ExecuteBorrowParams(
        asset,
        msg.sender,
        onBehalfOf,
        amount,
        interestRateMode,
        reserve.aTokenAddress,
        referralCode,
        true
      )
    );
  }









  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external override {
    _whenNotPaused();

    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(onBehalfOf, reserve);

    ReserveLogic.InterestRateMode interestRateMode = ReserveLogic.InterestRateMode(rateMode);


    uint256 paybackAmount = interestRateMode == ReserveLogic.InterestRateMode.STABLE
      ? stableDebt
      : variableDebt;

    if (amount != type(uint256).max && amount < paybackAmount) {
      paybackAmount = amount;
    }

    ValidationLogic.validateRepay(
      reserve,
      amount,
      interestRateMode,
      onBehalfOf,
      stableDebt,
      variableDebt
    );

    reserve.updateState();


    if (interestRateMode == ReserveLogic.InterestRateMode.STABLE) {
      IStableDebtToken(reserve.stableDebtTokenAddress).burn(onBehalfOf, paybackAmount);
    } else {
      IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
        onBehalfOf,
        paybackAmount,
        reserve.variableBorrowIndex
      );
    }

    address aToken = reserve.aTokenAddress;
    reserve.updateInterestRates(asset, aToken, paybackAmount, 0);

    if (stableDebt.add(variableDebt).sub(paybackAmount) == 0) {
      _usersConfig[onBehalfOf].setBorrowing(reserve.id, false);
    }

    IERC20(asset).safeTransferFrom(msg.sender, aToken, paybackAmount);

    emit Repay(asset, onBehalfOf, msg.sender, paybackAmount);
  }






  function swapBorrowRateMode(address asset, uint256 rateMode) external override {
    _whenNotPaused();
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(msg.sender, reserve);

    ReserveLogic.InterestRateMode interestRateMode = ReserveLogic.InterestRateMode(rateMode);

    ValidationLogic.validateSwapRateMode(
      reserve,
      _usersConfig[msg.sender],
      stableDebt,
      variableDebt,
      interestRateMode
    );

    reserve.updateState();

    if (interestRateMode == ReserveLogic.InterestRateMode.STABLE) {

      IStableDebtToken(reserve.stableDebtTokenAddress).burn(msg.sender, stableDebt);
      IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
        msg.sender,
        stableDebt,
        reserve.variableBorrowIndex
      );
    } else {

      IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
        msg.sender,
        variableDebt,
        reserve.variableBorrowIndex
      );
      IStableDebtToken(reserve.stableDebtTokenAddress).mint(
        msg.sender,
        variableDebt,
        reserve.currentStableBorrowRate
      );
    }

    reserve.updateInterestRates(asset, reserve.aTokenAddress, 0, 0);

    emit Swap(asset, msg.sender);
  }








  function rebalanceStableBorrowRate(address asset, address user) external override {

    _whenNotPaused();

    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    IERC20 stableDebtToken = IERC20(reserve.stableDebtTokenAddress);
    IERC20 variableDebtToken = IERC20(reserve.variableDebtTokenAddress);
    address aTokenAddress = reserve.aTokenAddress;

    uint256 stableBorrowBalance = IERC20(stableDebtToken).balanceOf(user);


    uint256 totalBorrows = stableDebtToken.totalSupply().add(variableDebtToken.totalSupply()).wadToRay();
    uint256 availableLiquidity = IERC20(asset).balanceOf(aTokenAddress).wadToRay();
    uint256 usageRatio = totalBorrows == 0
      ? 0
      : totalBorrows.rayDiv(availableLiquidity.add(totalBorrows));




    uint256 currentLiquidityRate = reserve.currentLiquidityRate;
    uint256 maxVariableBorrowRate = IReserveInterestRateStrategy(
      reserve
        .interestRateStrategyAddress
    )
      .getMaxVariableBorrowRate();

    require(
      usageRatio >= REBALANCE_UP_USAGE_RATIO_THRESHOLD &&
      currentLiquidityRate <=
        maxVariableBorrowRate.percentMul(REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD),
      Errors.INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET
    );

    reserve.updateState();

    IStableDebtToken(address(stableDebtToken)).burn(user, stableBorrowBalance);
    IStableDebtToken(address(stableDebtToken)).mint(user, stableBorrowBalance, reserve.currentStableBorrowRate);

    reserve.updateInterestRates(asset, aTokenAddress, 0, 0);

    emit RebalanceStableBorrowRate(asset, user);

  }






  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external override {
    _whenNotPaused();
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    ValidationLogic.validateSetUseReserveAsCollateral(
      reserve,
      asset,
      _reserves,
      _usersConfig[msg.sender],
      _reservesList,
      _addressesProvider.getPriceOracle()
    );

    _usersConfig[msg.sender].setUsingAsCollateral(reserve.id, useAsCollateral);

    if (useAsCollateral) {
      emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
    } else {
      emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
    }
  }










  function liquidationCall(
    address collateral,
    address asset,
    address user,
    uint256 purchaseAmount,
    bool receiveAToken
  ) external override {
    _whenNotPaused();
    address collateralManager = _addressesProvider.getLendingPoolCollateralManager();


    (bool success, bytes memory result) = collateralManager.delegatecall(
      abi.encodeWithSignature(
        'liquidationCall(address,address,address,uint256,bool)',
        collateral,
        asset,
        user,
        purchaseAmount,
        receiveAToken
      )
    );
    require(success, Errors.LIQUIDATION_CALL_FAILED);

    (uint256 returnCode, string memory returnMessage) = abi.decode(result, (uint256, string));

    if (returnCode != 0) {

      revert(string(abi.encodePacked(returnMessage)));
    }
  }













  function repayWithCollateral(
    address collateral,
    address principal,
    address user,
    uint256 principalAmount,
    address receiver,
    bytes calldata params
  ) external override {
    _whenNotPaused();
    require(!_flashLiquidationLocked, Errors.REENTRANCY_NOT_ALLOWED);
    _flashLiquidationLocked = true;

    address collateralManager = _addressesProvider.getLendingPoolCollateralManager();


    (bool success, bytes memory result) = collateralManager.delegatecall(
      abi.encodeWithSignature(
        'repayWithCollateral(address,address,address,uint256,address,bytes)',
        collateral,
        principal,
        user,
        principalAmount,
        receiver,
        params
      )
    );
    require(success, Errors.FAILED_REPAY_WITH_COLLATERAL);

    (uint256 returnCode, string memory returnMessage) = abi.decode(result, (uint256, string));

    if (returnCode != 0) {
      revert(string(abi.encodePacked(returnMessage)));
    }

    _flashLiquidationLocked = false;
  }

  struct FlashLoanLocalVars {
    uint256 premium;
    uint256 amountPlusPremium;
    IFlashLoanReceiver receiver;
    address aTokenAddress;
    address oracle;
  }












  function flashLoan(
    address receiverAddress,
    address asset,
    uint256 amount,
    uint256 mode,
    bytes calldata params,
    uint16 referralCode
  ) external override {
    _whenNotPaused();
    ReserveLogic.ReserveData storage reserve = _reserves[asset];
    FlashLoanLocalVars memory vars;

    vars.aTokenAddress = reserve.aTokenAddress;

    vars.premium = amount.mul(FLASHLOAN_PREMIUM_TOTAL).div(10000);

    ValidationLogic.validateFlashloan(mode, vars.premium);

    ReserveLogic.InterestRateMode debtMode = ReserveLogic.InterestRateMode(mode);

    vars.receiver = IFlashLoanReceiver(receiverAddress);


    IAToken(vars.aTokenAddress).transferUnderlyingTo(receiverAddress, amount);


    vars.receiver.executeOperation(asset, amount, vars.premium, params);

    vars.amountPlusPremium = amount.add(vars.premium);

    if (debtMode == ReserveLogic.InterestRateMode.NONE) {

      IERC20(asset).transferFrom(receiverAddress, vars.aTokenAddress, vars.amountPlusPremium);

      reserve.updateState();
      reserve.cumulateToLiquidityIndex(IERC20(vars.aTokenAddress).totalSupply(), vars.premium);
      reserve.updateInterestRates(asset, vars.aTokenAddress, vars.premium, 0);

      emit FlashLoan(receiverAddress, asset, amount, vars.premium, referralCode);
    } else {

      _executeBorrow(
        ExecuteBorrowParams(
          asset,
          msg.sender,
          msg.sender,
          vars.amountPlusPremium,
          mode,
          vars.aTokenAddress,
          referralCode,
          false
        )
      );
    }
  }









  function swapLiquidity(
    address receiverAddress,
    address fromAsset,
    address toAsset,
    uint256 amountToSwap,
    bytes calldata params
  ) external override {
    _whenNotPaused();
    address collateralManager = _addressesProvider.getLendingPoolCollateralManager();


    (bool success, bytes memory result) = collateralManager.delegatecall(
      abi.encodeWithSignature(
        'swapLiquidity(address,address,address,uint256,bytes)',
        receiverAddress,
        fromAsset,
        toAsset,
        amountToSwap,
        params
      )
    );
    require(success, Errors.FAILED_COLLATERAL_SWAP);

    (uint256 returnCode, string memory returnMessage) = abi.decode(result, (uint256, string));

    if (returnCode != 0) {
      revert(string(abi.encodePacked(returnMessage)));
    }
  }





  function getReserveConfigurationData(address asset)
    external
    override
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      address interestRateStrategyAddress,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFreezed
    )
  {
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    return (
      reserve.configuration.getDecimals(),
      reserve.configuration.getLtv(),
      reserve.configuration.getLiquidationThreshold(),
      reserve.configuration.getLiquidationBonus(),
      reserve.configuration.getReserveFactor(),
      reserve.interestRateStrategyAddress,
      reserve.configuration.getLtv() != 0,
      reserve.configuration.getBorrowingEnabled(),
      reserve.configuration.getStableRateBorrowingEnabled(),
      reserve.configuration.getActive(),
      reserve.configuration.getFrozen()
    );
  }

  function getReserveTokensAddresses(address asset)
    external
    override
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    )
  {
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    return (
      reserve.aTokenAddress,
      reserve.stableDebtTokenAddress,
      reserve.variableDebtTokenAddress
    );
  }

  function getReserveData(address asset)
    external
    override
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    )
  {
    ReserveLogic.ReserveData memory reserve = _reserves[asset];

    return (
      IERC20(asset).balanceOf(reserve.aTokenAddress),
      IERC20(reserve.stableDebtTokenAddress).totalSupply(),
      IERC20(reserve.variableDebtTokenAddress).totalSupply(),
      reserve.currentLiquidityRate,
      reserve.currentVariableBorrowRate,
      reserve.currentStableBorrowRate,
      IStableDebtToken(reserve.stableDebtTokenAddress).getAverageStableRate(),
      reserve.liquidityIndex,
      reserve.variableBorrowIndex,
      reserve.lastUpdateTimestamp
    );
  }

  function getUserAccountData(address user)
    external
    override
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalBorrowsETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    (
      totalCollateralETH,
      totalBorrowsETH,
      ltv,
      currentLiquidationThreshold,
      healthFactor
    ) = GenericLogic.calculateUserAccountData(
      user,
      _reserves,
      _usersConfig[user],
      _reservesList,
      _addressesProvider.getPriceOracle()
    );

    availableBorrowsETH = GenericLogic.calculateAvailableBorrowsETH(
      totalCollateralETH,
      totalBorrowsETH,
      ltv
    );
  }

  function getUserReserveData(address asset, address user)
    external
    override
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    )
  {
    ReserveLogic.ReserveData storage reserve = _reserves[asset];

    currentATokenBalance = IERC20(reserve.aTokenAddress).balanceOf(user);
    (currentStableDebt, currentVariableDebt) = Helpers.getUserCurrentDebt(user, reserve);
    principalStableDebt = IStableDebtToken(reserve.stableDebtTokenAddress).principalBalanceOf(user);
    scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
    liquidityRate = reserve.currentLiquidityRate;
    stableBorrowRate = IStableDebtToken(reserve.stableDebtTokenAddress).getUserStableRate(user);
    stableRateLastUpdated = IStableDebtToken(reserve.stableDebtTokenAddress).getUserLastUpdated(
      user
    );
    usageAsCollateralEnabled = _usersConfig[user].isUsingAsCollateral(reserve.id);
  }

  function getReserves() external override view returns (address[] memory) {
    return _reservesList;
  }

  receive() external payable {
    revert();
  }







  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external override {
    _onlyLendingPoolConfigurator();
    _reserves[asset].init(
      aTokenAddress,
      stableDebtAddress,
      variableDebtAddress,
      interestRateStrategyAddress
    );
    _addReserveToList(asset);
  }







  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external
    override
  {
    _onlyLendingPoolConfigurator();
    _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
  }

  function setConfiguration(address asset, uint256 configuration) external override {
    _onlyLendingPoolConfigurator();
    _reserves[asset].configuration.data = configuration;
  }

  function getConfiguration(address asset)
    external
    override
    view
    returns (ReserveConfiguration.Map memory)
  {
    return _reserves[asset].configuration;
  }



  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    uint256 interestRateMode;
    address aTokenAddress;
    uint16 referralCode;
    bool releaseUnderlying;
  }





  function _executeBorrow(ExecuteBorrowParams memory vars) internal {
    ReserveLogic.ReserveData storage reserve = _reserves[vars.asset];
    UserConfiguration.Map storage userConfig = _usersConfig[vars.onBehalfOf];

    address oracle = _addressesProvider.getPriceOracle();

    uint256 amountInETH = IPriceOracleGetter(oracle).getAssetPrice(vars.asset).mul(vars.amount).div(
      10**reserve.configuration.getDecimals()
    );

    ValidationLogic.validateBorrow(
      reserve,
      vars.onBehalfOf,
      vars.amount,
      amountInETH,
      vars.interestRateMode,
      MAX_STABLE_RATE_BORROW_SIZE_PERCENT,
      _reserves,
      userConfig,
      _reservesList,
      oracle
    );

    uint256 reserveId = reserve.id;
    if (!userConfig.isBorrowing(reserveId)) {
      userConfig.setBorrowing(reserveId, true);
    }

    reserve.updateState();


    uint256 currentStableRate = 0;

    if (
      ReserveLogic.InterestRateMode(vars.interestRateMode) == ReserveLogic.InterestRateMode.STABLE
    ) {
      currentStableRate = reserve.currentStableBorrowRate;

      IStableDebtToken(reserve.stableDebtTokenAddress).mint(
        vars.onBehalfOf,
        vars.amount,
        currentStableRate
      );
    } else {
      IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
        vars.onBehalfOf,
        vars.amount,
        reserve.variableBorrowIndex
      );
    }

    reserve.updateInterestRates(
      vars.asset,
      vars.aTokenAddress,
      0,
      vars.releaseUnderlying ? vars.amount : 0
    );

    if (vars.releaseUnderlying) {
      IAToken(vars.aTokenAddress).transferUnderlyingTo(vars.user, vars.amount);
    }

    emit Borrow(
      vars.asset,
      vars.user,
      vars.onBehalfOf,
      vars.amount,
      vars.interestRateMode,
      ReserveLogic.InterestRateMode(vars.interestRateMode) == ReserveLogic.InterestRateMode.STABLE
        ? currentStableRate
        : reserve.currentVariableBorrowRate,
      vars.referralCode
    );
  }




  function _addReserveToList(address asset) internal {
    bool reserveAlreadyAdded = false;
    require(_reservesList.length < MAX_NUMBER_RESERVES, Errors.NO_MORE_RESERVES_ALLOWED);
    for (uint256 i = 0; i < _reservesList.length; i++)
      if (_reservesList[i] == asset) {
        reserveAlreadyAdded = true;
      }
    if (!reserveAlreadyAdded) {
      _reserves[asset].id = uint8(_reservesList.length);
      _reservesList.push(asset);
    }
  }






  function getReserveNormalizedIncome(address asset) external override view returns (uint256) {
    return _reserves[asset].getNormalizedIncome();
  }






  function getReserveNormalizedVariableDebt(address asset)
    external
    override
    view
    returns (uint256)
  {
    return _reserves[asset].getNormalizedDebt();
  }








  function balanceDecreaseAllowed(
    address asset,
    address user,
    uint256 amount
  ) external override view returns (bool) {
    _whenNotPaused();
    return
      GenericLogic.balanceDecreaseAllowed(
        asset,
        user,
        amount,
        _reserves,
        _usersConfig[user],
        _reservesList,
        _addressesProvider.getPriceOracle()
      );
  }





  function setPause(bool val) external override {
    _onlyLendingPoolConfigurator();

    _paused = val;
    if (_paused) {
      emit Paused();
    } else {
      emit Unpaused();
    }
  }




  function paused() external override view returns (bool) {
    return _paused;
  }
}
