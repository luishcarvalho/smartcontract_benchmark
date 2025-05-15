
pragma solidity 0.8.7;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';






library UserConfiguration {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  uint256 internal constant BORROWING_MASK =
    0x5555555555555555555555555555555555555555555555555555555555555555;
  uint256 internal constant COLLATERAL_MASK =
    0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;







  function setBorrowing(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool borrowing
  ) internal {
    unchecked {
      require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
      self.data =
        (self.data & ~(1 << (reserveIndex * 2))) |
        (uint256(borrowing ? 1 : 0) << (reserveIndex * 2));
    }
  }







  function setUsingAsCollateral(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool usingAsCollateral
  ) internal {
    unchecked {
      require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
      self.data =
        (self.data & ~(1 << (reserveIndex * 2 + 1))) |
        (uint256(usingAsCollateral ? 1 : 0) << (reserveIndex * 2 + 1));
    }
  }







  function isUsingAsCollateralOrBorrowing(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {
    unchecked {
      require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
      return (self.data >> (reserveIndex * 2)) & 3 != 0;
    }
  }







  function isBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    unchecked {
      require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
      return (self.data >> (reserveIndex * 2)) & 1 != 0;
    }
  }







  function isUsingAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    unchecked {
      require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
      return (self.data >> (reserveIndex * 2 + 1)) & 1 != 0;
    }
  }







  function isUsingAsCollateralOne(DataTypes.UserConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    uint256 collateralData = self.data & COLLATERAL_MASK;

    return collateralData & (collateralData - 1) == 0;
  }






  function isUsingAsCollateralAny(DataTypes.UserConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return self.data & COLLATERAL_MASK != 0;
  }






  function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data & BORROWING_MASK != 0;
  }






  function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data == 0;
  }










  function getIsolationModeState(
    DataTypes.UserConfigurationMap memory self,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList
  )
    internal
    view
    returns (
      bool,
      address,
      uint256
    )
  {
    if (!isUsingAsCollateralAny(self)) {
      return (false, address(0), 0);
    }
    if (isUsingAsCollateralOne(self)) {
      uint256 assetId = _getFirstAssetAsCollateralId(self);

      address assetAddress = reservesList[assetId];
      uint256 ceiling = reservesData[assetAddress].configuration.getDebtCeiling();
      if (ceiling > 0) {
        return (true, assetAddress, ceiling);
      }
    }
    return (false, address(0), 0);
  }






  function _getFirstAssetAsCollateralId(DataTypes.UserConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 collateralData = self.data & COLLATERAL_MASK;
      uint256 firstCollateralPosition = collateralData & ~(collateralData - 1);
      uint256 id;

      while ((firstCollateralPosition >>= 2) > 0) {
        id += 2;
      }
      return id / 2;
    }
  }
}
