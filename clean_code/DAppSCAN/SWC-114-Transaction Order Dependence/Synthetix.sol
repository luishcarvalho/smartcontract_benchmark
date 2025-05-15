





















































































































pragma solidity 0.4.25;


import "./ExternStateToken.sol";
import "./TokenState.sol";
import "./SupplySchedule.sol";
import "./ExchangeRates.sol";
import "./SynthetixState.sol";
import "./Synth.sol";
import "./interfaces/ISynthetixEscrow.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IExchangeGasPriceLimit.sol";





contract Synthetix is ExternStateToken {




    Synth[] public availableSynths;
    mapping(bytes32 => Synth) public synths;

    IFeePool public feePool;
    ISynthetixEscrow public escrow;
    ISynthetixEscrow public rewardEscrow;
    ExchangeRates public exchangeRates;
    SynthetixState public synthetixState;
    SupplySchedule public supplySchedule;
    IExchangeGasPriceLimit public gasPriceLimit;

    bool private protectionCircuit = false;

    string constant TOKEN_NAME = "Synthetix Network Token";
    string constant TOKEN_SYMBOL = "SNX";
    uint8 constant DECIMALS = 18;
    bool public exchangeEnabled = true;









    constructor(address _proxy, TokenState _tokenState, SynthetixState _synthetixState,
        address _owner, ExchangeRates _exchangeRates, IFeePool _feePool, SupplySchedule _supplySchedule,
        ISynthetixEscrow _rewardEscrow, ISynthetixEscrow _escrow, uint _totalSupply, IExchangeGasPriceLimit _gasPriceLimit
    )
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, _totalSupply, DECIMALS, _owner)
        public
    {
        synthetixState = _synthetixState;
        exchangeRates = _exchangeRates;
        feePool = _feePool;
        supplySchedule = _supplySchedule;
        rewardEscrow = _rewardEscrow;
        escrow = _escrow;
        gasPriceLimit = _gasPriceLimit;
    }


    function setFeePool(IFeePool _feePool)
        external
        optionalProxy_onlyOwner
    {
        feePool = _feePool;
    }

    function setGasPriceLimit(IExchangeGasPriceLimit _gasPriceLimit)
        external
        optionalProxy_onlyOwner
    {
        gasPriceLimit = _gasPriceLimit;
    }

    function setExchangeRates(ExchangeRates _exchangeRates)
        external
        optionalProxy_onlyOwner
    {
        exchangeRates = _exchangeRates;
    }

    function setProtectionCircuit(bool _protectionCircuitIsActivated)
        external
        onlyOracle
    {
        protectionCircuit = _protectionCircuitIsActivated;
    }

    function setExchangeEnabled(bool _exchangeEnabled)
        external
        optionalProxy_onlyOwner
    {
        exchangeEnabled = _exchangeEnabled;
    }





    function addSynth(Synth synth)
        external
        optionalProxy_onlyOwner
    {
        bytes32 currencyKey = synth.currencyKey();

        require(synths[currencyKey] == Synth(0), "Synth already exists");

        availableSynths.push(synth);
        synths[currencyKey] = synth;
    }





    function removeSynth(bytes32 currencyKey)
        external
        optionalProxy_onlyOwner
    {
        require(synths[currencyKey] != address(0), "Synth does not exist");
        require(synths[currencyKey].totalSupply() == 0, "Synth supply exists");
        require(currencyKey != "XDR", "Cannot remove XDR synth");


        address synthToRemove = synths[currencyKey];


        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (availableSynths[i] == synthToRemove) {
                delete availableSynths[i];




                availableSynths[i] = availableSynths[availableSynths.length - 1];


                availableSynths.length--;

                break;
            }
        }


        delete synths[currencyKey];




    }









    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
        public
        view
        returns (uint)
    {
        return exchangeRates.effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }





    function totalIssuedSynths(bytes32 currencyKey)
        public
        view
        rateNotStale(currencyKey)
        returns (uint)
    {
        uint total = 0;
        uint currencyRate = exchangeRates.rateForCurrency(currencyKey);

        require(!exchangeRates.anyRateIsStale(availableCurrencyKeys()), "Rates are stale");

        for (uint8 i = 0; i < availableSynths.length; i++) {




            uint synthValue = availableSynths[i].totalSupply()
                .multiplyDecimalRound(exchangeRates.rateForCurrency(availableSynths[i].currencyKey()))
                .divideDecimalRound(currencyRate);
            total = total.add(synthValue);
        }

        return total;
    }




    function availableCurrencyKeys()
        public
        view
        returns (bytes32[])
    {
        bytes32[] memory availableCurrencyKeys = new bytes32[](availableSynths.length);

        for (uint8 i = 0; i < availableSynths.length; i++) {
            availableCurrencyKeys[i] = availableSynths[i].currencyKey();
        }

        return availableCurrencyKeys;
    }




    function availableSynthCount()
        public
        view
        returns (uint)
    {
        return availableSynths.length;
    }






    function transfer(address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transfer(to, value, empty);
    }







    function transfer(address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {

        require(value <= transferableSynthetix(messageSender), "Insufficient balance");


        _transfer_byProxy(messageSender, to, value, data);

        return true;
    }




    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transferFrom(from, to, value, empty);
    }







    function transferFrom(address from, address to, uint value, bytes data)
        public
        optionalProxy
        returns (bool)
    {

        require(value <= transferableSynthetix(from), "Insufficient balance");



        _transferFrom_byProxy(messageSender, from, to, value, data);

        return true;
    }









    function exchange(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey, address destinationAddress)
        external
        optionalProxy

        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Must use different synths");
        require(sourceAmount > 0, "Zero amount");


        gasPriceLimit.validateGasPrice(tx.gasprice);


        if (protectionCircuit) {
            return _internalLiquidation(
                messageSender,
                sourceCurrencyKey,
                sourceAmount
            );
        } else {

            return _internalExchange(
                messageSender,
                sourceCurrencyKey,
                sourceAmount,
                destinationCurrencyKey,
                messageSender,
                true
            );
        }
    }











    function synthInitiatedExchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    )
        external
        returns (bool)
    {
        _onlySynth();
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");
        require(sourceAmount > 0, "Zero amount");


        return _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress,
            false
        );
    }









    function synthInitiatedFeePayment(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount
    )
        external
        returns (bool)
    {
        _onlySynth();


        if (sourceAmount == 0) {
            return true;
        }

        require(sourceAmount > 0, "Source can't be 0");


        bool result = _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            "XDR",
            feePool.FEE_ADDRESS(),
            false
        );


        feePool.feePaid(sourceCurrencyKey, sourceAmount);

        return result;
    }












    function _internalExchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool chargeFee
    )
        internal
        notFeeAddress(from)
        returns (bool)
    {
        require(exchangeEnabled, "Exchanging is disabled");
        require(!exchangeRates.priceUpdateLock(), "Price update lock");
        require(destinationAddress != address(0), "Zero destination");
        require(destinationAddress != address(this), "Synthetix is invalid destination");
        require(destinationAddress != address(proxy), "Proxy is invalid destination");





        synths[sourceCurrencyKey].burn(from, sourceAmount);


        uint destinationAmount = effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);


        uint amountReceived = destinationAmount;
        uint fee = 0;

        if (chargeFee) {
            amountReceived = feePool.amountReceivedFromExchange(destinationAmount);
            fee = destinationAmount.sub(amountReceived);
        }


        synths[destinationCurrencyKey].issue(destinationAddress, amountReceived);


        if (fee > 0) {
            uint xdrFeeAmount = effectiveValue(destinationCurrencyKey, fee, "XDR");
            synths["XDR"].issue(feePool.FEE_ADDRESS(), xdrFeeAmount);

            feePool.feePaid("XDR", xdrFeeAmount);
        }




        synths[destinationCurrencyKey].triggerTokenFallbackIfNeeded(from, destinationAddress, amountReceived);


        emitSynthExchange(from, sourceCurrencyKey, sourceAmount, destinationCurrencyKey, amountReceived, destinationAddress);

        return true;
    }








    function _internalLiquidation(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount
    )
        internal
        returns (bool)
    {

        synths[sourceCurrencyKey].burn(from, sourceAmount);
        return true;
    }







    function _addToDebtRegister(bytes32 currencyKey, uint amount)
        internal
        optionalProxy
    {

        uint xdrValue = effectiveValue(currencyKey, amount, "XDR");


        uint totalDebtIssued = totalIssuedSynths("XDR");


        uint newTotalDebtIssued = xdrValue.add(totalDebtIssued);


        uint debtPercentage = xdrValue.divideDecimalRoundPrecise(newTotalDebtIssued);





        uint delta = SafeDecimalMath.preciseUnit().sub(debtPercentage);


        uint existingDebt = debtBalanceOf(messageSender, "XDR");


        if (existingDebt > 0) {
            debtPercentage = xdrValue.add(existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        }


        if (!synthetixState.hasIssued(messageSender)) {
            synthetixState.incrementTotalIssuerCount();
        }


        synthetixState.setCurrentIssuanceData(messageSender, debtPercentage);



        if (synthetixState.debtLedgerLength() > 0) {
            synthetixState.appendDebtLedgerValue(
                synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
            );
        } else {
            synthetixState.appendDebtLedgerValue(SafeDecimalMath.preciseUnit());
        }
    }







    function issueSynths(bytes32 currencyKey, uint amount)
        public
        optionalProxy

    {
        require(amount <= remainingIssuableSynths(messageSender, currencyKey), "Amount too large");


        _addToDebtRegister(currencyKey, amount);


        synths[currencyKey].issue(messageSender, amount);


        _appendAccountIssuanceRecord();
    }






    function issueMaxSynths(bytes32 currencyKey)
        external
        optionalProxy
    {

        uint maxIssuable = remainingIssuableSynths(messageSender, currencyKey);


        issueSynths(currencyKey, maxIssuable);
    }







    function burnSynths(bytes32 currencyKey, uint amount)
        external
        optionalProxy

    {

        uint debtToRemove = effectiveValue(currencyKey, amount, "XDR");
        uint debt = debtBalanceOf(messageSender, "XDR");
        uint debtInCurrencyKey = debtBalanceOf(messageSender, currencyKey);

        require(debt > 0, "No debt to forgive");



        uint amountToRemove = debt < debtToRemove ? debt : debtToRemove;


        _removeFromDebtRegister(amountToRemove);

        uint amountToBurn = debtInCurrencyKey < amount ? debtInCurrencyKey : amount;


        synths[currencyKey].burn(messageSender, amountToBurn);


        _appendAccountIssuanceRecord();
    }






    function _appendAccountIssuanceRecord()
        internal
    {
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState.issuanceData(messageSender);

        feePool.appendAccountIssuanceRecord(
            messageSender,
            initialDebtOwnership,
            debtEntryIndex
        );
    }





    function _removeFromDebtRegister(uint amount)
        internal
    {
        uint debtToRemove = amount;


        uint existingDebt = debtBalanceOf(messageSender, "XDR");


        uint totalDebtIssued = totalIssuedSynths("XDR");


        uint newTotalDebtIssued = totalDebtIssued.sub(debtToRemove);

        uint delta;



        if (newTotalDebtIssued > 0) {


            uint debtPercentage = debtToRemove.divideDecimalRoundPrecise(newTotalDebtIssued);




            delta = SafeDecimalMath.preciseUnit().add(debtPercentage);
        } else {
            delta = 0;
        }


        if (debtToRemove == existingDebt) {
            synthetixState.setCurrentIssuanceData(messageSender, 0);
            synthetixState.decrementTotalIssuerCount();
        } else {

            uint newDebt = existingDebt.sub(debtToRemove);
            uint newDebtPercentage = newDebt.divideDecimalRoundPrecise(newTotalDebtIssued);


            synthetixState.setCurrentIssuanceData(messageSender, newDebtPercentage);
        }


        synthetixState.appendDebtLedgerValue(
            synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
        );
    }







    function maxIssuableSynths(address issuer, bytes32 currencyKey)
        public
        view

        returns (uint)
    {

        uint destinationValue = effectiveValue("SNX", collateral(issuer), currencyKey);


        return destinationValue.multiplyDecimal(synthetixState.issuanceRatio());
    }









    function collateralisationRatio(address issuer)
        public
        view
        returns (uint)
    {
        uint totalOwnedSynthetix = collateral(issuer);
        if (totalOwnedSynthetix == 0) return 0;

        uint debtBalance = debtBalanceOf(issuer, "SNX");
        return debtBalance.divideDecimalRound(totalOwnedSynthetix);
    }







    function debtBalanceOf(address issuer, bytes32 currencyKey)
        public
        view

        returns (uint)
    {

        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState.issuanceData(issuer);


        if (initialDebtOwnership == 0) return 0;



        uint currentDebtOwnership = synthetixState.lastDebtLedgerEntry()
            .divideDecimalRoundPrecise(synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(initialDebtOwnership);


        uint totalSystemValue = totalIssuedSynths(currencyKey);


        uint highPrecisionBalance = totalSystemValue.decimalToPreciseDecimal()
            .multiplyDecimalRoundPrecise(currentDebtOwnership);

        return highPrecisionBalance.preciseDecimalToDecimal();
    }






    function remainingIssuableSynths(address issuer, bytes32 currencyKey)
        public
        view

        returns (uint)
    {
        uint alreadyIssued = debtBalanceOf(issuer, currencyKey);
        uint max = maxIssuableSynths(issuer, currencyKey);

        if (alreadyIssued >= max) {
            return 0;
        } else {
            return max.sub(alreadyIssued);
        }
    }







    function collateral(address account)
        public
        view
        returns (uint)
    {
        uint balance = tokenState.balanceOf(account);

        if (escrow != address(0)) {
            balance = balance.add(escrow.balanceOf(account));
        }

        if (rewardEscrow != address(0)) {
            balance = balance.add(rewardEscrow.balanceOf(account));
        }

        return balance;
    }







    function transferableSynthetix(address account)
        public
        view
        rateNotStale("SNX")
        returns (uint)
    {



        uint balance = tokenState.balanceOf(account);





        uint lockedSynthetixValue = debtBalanceOf(account, "SNX").divideDecimalRound(synthetixState.issuanceRatio());


        if (lockedSynthetixValue >= balance) {
            return 0;
        } else {
            return balance.sub(lockedSynthetixValue);
        }
    }

    function mint()
        external
        returns (bool)
    {
        require(rewardEscrow != address(0), "Reward Escrow not set");

        uint supplyToMint = supplySchedule.mintableSupply();
        require(supplyToMint > 0, "No supply is mintable");

        supplySchedule.updateMintValues();



        uint minterReward = supplySchedule.minterReward();

        tokenState.setBalanceOf(rewardEscrow, tokenState.balanceOf(rewardEscrow).add(supplyToMint.sub(minterReward)));
        emitTransfer(this, rewardEscrow, supplyToMint.sub(minterReward));


        feePool.rewardsMinted(supplyToMint.sub(minterReward));


        tokenState.setBalanceOf(msg.sender, tokenState.balanceOf(msg.sender).add(minterReward));
        emitTransfer(this, msg.sender, minterReward);

        totalSupply = totalSupply.add(supplyToMint);
    }



    modifier rateNotStale(bytes32 currencyKey) {
        require(!exchangeRates.rateIsStale(currencyKey), "Rate stale or not a synth");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Fee address not allowed");
        _;
    }






    function _onlySynth() internal view {
        bool isSynth = false;


        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (availableSynths[i] == msg.sender) {
                isSynth = true;
                break;
            }
        }

        require(isSynth, "Only synth allowed");
    }

    modifier onlyOracle
    {
        require(msg.sender == exchangeRates.oracle(), "Only oracle allowed");
        _;
    }










