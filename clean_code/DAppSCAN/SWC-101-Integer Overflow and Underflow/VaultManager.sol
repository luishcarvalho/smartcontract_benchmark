

pragma solidity ^0.8.0;

import "../../oracle/OracleRegistry.sol";
import "./Vault.sol";
import "./interfaces/IVaultFactory.sol";

contract VaultManager is OracleRegistry, IVaultManager {


    uint256 public override desiredSupply;

    bool public override rebaseActive;



    mapping (address => uint) internal LFRConfig;

    mapping (address => uint) internal MCRConfig;

    mapping (address => uint) internal SFRConfig;

    mapping (address => bool) internal IsOpen;


    address public override stablecoin;

    address public override factory;

    address public override feeTo;

    address public override dividend;

    address public override treasury;

    address public override liquidator;

    constructor() {
        _setupRole(ORACLE_OPERATOR_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initializeCDP(address collateral_, uint MCR_, uint LFR_, uint SFR_, bool on) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA");
        LFRConfig[collateral_] = LFR_;
        MCRConfig[collateral_] = MCR_;
        SFRConfig[collateral_] = SFR_;
        IsOpen[collateral_] = on;
        uint8 cDecimals = IERC20Minimal(collateral_).decimals();
        emit CDPInitialized(collateral_, MCR_, LFR_, SFR_, cDecimals);
    }

    function setRebaseActive(bool set_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA");
        rebaseActive = set_;
        emit RebaseActive(set_);
    }

    function setFees(address feeTo_, address dividend_, address treasury_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA");
        feeTo = feeTo_;
        dividend = dividend_;
        treasury = treasury_;
        emit SetFees(feeTo_, dividend_, treasury_);
    }

    function initialize(address stablecoin_, address factory_, address liquidator_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA");
        stablecoin = stablecoin_;
        factory = factory_;
        liquidator = liquidator_;
    }

    function createCDP(address collateral_, uint cAmount_, uint dAmount_) external override returns(bool success) {

        require(IsOpen[collateral_], "VAULTMANAGER: NOT OPEN");

        require(isValidCDP(collateral_, stablecoin, cAmount_, dAmount_)
        , "IP");

        require(isValidSupply(dAmount_), "RB");

        (address vlt, uint256 id) = IVaultFactory(factory).createVault(collateral_, stablecoin, dAmount_, _msgSender());
        require(vlt != address(0), "VAULTMANAGER: FE");

        TransferHelper.safeTransferFrom(collateral_, _msgSender(), vlt, cAmount_);

        IStablecoin(stablecoin).mint(_msgSender(), dAmount_);
        emit VaultCreated(id, collateral_, stablecoin, msg.sender, vlt, cAmount_, dAmount_);
        return true;
    }

    function createCDPNative(uint dAmount_) payable public returns(bool success) {
        address WETH = IVaultFactory(factory).WETH();

        require(IsOpen[WETH], "VAULTMANAGER: NOT OPEN");

        require(isValidCDP(WETH, stablecoin, msg.value, dAmount_)
        , "IP");

        require(isValidSupply(dAmount_), "RB");

        (address vlt, uint256 id) = IVaultFactory(factory).createVault(WETH, stablecoin, dAmount_, _msgSender());
        require(vlt != address(0), "VAULTMANAGER: FE");

        IWETH(WETH).deposit{value: address(this).balance}();
        uint256 weth = IERC20Minimal(WETH).balanceOf(address(this));

        require(IWETH(WETH).transfer(vlt, weth));

        IStablecoin(stablecoin).mint(_msgSender(), dAmount_);
        emit VaultCreated(id, WETH, stablecoin, msg.sender, vlt, msg.value, dAmount_);
        return true;
    }


    function getCDPConfig(address collateral_) external view override returns (uint MCR, uint LFR, uint SFR, uint cDecimals, bool isOpen) {
        uint8 cDecimals = IERC20Minimal(collateral_).decimals();
        return (MCRConfig[collateral_], LFRConfig[collateral_], SFRConfig[collateral_], cDecimals, IsOpen[collateral_]);
    }

    function getMCR(address collateral_) public view override returns (uint) {
        return MCRConfig[collateral_];
    }

    function getLFR(address collateral_) external view override returns (uint) {
        return LFRConfig[collateral_];
    }

    function getSFR(address collateral_) public view override returns (uint) {
        return SFRConfig[collateral_];
    }

    function getOpen(address collateral_) public view override returns (bool) {
        return IsOpen[collateral_];
    }

    function getCDecimal(address collateral_) public view override returns (uint) {
        return IERC20Minimal(collateral_).decimals();
    }



    function rebase() public {
        uint256 totalSupply = IERC20Minimal(stablecoin).totalSupply();
        if ( totalSupply == 0 ) {
            return;
        }
        uint overallPrice = uint(_getPriceOf(address(0x0)));

        desiredSupply = totalSupply * 1e8 / overallPrice;
        emit Rebase(totalSupply, desiredSupply);
    }

    function isValidCDP(address collateral_, address debt_, uint256 cAmount_, uint256 dAmount_) public view override returns (bool) {
        (uint256 collateralValueTimes100Point00000, uint256 debtValue) = _calculateValues(collateral_, debt_, cAmount_, dAmount_);

        uint mcr = getMCR(collateral_);
        uint cDecimals = IERC20Minimal(collateral_).decimals();

        uint256 debtValueAdjusted = debtValue / (10 ** cDecimals);


        return debtValueAdjusted == 0 ? true : collateralValueTimes100Point00000 / debtValueAdjusted >= mcr;
    }

    function isValidSupply(uint256 issueAmount_) public view override returns (bool) {
        if (rebaseActive) {
            return IERC20Minimal(stablecoin).totalSupply() + issueAmount_ <= desiredSupply;
        } else {
            return true;
        }
    }

    function _calculateValues(address collateral_, address debt_, uint256 cAmount_, uint256 dAmount_) internal view returns (uint256, uint256) {
        uint256 collateralValue = getAssetValue(collateral_, cAmount_);
        uint256 debtValue = getAssetValue(debt_, dAmount_);
        uint256 collateralValueTimes100Point00000 = collateralValue * 10000000;
        require(collateralValueTimes100Point00000 >= collateralValue);
        return (collateralValueTimes100Point00000, debtValue);
    }

    function getAssetPrice(address asset_) public view override returns (uint) {
        address aggregator = PriceFeeds[asset_];
        require(
            aggregator != address(0x0),
            "VAULT: Asset not registered"
        );
        int256 result = IPrice(aggregator).getThePrice();
        return uint(result);
    }

    function getAssetValue(address asset_, uint256 amount_) public view override returns (uint256) {
        uint price = getAssetPrice(asset_);
        uint256 value = price * amount_;
        require(value >= amount_);
        return value;
    }

}

