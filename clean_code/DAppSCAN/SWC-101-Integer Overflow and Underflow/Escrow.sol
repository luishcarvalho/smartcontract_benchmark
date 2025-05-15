
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/Governed.sol";
import "./utils/Liquidation.sol";

import "./lib/SafeInt256.sol";
import "./lib/SafeMath.sol";
import "./lib/SafeUInt128.sol";
import "./lib/SafeERC20.sol";

import "./interface/IERC20.sol";
import "./interface/IERC777.sol";
import "./interface/IERC777Recipient.sol";
import "./interface/IERC1820Registry.sol";
import "./interface/IAggregator.sol";
import "./interface/IEscrowCallable.sol";
import "./interface/IWETH.sol";

import "./storage/EscrowStorage.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";






contract Escrow is EscrowStorage, Governed, IERC777Recipient, IEscrowCallable {
    using SafeUInt128 for uint128;
    using SafeMath for uint256;
    using SafeInt256 for int256;

    uint256 private constant UINT256_MAX = 2**256 - 1;






    function initialize(
        address directory,
        address owner,
        address registry,
        address weth
    ) external initializer {
        Governed.initialize(directory, owner);


        IERC1820Registry(registry).setInterfaceImplementer(address(0), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));


        WETH = weth;
        currencyIdToAddress[0] = WETH;
        addressToCurrencyId[WETH] = 0;
        currencyIdToDecimals[0] = Common.DECIMALS;
        emit NewCurrency(WETH);
    }







    event NewCurrency(address indexed token);






    event UpdateExchangeRate(uint16 indexed base, uint16 indexed quote);







    event Deposit(uint16 indexed currency, address account, uint256 value);







    event Withdraw(uint16 indexed currency, address account, uint256 value);








    event Liquidate(uint16 indexed localCurrency, uint16 collateralCurrency, address account, uint128 amountRecollateralized);








    event LiquidateBatch(
        uint16 indexed localCurrency,
        uint16 collateralCurrency,
        address[] accounts,
        uint128[] amountRecollateralized
    );








    event SettleCash(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address indexed payer,
        uint128 settledAmount
    );








    event SettleCashBatch(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address[] payers,
        uint128[] settledAmounts
    );







    event SetDiscounts(uint128 liquidationDiscount, uint128 settlementDiscount, uint128 repoIncentive);





    event SetReserve(address reserveAccount);










    function setLiquidityHaircut(uint128 haircut) external override {
        require(calledByPortfolios(), $$(ErrorCode(UNAUTHORIZED_CALLER)));
        EscrowStorageSlot._setLiquidityHaircut(haircut);
    }










    function setDiscounts(uint128 liquidation, uint128 settlement, uint128 repoIncentive) external onlyOwner {
        EscrowStorageSlot._setLiquidationDiscount(liquidation);
        EscrowStorageSlot._setSettlementDiscount(settlement);
        EscrowStorageSlot._setLiquidityTokenRepoIncentive(repoIncentive);

        emit SetDiscounts(liquidation, settlement, repoIncentive);
    }






    function setReserveAccount(address account) external onlyOwner {
        G_RESERVE_ACCOUNT = account;

        emit SetReserve(account);
    }







    function listCurrency(address token, TokenOptions memory options) public onlyOwner {
        require(addressToCurrencyId[token] == 0 && token != WETH, $$(ErrorCode(INVALID_CURRENCY)));

        maxCurrencyId++;


        currencyIdToAddress[maxCurrencyId] = token;
        addressToCurrencyId[token] = maxCurrencyId;
        tokenOptions[token] = options;
        uint256 decimals = IERC20(token).decimals();
        currencyIdToDecimals[maxCurrencyId] = 10**(decimals);


        Portfolios().setNumCurrencies(maxCurrencyId);

        emit NewCurrency(token);
    }











    function addExchangeRate(
        uint16 base,
        uint16 quote,
        address rateOracle,
        uint128 buffer,
        uint128 rateDecimals,
        bool mustInvert
    ) external onlyOwner {



        require(buffer > G_SETTLEMENT_DISCOUNT(), $$(ErrorCode(INVALID_HAIRCUT_SIZE)));
        exchangeRateOracles[base][quote] = ExchangeRate.Rate(
            rateOracle,
            rateDecimals,
            mustInvert,
            buffer
        );

        emit UpdateExchangeRate(base, quote);
    }










    function isValidCurrency(uint16 currency) public override view returns (bool) {
        return currency <= maxCurrencyId;
    }







    function getExchangeRate(uint16 base, uint16 quote) external view returns (ExchangeRate.Rate memory) {
        return exchangeRateOracles[base][quote];
    }







    function getBalances(address account) external override view returns (int256[] memory) {

        int256[] memory balances = new int256[](maxCurrencyId + 1);

        for (uint256 i; i < balances.length; i++) {
            balances[i] = cashBalances[uint16(i)][account];
        }

        return balances;
    }









    function convertBalancesToETH(int256[] memory amounts) public override view returns (int256[] memory) {

        require(amounts.length == maxCurrencyId + 1, $$(ErrorCode(INVALID_CURRENCY)));
        int256[] memory results = new int256[](amounts.length);



        if (amounts[0] < 0) {

            uint128 buffer = exchangeRateOracles[0][0].buffer;
            results[0] = amounts[0].mul(buffer).div(Common.DECIMALS);
        } else {
            results[0] = amounts[0];
        }

        for (uint256 i = 1; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;

            ExchangeRate.Rate memory er = exchangeRateOracles[uint16(i)][0];
            uint256 baseDecimals = currencyIdToDecimals[uint16(i)];

            if (amounts[i] < 0) {

                results[i] = ExchangeRate._convertToETH(er, baseDecimals, amounts[i], true);
            } else {


                results[i] = ExchangeRate._convertToETH(er, baseDecimals, amounts[i], false);
            }
        }

        return results;
    }









    receive() external payable {
        assert(msg.sender == WETH);
    }





    function depositEth() external payable {
        _depositEth(msg.sender);
    }

    function _depositEth(address to) internal {
        require(msg.value <= Common.MAX_UINT_128, $$(ErrorCode(OVER_MAX_ETH_BALANCE)));
        IWETH(WETH).deposit{value: msg.value}();

        cashBalances[0][to] = cashBalances[0][to].add(
            uint128(msg.value)
        );
        emit Deposit(0, to, msg.value);
    }








    function withdrawEth(uint128 amount) external {
        _withdrawEth(msg.sender, amount);
    }

    function _withdrawEth(address to, uint128 amount) internal {
        int256 balance = cashBalances[0][to];
        cashBalances[0][to] = balance.subNoNeg(amount);
        require(_freeCollateral(to) >= 0, $$(ErrorCode(INSUFFICIENT_FREE_COLLATERAL)));

        IWETH(WETH).withdraw(uint256(amount));

        (bool success, ) = to.call{value: amount}("");
        require(success, $$(ErrorCode(TRANSFER_FAILED)));
        emit Withdraw(0, to, amount);
    }








    function deposit(address token, uint128 amount) external {
        _deposit(msg.sender, token, amount);
    }

    function _deposit(address from, address token, uint128 amount) internal {
        uint16 currencyId = addressToCurrencyId[token];
        if ((currencyId == 0 && token != WETH)) {
            revert($$(ErrorCode(INVALID_CURRENCY)));
        }

        TokenOptions memory options = tokenOptions[token];
        amount = _tokenDeposit(token, from, amount, options);
        if (!options.isERC777) cashBalances[currencyId][from] = cashBalances[currencyId][from].add(amount);

        emit Deposit(currencyId, from, amount);
    }

    function _tokenDeposit(
        address token,
        address from,
        uint128 amount,
        TokenOptions memory options
    ) internal returns (uint128) {
        if (options.hasTransferFee) {


            uint256 preTransferBalance = IERC20(token).balanceOf(address(this));
            SafeERC20.safeTransferFrom(IERC20(token), from, address(this), amount);
            uint256 postTransferBalance = IERC20(token).balanceOf(address(this));

            amount = SafeCast.toUint128(postTransferBalance.sub(preTransferBalance));
        } else if (options.isERC777) {
            IERC777(token).operatorSend(from, address(this), amount, "0x", "0x");
        }else {
            SafeERC20.safeTransferFrom(IERC20(token), from, address(this), amount);
        }

        return amount;
    }










    function withdraw(address token, uint128 amount) external {
       _withdraw(msg.sender, msg.sender, token, amount, true);
    }

    function _withdraw(
        address from,
        address to,
        address token,
        uint128 amount,
        bool checkFC
    ) internal {
        uint16 currencyId = addressToCurrencyId[token];
        require(token != address(0), $$(ErrorCode(INVALID_CURRENCY)));



        if (checkFC) Portfolios().settleMaturedAssets(from);

        int256 balance = cashBalances[currencyId][from];
        cashBalances[currencyId][from] = balance.subNoNeg(amount);



        if (checkFC) {

























    function depositsOnBehalf(address account, Common.Deposit[] memory deposits) public payable override {
        require(calledByERC1155Trade(), $$(ErrorCode(UNAUTHORIZED_CALLER)));

        if (msg.value != 0) {
            _depositEth(account);
        }

        for (uint256 i; i < deposits.length; i++) {
            address tokenAddress = currencyIdToAddress[deposits[i].currencyId];
            _deposit(account, tokenAddress, deposits[i].amount);
        }
    }






    function withdrawsOnBehalf(address account, Common.Withdraw[] memory withdraws) public override {
        require(calledByERC1155Trade(), $$(ErrorCode(UNAUTHORIZED_CALLER)));

        for (uint256 i; i < withdraws.length; i++) {
            address tokenAddress = currencyIdToAddress[withdraws[i].currencyId];
            uint128 amount;

            if (withdraws[i].amount == 0) {

                continue;
            } else {
                amount = withdraws[i].amount;
            }



            _withdraw(account, withdraws[i].to, tokenAddress, amount, false);
        }
    }







    function tokensReceived(



























    function depositIntoMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external override {

        Common.CashGroup memory cg = Portfolios().getCashGroup(cashGroupId);
        require(msg.sender == cg.cashMarket, $$(ErrorCode(UNAUTHORIZED_CALLER)));

        if (fee > 0) {
            cashBalances[cg.currency][G_RESERVE_ACCOUNT] = cashBalances[cg.currency][G_RESERVE_ACCOUNT]
                .add(fee);
        }

        cashBalances[cg.currency][msg.sender] = cashBalances[cg.currency][msg.sender].add(value);
        int256 balance = cashBalances[cg.currency][account];
        cashBalances[cg.currency][account] = balance.subNoNeg(value.add(fee));
    }










    function withdrawFromMarket(
        address account,
        uint8 cashGroupId,
        uint128 value,
        uint128 fee
    ) external override {

        Common.CashGroup memory cg = Portfolios().getCashGroup(cashGroupId);
        require(msg.sender == cg.cashMarket, $$(ErrorCode(UNAUTHORIZED_CALLER)));

        if (fee > 0) {
            cashBalances[cg.currency][G_RESERVE_ACCOUNT] = cashBalances[cg.currency][G_RESERVE_ACCOUNT]
                .add(fee);
        }

        cashBalances[cg.currency][account] = cashBalances[cg.currency][account].add(value.sub(fee));

        int256 balance = cashBalances[cg.currency][msg.sender];
        cashBalances[cg.currency][msg.sender] = balance.subNoNeg(value);
    }









    function unlockCurrentCash(
        uint16 currency,
        address cashMarket,
        int256 amount
    ) external override {
        require(calledByPortfolios(), $$(ErrorCode(UNAUTHORIZED_CALLER)));



        int256 balance = cashBalances[currency][cashMarket];
        cashBalances[currency][cashMarket] = balance.subNoNeg(amount);
    }









    function portfolioSettleCash(address account, int256[] calldata settledCash) external override {
        require(calledByPortfolios(), $$(ErrorCode(UNAUTHORIZED_CALLER)));


        require(settledCash.length == maxCurrencyId + 1, $$(ErrorCode(INVALID_CURRENCY)));

        for (uint256 i = 0; i < settledCash.length; i++) {
            if (settledCash[i] != 0) {


                cashBalances[uint16(i)][account] = cashBalances[uint16(i)][account].add(settledCash[i]);
            }
        }
    }























    function settleCashBalanceBatch(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address[] calldata payers,
        uint128[] calldata values
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        uint128[] memory settledAmounts = new uint128[](values.length);
        uint128 totalCollateral;
        uint128 totalLocal;

        for (uint256 i; i < payers.length; i++) {
            uint128 local;
            uint128 collateral;
            (settledAmounts[i], local, collateral) = _settleCashBalance(
                payers[i],
                values[i],
                rateParam
            );

            totalCollateral = totalCollateral.add(collateral);
            totalLocal = totalLocal.add(local);
        }

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit SettleCashBatch(localCurrency, collateralCurrency, payers, settledAmounts);
    }

















    function settleCashBalance(
        uint16 localCurrency,
        uint16 collateralCurrency,
        address payer,
        uint128 value
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        (uint128 settledAmount, uint128 totalLocal, uint128 totalCollateral) = _settleCashBalance(payer, value, rateParam);

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit SettleCash(localCurrency, collateralCurrency, payer, settledAmount);
    }







    function _settleCashBalance(
        address payer,
        uint128 valueToSettle,
        Liquidation.RateParameters memory rateParam
    ) internal returns (uint128, uint128, uint128) {
        require(payer != msg.sender, $$(ErrorCode(CANNOT_SETTLE_SELF)));
        if (valueToSettle == 0) return (0, 0, 0);
        Common.FreeCollateralFactors memory fc = _freeCollateralFactors(
            payer,
            rateParam.localCurrency,
            rateParam.collateralCurrency
        );

        int256 payerLocalBalance = cashBalances[rateParam.localCurrency][payer];
        int256 payerCollateralBalance = cashBalances[rateParam.collateralCurrency][payer];


        require(payerLocalBalance <= int256(valueToSettle).neg(), $$(ErrorCode(INCORRECT_CASH_BALANCE)));

        Liquidation.TransferAmounts memory transfer = Liquidation.settle(
            payer,
            payerCollateralBalance,
            valueToSettle,
            fc,
            rateParam,
            address(Portfolios())
        );

        if (payerCollateralBalance != transfer.payerCollateralBalance) {
            cashBalances[rateParam.collateralCurrency][payer] = transfer.payerCollateralBalance;
        }

        if (transfer.netLocalCurrencyPayer > 0) {
            cashBalances[rateParam.localCurrency][payer] = payerLocalBalance.add(transfer.netLocalCurrencyPayer);
        }


        require(transfer.netLocalCurrencyLiquidator >= 0);

        return (

            transfer.netLocalCurrencyPayer,

            uint128(transfer.netLocalCurrencyLiquidator),

            transfer.collateralTransfer
        );
    }











    function liquidateBatch(
        address[] calldata accounts,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        uint128[] memory amountRecollateralized = new uint128[](accounts.length);
        int256 totalLocal;
        uint128 totalCollateral;

        for (uint256 i; i < accounts.length; i++) {
            int256 local;
            uint128 collateral;
            (amountRecollateralized[i], local, collateral) = _liquidate(accounts[i], rateParam);
            totalLocal = totalLocal.add(local);
            totalCollateral = totalCollateral.add(collateral);
        }

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit LiquidateBatch(localCurrency, collateralCurrency, accounts, amountRecollateralized);
    }













    function liquidate(
        address account,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) external {
        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);
        (uint128 amountRecollateralized, int256 totalLocal, uint128 totalCollateral) = _liquidate(account, rateParam);

        _finishLiquidateSettle(localCurrency, totalLocal);
        _finishLiquidateSettle(collateralCurrency, int256(totalCollateral).neg());
        emit Liquidate(localCurrency, collateralCurrency, account, amountRecollateralized);
    }






















































    function settlefCash(
        address payer,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 valueToSettle
    ) external {
        Common.FreeCollateralFactors memory fc = _freeCollateralFactors(payer, localCurrency, collateralCurrency);
        require(fc.aggregate >= 0, $$(ErrorCode(INSUFFICIENT_FREE_COLLATERAL)));
        if (valueToSettle == 0) return;

        int256 payerLocalBalance = cashBalances[localCurrency][payer];


        require(payerLocalBalance <= int256(valueToSettle).neg(), $$(ErrorCode(INCORRECT_CASH_BALANCE)));
        require(!_hasCollateral(payer), $$(ErrorCode(ACCOUNT_HAS_COLLATERAL)));

        int256 netCollateralCurrencyLiquidator;
        uint128 netLocalCurrencyPayer;
        if (localCurrency == collateralCurrency) {
            require(isValidCurrency(localCurrency), $$(ErrorCode(INVALID_CURRENCY)));


            (uint128 shortfall, uint128 liquidatorPayment) = Portfolios().raiseCurrentCashViaCashReceiver(
                payer,
                msg.sender,
                localCurrency,
                valueToSettle
            );

            netLocalCurrencyPayer = valueToSettle.sub(shortfall);


            cashBalances[localCurrency][payer] = cashBalances[localCurrency][payer].add(netLocalCurrencyPayer);

            _finishLiquidateSettle(localCurrency, liquidatorPayment);
        } else {
            Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);
            (netCollateralCurrencyLiquidator, netLocalCurrencyPayer) = Liquidation.settlefCash(
                payer,
                msg.sender,
                valueToSettle,
                fc.collateralNetAvailable,
                rateParam,
                address(Portfolios())
            );



            cashBalances[localCurrency][payer] = cashBalances[localCurrency][payer].add(netLocalCurrencyPayer);

            _finishLiquidateSettle(localCurrency, netLocalCurrencyPayer);
            _finishLiquidateSettle(collateralCurrency, netCollateralCurrencyLiquidator);
        }

        emit SettleCash(localCurrency, collateralCurrency, payer, netLocalCurrencyPayer);
    }









    function liquidatefCash(
        address payer,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) external {

        Common.FreeCollateralFactors memory fc = _freeCollateralFactors(payer, localCurrency, collateralCurrency);
        require(!_hasCollateral(payer), $$(ErrorCode(ACCOUNT_HAS_COLLATERAL)));
        require(fc.aggregate < 0, $$(ErrorCode(CANNOT_LIQUIDATE_SUFFICIENT_COLLATERAL)));

        Liquidation.RateParameters memory rateParam = _validateCurrencies(localCurrency, collateralCurrency);

        (int256 netCollateralCurrencyLiquidator, uint128 netLocalCurrencyPayer) = Liquidation.liquidatefCash(
            payer,
            msg.sender,
            fc.aggregate,
            fc.localNetAvailable,
            fc.collateralNetAvailable,
            rateParam,
            address(Portfolios())
        );

        int256 payerLocalBalance = cashBalances[localCurrency][payer];
        cashBalances[localCurrency][payer] = payerLocalBalance.add(netLocalCurrencyPayer);

        _finishLiquidateSettle(localCurrency, netLocalCurrencyPayer);
        _finishLiquidateSettle(collateralCurrency, netCollateralCurrencyLiquidator);

        emit Liquidate(localCurrency, collateralCurrency, payer, netLocalCurrencyPayer);
    }







    function settleReserve(
        address account,
        uint16 localCurrency
    ) external {
        require(!_hasCollateral(account), $$(ErrorCode(ACCOUNT_HAS_COLLATERAL)));
        require(_hasNoAssets(account), $$(ErrorCode(ACCOUNT_HAS_COLLATERAL)));
        int256 accountLocalBalance = cashBalances[localCurrency][account];
        int256 reserveLocalBalance = cashBalances[localCurrency][G_RESERVE_ACCOUNT];

        require(accountLocalBalance < 0, $$(ErrorCode(INCORRECT_CASH_BALANCE)));

        if (accountLocalBalance.neg() < reserveLocalBalance) {
            cashBalances[localCurrency][account] = 0;
            cashBalances[localCurrency][G_RESERVE_ACCOUNT] = reserveLocalBalance.subNoNeg(accountLocalBalance.neg());
        } else {
            cashBalances[localCurrency][account] = accountLocalBalance.add(reserveLocalBalance);
            cashBalances[localCurrency][G_RESERVE_ACCOUNT] = 0;
        }
    }



























































    function _freeCollateral(address account) internal returns (int256) {
        return Portfolios().freeCollateralAggregateOnly(account);
    }

    function _freeCollateralFactors(
        address account,
        uint16 localCurrency,
        uint16 collateralCurrency
    ) internal returns (Common.FreeCollateralFactors memory) {
        return Portfolios().freeCollateralFactors(account, localCurrency, collateralCurrency);
    }


    function _hasCollateral(address account) internal view returns (bool) {
        for (uint256 i; i <= maxCurrencyId; i++) {
            if (cashBalances[uint16(i)][account] > 0) {
                return true;
            }
        }

        return false;
    }

    function _hasNoAssets(address account) internal view returns (bool) {
        Common.Asset[] memory portfolio = Portfolios().getAssets(account);
        for (uint256 i; i < portfolio.length; i++) {

            if (Common.isReceiver(portfolio[i].assetType)) {
                return false;
            }
        }

        return true;
    }
}
