
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/interfaces/IERC20Standard.sol";
import "../../oracle/implementation/ContractCreator.sol";
import "../../common/implementation/Testable.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "../../common/implementation/Lockable.sol";
import "../common/TokenFactory.sol";
import "../common/SyntheticToken.sol";
import "./PerpetualLib.sol";
import "./ConfigStore.sol";











contract PerpetualCreator is ContractCreator, Testable, Lockable {
    using FixedPoint for FixedPoint.Unsigned;






    struct Params {
        address collateralAddress;
        bytes32 priceFeedIdentifier;
        bytes32 fundingRateIdentifier;
        string syntheticName;
        string syntheticSymbol;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPct;
        FixedPoint.Unsigned sponsorDisputeRewardPct;
        FixedPoint.Unsigned disputerDisputeRewardPct;
        FixedPoint.Unsigned minSponsorTokens;
        FixedPoint.Unsigned tokenScaling;
        uint256 withdrawalLiveness;
        uint256 liquidationLiveness;
    }

    address public tokenFactoryAddress;

    event CreatedPerpetual(address indexed perpetualAddress, address indexed deployerAddress);
    event CreatedConfigStore(address indexed configStoreAddress, address indexed ownerAddress);







    constructor(
        address _finderAddress,
        address _tokenFactoryAddress,
        address _timerAddress
    ) public ContractCreator(_finderAddress) Testable(_timerAddress) nonReentrant() {
        tokenFactoryAddress = _tokenFactoryAddress;
    }






    function createPerpetual(Params memory params, ConfigStore.ConfigSettings memory configSettings)
        public
        nonReentrant()
        returns (address)
    {

        ConfigStore configStore = new ConfigStore(configSettings, timerAddress);
        configStore.transferOwnership(msg.sender);
        CreatedConfigStore(address(configStore), configStore.owner());


        require(bytes(params.syntheticName).length != 0, "Missing synthetic name");
        require(bytes(params.syntheticSymbol).length != 0, "Missing synthetic symbol");
        TokenFactory tf = TokenFactory(tokenFactoryAddress);



        uint8 syntheticDecimals = _getSyntheticDecimals(params.collateralAddress);
        ExpandedIERC20 tokenCurrency = tf.createToken(params.syntheticName, params.syntheticSymbol, syntheticDecimals);
        address derivative = PerpetualLib.deploy(_convertParams(params, tokenCurrency, address(configStore)));


        tokenCurrency.addMinter(derivative);
        tokenCurrency.addBurner(derivative);
        tokenCurrency.resetOwner(derivative);

        _registerContract(new address[](0), address(derivative));

        emit CreatedPerpetual(address(derivative), msg.sender);

        return address(derivative);
    }






    function _convertParams(
        Params memory params,
        ExpandedIERC20 newTokenCurrency,
        address configStore
    ) private view returns (Perpetual.ConstructorParams memory constructorParams) {

        constructorParams.finderAddress = finderAddress;
        constructorParams.timerAddress = timerAddress;


        require(params.withdrawalLiveness != 0, "Withdrawal liveness cannot be 0");
        require(params.liquidationLiveness != 0, "Liquidation liveness cannot be 0");
        _requireWhitelistedCollateral(params.collateralAddress);






        require(params.withdrawalLiveness < 5200 weeks, "Withdrawal liveness too large");
        require(params.liquidationLiveness < 5200 weeks, "Liquidation liveness too large");


        FixedPoint.Unsigned memory minScaling = FixedPoint.Unsigned(1e8);
        FixedPoint.Unsigned memory maxScaling = FixedPoint.Unsigned(1e28);
        require(
            params.tokenScaling.isGreaterThan(minScaling) && params.tokenScaling.isLessThan(maxScaling),
            "Invalid tokenScaling"
        );


        constructorParams.configStoreAddress = configStore;
        constructorParams.tokenAddress = address(newTokenCurrency);
        constructorParams.collateralAddress = params.collateralAddress;
        constructorParams.priceFeedIdentifier = params.priceFeedIdentifier;
        constructorParams.fundingRateIdentifier = params.fundingRateIdentifier;
        constructorParams.collateralRequirement = params.collateralRequirement;
        constructorParams.disputeBondPct = params.disputeBondPct;
        constructorParams.sponsorDisputeRewardPct = params.sponsorDisputeRewardPct;
        constructorParams.disputerDisputeRewardPct = params.disputerDisputeRewardPct;
        constructorParams.minSponsorTokens = params.minSponsorTokens;
        constructorParams.withdrawalLiveness = params.withdrawalLiveness;
        constructorParams.liquidationLiveness = params.liquidationLiveness;
        constructorParams.tokenScaling = params.tokenScaling;
    }




    function _getSyntheticDecimals(address _collateralAddress) public view returns (uint8 decimals) {
        try IERC20Standard(_collateralAddress).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
            return 18;
        }
    }
}
