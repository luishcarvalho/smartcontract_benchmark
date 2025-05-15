




































pragma solidity 0.4.25;

import "./Proxyable.sol";
import "./SelfDestructible.sol";
import "./SafeDecimalMath.sol";
import "./Synthetix.sol";
import "./interfaces/ISynthetixEscrow.sol";
import "./interfaces/ISynthetixState.sol";
import "./Synth.sol";
import "./FeePoolState.sol";
import "./FeePoolEternalStorage.sol";
import "./DelegateApprovals.sol";

contract FeePool is Proxyable, SelfDestructible, LimitedSetup {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

    Synthetix public synthetix;
    ISynthetixState public synthetixState;
    ISynthetixEscrow public rewardEscrow;
    FeePoolEternalStorage public feePoolEternalStorage;


    uint public transferFeeRate;


    uint constant public MAX_TRANSFER_FEE_RATE = SafeDecimalMath.unit() / 10;


    uint public exchangeFeeRate;


    uint constant public MAX_EXCHANGE_FEE_RATE = SafeDecimalMath.unit() / 10;


    address public feeAuthority;


    FeePoolState public feePoolState;


    DelegateApprovals public delegates;


    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;


    struct FeePeriod {
        uint feePeriodId;
        uint startingDebtIndex;
        uint startTime;
        uint feesToDistribute;
        uint feesClaimed;
        uint rewardsToDistribute;
        uint rewardsClaimed;
    }





    uint8 constant public FEE_PERIOD_LENGTH = 3;

    FeePeriod[FEE_PERIOD_LENGTH] public recentFeePeriods;





    uint public feePeriodDuration = 1 weeks;

    uint public constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint public constant MAX_FEE_PERIOD_DURATION = 60 days;


    uint public TARGET_THRESHOLD = (10 * SafeDecimalMath.unit()) / 100;















































    function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex)
        external
        onlySynthetix
    {
        feePoolState.appendAccountIssuanceRecord(account, debtRatio, debtEntryIndex, recentFeePeriods[0].startingDebtIndex);

        emitIssuanceDebtRatioEntry(account, debtRatio, debtEntryIndex, recentFeePeriods[0].startingDebtIndex);
    }





    function setExchangeFeeRate(uint _exchangeFeeRate)
        external
        optionalProxy_onlyOwner
    {
        exchangeFeeRate = _exchangeFeeRate;
    }





    function setTransferFeeRate(uint _transferFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE, "Transfer fee rate must be below MAX_TRANSFER_FEE_RATE");

        transferFeeRate = _transferFeeRate;
    }





    function setFeeAuthority(address _feeAuthority)
        external
        optionalProxy_onlyOwner
    {
        feeAuthority = _feeAuthority;
    }




    function setFeePoolState(FeePoolState _feePoolState)
        external
        optionalProxy_onlyOwner
    {
        feePoolState = _feePoolState;
    }




    function setDelegateApprovals(DelegateApprovals _delegates)
        external
        optionalProxy_onlyOwner
    {
        delegates = _delegates;
    }




    function setFeePeriodDuration(uint _feePeriodDuration)
        external
        optionalProxy_onlyOwner
    {
        require(_feePeriodDuration >= MIN_FEE_PERIOD_DURATION, "New fee period cannot be less than minimum fee period duration");
        require(_feePeriodDuration <= MAX_FEE_PERIOD_DURATION, "New fee period cannot be greater than maximum fee period duration");

        feePeriodDuration = _feePeriodDuration;

        emitFeePeriodDurationUpdated(_feePeriodDuration);
    }




    function setSynthetix(Synthetix _synthetix)
        external
        optionalProxy_onlyOwner
    {
        require(address(_synthetix) != address(0), "New Synthetix must be non-zero");

        synthetix = _synthetix;
    }

    function setTargetThreshold(uint _percent)
        external
        optionalProxy_onlyOwner
    {
        require(_percent >= 0, "Threshold should be positive");
        TARGET_THRESHOLD = (_percent * SafeDecimalMath.unit()) / 100;
    }




    function feePaid(bytes32 currencyKey, uint amount)
        external
        onlySynthetix
    {
        uint xdrAmount;

        if (currencyKey != "XDR") {
            xdrAmount = synthetix.effectiveValue(currencyKey, amount, "XDR");
        } else {
            xdrAmount = amount;
        }


        recentFeePeriods[0].feesToDistribute = recentFeePeriods[0].feesToDistribute.add(xdrAmount);
    }




    function rewardsMinted(uint amount)
        external
        onlySynthetix
    {

        recentFeePeriods[0].rewardsToDistribute = recentFeePeriods[0].rewardsToDistribute.add(amount);
    }




    function closeCurrentFeePeriod()
        external
        optionalProxy_onlyFeeAuthority
    {
        require(recentFeePeriods[0].startTime <= (now - feePeriodDuration), "It is too early to close the current fee period");

        FeePeriod memory secondLastFeePeriod = recentFeePeriods[FEE_PERIOD_LENGTH - 2];
        FeePeriod memory lastFeePeriod = recentFeePeriods[FEE_PERIOD_LENGTH - 1];






        recentFeePeriods[FEE_PERIOD_LENGTH - 2].feesToDistribute = lastFeePeriod.feesToDistribute
            .sub(lastFeePeriod.feesClaimed)
            .add(secondLastFeePeriod.feesToDistribute);
        recentFeePeriods[FEE_PERIOD_LENGTH - 2].rewardsToDistribute = lastFeePeriod.rewardsToDistribute
            .sub(lastFeePeriod.rewardsClaimed)
            .add(secondLastFeePeriod.rewardsToDistribute);






        for (uint i = FEE_PERIOD_LENGTH - 2; i < FEE_PERIOD_LENGTH; i--) {
            uint next = i + 1;
            recentFeePeriods[next].feePeriodId = recentFeePeriods[i].feePeriodId;
            recentFeePeriods[next].startingDebtIndex = recentFeePeriods[i].startingDebtIndex;
            recentFeePeriods[next].startTime = recentFeePeriods[i].startTime;
            recentFeePeriods[next].feesToDistribute = recentFeePeriods[i].feesToDistribute;
            recentFeePeriods[next].feesClaimed = recentFeePeriods[i].feesClaimed;
            recentFeePeriods[next].rewardsToDistribute = recentFeePeriods[i].rewardsToDistribute;
            recentFeePeriods[next].rewardsClaimed = recentFeePeriods[i].rewardsClaimed;
        }


        delete recentFeePeriods[0];



        recentFeePeriods[0].feePeriodId = recentFeePeriods[1].feePeriodId.add(1);
        recentFeePeriods[0].startingDebtIndex = synthetixState.debtLedgerLength();
        recentFeePeriods[0].startTime = now;

        emitFeePeriodClosed(recentFeePeriods[1].feePeriodId);
    }





    function claimFees(bytes32 currencyKey)
        external
        optionalProxy
        returns (bool)
    {
        return _claimFees(messageSender, currencyKey);
    }

    function claimOnBehalf(address claimingForAddress, bytes32 currencyKey)
        external
        optionalProxy
        returns (bool)
    {
        require(delegates.approval(claimingForAddress, messageSender), "Not approved to claim on behalf this address");

        return _claimFees(claimingForAddress, currencyKey);
    }

    function _claimFees(address claimingAddress, bytes32 currencyKey)
        internal
        returns (bool)
    {
        uint rewardsPaid;
        uint feesPaid;
        uint availableFees;
        uint availableRewards;



        require(feesClaimable(claimingAddress), "C-Ratio below penalty threshold");


        (availableFees, availableRewards) = feesAvailable(claimingAddress, "XDR");

        require(availableFees > 0 || availableRewards > 0, "No fees or rewards available for period, or fees already claimed");


        _setLastFeeWithdrawal(claimingAddress, recentFeePeriods[1].feePeriodId);

        if (availableFees > 0) {

            feesPaid = _recordFeePayment(availableFees);


            _payFees(claimingAddress, feesPaid, currencyKey);
        }

        if (availableRewards > 0) {

            rewardsPaid = _recordRewardPayment(availableRewards);


            _payRewards(claimingAddress, rewardsPaid);
        }

        emitFeesClaimed(claimingAddress, feesPaid, rewardsPaid);

        return true;
    }

    function importFeePeriod(
        uint feePeriodIndex, uint feePeriodId, uint startingDebtIndex, uint startTime,
        uint feesToDistribute, uint feesClaimed, uint rewardsToDistribute, uint rewardsClaimed)
        public
        optionalProxy_onlyOwner
        onlyDuringSetup
    {
        recentFeePeriods[feePeriodIndex].feePeriodId = feePeriodId;
        recentFeePeriods[feePeriodIndex].startingDebtIndex = startingDebtIndex;
        recentFeePeriods[feePeriodIndex].startTime = startTime;
        recentFeePeriods[feePeriodIndex].feesToDistribute = feesToDistribute;
        recentFeePeriods[feePeriodIndex].feesClaimed = feesClaimed;
        recentFeePeriods[feePeriodIndex].rewardsToDistribute = rewardsToDistribute;
        recentFeePeriods[feePeriodIndex].rewardsClaimed = rewardsClaimed;
    }

    function approveClaimOnBehalf(address account)
        public
        optionalProxy
    {
        require(delegates != address(0), "Delegates Approval destination missing");
        require(account != address(0), "Can't delegate to address(0)");
        delegates.setApproval(messageSender, account);
    }

    function removeClaimOnBehalf(address account)
        public
        optionalProxy
    {
        require(delegates != address(0), "Delegates Approval destination missing");
        delegates.withdrawApproval(messageSender, account);
    }





    function _recordFeePayment(uint xdrAmount)
        internal
        returns (uint)
    {

        uint remainingToAllocate = xdrAmount;

        uint feesPaid;



        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint delta = recentFeePeriods[i].feesToDistribute.sub(recentFeePeriods[i].feesClaimed);

            if (delta > 0) {

                uint amountInPeriod = delta < remainingToAllocate ? delta : remainingToAllocate;

                recentFeePeriods[i].feesClaimed = recentFeePeriods[i].feesClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                feesPaid = feesPaid.add(amountInPeriod);


                if (remainingToAllocate == 0) return feesPaid;



                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }

        return feesPaid;
    }





    function _recordRewardPayment(uint snxAmount)
        internal
        returns (uint)
    {

        uint remainingToAllocate = snxAmount;

        uint rewardPaid;




        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint toDistribute = recentFeePeriods[i].rewardsToDistribute.sub(recentFeePeriods[i].rewardsClaimed);

            if (toDistribute > 0) {

                uint amountInPeriod = toDistribute < remainingToAllocate ? toDistribute : remainingToAllocate;

                recentFeePeriods[i].rewardsClaimed = recentFeePeriods[i].rewardsClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                rewardPaid = rewardPaid.add(amountInPeriod);


                if (remainingToAllocate == 0) return rewardPaid;




                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }
        return rewardPaid;
    }







    function _payFees(address account, uint xdrAmount, bytes32 destinationCurrencyKey)
        internal
        notFeeAddress(account)
    {
        require(account != address(0), "Account can't be 0");
        require(account != address(this), "Can't send fees to fee pool");
        require(account != address(proxy), "Can't send fees to proxy");
        require(account != address(synthetix), "Can't send fees to synthetix");

        Synth xdrSynth = synthetix.synths("XDR");
        Synth destinationSynth = synthetix.synths(destinationCurrencyKey);





        xdrSynth.burn(FEE_ADDRESS, xdrAmount);


        uint destinationAmount = synthetix.effectiveValue("XDR", xdrAmount, destinationCurrencyKey);




        destinationSynth.issue(account, destinationAmount);




        destinationSynth.triggerTokenFallbackIfNeeded(FEE_ADDRESS, account, destinationAmount);
    }






    function _payRewards(address account, uint snxAmount)
        internal
        notFeeAddress(account)
    {
        require(account != address(0), "Account can't be 0");
        require(account != address(this), "Can't send rewards to fee pool");
        require(account != address(proxy), "Can't send rewards to proxy");
        require(account != address(synthetix), "Can't send rewards to synthetix");



        rewardEscrow.appendVestingEntry(account, snxAmount);
    }





    function transferFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return value.multiplyDecimal(transferFeeRate);








    }






    function transferredAmountToReceive(uint value)
        external
        view
        returns (uint)
    {
        return value.add(transferFeeIncurred(value));
    }





    function amountReceivedFromTransfer(uint value)
        external
        view
        returns (uint)
    {
        return value.divideDecimal(transferFeeRate.add(SafeDecimalMath.unit()));
    }





    function exchangeFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return value.multiplyDecimal(exchangeFeeRate);








    }






    function exchangedAmountToReceive(uint value)
        external
        view
        returns (uint)
    {
        return value.add(exchangeFeeIncurred(value));
    }






    function amountReceivedFromExchange(uint value)
        external
        view
        returns (uint)
    {
        return value.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));
    }





    function totalFeesAvailable(bytes32 currencyKey)
        external
        view
        returns (uint)
    {
        uint totalFees = 0;


        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(recentFeePeriods[i].feesToDistribute);
            totalFees = totalFees.sub(recentFeePeriods[i].feesClaimed);
        }

        return synthetix.effectiveValue("XDR", totalFees, currencyKey);
    }




    function totalRewardsAvailable()
        external
        view
        returns (uint)
    {
        uint totalRewards = 0;


        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalRewards = totalRewards.add(recentFeePeriods[i].rewardsToDistribute);
            totalRewards = totalRewards.sub(recentFeePeriods[i].rewardsClaimed);
        }

        return totalRewards;
    }






    function feesAvailable(address account, bytes32 currencyKey)
        public
        view
        returns (uint, uint)
    {

        uint[2][FEE_PERIOD_LENGTH] memory userFees = feesByPeriod(account);

        uint totalFees = 0;
        uint totalRewards = 0;


        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(userFees[i][0]);
            totalRewards = totalRewards.add(userFees[i][1]);
        }



        return (
            synthetix.effectiveValue("XDR", totalFees, currencyKey),
            totalRewards
        );
    }





    function feesClaimable(address account)
        public
        view
        returns (bool)
    {



        uint ratio = synthetix.collateralisationRatio(account);
        uint targetRatio = synthetix.synthetixState().issuanceRatio();


        if (ratio < targetRatio) {
            return true;
        }


        uint ratio_threshold = targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(TARGET_THRESHOLD));


        if (ratio > ratio_threshold) {
            return false;
        }

        return true;
    }





    function feesByPeriod(address account)
        public
        view
        returns (uint[2][FEE_PERIOD_LENGTH] memory results)
    {

        uint userOwnershipPercentage;
        uint debtEntryIndex;
        (userOwnershipPercentage, debtEntryIndex) = feePoolState.getAccountsDebtEntry(account, 0);


        if (debtEntryIndex == 0 && userOwnershipPercentage == 0) return;


        if (synthetix.totalIssuedSynths("XDR") == 0) return;



        uint feesFromPeriod;
        uint rewardsFromPeriod;
        (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(0, userOwnershipPercentage, debtEntryIndex);

        results[0][0] = feesFromPeriod;
        results[0][1] = rewardsFromPeriod;



        for (uint i = FEE_PERIOD_LENGTH - 1; i > 0; i--) {
            uint next = i - 1;
            FeePeriod memory nextPeriod = recentFeePeriods[next];


            if (nextPeriod.startingDebtIndex > 0 &&
            getLastFeeWithdrawal(account) < recentFeePeriods[i].feePeriodId) {




                uint closingDebtIndex = nextPeriod.startingDebtIndex.sub(1);




                (userOwnershipPercentage, debtEntryIndex) = feePoolState.applicableIssuanceData(account, closingDebtIndex);

                (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(i, userOwnershipPercentage, debtEntryIndex);

                results[i][0] = feesFromPeriod;
                results[i][1] = rewardsFromPeriod;
            }
        }
    }







    function _feesAndRewardsFromPeriod(uint period, uint ownershipPercentage, uint debtEntryIndex)
        internal
        returns (uint, uint)
    {

        if (ownershipPercentage == 0) return (0, 0);

        uint debtOwnershipForPeriod = ownershipPercentage;


        if (period > 0) {
            uint closingDebtIndex = recentFeePeriods[period - 1].startingDebtIndex.sub(1);
            debtOwnershipForPeriod = _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
        }



        uint feesFromPeriod = recentFeePeriods[period].feesToDistribute
            .multiplyDecimal(debtOwnershipForPeriod);

        uint rewardsFromPeriod = recentFeePeriods[period].rewardsToDistribute
            .multiplyDecimal(debtOwnershipForPeriod);

        return (
            feesFromPeriod.preciseDecimalToDecimal(),
            rewardsFromPeriod.preciseDecimalToDecimal()
        );
    }

    function _effectiveDebtRatioForPeriod(uint closingDebtIndex, uint ownershipPercentage, uint debtEntryIndex)
        internal
        view
        returns (uint)
    {

        if (closingDebtIndex > synthetixState.debtLedgerLength()) return 0;



        uint feePeriodDebtOwnership = synthetixState.debtLedger(closingDebtIndex)
            .divideDecimalRoundPrecise(synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(ownershipPercentage);

        return feePeriodDebtOwnership;
    }

    function effectiveDebtRatioForPeriod(address account, uint period)
        external
        view
        returns (uint)
    {
        require(period != 0, "Current period has not closed yet");
        require(period < FEE_PERIOD_LENGTH, "Period exceeds the FEE_PERIOD_LENGTH");


        if (recentFeePeriods[period - 1].startingDebtIndex == 0) return;

        uint closingDebtIndex = recentFeePeriods[period - 1].startingDebtIndex.sub(1);

        uint ownershipPercentage;
        uint debtEntryIndex;
        (ownershipPercentage, debtEntryIndex) = feePoolState.applicableIssuanceData(account, closingDebtIndex);


        return _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
    }






    function getLastFeeWithdrawal(address _claimingAddress)
        public
        view
        returns (uint)
    {
        return feePoolEternalStorage.getUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)));
    }




    function getPenaltyThresholdRatio()
        public
        view
        returns (uint)
    {
        uint targetRatio = synthetix.synthetixState().issuanceRatio();

        return targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(TARGET_THRESHOLD));
    }








    function _setLastFeeWithdrawal(address _claimingAddress, uint _feePeriodID)
        internal
    {
        feePoolEternalStorage.setUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)), _feePeriodID);
    }

    modifier optionalProxy_onlyFeeAuthority
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        require(msg.sender == feeAuthority, "Only the fee authority can perform this action");
        _;
    }

    modifier onlySynthetix
    {
        require(msg.sender == address(synthetix), "Only the synthetix contract can perform this action");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != FEE_ADDRESS, "Fee address not allowed");
        _;
    }







































