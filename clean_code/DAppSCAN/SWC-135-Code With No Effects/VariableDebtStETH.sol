
pragma solidity 0.6.12;

import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IAaveIncentivesController} from '../../../interfaces/IAaveIncentivesController.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';
import {DebtTokenBase} from '../base/DebtTokenBase.sol';
import {ISTETH} from '../../../interfaces/ISTETH.sol';
import {ILendingPool} from '../../../interfaces/ILendingPool.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeMath} from '../../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {SignedSafeMath} from '../../../dependencies/openzeppelin/contracts/SignedSafeMath.sol';











contract VariableDebtStETH is DebtTokenBase, IVariableDebtToken {
  using WadRayMath for uint256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  uint256 public constant DEBT_TOKEN_REVISION = 0x1;

  constructor(
    address pool,
    address underlyingAsset,
    string memory name,
    string memory symbol,
    address incentivesController
  ) public DebtTokenBase(pool, underlyingAsset, name, symbol, incentivesController) {}




  int256 private _totalSharesBorrowed;







  function getRevision() internal pure virtual override returns (uint256) {
    return DEBT_TOKEN_REVISION;
  }





  function balanceOf(address user) public view virtual override returns (uint256) {
    uint256 scaledBalance = super.balanceOf(user);

    if (scaledBalance == 0) {
      return 0;
    }

    return scaledBalance.rayMul(POOL.getReserveNormalizedVariableDebt(UNDERLYING_ASSET_ADDRESS));
  }











  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool returns (bool) {
    if (user != onBehalfOf) {
      _decreaseBorrowAllowance(onBehalfOf, user, amount);
    }

    uint256 previousBalance = super.balanceOf(onBehalfOf);
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);

    _mint(onBehalfOf, amountScaled);
    _totalSharesBorrowed = _totalSharesBorrowed.add(
      int256(ISTETH(UNDERLYING_ASSET_ADDRESS).getSharesByPooledEth(amountScaled))
    );

    emit Transfer(address(0), onBehalfOf, amount);
    emit Mint(user, onBehalfOf, amount, index);

    return previousBalance == 0;
  }








  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);

    _burn(user, amountScaled);
    _totalSharesBorrowed = _totalSharesBorrowed.sub(
      int256(ISTETH(UNDERLYING_ASSET_ADDRESS).getSharesByPooledEth(amountScaled))
    );

    emit Transfer(user, address(0), amount);
    emit Burn(user, amount, index);
  }





  function scaledBalanceOf(address user) public view virtual override returns (uint256) {
    return super.balanceOf(user);
  }





  function totalSupply() public view virtual override returns (uint256) {
    return
      super.totalSupply().rayMul(POOL.getReserveNormalizedVariableDebt(UNDERLYING_ASSET_ADDRESS));
  }





  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }







  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }



  function getBorrowData() external view returns (uint256, int256) {
    return (super.totalSupply(), _totalSharesBorrowed);
  }


  function fetchStETHTotalSupply() internal view returns (uint256) {
    return ISTETH(UNDERLYING_ASSET_ADDRESS).totalSupply();
  }
}
