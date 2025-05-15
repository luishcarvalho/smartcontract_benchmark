
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../lib/SafeInt256.sol";
import "../lib/SafeMath.sol";

import "../utils/Governed.sol";
import "../utils/Common.sol";
import "../interface/IPortfoliosCallable.sol";
import "../storage/PortfoliosStorage.sol";

import "../CashMarket.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";





library RiskFramework {
    using SafeMath for uint256;
    using SafeInt256 for int256;
















    function getRequirement(
        Common.Asset[] memory portfolio,
        address Portfolios
    ) public view returns (Common.Requirement[] memory) {
        Common._sortPortfolio(portfolio);


        (Common.CashGroup[] memory cashGroups, CashLadder[] memory ladders) = _fetchCashGroups(
            portfolio,
            IPortfoliosCallable(Portfolios)
        );

        uint128 fCashHaircut = PortfoliosStorageSlot._fCashHaircut();
        uint128 fCashMaxHaircut = PortfoliosStorageSlot._fCashMaxHaircut();
        uint32 blockTime = uint32(block.timestamp);

        int256[] memory cashClaims = _getCashLadders(
            portfolio,
            cashGroups,
            ladders,
            PortfoliosStorageSlot._liquidityHaircut(),
            blockTime
        );



        Common.Requirement[] memory requirements = new Common.Requirement[](ladders.length);

        for (uint256 i; i < ladders.length; i++) {
            requirements[i].currency = ladders[i].currency;
            requirements[i].cashClaim = cashClaims[i];
            uint32 initialMaturity;
            if (blockTime % cashGroups[i].maturityLength == 0) {

                initialMaturity = blockTime;
            } else {
                initialMaturity = blockTime - (blockTime % cashGroups[i].maturityLength) + cashGroups[i].maturityLength;
            }

            for (uint256 j; j < ladders[i].cashLadder.length; j++) {
                int256 netfCash = ladders[i].cashLadder[j];
                if (netfCash > 0) {
                    uint32 maturity = initialMaturity + cashGroups[i].maturityLength * uint32(j);

                    netfCash = _calculateReceiverValue(netfCash, maturity, blockTime, fCashHaircut, fCashMaxHaircut);
                }

                requirements[i].netfCashValue = requirements[i].netfCashValue.add(netfCash);
            }
        }

        return requirements;
    }







    function _getCashLadders(
        Common.Asset[] memory portfolio,
        Common.CashGroup[] memory cashGroups,
        CashLadder[] memory ladders,
        uint128 liquidityHaircut,
        uint32 blockTime
    ) internal view returns (int256[] memory) {


        int256[] memory cashClaims = new int256[](ladders.length);


        uint256 groupIndex;


        for (uint256 i; i < portfolio.length; i++) {
            if (portfolio[i].cashGroupId != ladders[groupIndex].id) {

                groupIndex++;
            }

            (int256 fCashAmount, int256 cashClaimAmount) = _calculateAssetValue(
                portfolio[i],
                cashGroups[groupIndex],
                blockTime,
                liquidityHaircut
            );

            cashClaims[groupIndex] = cashClaims[groupIndex].add(cashClaimAmount);
            if (portfolio[i].maturity <= blockTime) {



                cashClaims[groupIndex] = cashClaims[groupIndex].add(fCashAmount);
            } else {
                uint256 offset = (portfolio[i].maturity - blockTime) / cashGroups[groupIndex].maturityLength;

                if (cashGroups[groupIndex].cashMarket == address(0)) {


                    fCashAmount = fCashAmount > 0 ? 0 : fCashAmount;
                }

                ladders[groupIndex].cashLadder[offset] = ladders[groupIndex].cashLadder[offset].add(fCashAmount);
            }
        }

        return cashClaims;
    }

    function _calculateAssetValue(
        Common.Asset memory asset,
        Common.CashGroup memory cg,
        uint32 blockTime,
        uint128 liquidityHaircut
    ) internal view returns (int256, int256) {
        int256 cashClaim;
        int256 fCash;

        if (Common.isLiquidityToken(asset.assetType)) {
            (cashClaim, fCash) = _calculateLiquidityTokenClaims(asset, cg.cashMarket, blockTime, liquidityHaircut);
        } else if (Common.isCashPayer(asset.assetType)) {
            fCash = int256(asset.notional).neg();
        } else if (Common.isCashReceiver(asset.assetType)) {
            fCash = int256(asset.notional);
        }

        return (fCash, cashClaim);
    }

    function _calculateReceiverValue(
        int256 fCash,
        uint32 maturity,
        uint32 blockTime,
        uint128 fCashHaircut,
        uint128 fCashMaxHaircut
    ) internal pure returns (int256) {
        require(maturity > blockTime);




        int256 postHaircutValue = fCash.sub(
            fCash
                .mul(fCashHaircut)
                .mul(maturity - blockTime)
                .div(Common.SECONDS_IN_YEAR)

                .div(Common.DECIMALS)
        );

        int256 maxPostHaircutValue = fCash

            .mul(fCashMaxHaircut)
            .div(Common.DECIMALS);

        if (postHaircutValue < maxPostHaircutValue) {
            return postHaircutValue;
        } else {
            return maxPostHaircutValue;
        }
    }

    function _calculateLiquidityTokenClaims(
        Common.Asset memory asset,
        address cashMarket,
        uint32 blockTime,
        uint128 liquidityHaircut
    ) internal view returns (uint128, uint128) {
        CashMarket.Market memory market = CashMarket(cashMarket).getMarket(asset.maturity);

        uint256 cashClaim;
        uint256 fCashClaim;

        if (blockTime < asset.maturity) {




            cashClaim = uint256(market.totalCurrentCash)
                .mul(asset.notional)
                .mul(liquidityHaircut)
                .div(Common.DECIMALS)
                .div(market.totalLiquidity);

            fCashClaim = uint256(market.totalfCash)
                .mul(asset.notional)
                .mul(liquidityHaircut)
                .div(Common.DECIMALS)
                .div(market.totalLiquidity);
        } else {
            cashClaim = uint256(market.totalCurrentCash)
                .mul(asset.notional)
                .div(market.totalLiquidity);

            fCashClaim = uint256(market.totalfCash)
                .mul(asset.notional)
                .div(market.totalLiquidity);
        }

        return (SafeCast.toUint128(cashClaim), SafeCast.toUint128(fCashClaim));
    }

    function _fetchCashGroups(
        Common.Asset[] memory portfolio,
        IPortfoliosCallable Portfolios
    ) internal view returns (Common.CashGroup[] memory, CashLadder[] memory) {
        uint8[] memory groupIds = new uint8[](portfolio.length);
        uint256 numGroups;

        groupIds[numGroups] = portfolio[0].cashGroupId;

        for (uint256 i = 1; i < portfolio.length; i++) {
            if (portfolio[i].cashGroupId != groupIds[numGroups]) {
                numGroups++;
                groupIds[numGroups] = portfolio[i].cashGroupId;
            }
        }

        uint8[] memory requestGroups = new uint8[](numGroups + 1);
        for (uint256 i; i < requestGroups.length; i++) {
            requestGroups[i] = groupIds[i];
        }

        Common.CashGroup[] memory cgs = Portfolios.getCashGroups(requestGroups);

        CashLadder[] memory ladders = new CashLadder[](cgs.length);
        for (uint256 i; i < ladders.length; i++) {
            ladders[i].id = requestGroups[i];
            ladders[i].currency = cgs[i].currency;
            ladders[i].cashLadder = new int256[](cgs[i].numMaturities);
        }

        return (cgs, ladders);
    }
}
