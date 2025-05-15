

pragma solidity 0.6.11;

import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IPool.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ILUSDToken.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/IPriceFeed.sol";
import "./Interfaces/ILQTYStaking.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/console.sol";

contract TroveManager is LiquityBase, Ownable, ITroveManager {



    address public borrowerOperationsAddress;

    IPool public activePool;

    IPool public defaultPool;

    IStabilityPool public stabilityPool;

    ICollSurplusPool collSurplusPool;

    ILUSDToken public lusdToken;

    IPriceFeed public priceFeed;

    ILQTYStaking public lqtyStaking;
    address public lqtyStakingAddress;


    ISortedTroves public sortedTroves;



    uint constant public SECONDS_IN_ONE_MINUTE = 60;
    uint constant public MINUTE_DECAY_FACTOR = 999832508430720967;





    uint constant public BETA = 2;

    uint public baseRate;


    uint public lastFeeOperationTime;

    enum Status { nonExistent, active, closed }


    struct Trove {
        uint debt;
        uint coll;
        uint stake;
        Status status;
        uint128 arrayIndex;
    }

    mapping (address => Trove) public Troves;

    uint public totalStakes;


    uint public totalStakesSnapshot;


    uint public totalCollateralSnapshot;









    uint public L_ETH;
    uint public L_LUSDDebt;


    mapping (address => RewardSnapshot) public rewardSnapshots;


    struct RewardSnapshot { uint ETH; uint LUSDDebt;}


    address[] public TroveOwners;


    uint public lastETHError_Redistribution;
    uint public lastLUSDDebtError_Redistribution;








    struct LocalVariables_OuterLiquidationFunction {
        uint price;
        uint LUSDInStabPool;
        bool recoveryModeAtStart;
        uint liquidatedDebt;
        uint liquidatedColl;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        uint collToLiquidate;
        uint pendingDebtReward;
        uint pendingCollReward;
    }

    struct LocalVariables_LiquidationSequence {
        uint remainingLUSDInStabPool;
        uint i;
        uint ICR;
        address user;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
    }

    struct LiquidationValues {
        uint entireTroveDebt;
        uint entireTroveColl;
        uint collGasCompensation;
        uint LUSDGasCompensation;
        uint debtToOffset;
        uint collToSendToSP;
        uint debtToRedistribute;
        uint collToRedistribute;
        address partialAddr;
        uint partialNewDebt;
        uint partialNewColl;
        address partialUpperHint;
        address partialLowerHint;
    }

    struct LiquidationTotals {
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalCollGasCompensation;
        uint totalLUSDGasCompensation;
        uint totalDebtToOffset;
        uint totalCollToSendToSP;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        address partialAddr;
        uint partialNewDebt;
        uint partialNewColl;
        address partialUpperHint;
        address partialLowerHint;
    }



    struct RedemptionTotals {
        uint totalLUSDToRedeem;
        uint totalETHDrawn;
        uint ETHFee;
        uint ETHToSendToRedeemer;
        uint decayedBaseRate;
    }

    struct SingleRedemptionValues {
        uint LUSDLot;
        uint ETHLot;
    }



    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _LUSDGasCompensation);
    event Redemption(uint _attemptedLUSDAmount, uint _actualLUSDAmount, uint _ETHSent, uint _ETHFee);

    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        partiallyLiquidateInRecoveryMode,
        redeemCollateral
    }

    event TroveCreated(address indexed _borrower, uint _arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint _stake, TroveManagerOperation _operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, TroveManagerOperation _operation);



    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _lqtyStakingAddress
    )
        external
        override
        onlyOwner
    {
        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IPool(_activePoolAddress);
        defaultPool = IPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        lusdToken = ILUSDToken(_lusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        lqtyStakingAddress = _lqtyStakingAddress;
        lqtyStaking = ILQTYStaking(_lqtyStakingAddress);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit LUSDTokenAddressChanged(_lusdTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit LQTYStakingAddressChanged(_lqtyStakingAddress);

        _renounceOwnership();
    }



    function getTroveOwnersCount() external view override returns (uint) {
        return TroveOwners.length;
    }

    function getTroveFromTroveOwnersArray(uint _index) external view override returns (address) {
        return TroveOwners[_index];
    }




    function liquidate(address _borrower) external override {
        _requireTroveisActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateTroves(borrowers);
    }




    function _liquidateNormalMode(address _borrower, uint _LUSDInStabPool) internal returns (LiquidationValues memory V) {
        LocalVariables_InnerSingleLiquidateFunction memory L;

        (V.entireTroveDebt,
        V.entireTroveColl,
        L.pendingDebtReward,
        L.pendingCollReward) = getEntireDebtAndColl(_borrower);

        _movePendingTroveRewardsToActivePool(L.pendingDebtReward, L.pendingCollReward);
        _removeStake(_borrower);

        V.collGasCompensation = _getCollGasCompensation(V.entireTroveColl);
        V.LUSDGasCompensation = LUSD_GAS_COMPENSATION;
        uint collToLiquidate = V.entireTroveColl.sub(V.collGasCompensation);

        (V.debtToOffset,
        V.collToSendToSP,
        V.debtToRedistribute,
        V.collToRedistribute) = _getOffsetAndRedistributionVals(V.entireTroveDebt, collToLiquidate, _LUSDInStabPool);

        _closeTrove(_borrower);
        emit TroveLiquidated(_borrower, V.entireTroveDebt, V.entireTroveColl, TroveManagerOperation.liquidateInNormalMode);

        return V;
    }


    function _liquidateRecoveryMode(address _borrower, uint _ICR, uint _LUSDInStabPool, uint _TCR) internal returns (LiquidationValues memory V) {
        LocalVariables_InnerSingleLiquidateFunction memory L;

        if (TroveOwners.length <= 1) { return V; }

        (V.entireTroveDebt,
        V.entireTroveColl,
        L.pendingDebtReward,
        L.pendingCollReward) = getEntireDebtAndColl(_borrower);

        _movePendingTroveRewardsToActivePool(L.pendingDebtReward, L.pendingCollReward);

        V.collGasCompensation = _getCollGasCompensation(V.entireTroveColl);

        V.LUSDGasCompensation = LUSD_GAS_COMPENSATION;
        L.collToLiquidate = V.entireTroveColl.sub(V.collGasCompensation);


        if (_ICR <= _100pct) {
            _removeStake(_borrower);

            V.debtToOffset = 0;
            V.collToSendToSP = 0;
            V.debtToRedistribute = V.entireTroveDebt;
            V.collToRedistribute = L.collToLiquidate;

            _closeTrove(_borrower);
            emit TroveLiquidated(_borrower, V.entireTroveDebt, V.entireTroveColl, TroveManagerOperation.liquidateInRecoveryMode);


        } else if ((_ICR > _100pct) && (_ICR < MCR)) {
            _removeStake(_borrower);

            (V.debtToOffset,
            V.collToSendToSP,
            V.debtToRedistribute,
            V.collToRedistribute) = _getOffsetAndRedistributionVals(V.entireTroveDebt, L.collToLiquidate, _LUSDInStabPool);

            _closeTrove(_borrower);
            emit TroveLiquidated(_borrower, V.entireTroveDebt, V.entireTroveColl, TroveManagerOperation.liquidateInRecoveryMode);





        } else if ((_ICR >= MCR) && (_ICR < _TCR)) {
            assert(_LUSDInStabPool != 0);

            _removeStake(_borrower);

            V = _getFullOrPartialOffsetVals(_borrower, V.entireTroveDebt, V.entireTroveColl, _LUSDInStabPool);

            _closeTrove(_borrower);
        }
        else if (_ICR >= _TCR) {
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        return V;
    }




    function _getOffsetAndRedistributionVals
    (
        uint _debt,
        uint _coll,
        uint _LUSDInStabPool
    )
        internal
        pure
        returns (uint debtToOffset, uint collToSendToSP, uint debtToRedistribute, uint collToRedistribute)
    {
        if (_LUSDInStabPool > 0) {










            debtToOffset = LiquityMath._min(_debt, _LUSDInStabPool);
            collToSendToSP = _coll.mul(debtToOffset).div(_debt);
            debtToRedistribute = _debt.sub(debtToOffset);
            collToRedistribute = _coll.sub(collToSendToSP);
        } else {
            debtToOffset = 0;
            collToSendToSP = 0;
            debtToRedistribute = _debt;
            collToRedistribute = _coll;
        }
    }






    function _getFullOrPartialOffsetVals
    (
        address _borrower,
        uint _entireTroveDebt,
        uint _entireTroveColl,
        uint _LUSDInStabPool
    )
        internal
        returns (LiquidationValues memory V)
    {
        V.entireTroveDebt = _entireTroveDebt;
        V.entireTroveColl = _entireTroveColl;


        if (_entireTroveDebt <= _LUSDInStabPool) {
            V.collGasCompensation = _getCollGasCompensation(_entireTroveColl);
            V.LUSDGasCompensation = LUSD_GAS_COMPENSATION;

            V.debtToOffset = _entireTroveDebt;
            V.collToSendToSP = _entireTroveColl.sub(V.collGasCompensation);
            V.debtToRedistribute = 0;
            V.collToRedistribute = 0;

            emit TroveLiquidated(_borrower, _entireTroveDebt, _entireTroveColl, TroveManagerOperation.liquidateInRecoveryMode);
        }










        else if (_entireTroveDebt > _LUSDInStabPool) {

            V.partialNewDebt = LiquityMath._max(_entireTroveDebt.sub(_LUSDInStabPool), LUSD_GAS_COMPENSATION);

            V.debtToOffset = _entireTroveDebt.sub(V.partialNewDebt);

            uint collFraction = _entireTroveColl.mul(V.debtToOffset).div(_entireTroveDebt);
            V.collGasCompensation = _getCollGasCompensation(collFraction);

            V.LUSDGasCompensation = 0;

            V.collToSendToSP = collFraction.sub(V.collGasCompensation);
            V.collToRedistribute = 0;
            V.debtToRedistribute = 0;

            V.partialAddr = _borrower;
            V.partialNewColl = _entireTroveColl.sub(collFraction);


            V.partialUpperHint = sortedTroves.getPrev(_borrower);
            V.partialLowerHint = sortedTroves.getNext(_borrower);
        }
    }





    function liquidateTroves(uint _n) external override {
        LocalVariables_OuterLiquidationFunction memory L;

        LiquidationTotals memory T;

        L.price = priceFeed.getPrice();
        L.LUSDInStabPool = stabilityPool.getTotalLUSDDeposits();
        L.recoveryModeAtStart = checkRecoveryMode();


        if (L.recoveryModeAtStart == true) {
            T = _getTotalsFromLiquidateTrovesSequence_RecoveryMode(L.price, L.LUSDInStabPool, _n);
        } else if (L.recoveryModeAtStart == false) {
            T = _getTotalsFromLiquidateTrovesSequence_NormalMode(L.price, L.LUSDInStabPool, _n);
        }


        stabilityPool.offset(T.totalDebtToOffset, T.totalCollToSendToSP);
        _redistributeDebtAndColl(T.totalDebtToRedistribute, T.totalCollToRedistribute);


        _updateSystemSnapshots_excludeCollRemainder(T.partialNewColl.add(T.totalCollGasCompensation));
        _updatePartiallyLiquidatedTrove(T.partialAddr, T.partialNewDebt, T.partialNewColl, T.partialUpperHint, T. partialLowerHint, L.price);

        L.liquidatedDebt = T.totalDebtInSequence.sub(T.partialNewDebt);
        L.liquidatedColl = T.totalCollInSequence.sub(T.totalCollGasCompensation).sub(T.partialNewColl);
        emit Liquidation(L.liquidatedDebt, L.liquidatedColl, T.totalCollGasCompensation, T.totalLUSDGasCompensation);


        _sendGasCompensation(msg.sender, T.totalLUSDGasCompensation, T.totalCollGasCompensation);
    }





    function _getTotalsFromLiquidateTrovesSequence_RecoveryMode
    (
        uint _price,
        uint _LUSDInStabPool,
        uint _n
    )
        internal
        returns(LiquidationTotals memory T)
    {
        LocalVariables_LiquidationSequence memory L;
        LiquidationValues memory V;

        L.remainingLUSDInStabPool = _LUSDInStabPool;
        L.backToNormalMode = false;
        L.entireSystemDebt = activePool.getLUSDDebt().add(defaultPool.getLUSDDebt());
        L.entireSystemColl = activePool.getETH().add(defaultPool.getETH());

        L.i = 0;
        while (L.i < _n) {
            L.user = sortedTroves.getLast();
            L.ICR = getCurrentICR(L.user, _price);

            if (L.backToNormalMode == false) {

                if (L.ICR >= MCR && L.remainingLUSDInStabPool == 0) { break; }

                uint TCR = LiquityMath._computeCR(L.entireSystemColl, L.entireSystemDebt, _price);

                V = _liquidateRecoveryMode(L.user, L.ICR, L.remainingLUSDInStabPool, TCR);


                L.remainingLUSDInStabPool = L.remainingLUSDInStabPool.sub(V.debtToOffset);
                L.entireSystemDebt = L.entireSystemDebt.sub(V.debtToOffset);
                L.entireSystemColl = L.entireSystemColl.sub(V.collToSendToSP);


                T = _addLiquidationValuesToTotals(T, V);


                if (V.partialAddr != address(0)) {break;}

                L.backToNormalMode = !_checkPotentialRecoveryMode(L.entireSystemColl, L.entireSystemDebt, _price);
            }
            else if (L.backToNormalMode == true && L.ICR < MCR) {
                V = _liquidateNormalMode(L.user, L.remainingLUSDInStabPool);

                L.remainingLUSDInStabPool = L.remainingLUSDInStabPool.sub(V.debtToOffset);


                T = _addLiquidationValuesToTotals(T, V);

            }  else break;


            if (L.user == sortedTroves.getFirst()) { break; }

            L.i++;
        }
    }

    function _getTotalsFromLiquidateTrovesSequence_NormalMode
    (
        uint _price,
        uint _LUSDInStabPool,
        uint _n
    )
        internal
        returns(LiquidationTotals memory T)
    {
        LocalVariables_LiquidationSequence memory L;
        LiquidationValues memory V;

        L.remainingLUSDInStabPool = _LUSDInStabPool;

        L.i = 0;
        while (L.i < _n) {
            L.user = sortedTroves.getLast();
            L.ICR = getCurrentICR(L.user, _price);

            if (L.ICR < MCR) {
                V = _liquidateNormalMode(L.user, L.remainingLUSDInStabPool);

                L.remainingLUSDInStabPool = L.remainingLUSDInStabPool.sub(V.debtToOffset);


                T = _addLiquidationValuesToTotals(T, V);

            } else break;


            if (L.user == sortedTroves.getFirst()) { break; }
            L.i++;
        }
    }





    function batchLiquidateTroves(address[] memory _troveArray) public override {
        require(_troveArray.length != 0, "TroveManager: Calldata address array must not be empty");

        LocalVariables_OuterLiquidationFunction memory L;
        LiquidationTotals memory T;

        L.price = priceFeed.getPrice();
        L.LUSDInStabPool = stabilityPool.getTotalLUSDDeposits();
        L.recoveryModeAtStart = checkRecoveryMode();


        if (L.recoveryModeAtStart == true) {
           T = _getTotalFromBatchLiquidate_RecoveryMode(L.price, L.LUSDInStabPool, _troveArray);
        } else if (L.recoveryModeAtStart == false) {
            T = _getTotalsFromBatchLiquidate_NormalMode(L.price, L.LUSDInStabPool, _troveArray);
        }


        stabilityPool.offset(T.totalDebtToOffset, T.totalCollToSendToSP);
        _redistributeDebtAndColl(T.totalDebtToRedistribute, T.totalCollToRedistribute);


        _updateSystemSnapshots_excludeCollRemainder(T.partialNewColl.add(T.totalCollGasCompensation));
        _updatePartiallyLiquidatedTrove(T.partialAddr, T.partialNewDebt, T.partialNewColl, T.partialUpperHint, T. partialLowerHint, L.price);

        L.liquidatedDebt = T.totalDebtInSequence.sub(T.partialNewDebt);
        L.liquidatedColl = T.totalCollInSequence.sub(T.totalCollGasCompensation).sub(T.partialNewColl);
        emit Liquidation(L.liquidatedDebt, L.liquidatedColl, T.totalCollGasCompensation, T.totalLUSDGasCompensation);


        _sendGasCompensation(msg.sender, T.totalLUSDGasCompensation, T.totalCollGasCompensation);
    }





    function _getTotalFromBatchLiquidate_RecoveryMode
    (
        uint _price,
        uint _LUSDInStabPool,
        address[] memory _troveArray)
        internal
        returns(LiquidationTotals memory T)
    {
        LocalVariables_LiquidationSequence memory L;
        LiquidationValues memory V;

        L.remainingLUSDInStabPool = _LUSDInStabPool;
        L.backToNormalMode = false;
        L.entireSystemDebt = activePool.getLUSDDebt().add(defaultPool.getLUSDDebt());
        L.entireSystemColl = activePool.getETH().add(defaultPool.getETH());

        L.i = 0;
        for (L.i = 0; L.i < _troveArray.length; L.i++) {
            L.user = _troveArray[L.i];
            L.ICR = getCurrentICR(L.user, _price);

            if (L.backToNormalMode == false) {


                if (L.ICR >= MCR && L.remainingLUSDInStabPool == 0) { continue; }

                uint TCR = LiquityMath._computeCR(L.entireSystemColl, L.entireSystemDebt, _price);

                V = _liquidateRecoveryMode(L.user, L.ICR, L.remainingLUSDInStabPool, TCR);


                L.remainingLUSDInStabPool = L.remainingLUSDInStabPool.sub(V.debtToOffset);
                L.entireSystemDebt = L.entireSystemDebt.sub(V.debtToOffset);
                L.entireSystemColl = L.entireSystemColl.sub(V.collToSendToSP);


                T = _addLiquidationValuesToTotals(T, V);


                if (V.partialAddr != address(0)) { break; }

                L.backToNormalMode = !_checkPotentialRecoveryMode(L.entireSystemColl, L.entireSystemDebt, _price);
            }

            else if (L.backToNormalMode == true && L.ICR < MCR) {
                V = _liquidateNormalMode(L.user, L.remainingLUSDInStabPool);
                L.remainingLUSDInStabPool = L.remainingLUSDInStabPool.sub(V.debtToOffset);


                T = _addLiquidationValuesToTotals(T, V);
            }
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode
    (
        uint _price,
        uint _LUSDInStabPool,
        address[] memory _troveArray
    )
        internal
        returns(LiquidationTotals memory T)
    {
        LocalVariables_LiquidationSequence memory L;
        LiquidationValues memory V;

        L.remainingLUSDInStabPool = _LUSDInStabPool;

        for (L.i = 0; L.i < _troveArray.length; L.i++) {
            L.user = _troveArray[L.i];
            L.ICR = getCurrentICR(L.user, _price);

            if (L.ICR < MCR) {
                V = _liquidateNormalMode(L.user, L.remainingLUSDInStabPool);
                L.remainingLUSDInStabPool = L.remainingLUSDInStabPool.sub(V.debtToOffset);


                T = _addLiquidationValuesToTotals(T, V);
            }
        }
    }



    function _addLiquidationValuesToTotals(LiquidationTotals memory T1, LiquidationValues memory V)
    internal pure returns(LiquidationTotals memory T2) {


        T2.totalCollGasCompensation = T1.totalCollGasCompensation.add(V.collGasCompensation);
        T2.totalLUSDGasCompensation = T1.totalLUSDGasCompensation.add(V.LUSDGasCompensation);
        T2.totalDebtInSequence = T1.totalDebtInSequence.add(V.entireTroveDebt);
        T2.totalCollInSequence = T1.totalCollInSequence.add(V.entireTroveColl);
        T2.totalDebtToOffset = T1.totalDebtToOffset.add(V.debtToOffset);
        T2.totalCollToSendToSP = T1.totalCollToSendToSP.add(V.collToSendToSP);
        T2.totalDebtToRedistribute = T1.totalDebtToRedistribute.add(V.debtToRedistribute);
        T2.totalCollToRedistribute = T1.totalCollToRedistribute.add(V.collToRedistribute);


        T2.partialAddr = V.partialAddr;
        T2.partialNewDebt = V.partialNewDebt;
        T2.partialNewColl = V.partialNewColl;
        T2.partialUpperHint = V.partialUpperHint;
        T2.partialLowerHint = V.partialLowerHint;

        return T2;
    }


    function _updatePartiallyLiquidatedTrove
    (
        address _borrower,
        uint _newDebt,
        uint _newColl,
        address _upperHint,
        address _lowerHint,
        uint _price
    )
        internal
    {
        if ( _borrower == address(0)) { return; }

        Troves[_borrower].debt = _newDebt;
        Troves[_borrower].coll = _newColl;
        Troves[_borrower].status = Status.active;

        _updateTroveRewardSnapshots(_borrower);
        _updateStakeAndTotalStakes(_borrower);

        uint ICR = getCurrentICR(_borrower, _price);







        sortedTroves.insert(_borrower, ICR, _price, _upperHint, _lowerHint);
        _addTroveOwnerToArray(_borrower);
        emit TroveUpdated(_borrower, _newDebt, _newColl, Troves[_borrower].stake, TroveManagerOperation.partiallyLiquidateInRecoveryMode);
    }

    function _sendGasCompensation(address _liquidator, uint _LUSD, uint _ETH) internal {
        if (_LUSD > 0) {
            lusdToken.returnFromPool(GAS_POOL_ADDRESS, _liquidator, _LUSD);
        }

        if (_ETH > 0) {
            activePool.sendETH(_liquidator, _ETH);
        }
    }


    function _movePendingTroveRewardsToActivePool(uint _LUSD, uint _ETH) internal {
        defaultPool.decreaseLUSDDebt(_LUSD);
        activePool.increaseLUSDDebt(_LUSD);
        defaultPool.sendETH(address(activePool), _ETH);
    }




    function _redeemCollateralFromTrove(
        address _borrower,
        uint _maxLUSDamount,
        uint _price,
        address _partialRedemptionHint,
        uint _partialRedemptionHintICR
    )
        internal returns (SingleRedemptionValues memory V)
    {

        V.LUSDLot = LiquityMath._min(_maxLUSDamount, Troves[_borrower].debt.sub(LUSD_GAS_COMPENSATION));


        V.ETHLot = V.LUSDLot.mul(1e18).div(_price);


        uint newDebt = (Troves[_borrower].debt).sub(V.LUSDLot);
        uint newColl = (Troves[_borrower].coll).sub(V.ETHLot);

        if (newDebt == LUSD_GAS_COMPENSATION) {

            _removeStake(_borrower);
            _closeTrove(_borrower);
            _redeemCloseTrove(_borrower, LUSD_GAS_COMPENSATION, newColl);

        } else {
            uint newICR = LiquityMath._computeCR(newColl, newDebt, _price);



            if (newICR != _partialRedemptionHintICR) {
                V.LUSDLot = 0;
                V.ETHLot = 0;
                return V;
            }

            sortedTroves.reInsert(_borrower, newICR, _price, _partialRedemptionHint, _partialRedemptionHint);

            Troves[_borrower].debt = newDebt;
            Troves[_borrower].coll = newColl;
            _updateStakeAndTotalStakes(_borrower);
        }
        emit TroveUpdated(
            _borrower,
            newDebt, newColl,
            Troves[_borrower].stake,
            TroveManagerOperation.redeemCollateral
        );
        return V;
    }








    function _redeemCloseTrove(address _borrower, uint _LUSD, uint _ETH) internal {
        lusdToken.burn(GAS_POOL_ADDRESS, _LUSD);

        activePool.decreaseLUSDDebt(_LUSD);


        collSurplusPool.accountSurplus(_borrower, _ETH);
        activePool.sendETH(address(collSurplusPool), _ETH);
    }

    function _isValidFirstRedemptionHint(address _firstRedemptionHint, uint _price) internal view returns (bool) {
        if (_firstRedemptionHint == address(0) ||
            !sortedTroves.contains(_firstRedemptionHint) ||
            getCurrentICR(_firstRedemptionHint, _price) < MCR
        ) {
            return false;
        }

        address nextTrove = sortedTroves.getNext(_firstRedemptionHint);
        return nextTrove == address(0) || getCurrentICR(nextTrove, _price) < MCR;
    }






















    function redeemCollateral(
        uint _LUSDamount,
        address _firstRedemptionHint,
        address _partialRedemptionHint,
        uint _partialRedemptionHintICR,
        uint _maxIterations
    )
        external
        override
    {
        uint activeDebt = activePool.getLUSDDebt();
        uint defaultedDebt = defaultPool.getLUSDDebt();

        RedemptionTotals memory T;

        _requireAmountGreaterThanZero(_LUSDamount);
        _requireLUSDBalanceCoversRedemption(msg.sender, _LUSDamount);


        assert(lusdToken.balanceOf(msg.sender) <= (activeDebt.add(defaultedDebt)));

        uint remainingLUSD = _LUSDamount;
        uint price = priceFeed.getPrice();
        address currentBorrower;

        if (_isValidFirstRedemptionHint(_firstRedemptionHint, price)) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = sortedTroves.getLast();


            while (currentBorrower != address(0) && getCurrentICR(currentBorrower, price) < MCR) {
                currentBorrower = sortedTroves.getPrev(currentBorrower);
            }
        }


        if (_maxIterations == 0) { _maxIterations = uint(-1); }
        while (currentBorrower != address(0) && remainingLUSD > 0 && _maxIterations > 0) {
            _maxIterations--;

            address nextUserToCheck = sortedTroves.getPrev(currentBorrower);

            _applyPendingRewards(currentBorrower);
            SingleRedemptionValues memory V = _redeemCollateralFromTrove(
                currentBorrower,
                remainingLUSD,
                price,
                _partialRedemptionHint,
                _partialRedemptionHintICR
            );

            if (V.LUSDLot == 0) break;

            T.totalLUSDToRedeem  = T.totalLUSDToRedeem.add(V.LUSDLot);
            T.totalETHDrawn = T.totalETHDrawn.add(V.ETHLot);

            remainingLUSD = remainingLUSD.sub(V.LUSDLot);
            currentBorrower = nextUserToCheck;
        }


        _updateBaseRateFromRedemption(T.totalETHDrawn, price);


        T.ETHFee = _getRedemptionFee(T.totalETHDrawn);
        activePool.sendETH(lqtyStakingAddress, T.ETHFee);
        lqtyStaking.increaseF_ETH(T.ETHFee);

        T.ETHToSendToRedeemer = T.totalETHDrawn.sub(T.ETHFee);


        _activePoolRedeemCollateral(msg.sender, T.totalLUSDToRedeem, T.ETHToSendToRedeemer);

        emit Redemption(_LUSDamount, T.totalLUSDToRedeem, T.totalETHDrawn, T.ETHFee);
    }


    function _activePoolRedeemCollateral(address _redeemer, uint _LUSD, uint _ETH) internal {

        lusdToken.burn(_redeemer, _LUSD);
        activePool.decreaseLUSDDebt(_LUSD);

        activePool.sendETH(_redeemer, _ETH);
    }





    function getCurrentICR(address _borrower, uint _price) public view override returns (uint) {
        uint pendingETHReward = getPendingETHReward(_borrower);
        uint pendingLUSDDebtReward = getPendingLUSDDebtReward(_borrower);

        uint currentETH = Troves[_borrower].coll.add(pendingETHReward);
        uint currentLUSDDebt = Troves[_borrower].debt.add(pendingLUSDDebtReward);

        uint ICR = LiquityMath._computeCR(currentETH, currentLUSDDebt, _price);
        return ICR;
    }

    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _applyPendingRewards(_borrower);
    }


    function _applyPendingRewards(address _borrower) internal {
        if (hasPendingRewards(_borrower)) {
            _requireTroveisActive(_borrower);


            uint pendingETHReward = getPendingETHReward(_borrower);
            uint pendingLUSDDebtReward = getPendingLUSDDebtReward(_borrower);


            Troves[_borrower].coll = Troves[_borrower].coll.add(pendingETHReward);
            Troves[_borrower].debt = Troves[_borrower].debt.add(pendingLUSDDebtReward);

            _updateTroveRewardSnapshots(_borrower);


            _movePendingTroveRewardsToActivePool(pendingLUSDDebtReward, pendingETHReward);

            emit TroveUpdated(
                _borrower,
                Troves[_borrower].debt,
                Troves[_borrower].coll,
                Troves[_borrower].stake,
                TroveManagerOperation.applyPendingRewards
            );
        }
    }


    function updateTroveRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
       return _updateTroveRewardSnapshots(_borrower);
    }

    function _updateTroveRewardSnapshots(address _borrower) internal {
        rewardSnapshots[_borrower].ETH = L_ETH;
        rewardSnapshots[_borrower].LUSDDebt = L_LUSDDebt;
    }


    function getPendingETHReward(address _borrower) public view override returns (uint) {
        uint snapshotETH = rewardSnapshots[_borrower].ETH;
        uint rewardPerUnitStaked = L_ETH.sub(snapshotETH);

        if ( rewardPerUnitStaked == 0 ) { return 0; }

        uint stake = Troves[_borrower].stake;

        uint pendingETHReward = stake.mul(rewardPerUnitStaked).div(1e18);

        return pendingETHReward;
    }


    function getPendingLUSDDebtReward(address _borrower) public view override returns (uint) {
        uint snapshotLUSDDebt = rewardSnapshots[_borrower].LUSDDebt;
        uint rewardPerUnitStaked = L_LUSDDebt.sub(snapshotLUSDDebt);

        if ( rewardPerUnitStaked == 0 ) { return 0; }

        uint stake =  Troves[_borrower].stake;

        uint pendingLUSDDebtReward = stake.mul(rewardPerUnitStaked).div(1e18);

        return pendingLUSDDebtReward;
    }

    function hasPendingRewards(address _borrower) public view override returns (bool) {





        return (rewardSnapshots[_borrower].ETH < L_ETH);
    }


    function getEntireDebtAndColl(
        address _borrower
    )
        public
        view
        override
        returns (uint debt, uint coll, uint pendingLUSDDebtReward, uint pendingETHReward)
    {
        debt = Troves[_borrower].debt;
        coll = Troves[_borrower].coll;

        pendingLUSDDebtReward = getPendingLUSDDebtReward(_borrower);
        pendingETHReward = getPendingETHReward(_borrower);

        debt = debt.add(pendingLUSDDebtReward);
        coll = coll.add(pendingETHReward);
    }

    function removeStake(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _removeStake(_borrower);
    }


    function _removeStake(address _borrower) internal {
        uint stake = Troves[_borrower].stake;
        totalStakes = totalStakes.sub(stake);
        Troves[_borrower].stake = 0;
    }

    function updateStakeAndTotalStakes(address _borrower) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        return _updateStakeAndTotalStakes(_borrower);
    }


    function _updateStakeAndTotalStakes(address _borrower) internal returns (uint) {
        uint newStake = _computeNewStake(Troves[_borrower].coll);
        uint oldStake = Troves[_borrower].stake;
        Troves[_borrower].stake = newStake;
        totalStakes = totalStakes.sub(oldStake).add(newStake);

        return newStake;
    }


    function _computeNewStake(uint _coll) internal view returns (uint) {
        uint stake;
        if (totalCollateralSnapshot == 0) {
            stake = _coll;
        } else {






            assert(totalStakesSnapshot > 0);
            stake = _coll.mul(totalStakesSnapshot).div(totalCollateralSnapshot);
        }
        return stake;
    }

    function _redistributeDebtAndColl(uint _debt, uint _coll) internal {
        if (_debt == 0) { return; }

        if (totalStakes > 0) {





            uint ETHNumerator = _coll.mul(1e18).add(lastETHError_Redistribution);
            uint LUSDDebtNumerator = _debt.mul(1e18).add(lastLUSDDebtError_Redistribution);

            uint ETHRewardPerUnitStaked = ETHNumerator.div(totalStakes);
            uint LUSDDebtRewardPerUnitStaked = LUSDDebtNumerator.div(totalStakes);

            lastETHError_Redistribution = ETHNumerator.sub(ETHRewardPerUnitStaked.mul(totalStakes));
            lastLUSDDebtError_Redistribution = LUSDDebtNumerator.sub(LUSDDebtRewardPerUnitStaked.mul(totalStakes));

            L_ETH = L_ETH.add(ETHRewardPerUnitStaked);
            L_LUSDDebt = L_LUSDDebt.add(LUSDDebtRewardPerUnitStaked);
        }


        activePool.decreaseLUSDDebt(_debt);
        defaultPool.increaseLUSDDebt(_debt);
        activePool.sendETH(address(defaultPool), _coll);
    }

    function closeTrove(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _closeTrove(_borrower);
    }

    function _closeTrove(address _borrower) internal {
        uint TroveOwnersArrayLength = TroveOwners.length;
        _requireMoreThanOneTroveInSystem(TroveOwnersArrayLength);

        Troves[_borrower].status = Status.closed;
        Troves[_borrower].coll = 0;
        Troves[_borrower].debt = 0;

        rewardSnapshots[_borrower].ETH = 0;
        rewardSnapshots[_borrower].LUSDDebt = 0;

        _removeTroveOwner(_borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_borrower);
    }

















    function _updateSystemSnapshots_excludeCollRemainder(uint _collRemainder) internal {
        totalStakesSnapshot = totalStakes;

        uint activeColl = activePool.getETH();
        uint liquidatedColl = defaultPool.getETH();
        totalCollateralSnapshot = activeColl.sub(_collRemainder).add(liquidatedColl);
    }


    function addTroveOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOperations();
        return _addTroveOwnerToArray(_borrower);
    }

    function _addTroveOwnerToArray(address _borrower) internal returns (uint128 index) {
        require(TroveOwners.length < 2**128 - 1, "TroveManager: TroveOwners array has maximum size of 2^128 - 1");


        TroveOwners.push(_borrower);


        index = uint128(TroveOwners.length.sub(1));
        Troves[_borrower].arrayIndex = index;

        return index;
    }





    function _removeTroveOwner(address _borrower, uint TroveOwnersArrayLength) internal {
        require(Troves[_borrower].status == Status.closed, "TroveManager: Trove is still active");

        uint128 index = Troves[_borrower].arrayIndex;
        uint length = TroveOwnersArrayLength;
        uint idxLast = length.sub(1);

        assert(index <= idxLast);

        address addressToMove = TroveOwners[idxLast];

        TroveOwners[index] = addressToMove;
        Troves[addressToMove].arrayIndex = index;
        TroveOwners.pop();
    }



    function checkRecoveryMode() public view override returns (bool) {
        uint TCR = getTCR();

        if (TCR < CCR) {
            return true;
        } else {
            return false;
        }
    }


    function _checkPotentialRecoveryMode(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price
    )
        internal
        pure
    returns (bool)
    {
        uint TCR = LiquityMath._computeCR(_entireSystemColl, _entireSystemDebt, _price);
        if (TCR < CCR) {
            return true;
        } else {
            return false;
        }
    }

    function getTCR() public view override returns (uint TCR) {
        uint price = priceFeed.getPrice();
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();

        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt, price);

        return TCR;
    }

    function getEntireSystemColl() public view override returns (uint entireSystemColl) {
        uint activeColl = activePool.getETH();
        uint liquidatedColl = defaultPool.getETH();

        return activeColl.add(liquidatedColl);
    }

    function getEntireSystemDebt() public view override returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getLUSDDebt();
        uint closedDebt = defaultPool.getLUSDDebt();

        return activeDebt.add(closedDebt);
    }









    function _updateBaseRateFromRedemption(uint _ETHDrawn,  uint _price) internal returns (uint) {
        uint decayedBaseRate = _calcDecayedBaseRate();

        uint activeDebt = activePool.getLUSDDebt();
        uint closedDebt = defaultPool.getLUSDDebt();
        uint totalLUSDSupply = activeDebt.add(closedDebt);



        uint redeemedLUSDFraction = _ETHDrawn.mul(_price).div(totalLUSDSupply);

        uint newBaseRate = decayedBaseRate.add(redeemedLUSDFraction.div(BETA));


        baseRate = newBaseRate < 1e18 ? newBaseRate : 1e18;
        assert(baseRate <= 1e18 && baseRate > 0);

        _updateLastFeeOpTime();

        return baseRate;
    }

    function _getRedemptionFee(uint _ETHDrawn) internal view returns (uint) {
       return baseRate.mul(_ETHDrawn).div(1e18);
    }



    function getBorrowingFee(uint _LUSDDebt) external view override returns (uint) {
        return _LUSDDebt.mul(baseRate).div(1e18);
    }


    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOperations();

        baseRate = _calcDecayedBaseRate();
        assert(baseRate <= 1e18);

        _updateLastFeeOpTime();
    }




    function _updateLastFeeOpTime() internal {
        uint timePassed = block.timestamp.sub(lastFeeOperationTime);

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
        }
    }

    function _calcDecayedBaseRate() internal view returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = LiquityMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate.mul(decayFactor).div(1e18);
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint) {
        return (block.timestamp.sub(lastFeeOperationTime)).div(SECONDS_IN_ONE_MINUTE);
    }



    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperationsAddress, "TroveManager: Caller is not the BorrowerOperations contract");
    }

    function _requireTroveisActive(address _borrower) internal view {
        require(Troves[_borrower].status == Status.active, "TroveManager: Trove does not exist or is closed");
    }

    function _requireLUSDBalanceCoversRedemption(address _redeemer, uint _amount) internal view {
        require(lusdToken.balanceOf(_redeemer) >= _amount, "TroveManager: Requested redemption amount must be <= user's LUSD token balance");
    }

    function _requireMoreThanOneTroveInSystem(uint TroveOwnersArrayLength) internal view {
        require (TroveOwnersArrayLength > 1 && sortedTroves.getSize() > 1, "TroveManager: Only one trove in the system");
    }

    function _requireAmountGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "TroveManager: Amount must be greater than zero");
    }



    function getTroveStatus(address _borrower) external view override returns (uint) {
        return uint(Troves[_borrower].status);
    }

    function getTroveStake(address _borrower) external view override returns (uint) {
        return Troves[_borrower].stake;
    }

    function getTroveDebt(address _borrower) external view override returns (uint) {
        return Troves[_borrower].debt;
    }

    function getTroveColl(address _borrower) external view override returns (uint) {
        return Troves[_borrower].coll;
    }



    function setTroveStatus(address _borrower, uint _num) external override {
        _requireCallerIsBorrowerOperations();
        Troves[_borrower].status = Status(_num);
    }

    function increaseTroveColl(address _borrower, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Troves[_borrower].coll.add(_collIncrease);
        Troves[_borrower].coll = newColl;
        return newColl;
    }

    function decreaseTroveColl(address _borrower, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Troves[_borrower].coll.sub(_collDecrease);
        Troves[_borrower].coll = newColl;
        return newColl;
    }

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Troves[_borrower].debt.add(_debtIncrease);
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseTroveDebt(address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Troves[_borrower].debt.sub(_debtDecrease);
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }
}
