
pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

import "./Common.sol";
import "./ExchangeRate.sol";

import "../lib/SafeInt256.sol";
import "../lib/SafeMath.sol";
import "../lib/SafeUInt128.sol";

import "../interface/IPortfoliosCallable.sol";
import "../storage/EscrowStorage.sol";

import "@openzeppelin/contracts/utils/SafeCast.sol";

library Liquidation {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using SafeUInt128 for uint128;



    int256 public constant LIQUIDATION_BUFFER = 1.01e18;

    struct TransferAmounts {
        int256 netLocalCurrencyLiquidator;
        uint128 netLocalCurrencyPayer;
        uint128 collateralTransfer;
        int256 payerCollateralBalance;
    }

    struct CollateralCurrencyParameters {
        uint128 localCurrencyRequired;
        int256 localCurrencyAvailable;
        uint16 collateralCurrency;
        int256 collateralCurrencyCashClaim;
        int256 collateralCurrencyAvailable;
        uint128 discountFactor;
        uint128 liquidityHaircut;
        IPortfoliosCallable Portfolios;
    }

    struct RateParameters {
        uint256 rate;
        uint16 localCurrency;
        uint16 collateralCurrency;
        uint256 localDecimals;
        uint256 collateralDecimals;
        ExchangeRate.Rate localToETH;
    }

















    function _liquidateLocalLiquidityTokens(
        address payer,
        uint16 localCurrency,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        int256 localCurrencyNetAvailable,
        IPortfoliosCallable Portfolios
    ) internal returns (int256, uint128, int256, uint128) {

        (uint128 cashClaimWithdrawn, uint128 localCurrencyRaised) = Liquidation._localLiquidityTokenTrade(
            payer,
            localCurrency,
            localCurrencyRequired,
            liquidityHaircut,
            Portfolios
        );


        return _calculatePostTradeFactors(
            cashClaimWithdrawn,
            localCurrencyNetAvailable,
            localCurrencyRequired,
            localCurrencyRaised,
            liquidityHaircut
        );
    }


























































































    function liquidate(
        address payer,
        int256 payerCollateralBalance,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios
    ) public returns (TransferAmounts memory) {
        uint128 localCurrencyRequired = _fcAggregateToLocal(fc.aggregate, rateParam);

        TransferAmounts memory transfer = TransferAmounts(0, 0, 0, payerCollateralBalance);
        uint128 liquidityHaircut = EscrowStorageSlot._liquidityHaircut();
        if (fc.localCashClaim > 0) {

            (
                transfer.netLocalCurrencyLiquidator,
                transfer.netLocalCurrencyPayer,
                fc.localNetAvailable,
                localCurrencyRequired
            ) = _liquidateLocalLiquidityTokens(
                payer,
                rateParam.localCurrency,
                localCurrencyRequired,
                liquidityHaircut,
                fc.localNetAvailable,
                IPortfoliosCallable(Portfolios)
            );
        }




        if (localCurrencyRequired > 0 && fc.localNetAvailable < 0) {
            _liquidateCollateralCurrency(
                payer,
                localCurrencyRequired,
                liquidityHaircut,
                transfer,
                fc,
                rateParam,
                Portfolios
            );
        }

        return transfer;
    }


    function _fcAggregateToLocal(
        int256 fcAggregate,
        RateParameters memory rateParam
    ) internal view returns (uint128) {

        require(fcAggregate < 0);

        return uint128(
            ExchangeRate._convertETHTo(
                rateParam.localToETH,
                rateParam.localDecimals,
                fcAggregate.mul(LIQUIDATION_BUFFER).div(Common.DECIMALS).neg()
            )
        );
    }










    function settle(
        address payer,
        int256 payerCollateralBalance,
        uint128 valueToSettle,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios
    ) public returns (TransferAmounts memory) {
        TransferAmounts memory transfer = TransferAmounts(0, 0, 0, payerCollateralBalance);
        if (fc.localCashClaim > 0) {
            uint128 remainder = IPortfoliosCallable(Portfolios).raiseCurrentCashViaLiquidityToken(
                payer,
                rateParam.localCurrency,
                valueToSettle
            );

            transfer.netLocalCurrencyPayer = valueToSettle.sub(remainder);

            if (transfer.netLocalCurrencyPayer > fc.localCashClaim) {


                uint128 haircutAmount = transfer.netLocalCurrencyPayer.sub(uint128(fc.localCashClaim));

                int256 netFC = ExchangeRate._convertToETH(
                    rateParam.localToETH,
                    rateParam.localDecimals,
                    haircutAmount,
                    fc.localNetAvailable < 0
                );

                fc.aggregate = fc.aggregate.add(netFC);
            }
        }

        if (valueToSettle > transfer.netLocalCurrencyPayer && fc.aggregate >= 0) {
            uint128 liquidityHaircut = EscrowStorageSlot._liquidityHaircut();
            uint128 settlementDiscount = EscrowStorageSlot._settlementDiscount();
            uint128 localCurrencyRequired = valueToSettle.sub(transfer.netLocalCurrencyPayer);

            _tradeCollateralCurrency(
                payer,
                localCurrencyRequired,
                liquidityHaircut,
                settlementDiscount,
                transfer,
                fc,
                rateParam,
                Portfolios
            );
        }

        return transfer;
    }

    function _calculateLocalCurrencyToTrade(
        uint128 localCurrencyRequired,
        uint128 liquidationDiscount,
        uint128 localCurrencyBuffer,
        uint128 maxLocalCurrencyDebt
    ) internal pure returns (uint128) {






















        uint128 localCurrencyToTrade = SafeCast.toUint128(
            uint256(localCurrencyRequired)
                .mul(Common.DECIMALS)
                .div(localCurrencyBuffer.sub(liquidationDiscount))
        );


        localCurrencyToTrade = maxLocalCurrencyDebt < localCurrencyToTrade ? maxLocalCurrencyDebt : localCurrencyToTrade;

        return localCurrencyToTrade;
    }

    function _liquidateCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios
    ) internal {
        uint128 discountFactor = EscrowStorageSlot._liquidationDiscount();
        localCurrencyRequired = _calculateLocalCurrencyToTrade(
            localCurrencyRequired,
            discountFactor,
            rateParam.localToETH.buffer,
            uint128(fc.localNetAvailable.neg())
        );

        _tradeCollateralCurrency(
            payer,
            localCurrencyRequired,
            liquidityHaircut,
            discountFactor,
            transfer,
            fc,
            rateParam,
            Portfolios
        );
    }

    function _tradeCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        uint128 discountFactor,
        TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam,
        address Portfolios
    ) internal {
        uint128 amountToRaise;
        uint128 localToPurchase;

        uint128 haircutClaim = _calculateLiquidityTokenHaircut(
            fc.collateralCashClaim,
            liquidityHaircut
        );

        int256 collateralToSell = _calculateCollateralToSell(
            discountFactor,
            localCurrencyRequired,
            rateParam
        );



        if (collateralToSell == 0) return;

        int256 balanceAdjustment;
        (fc.collateralNetAvailable, balanceAdjustment) = _calculatePostfCashValue(fc, transfer);
        require(fc.collateralNetAvailable > 0, $$(ErrorCode(INSUFFICIENT_BALANCE)));

        (amountToRaise, localToPurchase, transfer.collateralTransfer) = _calculatePurchaseAmounts(
            localCurrencyRequired,
            discountFactor,
            liquidityHaircut,
            haircutClaim,
            collateralToSell,
            fc,
            rateParam
        );


        transfer.payerCollateralBalance = _calculateCollateralBalances(
            payer,
            transfer.payerCollateralBalance.add(balanceAdjustment),
            rateParam.collateralCurrency,
            transfer.collateralTransfer,
            amountToRaise,
            IPortfoliosCallable(Portfolios)
        );

        transfer.payerCollateralBalance = transfer.payerCollateralBalance.sub(balanceAdjustment);
        transfer.netLocalCurrencyPayer = transfer.netLocalCurrencyPayer.add(localToPurchase);
        transfer.netLocalCurrencyLiquidator = transfer.netLocalCurrencyLiquidator.add(localToPurchase);
    }





    function _calculatePostfCashValue(
        Common.FreeCollateralFactors memory fc,
        TransferAmounts memory transfer
    ) internal pure returns (int256, int256) {
        int256 fCashValue = fc.collateralNetAvailable
            .sub(transfer.payerCollateralBalance)
            .sub(fc.collateralCashClaim);

        if (fCashValue <= 0) {

            return (fc.collateralNetAvailable, 0);
        }

        if (transfer.payerCollateralBalance >= 0) {


            return (fc.collateralNetAvailable.sub(fCashValue), 0);
        }



        int256 netBalanceWithfCashValue = transfer.payerCollateralBalance.add(fCashValue);
        if (netBalanceWithfCashValue > 0) {


            return (fc.collateralNetAvailable.sub(netBalanceWithfCashValue), transfer.payerCollateralBalance.neg());
        } else {


            return (fc.collateralNetAvailable, fCashValue);
        }
    }

    function _calculateLiquidityTokenHaircut(
        int256 postHaircutCashClaim,
        uint128 liquidityHaircut
    ) internal pure returns (uint128) {
        require(postHaircutCashClaim >= 0);

        uint256 x = uint256(postHaircutCashClaim);

        return SafeCast.toUint128(
            uint256(x)
                .mul(Common.DECIMALS)
                .div(liquidityHaircut)
                .sub(x)
        );
    }

    function _calculatePurchaseAmounts(
        uint128 localCurrencyRequired,
        uint128 discountFactor,
        uint128 liquidityHaircut,
        uint128 haircutClaim,
        int256 collateralToSell,
        Common.FreeCollateralFactors memory fc,
        RateParameters memory rateParam
    ) internal pure returns (uint128, uint128, uint128) {
        require(fc.collateralNetAvailable > 0, $$(ErrorCode(INSUFFICIENT_BALANCE)));

        uint128 localToPurchase;
        uint128 amountToRaise;


        if (fc.collateralNetAvailable >= collateralToSell) {



            localToPurchase = localCurrencyRequired;
        } else if (fc.collateralNetAvailable.add(haircutClaim) >= collateralToSell) {







            amountToRaise = SafeCast.toUint128(
                uint256(collateralToSell.sub(fc.collateralNetAvailable))
                    .mul(Common.DECIMALS)
                    .div(Common.DECIMALS.sub(liquidityHaircut))
            );
            localToPurchase = localCurrencyRequired;
        } else if (collateralToSell > fc.collateralNetAvailable.add(haircutClaim)) {


            collateralToSell = fc.collateralNetAvailable.add(haircutClaim);



            uint256 x = haircutClaim.mul(Common.DECIMALS);
            x = x.div(Common.DECIMALS.sub(liquidityHaircut));
            amountToRaise = SafeCast.toUint128(x);


            require(collateralToSell > 0);
            localToPurchase = _calculateLocalCurrencyAmount(discountFactor, uint128(collateralToSell), rateParam);
        }

        require(collateralToSell > 0);

        return (amountToRaise, localToPurchase, uint128(collateralToSell));
    }

    function _calculateLocalCurrencyAmount(
        uint128 discountFactor,
        uint128 collateralToSell,
        RateParameters memory rateParam
    ) internal pure returns (uint128) {


        uint256 x = uint256(collateralToSell)
            .mul(rateParam.localToETH.rateDecimals)

            .mul(Common.DECIMALS);

        x = x
            .mul(rateParam.localDecimals)
            .div(rateParam.rate);

        return SafeCast.toUint128(x
            .div(discountFactor)
            .div(rateParam.collateralDecimals)
        );
    }

    function _calculateCollateralToSell(
        uint128 discountFactor,
        uint128 localCurrencyRequired,
        RateParameters memory rateParam
    ) internal pure returns (uint128) {
        uint256 x = rateParam.rate
            .mul(localCurrencyRequired)
            .mul(discountFactor);

        x = x
            .div(rateParam.localToETH.rateDecimals)
            .div(rateParam.localDecimals);


        return SafeCast.toUint128(x

            .mul(rateParam.collateralDecimals)

            .div(Common.DECIMALS)
        );
    }

    function _calculateCollateralBalances(
        address payer,
        int256 payerBalance,
        uint16 collateralCurrency,
        uint128 collateralToSell,
        uint128 amountToRaise,
        IPortfoliosCallable Portfolios
    ) internal returns (int256) {


        int256 balance = payerBalance;
        bool creditBalance;

        if (balance >= collateralToSell) {
            balance = balance.sub(collateralToSell);
            creditBalance = true;
        } else {



            int256 x = int256(collateralToSell).sub(balance);
            require(x > 0);
            uint128 tmp = uint128(x);

            if (amountToRaise > tmp) {
                balance = int256(amountToRaise).sub(tmp);
            } else {
                amountToRaise = tmp;
                balance = 0;
            }

            creditBalance = false;
        }

        if (amountToRaise > 0) {
            uint128 remainder = Portfolios.raiseCurrentCashViaLiquidityToken(
                payer,
                collateralCurrency,
                amountToRaise
            );

            if (creditBalance) {
                balance = balance.add(amountToRaise).sub(remainder);
            } else {





                require(remainder <= 1, $$(ErrorCode(RAISING_LIQUIDITY_TOKEN_BALANCE_ERROR)));
                balance = balance.sub(remainder);
            }
        }

        return balance;
    }










    function settlefCash(
        address payer,
        address liquidator,
        uint128 valueToSettle,
        int256 collateralNetAvailable,
        RateParameters memory rateParam,
        address Portfolios
    ) public returns (int256, uint128) {
        uint128 discountFactor = EscrowStorageSlot._settlementDiscount();

        return _tradefCash(
            payer,
            liquidator,
            valueToSettle,
            collateralNetAvailable,
            discountFactor,
            rateParam,
            Portfolios
        );
    }











    function liquidatefCash(
        address payer,
        address liquidator,
        int256 fcAggregate,
        int256 localNetAvailable,
        int256 collateralNetAvailable,
        RateParameters memory rateParam,
        address Portfolios
    ) public returns (int256, uint128) {
        uint128 localCurrencyRequired = _fcAggregateToLocal(fcAggregate, rateParam);
        uint128 discountFactor = EscrowStorageSlot._liquidationDiscount();
        require (localNetAvailable < 0, $$(ErrorCode(INSUFFICIENT_LOCAL_CURRENCY_DEBT)));

        localCurrencyRequired = _calculateLocalCurrencyToTrade(
            localCurrencyRequired,
            discountFactor,
            rateParam.localToETH.buffer,
            uint128(localNetAvailable.neg())
        );

        return _tradefCash(
            payer,
            liquidator,
            localCurrencyRequired,
            collateralNetAvailable,
            discountFactor,
            rateParam,
            Portfolios
        );
    }




















































