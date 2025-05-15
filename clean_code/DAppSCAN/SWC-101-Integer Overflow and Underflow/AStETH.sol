
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {ILendingPool} from '../../../interfaces/ILendingPool.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';
import {
  VersionedInitializable
} from '../../libraries/aave-upgradeability/VersionedInitializable.sol';
import {IncentivizedERC20} from '../IncentivizedERC20.sol';
import {IAaveIncentivesController} from '../../../interfaces/IAaveIncentivesController.sol';
import {DataTypes} from '../../libraries/types/DataTypes.sol';
import {ISTETH} from '../../../interfaces/ISTETH.sol';
import {SignedSafeMath} from '../../../dependencies/openzeppelin/contracts/SignedSafeMath.sol';
import {UInt256Lib} from '../../../dependencies/uFragments/UInt256Lib.sol';

interface IBookKeptBorrowing {



  function getBorrowData() external view returns (uint256, int256);
}






contract AStETH is VersionedInitializable, IncentivizedERC20, IAToken {
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;
  using UInt256Lib for uint256;
  using SignedSafeMath for int256;

  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  uint256 public constant UINT_MAX_VALUE = uint256(-1);
  uint256 public constant ATOKEN_REVISION = 0x1;
  address public immutable UNDERLYING_ASSET_ADDRESS;
  address public immutable RESERVE_TREASURY_ADDRESS;
  ILendingPool public immutable POOL;


  mapping(address => uint256) public _nonces;

  bytes32 public DOMAIN_SEPARATOR;



  IBookKeptBorrowing internal _variableDebtStETH;
  int256 internal _totalShares;

  struct ExtData {
    uint256 totalStETHSupply;
    uint256 totalPrincipalBorrowed;
    int256 totalSharesBorrowed;
  }


  modifier onlyLendingPool() {
    require(_msgSender() == address(POOL), Errors.CT_CALLER_MUST_BE_LENDING_POOL);
    _;
  }

  constructor(
    ILendingPool pool,
    address underlyingAssetAddress,
    address reserveTreasuryAddress,
    string memory tokenName,
    string memory tokenSymbol,
    address incentivesController
  ) public IncentivizedERC20(tokenName, tokenSymbol, 18, incentivesController) {
    POOL = pool;
    UNDERLYING_ASSET_ADDRESS = underlyingAssetAddress;
    RESERVE_TREASURY_ADDRESS = reserveTreasuryAddress;
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return ATOKEN_REVISION;
  }

  function initialize(
    uint8 underlyingAssetDecimals,
    string calldata tokenName,
    string calldata tokenSymbol
  ) external virtual initializer {
    uint256 chainId;


    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712_DOMAIN,
        keccak256(bytes(tokenName)),
        keccak256(EIP712_REVISION),
        chainId,
        address(this)
      )
    );

    _setName(tokenName);
    _setSymbol(tokenSymbol);
    _setDecimals(underlyingAssetDecimals);
  }

  function initializeDebtToken() external {
    DataTypes.ReserveData memory reserveData = POOL.getReserveData(UNDERLYING_ASSET_ADDRESS);
    _variableDebtStETH = IBookKeptBorrowing(reserveData.variableDebtTokenAddress);
  }









  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);

    _burnScaled(user, amountScaled, _fetchExtData());
    _totalShares = _totalShares.sub(
      ISTETH(UNDERLYING_ASSET_ADDRESS).getSharesByPooledEth(amountScaled).toInt256Safe()
    );

    IERC20(UNDERLYING_ASSET_ADDRESS).safeTransfer(receiverOfUnderlying, amount);

    emit Transfer(user, address(0), amount);
    emit Burn(user, receiverOfUnderlying, amount, index);
  }









  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool returns (bool) {
    uint256 previousBalance = super.balanceOf(user);

    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);

    _mintScaled(user, amountScaled, _fetchExtData());
    _totalShares = _totalShares.add(
      ISTETH(UNDERLYING_ASSET_ADDRESS).getSharesByPooledEth(amountScaled).toInt256Safe()
    );

    emit Transfer(address(0), user, amount);
    emit Mint(user, amount, index);

    return previousBalance == 0;
  }







  function mintToTreasury(uint256 amount, uint256 index) external override onlyLendingPool {
    if (amount == 0) {
      return;
    }

    address treasury = RESERVE_TREASURY_ADDRESS;





    uint256 amountScaled = amount.rayDiv(index);
    _mintScaled(treasury, amountScaled, _fetchExtData());
    _totalShares = _totalShares.add(
      ISTETH(UNDERLYING_ASSET_ADDRESS).getSharesByPooledEth(amountScaled).toInt256Safe()
    );

    emit Transfer(address(0), treasury, amount);
    emit Mint(treasury, amount, index);
  }








  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external override onlyLendingPool {


    _transfer(from, to, value, false);

    emit Transfer(from, to, value);
  }






  function balanceOf(address user)
    public
    view
    override(IncentivizedERC20, IERC20)
    returns (uint256)
  {
    uint256 userBalanceScaled =
      _scaledBalanceOf(
        super.balanceOf(user),
        super.totalSupply(),
        _scaledTotalSupply(_fetchExtData())
      );

    if (userBalanceScaled == 0) {
      return 0;
    }

    return userBalanceScaled.rayMul(POOL.getReserveNormalizedIncome(UNDERLYING_ASSET_ADDRESS));
  }







  function scaledBalanceOf(address user) external view override returns (uint256) {
    return
      _scaledBalanceOf(
        super.balanceOf(user),
        super.totalSupply(),
        _scaledTotalSupply(_fetchExtData())
      );
  }







  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    uint256 scaledTotalSupply = _scaledTotalSupply(_fetchExtData());
    return (
      _scaledBalanceOf(super.balanceOf(user), super.totalSupply(), scaledTotalSupply),
      scaledTotalSupply
    );
  }







  function getInternalUserBalanceAndSupply(address user) external view returns (uint256, uint256) {
    return (super.balanceOf(user), super.totalSupply());
  }







  function totalSupply() public view override(IncentivizedERC20, IERC20) returns (uint256) {
    uint256 currentSupplyScaled = _scaledTotalSupply(_fetchExtData());

    if (currentSupplyScaled == 0) {
      return 0;
    }

    return currentSupplyScaled.rayMul(POOL.getReserveNormalizedIncome(UNDERLYING_ASSET_ADDRESS));
  }





  function scaledTotalSupply() public view virtual override returns (uint256) {
    return _scaledTotalSupply(_fetchExtData());
  }





  function internalTotalSupply() public view returns (uint256) {
    return super.totalSupply();
  }








  function transferUnderlyingTo(address target, uint256 amount)
    external
    override
    onlyLendingPool
    returns (uint256)
  {
    IERC20(UNDERLYING_ASSET_ADDRESS).safeTransfer(target, amount);
    return amount;
  }












  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(owner != address(0), 'INVALID_OWNER');

    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
        )
      );
    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }









  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool validate
  ) internal {
    uint256 index = POOL.getReserveNormalizedIncome(UNDERLYING_ASSET_ADDRESS);
    uint256 amountScaled = amount.rayDiv(index);

    ExtData memory e = _fetchExtData();
    uint256 totalSupplyInternal = super.totalSupply();

    uint256 scaledTotalSupply = _scaledTotalSupply(e);
    uint256 fromBalanceScaled =
      _scaledBalanceOf(super.balanceOf(from), totalSupplyInternal, scaledTotalSupply);
    uint256 toBalanceScaled =
      _scaledBalanceOf(super.balanceOf(to), totalSupplyInternal, scaledTotalSupply);

    _transferScaled(from, to, amountScaled, e);

    if (validate) {
      POOL.finalizeTransfer(
        UNDERLYING_ASSET_ADDRESS,
        from,
        to,
        amount,
        fromBalanceScaled.rayMul(index),
        toBalanceScaled.rayMul(index)
      );
    }

    emit BalanceTransfer(from, to, amount, index);
  }







  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    _transfer(from, to, amount, true);
  }


















  function _mintScaled(
    address user,
    uint256 mintAmountScaled,
    ExtData memory e
  ) internal {
    uint256 totalSupplyInternalBefore = super.totalSupply();
    uint256 userBalanceInternalBefore = super.balanceOf(user);


    if (totalSupplyInternalBefore == 0) {
      _mint(user, ISTETH(UNDERLYING_ASSET_ADDRESS).getSharesByPooledEth(mintAmountScaled));
      return;
    }

    uint256 scaledTotalSupplyBefore = _scaledTotalSupply(e);

    uint256 userBalanceScaledBefore =
      _scaledBalanceOf(
        userBalanceInternalBefore,
        totalSupplyInternalBefore,
        scaledTotalSupplyBefore
      );
    uint256 otherBalanceScaledBefore = scaledTotalSupplyBefore.sub(userBalanceScaledBefore);

    uint256 scaledTotalSupplyAfter = scaledTotalSupplyBefore.add(mintAmountScaled);
    uint256 userBalanceScaledAfter = userBalanceScaledBefore.add(mintAmountScaled);
    uint256 mintAmountInternal = 0;


    if (otherBalanceScaledBefore == 0) {
      uint256 mintAmountInternal =
        mintAmountScaled.mul(totalSupplyInternalBefore).div(scaledTotalSupplyBefore);
      _mint(user, mintAmountInternal);
      return;
    }

    mintAmountInternal = totalSupplyInternalBefore
      .mul(userBalanceScaledAfter)
      .sub(scaledTotalSupplyAfter.mul(userBalanceInternalBefore))
      .div(otherBalanceScaledBefore);

    _mint(user, mintAmountInternal);
  }















  function _burnScaled(
    address user,
    uint256 burnAmountScaled,
    ExtData memory e
  ) internal {
    uint256 totalSupplyInternalBefore = super.totalSupply();
    uint256 userBalanceInternalBefore = super.balanceOf(user);

    uint256 scaledTotalSupplyBefore = _scaledTotalSupply(e);
    uint256 userBalanceScaledBefore =
      _scaledBalanceOf(
        userBalanceInternalBefore,
        totalSupplyInternalBefore,
        scaledTotalSupplyBefore
      );

    uint256 otherBalanceScaledBefore = 0;
    if (userBalanceScaledBefore <= scaledTotalSupplyBefore) {
      otherBalanceScaledBefore = scaledTotalSupplyBefore.sub(userBalanceScaledBefore);
    }

    uint256 scaledTotalSupplyAfter = 0;
    if (burnAmountScaled <= scaledTotalSupplyBefore) {
      scaledTotalSupplyAfter = scaledTotalSupplyBefore.sub(burnAmountScaled);
    }

    uint256 userBalanceScaledAfter = 0;
    if (burnAmountScaled <= userBalanceScaledBefore) {
      userBalanceScaledAfter = userBalanceScaledBefore.sub(burnAmountScaled);
    }

    uint256 burnAmountInternal = 0;


    if (otherBalanceScaledBefore == 0) {
      _burn(user, burnAmountScaled.mul(totalSupplyInternalBefore).div(scaledTotalSupplyBefore));
      return;
    }

    burnAmountInternal = scaledTotalSupplyAfter
      .mul(userBalanceInternalBefore)
      .sub(totalSupplyInternalBefore.mul(userBalanceScaledAfter))
      .div(otherBalanceScaledBefore);

    _burn(user, burnAmountInternal);
  }






  function _fetchExtData() internal view returns (ExtData memory) {
    ExtData memory extData;

    extData.totalStETHSupply = ISTETH(UNDERLYING_ASSET_ADDRESS).totalSupply();
    (extData.totalPrincipalBorrowed, extData.totalSharesBorrowed) = _variableDebtStETH
      .getBorrowData();

    return extData;
  }




  function _scaledBalanceOf(
    uint256 _intBalanceOf,
    uint256 _intTotalSupply,
    uint256 _scaledTotalSupply
  ) private pure returns (uint256) {
    if (_intBalanceOf == 0 || _intTotalSupply == 0) {
      return 0;
    }
    return _intBalanceOf.wadMul(_scaledTotalSupply).wadDiv(_intTotalSupply);
  }






  function _scaledTotalSupply(ExtData memory e) private view returns (uint256) {
    return

      ISTETH(UNDERLYING_ASSET_ADDRESS).getPooledEthByShares(
        uint256(_totalShares - e.totalSharesBorrowed)
      ) + e.totalPrincipalBorrowed;
  }




  function _transferScaled(
    address from,
    address to,
    uint256 transferAmountScaled,
    ExtData memory e
  ) private {
    uint256 totalSupplyInternal = super.totalSupply();
    uint256 scaledTotalSupply = _scaledTotalSupply(e);
    uint256 transferAmountInternal =
      transferAmountScaled.mul(totalSupplyInternal).div(scaledTotalSupply);
    super._transfer(from, to, transferAmountInternal);
  }

  function VARIABLE_DEBT_TOKEN_ADDRESS() external view returns (address) {
    return address(_variableDebtStETH);
  }
}
