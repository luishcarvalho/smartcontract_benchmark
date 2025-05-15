
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeERC20} from '../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IERC20WithPermit} from '../interfaces/IERC20WithPermit.sol';
import {FlashLoanReceiverBase} from '../flashloan/base/FlashLoanReceiverBase.sol';






abstract contract BaseParaSwapAdapter is FlashLoanReceiverBase, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct PermitSignature {
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }


  uint256 public constant MAX_SLIPPAGE_PERCENT = 3000;

  IPriceOracleGetter public immutable ORACLE;

  event Swapped(address indexed fromAsset, address indexed toAsset, uint256 fromAmount, uint256 receivedAmount);

  constructor(
    ILendingPoolAddressesProvider addressesProvider
  ) public FlashLoanReceiverBase(addressesProvider) {
    ORACLE = IPriceOracleGetter(addressesProvider.getPriceOracle());
  }






  function _getPrice(address asset) internal view returns (uint256) {
    return ORACLE.getAssetPrice(asset);
  }





  function _getDecimals(address asset) internal view returns (uint256) {
    return IERC20Detailed(asset).decimals();
  }





  function _getReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
    return LENDING_POOL.getReserveData(asset);
  }










  function _pullAToken(
    address reserve,
    address reserveAToken,
    address user,
    uint256 amount,
    PermitSignature memory permitSignature
  ) internal {
    if (_usePermit(permitSignature)) {
      IERC20WithPermit(reserveAToken).permit(
        user,
        address(this),
        permitSignature.amount,
        permitSignature.deadline,
        permitSignature.v,
        permitSignature.r,
        permitSignature.s
      );
    }


    IERC20(reserveAToken).safeTransferFrom(user, address(this), amount);



    LENDING_POOL.withdraw(reserve, amount, address(this));
  }







  function _usePermit(PermitSignature memory signature) internal pure returns (bool) {
    return
      !(uint256(signature.deadline) == uint256(signature.v) && uint256(signature.deadline) == 0);
  }






  function rescueTokens(IERC20 token) external onlyOwner {
    token.transfer(owner(), token.balanceOf(address(this)));
  }
}
