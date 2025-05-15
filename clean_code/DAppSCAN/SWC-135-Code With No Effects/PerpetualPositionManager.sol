
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../common/implementation/FixedPoint.sol";
import "../../common/interfaces/ExpandedIERC20.sol";

import "../../oracle/interfaces/OracleInterface.sol";
import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../oracle/implementation/Constants.sol";

import "../common/FeePayer.sol";
import "../common/FundingRateApplier.sol";







contract PerpetualPositionManager is FundingRateApplier {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;
    using SafeERC20 for ExpandedIERC20;







    struct PositionData {
        FixedPoint.Unsigned tokensOutstanding;

        uint256 withdrawalRequestPassTimestamp;
        FixedPoint.Unsigned withdrawalRequestAmount;


        FixedPoint.Unsigned rawCollateral;
    }


    mapping(address => PositionData) public positions;



    FixedPoint.Unsigned public totalTokensOutstanding;



    FixedPoint.Unsigned public rawTotalPositionCollateral;


    ExpandedIERC20 public tokenCurrency;


    bytes32 public priceIdentifier;






    uint256 public withdrawalLiveness;


    FixedPoint.Unsigned public minSponsorTokens;


    FixedPoint.Unsigned public emergencyShutdownPrice;





    event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
    event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalExecuted(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalCanceled(address indexed sponsor, uint256 indexed collateralAmount);
    event PositionCreated(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event NewSponsor(address indexed sponsor);
    event EndedSponsorPosition(address indexed sponsor);
    event Redeem(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
    event SettleEmergencyShutdown(
        address indexed caller,
        uint256 indexed collateralReturned,
        uint256 indexed tokensBurned
    );





    modifier onlyCollateralizedPosition(address sponsor) {
        _onlyCollateralizedPosition(sponsor);
        _;
    }

    modifier notEmergencyShutdown() {
        _notEmergencyShutdown();
        _;
    }

    modifier isEmergencyShutdown() {
        _isEmergencyShutdown();
        _;
    }

    modifier noPendingWithdrawal(address sponsor) {
        _positionHasNoPendingWithdrawal(sponsor);
        _;
    }



















    constructor(
        uint256 _withdrawalLiveness,
        address _collateralAddress,
        address _tokenAddress,
        address _finderAddress,
        bytes32 _priceIdentifier,
        bytes32 _fundingRateIdentifier,
        FixedPoint.Unsigned memory _minSponsorTokens,
        address _configStoreAddress,
        FixedPoint.Unsigned memory _tokenScaling,
        address _timerAddress
    )
        public
        FundingRateApplier(
            _fundingRateIdentifier,
            _collateralAddress,
            _finderAddress,
            _configStoreAddress,
            _tokenScaling,
            _timerAddress
        )
    {
        require(_getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier), "Unsupported price identifier");

        withdrawalLiveness = _withdrawalLiveness;
        tokenCurrency = ExpandedIERC20(_tokenAddress);
        minSponsorTokens = _minSponsorTokens;
        priceIdentifier = _priceIdentifier;
    }












    function depositTo(address sponsor, FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(sponsor)
        fees()
        nonReentrant()
    {
        require(collateralAmount.isGreaterThan(0), "Invalid collateral amount");
        PositionData storage positionData = _getPositionData(sponsor);


        _incrementCollateralBalances(positionData, collateralAmount);

        emit Deposit(sponsor, collateralAmount.rawValue);


        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);
    }







    function deposit(FixedPoint.Unsigned memory collateralAmount) public {

        depositTo(msg.sender, collateralAmount);
    }








    function withdraw(FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(collateralAmount.isGreaterThan(0), "Invalid collateral amount");



        amountWithdrawn = _decrementCollateralBalancesCheckGCR(positionData, collateralAmount);

        emit Withdrawal(msg.sender, amountWithdrawn.rawValue);





        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
    }






    function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        nonReentrant()
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            collateralAmount.isGreaterThan(0) &&
                collateralAmount.isLessThanOrEqual(_getFeeAdjustedCollateral(positionData.rawCollateral)),
            "Invalid collateral amount"
        );


        positionData.withdrawalRequestPassTimestamp = getCurrentTime().add(withdrawalLiveness);
        positionData.withdrawalRequestAmount = collateralAmount;

        emit RequestWithdrawal(msg.sender, collateralAmount.rawValue);
    }








    function withdrawPassedRequest()
        external
        notEmergencyShutdown()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            positionData.withdrawalRequestPassTimestamp != 0 &&
                positionData.withdrawalRequestPassTimestamp <= getCurrentTime(),
            "Invalid withdraw request"
        );



        FixedPoint.Unsigned memory amountToWithdraw = positionData.withdrawalRequestAmount;
        if (positionData.withdrawalRequestAmount.isGreaterThan(_getFeeAdjustedCollateral(positionData.rawCollateral))) {
            amountToWithdraw = _getFeeAdjustedCollateral(positionData.rawCollateral);
        }


        amountWithdrawn = _decrementCollateralBalances(positionData, amountToWithdraw);


        _resetWithdrawalRequest(positionData);


        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);

        emit RequestWithdrawalExecuted(msg.sender, amountWithdrawn.rawValue);
    }




    function cancelWithdrawal() external notEmergencyShutdown() nonReentrant() {
        PositionData storage positionData = _getPositionData(msg.sender);

        require(positionData.withdrawalRequestPassTimestamp != 0);

        emit RequestWithdrawalCanceled(msg.sender, positionData.withdrawalRequestAmount.rawValue);


        _resetWithdrawalRequest(positionData);
    }











    function create(FixedPoint.Unsigned memory collateralAmount, FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        fees()
        nonReentrant()
    {
        PositionData storage positionData = positions[msg.sender];


        require(
            (_checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral).add(collateralAmount),
                positionData.tokensOutstanding.add(numTokens)
            ) || _checkCollateralization(collateralAmount, numTokens)),
            "Insufficient collateral"
        );

        require(positionData.withdrawalRequestPassTimestamp == 0, "Pending withdrawal");
        if (positionData.tokensOutstanding.isEqual(0)) {
            require(numTokens.isGreaterThanOrEqual(minSponsorTokens), "Below minimum sponsor position");
            emit NewSponsor(msg.sender);
        }


        _incrementCollateralBalances(positionData, collateralAmount);


        positionData.tokensOutstanding = positionData.tokensOutstanding.add(numTokens);

        totalTokensOutstanding = totalTokensOutstanding.add(numTokens);

        emit PositionCreated(msg.sender, collateralAmount.rawValue, numTokens.rawValue);


        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);


        require(tokenCurrency.mint(msg.sender, numTokens.rawValue));
    }










    function redeem(FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(numTokens.isLessThanOrEqual(positionData.tokensOutstanding), "Invalid token amount");

        FixedPoint.Unsigned memory fractionRedeemed = numTokens.div(positionData.tokensOutstanding);
        FixedPoint.Unsigned memory collateralRedeemed =
            fractionRedeemed.mul(_getFeeAdjustedCollateral(positionData.rawCollateral));


        if (positionData.tokensOutstanding.isEqual(numTokens)) {
            amountWithdrawn = _deleteSponsorPosition(msg.sender);
        } else {

            amountWithdrawn = _decrementCollateralBalances(positionData, collateralRedeemed);


            FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(numTokens);
            require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens), "Below minimum sponsor position");
            positionData.tokensOutstanding = newTokenCount;


            totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);
        }

        emit Redeem(msg.sender, amountWithdrawn.rawValue, numTokens.rawValue);


        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), numTokens.rawValue);
        tokenCurrency.burn(numTokens.rawValue);
    }








    function repay(FixedPoint.Unsigned memory numTokens) public {
        deposit(redeem(numTokens));
    }












    function settleEmergencyShutdown()
        external
        isEmergencyShutdown()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {

        if (emergencyShutdownPrice.isEqual(FixedPoint.fromUnscaledUint(0))) {
            emergencyShutdownPrice = _getOracleEmergencyShutdownPrice();
        }


        FixedPoint.Unsigned memory tokensToRedeem = FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));
        FixedPoint.Unsigned memory totalRedeemableCollateral =
            _getFundingRateAppliedTokenDebt(tokensToRedeem).mul(emergencyShutdownPrice);


        PositionData storage positionData = positions[msg.sender];
        if (_getFeeAdjustedCollateral(positionData.rawCollateral).isGreaterThan(0)) {



            FixedPoint.Unsigned memory tokenDebtValueInCollateral =
                _getFundingRateAppliedTokenDebt(positionData.tokensOutstanding).mul(emergencyShutdownPrice);
            FixedPoint.Unsigned memory positionCollateral = _getFeeAdjustedCollateral(positionData.rawCollateral);


            FixedPoint.Unsigned memory positionRedeemableCollateral =
                tokenDebtValueInCollateral.isLessThan(positionCollateral)
                    ? positionCollateral.sub(tokenDebtValueInCollateral)
                    : FixedPoint.Unsigned(0);


            totalRedeemableCollateral = totalRedeemableCollateral.add(positionRedeemableCollateral);


            delete positions[msg.sender];
            emit EndedSponsorPosition(msg.sender);
        }



        FixedPoint.Unsigned memory payout =
            FixedPoint.min(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalRedeemableCollateral);


        amountWithdrawn = _removeCollateral(rawTotalPositionCollateral, payout);
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRedeem);

        emit SettleEmergencyShutdown(msg.sender, amountWithdrawn.rawValue, tokensToRedeem.rawValue);


        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensToRedeem.rawValue);
        tokenCurrency.burn(tokensToRedeem.rawValue);
    }












    function emergencyShutdown() external override notEmergencyShutdown() fees() nonReentrant() {

        require(msg.sender == _getFinancialContractsAdminAddress());

        emergencyShutdownTimestamp = getCurrentTime();
        _requestOraclePrice(emergencyShutdownTimestamp);

        emit EmergencyShutdown(msg.sender, emergencyShutdownTimestamp);
    }







    function remargin() external override {
        return;
    }











    function getCollateral(address sponsor)
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory collateralAmount)
    {

        return _getFeeAdjustedCollateral(positions[sponsor].rawCollateral);
    }





    function totalPositionCollateral()
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory totalCollateral)
    {
        return _getFeeAdjustedCollateral(rawTotalPositionCollateral);
    }

    function getFundingRateAppliedTokenDebt(FixedPoint.Unsigned memory rawTokenDebt)
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory totalCollateral)
    {
        return _getFundingRateAppliedTokenDebt(rawTokenDebt);
    }







    function _reduceSponsorPosition(
        address sponsor,
        FixedPoint.Unsigned memory tokensToRemove,
        FixedPoint.Unsigned memory collateralToRemove,
        FixedPoint.Unsigned memory withdrawalAmountToRemove
    ) internal {
        PositionData storage positionData = _getPositionData(sponsor);


        if (
            tokensToRemove.isEqual(positionData.tokensOutstanding) &&
            _getFeeAdjustedCollateral(positionData.rawCollateral).isEqual(collateralToRemove)
        ) {
            _deleteSponsorPosition(sponsor);
            return;
        }


        _decrementCollateralBalances(positionData, collateralToRemove);


        positionData.tokensOutstanding = positionData.tokensOutstanding.sub(tokensToRemove);
        require(
            positionData.tokensOutstanding.isGreaterThanOrEqual(minSponsorTokens),
            "Below minimum sponsor position"
        );


        positionData.withdrawalRequestAmount = positionData.withdrawalRequestAmount.sub(withdrawalAmountToRemove);


        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRemove);
    }


    function _deleteSponsorPosition(address sponsor) internal returns (FixedPoint.Unsigned memory) {
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        FixedPoint.Unsigned memory startingGlobalCollateral = _getFeeAdjustedCollateral(rawTotalPositionCollateral);


        rawTotalPositionCollateral = rawTotalPositionCollateral.sub(positionToLiquidate.rawCollateral);
        totalTokensOutstanding = totalTokensOutstanding.sub(positionToLiquidate.tokensOutstanding);


        delete positions[sponsor];

        emit EndedSponsorPosition(sponsor);


        return startingGlobalCollateral.sub(_getFeeAdjustedCollateral(rawTotalPositionCollateral));
    }

    function _pfc() internal view virtual override returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalPositionCollateral);
    }

    function _getPositionData(address sponsor)
        internal
        view
        onlyCollateralizedPosition(sponsor)
        returns (PositionData storage)
    {
        return positions[sponsor];
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    function _getOracle() internal view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getFinancialContractsAdminAddress() internal view returns (address) {
        return finder.getImplementationAddress(OracleInterfaces.FinancialContractsAdmin);
    }


    function _requestOraclePrice(uint256 requestedTime) internal {
        _getOracle().requestPrice(priceIdentifier, requestedTime);
    }


    function _getOraclePrice(uint256 requestedTime) internal view returns (FixedPoint.Unsigned memory price) {

        int256 oraclePrice = _getOracle().getPrice(priceIdentifier, requestedTime);


        if (oraclePrice < 0) {
            oraclePrice = 0;
        }
        return FixedPoint.Unsigned(uint256(oraclePrice));
    }


    function _getOracleEmergencyShutdownPrice() internal view returns (FixedPoint.Unsigned memory) {
        return _getOraclePrice(emergencyShutdownTimestamp);
    }


    function _resetWithdrawalRequest(PositionData storage positionData) internal {
        positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
        positionData.withdrawalRequestPassTimestamp = 0;
    }


    function _incrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _addCollateral(positionData.rawCollateral, collateralAmount);
        return _addCollateral(rawTotalPositionCollateral, collateralAmount);
    }





    function _decrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }




    function _decrementCollateralBalancesCheckGCR(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        require(_checkPositionCollateralization(positionData), "CR below GCR");
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }




    function _onlyCollateralizedPosition(address sponsor) internal view {
        require(
            _getFeeAdjustedCollateral(positions[sponsor].rawCollateral).isGreaterThan(0),
            "Position has no collateral"
        );
    }

    function _notEmergencyShutdown() internal view {

        require(emergencyShutdownTimestamp == 0);
    }

    function _isEmergencyShutdown() internal view {

        require(emergencyShutdownTimestamp != 0);
    }




    function _positionHasNoPendingWithdrawal(address sponsor) internal view {
        require(_getPositionData(sponsor).withdrawalRequestPassTimestamp == 0, "Pending withdrawal");
    }





    function _checkPositionCollateralization(PositionData storage positionData) private view returns (bool) {
        return
            _checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral),
                positionData.tokensOutstanding
            );
    }



    function _checkCollateralization(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        view
        returns (bool)
    {
        FixedPoint.Unsigned memory global =
            _getCollateralizationRatio(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalTokensOutstanding);
        FixedPoint.Unsigned memory thisChange = _getCollateralizationRatio(collateral, numTokens);
        return !global.isGreaterThan(thisChange);
    }

    function _getCollateralizationRatio(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        pure
        returns (FixedPoint.Unsigned memory ratio)
    {
        return numTokens.isLessThanOrEqual(0) ? FixedPoint.fromUnscaledUint(0) : collateral.div(numTokens);
    }

    function _getTokenAddress() internal view override returns (address) {
        return address(tokenCurrency);
    }
}
