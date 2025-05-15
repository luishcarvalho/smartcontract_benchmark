
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./PerpetualPositionManager.sol";

import "../../common/implementation/FixedPoint.sol";










contract PerpetualLiquidatable is PerpetualPositionManager {
    using FixedPoint for FixedPoint.Unsigned;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;






    enum Status { Uninitialized, PreDispute, PendingDispute, DisputeSucceeded, DisputeFailed }

    struct LiquidationData {

        address sponsor;
        address liquidator;
        Status state;
        uint256 liquidationTime;

        FixedPoint.Unsigned tokensOutstanding;
        FixedPoint.Unsigned lockedCollateral;


        FixedPoint.Unsigned liquidatedCollateral;

        FixedPoint.Unsigned rawUnitCollateral;

        address disputer;

        FixedPoint.Unsigned settlementPrice;
        FixedPoint.Unsigned finalFee;
    }



    struct ConstructorParams {

        uint256 withdrawalLiveness;
        address configStoreAddress;
        address collateralAddress;
        address tokenAddress;
        address finderAddress;
        address timerAddress;
        bytes32 priceFeedIdentifier;
        bytes32 fundingRateIdentifier;
        FixedPoint.Unsigned minSponsorTokens;
        FixedPoint.Unsigned tokenScaling;

        uint256 liquidationLiveness;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPct;
        FixedPoint.Unsigned sponsorDisputeRewardPct;
        FixedPoint.Unsigned disputerDisputeRewardPct;
    }





    struct RewardsData {
        FixedPoint.Unsigned payToSponsor;
        FixedPoint.Unsigned payToLiquidator;
        FixedPoint.Unsigned payToDisputer;
        FixedPoint.Unsigned paidToSponsor;
        FixedPoint.Unsigned paidToLiquidator;
        FixedPoint.Unsigned paidToDisputer;
    }


    mapping(address => LiquidationData[]) public liquidations;


    FixedPoint.Unsigned public rawLiquidationCollateral;








    uint256 public liquidationLiveness;

    FixedPoint.Unsigned public collateralRequirement;


    FixedPoint.Unsigned public disputeBondPct;


    FixedPoint.Unsigned public sponsorDisputeRewardPct;


    FixedPoint.Unsigned public disputerDisputeRewardPct;





    event LiquidationCreated(
        address indexed sponsor,
        address indexed liquidator,
        uint256 indexed liquidationId,
        uint256 tokensOutstanding,
        uint256 lockedCollateral,
        uint256 liquidatedCollateral,
        uint256 liquidationTime
    );
    event LiquidationDisputed(
        address indexed sponsor,
        address indexed liquidator,
        address indexed disputer,
        uint256 liquidationId,
        uint256 disputeBondAmount
    );
    event DisputeSettled(
        address indexed caller,
        address indexed sponsor,
        address indexed liquidator,
        address disputer,
        uint256 liquidationId,
        bool disputeSucceeded
    );
    event LiquidationWithdrawn(
        address indexed caller,
        uint256 paidToLiquidator,
        uint256 paidToDisputer,
        uint256 paidToSponsor,
        Status indexed liquidationStatus,
        uint256 settlementPrice
    );





    modifier disputable(uint256 liquidationId, address sponsor) {
        _disputable(liquidationId, sponsor);
        _;
    }

    modifier withdrawable(uint256 liquidationId, address sponsor) {
        _withdrawable(liquidationId, sponsor);
        _;
    }






    constructor(ConstructorParams memory params)
        public
        PerpetualPositionManager(
            params.withdrawalLiveness,
            params.collateralAddress,
            params.tokenAddress,
            params.finderAddress,
            params.priceFeedIdentifier,
            params.fundingRateIdentifier,
            params.minSponsorTokens,
            params.configStoreAddress,
            params.tokenScaling,
            params.timerAddress
        )
    {
        require(params.collateralRequirement.isGreaterThan(1), "CR is more than 100%");
        require(
            params.sponsorDisputeRewardPct.add(params.disputerDisputeRewardPct).isLessThan(1),
            "Rewards are more than 100%"
        );


        liquidationLiveness = params.liquidationLiveness;
        collateralRequirement = params.collateralRequirement;
        disputeBondPct = params.disputeBondPct;
        sponsorDisputeRewardPct = params.sponsorDisputeRewardPct;
        disputerDisputeRewardPct = params.disputerDisputeRewardPct;
    }





















    function createLiquidation(
        address sponsor,
        FixedPoint.Unsigned calldata minCollateralPerToken,
        FixedPoint.Unsigned calldata maxCollateralPerToken,
        FixedPoint.Unsigned calldata maxTokensToLiquidate,
        uint256 deadline
    )
        external
        notEmergencyShutdown()
        fees()
        nonReentrant()
        returns (
            uint256 liquidationId,
            FixedPoint.Unsigned memory tokensLiquidated,
            FixedPoint.Unsigned memory finalFeeBond
        )
    {

        require(getCurrentTime() <= deadline, "Mined after deadline");


        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        tokensLiquidated = FixedPoint.min(maxTokensToLiquidate, positionToLiquidate.tokensOutstanding);
        require(tokensLiquidated.isGreaterThan(0), "Liquidating 0 tokens");



        FixedPoint.Unsigned memory startCollateral = _getFeeAdjustedCollateral(positionToLiquidate.rawCollateral);
        FixedPoint.Unsigned memory startCollateralNetOfWithdrawal = FixedPoint.fromUnscaledUint(0);
        if (positionToLiquidate.withdrawalRequestAmount.isLessThanOrEqual(startCollateral)) {
            startCollateralNetOfWithdrawal = startCollateral.sub(positionToLiquidate.withdrawalRequestAmount);
        }


        {
            FixedPoint.Unsigned memory startTokens = positionToLiquidate.tokensOutstanding;


            require(
                maxCollateralPerToken.mul(startTokens).isGreaterThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is more than max liq. price"
            );

            require(
                minCollateralPerToken.mul(startTokens).isLessThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is less than min liq. price"
            );
        }


        finalFeeBond = _computeFinalFees();


        FixedPoint.Unsigned memory lockedCollateral;
        FixedPoint.Unsigned memory liquidatedCollateral;




        {
            FixedPoint.Unsigned memory ratio = tokensLiquidated.div(positionToLiquidate.tokensOutstanding);


            lockedCollateral = startCollateral.mul(ratio);



            liquidatedCollateral = startCollateralNetOfWithdrawal.mul(ratio);



            FixedPoint.Unsigned memory withdrawalAmountToRemove =
                positionToLiquidate.withdrawalRequestAmount.mul(ratio);
            _reduceSponsorPosition(sponsor, tokensLiquidated, lockedCollateral, withdrawalAmountToRemove);
        }


        _addCollateral(rawLiquidationCollateral, lockedCollateral.add(finalFeeBond));




        liquidationId = liquidations[sponsor].length;
        liquidations[sponsor].push(
            LiquidationData({
                sponsor: sponsor,
                liquidator: msg.sender,
                state: Status.PreDispute,
                liquidationTime: getCurrentTime(),
                tokensOutstanding: _getFundingRateAppliedTokenDebt(tokensLiquidated),
                lockedCollateral: lockedCollateral,
                liquidatedCollateral: liquidatedCollateral,
                rawUnitCollateral: _convertToRawCollateral(FixedPoint.fromUnscaledUint(1)),
                disputer: address(0),
                settlementPrice: FixedPoint.fromUnscaledUint(0),
                finalFee: finalFeeBond
            })
        );








        FixedPoint.Unsigned memory griefingThreshold = minSponsorTokens;
        if (
            positionToLiquidate.withdrawalRequestPassTimestamp > 0 &&
            positionToLiquidate.withdrawalRequestPassTimestamp > getCurrentTime() &&
            tokensLiquidated.isGreaterThanOrEqual(griefingThreshold)
        ) {
            positionToLiquidate.withdrawalRequestPassTimestamp = getCurrentTime().add(withdrawalLiveness);
        }

        emit LiquidationCreated(
            sponsor,
            msg.sender,
            liquidationId,
            _getFundingRateAppliedTokenDebt(tokensLiquidated).rawValue,
            lockedCollateral.rawValue,
            liquidatedCollateral.rawValue,
            getCurrentTime()
        );


        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensLiquidated.rawValue);
        tokenCurrency.burn(tokensLiquidated.rawValue);


        collateralCurrency.safeTransferFrom(msg.sender, address(this), finalFeeBond.rawValue);
    }











    function dispute(uint256 liquidationId, address sponsor)
        external
        disputable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory totalPaid)
    {
        LiquidationData storage disputedLiquidation = _getLiquidationData(sponsor, liquidationId);


        FixedPoint.Unsigned memory disputeBondAmount =
            disputedLiquidation.lockedCollateral.mul(disputeBondPct).mul(
                _getFeeAdjustedCollateral(disputedLiquidation.rawUnitCollateral)
            );
        _addCollateral(rawLiquidationCollateral, disputeBondAmount);


        disputedLiquidation.state = Status.PendingDispute;
        disputedLiquidation.disputer = msg.sender;


        _requestOraclePrice(disputedLiquidation.liquidationTime);

        emit LiquidationDisputed(
            sponsor,
            disputedLiquidation.liquidator,
            msg.sender,
            liquidationId,
            disputeBondAmount.rawValue
        );
        totalPaid = disputeBondAmount.add(disputedLiquidation.finalFee);


        _payFinalFees(msg.sender, disputedLiquidation.finalFee);


        collateralCurrency.safeTransferFrom(msg.sender, address(this), disputeBondAmount.rawValue);
    }











    function withdrawLiquidation(uint256 liquidationId, address sponsor)
        public
        withdrawable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (RewardsData memory)
    {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);


        _settle(liquidationId, sponsor);





        FixedPoint.Unsigned memory feeAttenuation = _getFeeAdjustedCollateral(liquidation.rawUnitCollateral);
        FixedPoint.Unsigned memory settlementPrice = liquidation.settlementPrice;
        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(settlementPrice).mul(feeAttenuation);
        FixedPoint.Unsigned memory collateral = liquidation.lockedCollateral.mul(feeAttenuation);
        FixedPoint.Unsigned memory disputerDisputeReward = disputerDisputeRewardPct.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory sponsorDisputeReward = sponsorDisputeRewardPct.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory disputeBondAmount = collateral.mul(disputeBondPct);
        FixedPoint.Unsigned memory finalFee = liquidation.finalFee.mul(feeAttenuation);






        RewardsData memory rewards;
        if (liquidation.state == Status.DisputeSucceeded) {



            rewards.payToDisputer = disputerDisputeReward.add(disputeBondAmount).add(finalFee);


            rewards.payToSponsor = sponsorDisputeReward.add(collateral.sub(tokenRedemptionValue));





            rewards.payToLiquidator = tokenRedemptionValue.sub(sponsorDisputeReward).sub(disputerDisputeReward);


            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);
            rewards.paidToSponsor = _removeCollateral(rawLiquidationCollateral, rewards.payToSponsor);
            rewards.paidToDisputer = _removeCollateral(rawLiquidationCollateral, rewards.payToDisputer);

            collateralCurrency.safeTransfer(liquidation.disputer, rewards.paidToDisputer.rawValue);
            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
            collateralCurrency.safeTransfer(liquidation.sponsor, rewards.paidToSponsor.rawValue);


        } else if (liquidation.state == Status.DisputeFailed) {

            rewards.payToLiquidator = collateral.add(disputeBondAmount).add(finalFee);


            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);



        } else if (liquidation.state == Status.PreDispute) {

            rewards.payToLiquidator = collateral.add(finalFee);


            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
        }

        emit LiquidationWithdrawn(
            msg.sender,
            rewards.paidToLiquidator.rawValue,
            rewards.paidToDisputer.rawValue,
            rewards.paidToSponsor.rawValue,
            liquidation.state,
            settlementPrice.rawValue
        );


        delete liquidations[sponsor][liquidationId];

        return rewards;
    }






    function getLiquidations(address sponsor)
        external
        view
        nonReentrantView()
        returns (LiquidationData[] memory liquidationData)
    {
        return liquidations[sponsor];
    }







    function _settle(uint256 liquidationId, address sponsor) internal {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);



        if (liquidation.state != Status.PendingDispute) {
            return;
        }


        liquidation.settlementPrice = _getOraclePrice(liquidation.liquidationTime);


        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(liquidation.settlementPrice);


        FixedPoint.Unsigned memory requiredCollateral = tokenRedemptionValue.mul(collateralRequirement);



        bool disputeSucceeded = liquidation.liquidatedCollateral.isGreaterThanOrEqual(requiredCollateral);
        liquidation.state = disputeSucceeded ? Status.DisputeSucceeded : Status.DisputeFailed;

        emit DisputeSettled(
            msg.sender,
            sponsor,
            liquidation.liquidator,
            liquidation.disputer,
            liquidationId,
            disputeSucceeded
        );
    }

    function _pfc() internal view override returns (FixedPoint.Unsigned memory) {
        return super._pfc().add(_getFeeAdjustedCollateral(rawLiquidationCollateral));
    }

    function _getLiquidationData(address sponsor, uint256 liquidationId)
        internal
        view
        returns (LiquidationData storage liquidation)
    {
        LiquidationData[] storage liquidationArray = liquidations[sponsor];



        require(
            liquidationId < liquidationArray.length && liquidationArray[liquidationId].state != Status.Uninitialized,
            "Invalid liquidation ID"
        );
        return liquidationArray[liquidationId];
    }

    function _getLiquidationExpiry(LiquidationData storage liquidation) internal view returns (uint256) {
        return liquidation.liquidationTime.add(liquidationLiveness);
    }




    function _disputable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        require(
            (getCurrentTime() < _getLiquidationExpiry(liquidation)) && (liquidation.state == Status.PreDispute),
            "Liquidation not disputable"
        );
    }

    function _withdrawable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        Status state = liquidation.state;


        require(
            (state > Status.PreDispute) ||
                ((_getLiquidationExpiry(liquidation) <= getCurrentTime()) && (state == Status.PreDispute)),
            "Liquidation not withdrawable"
        );
    }
}
