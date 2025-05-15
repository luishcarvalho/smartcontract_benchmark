

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import "./abstracts/vault/VaultBaseUpgradeable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IHarvester.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/chainlink/AggregatorV3Interface.sol";
import "./interfaces/IFujiAdmin.sol";
import "./interfaces/IFujiOracle.sol";
import "./interfaces/IFujiERC1155.sol";
import "./interfaces/IProvider.sol";
import "./libraries/Errors.sol";
import "./libraries/LibUniversalERC20Upgradeable.sol";


contract FujiVault is VaultBaseUpgradeable, ReentrancyGuardUpgradeable, IVault {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using LibUniversalERC20Upgradeable for IERC20Upgradeable;

  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  struct Factor {
    uint64 a;
    uint64 b;
  }


  Factor public safetyF;


  Factor public collatF;


  Factor public override protocolFee;


  Factor public bonusLiqF;


  address[] public providers;
  address public override activeProvider;

  IFujiAdmin private _fujiAdmin;
  address public override fujiERC1155;
  IFujiOracle public oracle;

  string public name;

  uint8 internal _collateralAssetDecimals;
  uint8 internal _borrowAssetDecimals;

  uint256 public constant ONE_YEAR = 60 * 60 * 24 * 365;

  mapping(address => uint256) internal _userFeeTimestamps;
  uint256 public remainingProtocolFee;

  modifier isAuthorized() {
    require(
      msg.sender == owner() || msg.sender == _fujiAdmin.getController(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  modifier onlyFlash() {
    require(msg.sender == _fujiAdmin.getFlasher(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  modifier onlyFliquidator() {
    require(msg.sender == _fujiAdmin.getFliquidator(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  function initialize(
    address _fujiadmin,
    address _oracle,
    address _collateralAsset,
    address _borrowAsset
  ) external initializer {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    _fujiAdmin = IFujiAdmin(_fujiadmin);
    oracle = IFujiOracle(_oracle);
    vAssets.collateralAsset = _collateralAsset;
    vAssets.borrowAsset = _borrowAsset;

    string memory collateralSymbol;
    string memory borrowSymbol;

    if (_collateralAsset == ETH) {
      collateralSymbol = "ETH";
      _collateralAssetDecimals = 18;
    } else {
      collateralSymbol = IERC20Extended(_collateralAsset).symbol();
      _collateralAssetDecimals = IERC20Extended(_collateralAsset).decimals();
    }

    if (_borrowAsset == ETH) {
      borrowSymbol = "ETH";
      _borrowAssetDecimals = 18;
    } else {
      borrowSymbol = IERC20Extended(_borrowAsset).symbol();
      _borrowAssetDecimals = IERC20Extended(_borrowAsset).decimals();
    }

    name = string(abi.encodePacked("Vault", collateralSymbol, borrowSymbol));


    safetyF.a = 21;
    safetyF.b = 20;


    collatF.a = 80;
    collatF.b = 63;


    bonusLiqF.a = 1;
    bonusLiqF.b = 20;

    protocolFee.a = 1;
    protocolFee.b = 1000;
  }

  receive() external payable {}








  function depositAndBorrow(uint256 _collateralAmount, uint256 _borrowAmount) external payable {
    deposit(_collateralAmount);
    borrow(_borrowAmount);
  }






  function paybackAndWithdraw(int256 _paybackAmount, int256 _collateralAmount) external payable {
    payback(_paybackAmount);
    withdraw(_collateralAmount);
  }







  function deposit(uint256 _collateralAmount) public payable override {
    if (vAssets.collateralAsset == ETH) {
      require(msg.value == _collateralAmount && _collateralAmount != 0, Errors.VL_AMOUNT_ERROR);
    } else {
      require(_collateralAmount != 0, Errors.VL_AMOUNT_ERROR);
      IERC20Upgradeable(vAssets.collateralAsset).safeTransferFrom(
        msg.sender,
        address(this),
        _collateralAmount
      );
    }



    _deposit(_collateralAmount, address(activeProvider));


    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.collateralID, _collateralAmount, "");

    emit Deposit(msg.sender, vAssets.collateralAsset, _collateralAmount);
  }








  function withdraw(int256 _withdrawAmount) public override nonReentrant {

    updateF1155Balances();


    uint256 providedCollateral = IFujiERC1155(fujiERC1155).balanceOf(
      msg.sender,
      vAssets.collateralID
    );


    require(providedCollateral > 0, Errors.VL_INVALID_COLLATERAL);


    uint256 neededCollateral = getNeededCollateralFor(
      IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID),
      true
    );

    uint256 amountToWithdraw = _withdrawAmount < 0
      ? providedCollateral - neededCollateral
      : uint256(_withdrawAmount);


    require(
      amountToWithdraw != 0 && providedCollateral - amountToWithdraw >= neededCollateral,
      Errors.VL_INVALID_WITHDRAW_AMOUNT
    );


    IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.collateralID, amountToWithdraw);



    _withdraw(amountToWithdraw, address(activeProvider));


    IERC20Upgradeable(vAssets.collateralAsset).univTransfer(payable(msg.sender), amountToWithdraw);

    emit Withdraw(msg.sender, vAssets.collateralAsset, amountToWithdraw);
  }








  function withdrawLiq(int256 _withdrawAmount) external override nonReentrant onlyFliquidator {

    _withdraw(uint256(_withdrawAmount), address(activeProvider));
    IERC20Upgradeable(vAssets.collateralAsset).univTransfer(
      payable(msg.sender),
      uint256(_withdrawAmount)
    );
  }






  function borrow(uint256 _borrowAmount) public override nonReentrant {
    updateF1155Balances();

    uint256 providedCollateral = IFujiERC1155(fujiERC1155).balanceOf(
      msg.sender,
      vAssets.collateralID
    );

    uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID);
    uint256 totalBorrow = _borrowAmount + debtPrincipal;

    uint256 neededCollateral = getNeededCollateralFor(totalBorrow, true);


    require(
      _borrowAmount != 0 && providedCollateral > neededCollateral,
      Errors.VL_INVALID_BORROW_AMOUNT
    );



    uint256 userFee = (debtPrincipal *
      (block.timestamp - _userFeeTimestamps[msg.sender]) *
      protocolFee.a) /
      protocolFee.b /
      ONE_YEAR;

    _userFeeTimestamps[msg.sender] =
      block.timestamp -
      (userFee * ONE_YEAR * protocolFee.a) /
      protocolFee.b /
      totalBorrow;



    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.borrowID, _borrowAmount, "");


    _borrow(_borrowAmount, address(activeProvider));


    IERC20Upgradeable(vAssets.borrowAsset).univTransfer(payable(msg.sender), _borrowAmount);

    emit Borrow(msg.sender, vAssets.borrowAsset, _borrowAmount);
  }






  function payback(int256 _repayAmount) public payable override {

    updateF1155Balances();

    uint256 debtBalance = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID);
    uint256 userFee = _userProtocolFee(msg.sender, debtBalance);


    require(uint256(_repayAmount) > userFee && debtBalance > 0, Errors.VL_NO_DEBT_TO_PAYBACK);




    uint256 amountToPayback = _repayAmount < 0 ? debtBalance + userFee : uint256(_repayAmount);

    if (vAssets.borrowAsset == ETH) {
      require(msg.value >= amountToPayback, Errors.VL_AMOUNT_ERROR);
      if (msg.value > amountToPayback) {
        IERC20Upgradeable(vAssets.borrowAsset).univTransfer(
          payable(msg.sender),
          msg.value - amountToPayback
        );
      }
    } else {

      require(
        IERC20Upgradeable(vAssets.borrowAsset).allowance(msg.sender, address(this)) >=
          amountToPayback,
        Errors.VL_MISSING_ERC20_ALLOWANCE
      );



      IERC20Upgradeable(vAssets.borrowAsset).safeTransferFrom(
        msg.sender,
        address(this),
        amountToPayback
      );
    }


    _payback(amountToPayback - userFee, address(activeProvider));


    IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.borrowID, amountToPayback - userFee);


    _userFeeTimestamps[msg.sender] = block.timestamp;
    remainingProtocolFee += userFee;

    emit Payback(msg.sender, vAssets.borrowAsset, debtBalance);
  }






  function paybackLiq(address[] memory _users, uint256 _repayAmount)
    external
    payable
    override
    onlyFliquidator
  {

    uint256 _fee = 0;
    for (uint256 i = 0; i < _users.length; i++) {
      if (_users[i] != address(0)) {
        _userFeeTimestamps[_users[i]] = block.timestamp;

        uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(_users[i], vAssets.borrowID);
        _fee += _userProtocolFee(_users[i], debtPrincipal);
      }
    }


    _payback(_repayAmount - _fee, address(activeProvider));


    remainingProtocolFee += _fee;
  }







  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanAmount,
    uint256 _fee
  ) external payable override onlyFlash whenNotPaused {

    uint256 ratio = (_flashLoanAmount * 1e18) /
      (IProvider(activeProvider).getBorrowBalance(vAssets.borrowAsset));


    _payback(_flashLoanAmount, activeProvider);


    uint256 collateraltoMove = (IProvider(activeProvider).getDepositBalance(
      vAssets.collateralAsset
    ) * ratio) / 1e18;

    _withdraw(collateraltoMove, activeProvider);


    _deposit(collateraltoMove, _newProvider);


    _borrow(_flashLoanAmount + _fee, _newProvider);


    IERC20Upgradeable(vAssets.borrowAsset).univTransfer(
      payable(msg.sender),
      _flashLoanAmount + _fee
    );

    emit Switch(activeProvider, _newProvider, _flashLoanAmount, collateraltoMove);
  }







  function setFujiAdmin(address _newFujiAdmin) external onlyOwner {
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }






  function setActiveProvider(address _provider) external override isAuthorized {
    require(_provider != address(0), Errors.VL_ZERO_ADDR);
    activeProvider = _provider;

    emit SetActiveProvider(_provider);
  }







  function setFujiERC1155(address _fujiERC1155) external isAuthorized {
    require(_fujiERC1155 != address(0), Errors.VL_ZERO_ADDR);
    fujiERC1155 = _fujiERC1155;

    vAssets.collateralID = IFujiERC1155(_fujiERC1155).addInitializeAsset(
      IFujiERC1155.AssetType.collateralToken,
      address(this)
    );
    vAssets.borrowID = IFujiERC1155(_fujiERC1155).addInitializeAsset(
      IFujiERC1155.AssetType.debtToken,
      address(this)
    );
  }









  function setFactor(
    uint64 _newFactorA,
    uint64 _newFactorB,
    string calldata _type
  ) external isAuthorized {
    bytes32 typeHash = keccak256(abi.encode(_type));
    if (typeHash == keccak256(abi.encode("collatF"))) {
      collatF.a = _newFactorA;
      collatF.b = _newFactorB;
    } else if (typeHash == keccak256(abi.encode("safetyF"))) {
      safetyF.a = _newFactorA;
      safetyF.b = _newFactorB;
    } else if (typeHash == keccak256(abi.encode("bonusLiqF"))) {
      bonusLiqF.a = _newFactorA;
      bonusLiqF.b = _newFactorB;
    } else if (typeHash == keccak256(abi.encode("protocolFee"))) {
      protocolFee.a = _newFactorA;
      protocolFee.b = _newFactorB;
    }
  }





  function setOracle(address _oracle) external isAuthorized {
    oracle = IFujiOracle(_oracle);
  }





  function setProviders(address[] calldata _providers) external isAuthorized {
    providers = _providers;
  }




  function updateF1155Balances() public override {
    IFujiERC1155(fujiERC1155).updateState(
      vAssets.borrowID,
      IProvider(activeProvider).getBorrowBalance(vAssets.borrowAsset)
    );
    IFujiERC1155(fujiERC1155).updateState(
      vAssets.collateralID,
      IProvider(activeProvider).getDepositBalance(vAssets.collateralAsset)
    );
  }






  function getProviders() external view override returns (address[] memory) {
    return providers;
  }





  function getLiquidationBonusFor(uint256 _amount) external view override returns (uint256) {
    return (_amount * bonusLiqF.a) / bonusLiqF.b;
  }






  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    public
    view
    override
    returns (uint256)
  {

    uint256 price = oracle.getPriceOf(
      vAssets.collateralAsset,
      vAssets.borrowAsset,
      _collateralAssetDecimals
    );
    uint256 minimumReq = (_amount * price) / (10**uint256(_borrowAssetDecimals));
    if (_withFactors) {
      return (minimumReq * (collatF.a) * (safetyF.a)) / (collatF.b) / (safetyF.b);
    } else {
      return minimumReq;
    }
  }





  function borrowBalance(address _provider) external view override returns (uint256) {
    return IProvider(_provider).getBorrowBalance(vAssets.borrowAsset);
  }





  function depositBalance(address _provider) external view override returns (uint256) {
    return IProvider(_provider).getDepositBalance(vAssets.collateralAsset);
  }






  function userDebtBalance(address _user) external view override returns (uint256) {
    uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(_user, vAssets.borrowID);
    uint256 fee = (debtPrincipal * (block.timestamp - _userFeeTimestamps[_user]) * protocolFee.a) /
      protocolFee.b /
      ONE_YEAR;

    return debtPrincipal + fee;
  }






  function userProtocolFee(address _user) external view override returns (uint256) {
    uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(_user, vAssets.borrowID);
    return _userProtocolFee(_user, debtPrincipal);
  }






  function userDepositBalance(address _user) external view override returns (uint256) {
    return IFujiERC1155(fujiERC1155).balanceOf(_user, vAssets.collateralID);
  }






  function harvestRewards(uint256 _farmProtocolNum, bytes memory _data) external onlyOwner {
    (address tokenReturned, IHarvester.Transaction memory harvestTransaction) = IHarvester(
      _fujiAdmin.getVaultHarvester()
    ).getHarvestTransaction(_farmProtocolNum, _data);


    (bool success, ) = harvestTransaction.to.call(harvestTransaction.data);
    require(success, "failed to harvest rewards");

    if (tokenReturned != address(0)) {
      uint256 tokenBal = IERC20Upgradeable(tokenReturned).univBalanceOf(address(this));
      require(tokenReturned != address(0) && tokenBal > 0, Errors.VL_HARVESTING_FAILED);

      ISwapper.Transaction memory swapTransaction = ISwapper(_fujiAdmin.getSwapper())
      .getSwapTransaction(tokenReturned, vAssets.collateralAsset, tokenBal);


      if (tokenReturned != ETH) {
        IERC20Upgradeable(tokenReturned).univApprove(swapTransaction.to, tokenBal);
      }


      (success, ) = swapTransaction.to.call{ value: swapTransaction.value }(swapTransaction.data);
      require(success, "failed to swap rewards");

      _deposit(
        IERC20Upgradeable(vAssets.collateralAsset).univBalanceOf(address(this)),
        address(activeProvider)
      );

      updateF1155Balances();
    }
  }

  function withdrawProtocolFee() external nonReentrant {
    IERC20Upgradeable(vAssets.borrowAsset).univTransfer(
      payable(IFujiAdmin(_fujiAdmin).getTreasury()),
      remainingProtocolFee
    );

    remainingProtocolFee = 0;
  }



  function _userProtocolFee(address _user, uint256 _debtPrincipal) internal view returns (uint256) {
    return
      (_debtPrincipal * (block.timestamp - _userFeeTimestamps[_user]) * protocolFee.a) /
      protocolFee.b /
      ONE_YEAR;
  }
}
