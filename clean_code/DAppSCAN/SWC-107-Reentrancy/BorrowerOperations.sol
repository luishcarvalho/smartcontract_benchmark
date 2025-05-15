

pragma solidity 0.6.11;

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ILUSDToken.sol";
import "./Interfaces/IPool.sol";
import "./Interfaces/ICollSurplusPool.sol";
import './Interfaces/ILUSDToken.sol';
import "./Interfaces/IPriceFeed.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/ILQTYStaking.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/console.sol";

contract BorrowerOperations is LiquityBase, Ownable, IBorrowerOperations {



    ITroveManager public troveManager;

    IPool public activePool;

    IPool public defaultPool;

    address stabilityPoolAddress;

    ICollSurplusPool collSurplusPool;

    IPriceFeed public priceFeed;

    ILQTYStaking public lqtyStaking;
    address public lqtyStakingAddress;

    ILUSDToken public lusdToken;


    ISortedTroves public sortedTroves;






     struct LocalVariables_adjustTrove {
        uint price;
        uint collChange;
        uint rawDebtChange;
        bool isCollIncrease;
        uint debt;
        uint coll;
        uint newICR;
        uint LUSDFee;
        uint newDebt;
        uint newColl;
        uint stake;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        addColl,
        withdrawColl,
        withdrawLUSD,
        repayLUSD,
        adjustTrove
    }

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, BorrowerOperation operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);



    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _lusdTokenAddress,
        address _lqtyStakingAddress
    )
        external
        override
        onlyOwner
    {
        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IPool(_activePoolAddress);
        defaultPool = IPool(_defaultPoolAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        lusdToken = ILUSDToken(_lusdTokenAddress);
        lqtyStakingAddress = _lqtyStakingAddress;
        lqtyStaking = ILQTYStaking(_lqtyStakingAddress);

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit LUSDTokenAddressChanged(_lusdTokenAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit LUSDTokenAddressChanged(_lusdTokenAddress);
        emit LQTYStakingAddressChanged(_lqtyStakingAddress);

        _renounceOwnership();
    }



    function openTrove(uint _LUSDAmount, address _hint) external payable override {
        uint price = priceFeed.getPrice();

        _requireTroveisNotActive(msg.sender);


        troveManager.decayBaseRateFromBorrowing();
        uint LUSDFee = troveManager.getBorrowingFee(_LUSDAmount);
        uint rawDebt = _LUSDAmount.add(LUSDFee);


        uint compositeDebt = _getCompositeDebt(rawDebt);
        assert(compositeDebt > 0);
        uint ICR = LiquityMath._computeCR(msg.value, compositeDebt, price);

        if (_checkRecoveryMode()) {
            _requireICRisAboveR_MCR(ICR);
        } else {
            _requireICRisAboveMCR(ICR);
            _requireNewTCRisAboveCCR(msg.value, true, compositeDebt, true, price);
        }


        troveManager.setTroveStatus(msg.sender, 1);
        troveManager.increaseTroveColl(msg.sender, msg.value);
        troveManager.increaseTroveDebt(msg.sender, compositeDebt);

        troveManager.updateTroveRewardSnapshots(msg.sender);
        uint stake = troveManager.updateStakeAndTotalStakes(msg.sender);

        sortedTroves.insert(msg.sender, ICR, price, _hint, _hint);
        uint arrayIndex = troveManager.addTroveOwnerToArray(msg.sender);
        emit TroveCreated(msg.sender, arrayIndex);


        lusdToken.mint(lqtyStakingAddress, LUSDFee);
        lqtyStaking.increaseF_LUSD(LUSDFee);


        _activePoolAddColl(msg.value);
        _withdrawLUSD(msg.sender, _LUSDAmount, rawDebt);

        _withdrawLUSD(GAS_POOL_ADDRESS, LUSD_GAS_COMPENSATION, LUSD_GAS_COMPENSATION);

        emit TroveUpdated(msg.sender, rawDebt, msg.value, stake, BorrowerOperation.openTrove);
        emit LUSDBorrowingFeePaid(msg.sender, LUSDFee);
    }


    function addColl(address _hint) external payable override {
        _adjustTrove(msg.sender, 0, 0, false, _hint);
    }


    function moveETHGainToTrove(address _borrower, address _hint) external payable override {
        _requireCallerIsStabilityPool();
        _adjustTrove(_borrower, 0, 0, false, _hint);
    }


    function withdrawColl(uint _collWithdrawal, address _hint) external override {
        _adjustTrove(msg.sender, _collWithdrawal, 0, false, _hint);
    }


    function withdrawLUSD(uint _LUSDAmount, address _hint) external override {
        _adjustTrove(msg.sender, 0, _LUSDAmount, true, _hint);
    }


    function repayLUSD(uint _LUSDAmount, address _hint) external override {
        _adjustTrove(msg.sender, 0, _LUSDAmount, false, _hint);
    }





    function adjustTrove(uint _collWithdrawal, uint _debtChange, bool _isDebtIncrease, address _hint) external payable override {
        _adjustTrove(msg.sender, _collWithdrawal, _debtChange, _isDebtIncrease, _hint);
    }

    function _adjustTrove(address _borrower, uint _collWithdrawal, uint _debtChange, bool _isDebtIncrease, address _hint) internal {
        require(msg.value == 0 || _collWithdrawal == 0, "BorrowerOperations: Cannot withdraw and add coll");

        bool isWithdrawal = _collWithdrawal != 0 || _isDebtIncrease;
        require(msg.sender == _borrower || !isWithdrawal, "BorrowerOps: User must be sender for withdrawals");
        require(msg.value != 0 || _collWithdrawal != 0 || _debtChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");

        LocalVariables_adjustTrove memory L;

        _requireTroveisActive(_borrower);
        if (isWithdrawal) {_requireNotInRecoveryMode();}

        L.price = priceFeed.getPrice();

        troveManager.applyPendingRewards(_borrower);

        (L.collChange, L.isCollIncrease) = _getCollChange(msg.value, _collWithdrawal);

        L.rawDebtChange = _debtChange;
        if (_isDebtIncrease && _debtChange > 0) {

            troveManager.decayBaseRateFromBorrowing();
            L.LUSDFee = troveManager.getBorrowingFee(_debtChange);


            L.rawDebtChange = L.rawDebtChange.add(L.LUSDFee);


            lqtyStaking.increaseF_LUSD(L.LUSDFee);
            lusdToken.mint(lqtyStakingAddress, L.LUSDFee);
        }

        L.debt = troveManager.getTroveDebt(_borrower);
        L.coll = troveManager.getTroveColl(_borrower);

        L.newICR = _getNewICRFromTroveChange(L.coll, L.debt, L.collChange, L.isCollIncrease, L.rawDebtChange, _isDebtIncrease, L.price);

        if (isWithdrawal) {_requireICRisAboveMCR(L.newICR);}
        if (_isDebtIncrease && _debtChange > 0) {
            _requireNewTCRisAboveCCR(L.collChange, L.isCollIncrease, L.rawDebtChange, _isDebtIncrease, L.price);
        }
        if (!L.isCollIncrease) {_requireCollAmountIsWithdrawable(L.coll, L.collChange);}
        if (!_isDebtIncrease && _debtChange > 0) {_requireLUSDRepaymentAllowed(L.debt, L.rawDebtChange);}

        (L.newColl, L.newDebt) = _updateTroveFromAdjustment(_borrower, L.collChange, L.isCollIncrease, L.rawDebtChange, _isDebtIncrease);
        L.stake = troveManager.updateStakeAndTotalStakes(_borrower);


        sortedTroves.reInsert(_borrower, L.newICR, L.price, _hint, _hint);


        _moveTokensAndETHfromAdjustment(msg.sender, L.collChange, L.isCollIncrease, _debtChange, _isDebtIncrease, L.rawDebtChange);

        emit TroveUpdated(_borrower, L.newDebt, L.newColl, L.stake, BorrowerOperation.adjustTrove);
        emit LUSDBorrowingFeePaid(msg.sender,  L.LUSDFee);
    }

    function closeTrove() external override {
        _requireTroveisActive(msg.sender);
        _requireNotInRecoveryMode();

        troveManager.applyPendingRewards(msg.sender);

        uint coll = troveManager.getTroveColl(msg.sender);
        uint debt = troveManager.getTroveDebt(msg.sender);

        troveManager.removeStake(msg.sender);
        troveManager.closeTrove(msg.sender);


        _repayLUSD(msg.sender, debt.sub(LUSD_GAS_COMPENSATION));
        activePool.sendETH(msg.sender, coll);

        _repayLUSD(GAS_POOL_ADDRESS, LUSD_GAS_COMPENSATION);

        emit TroveUpdated(msg.sender, 0, 0, 0, BorrowerOperation.closeTrove);
    }

    function claimRedeemedCollateral(address _user) external override {

        collSurplusPool.claimColl(_user);

        emit RedeemedCollateralClaimed(_user);
    }



    function _getUSDValue(uint _coll, uint _price) internal pure returns (uint) {
        uint usdValue = _price.mul(_coll).div(1e18);

        return usdValue;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }


    function _updateTroveFromAdjustment
    (
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        returns (uint, uint)
    {
        uint newColl = (_isCollIncrease) ? troveManager.increaseTroveColl(_borrower, _collChange)
                                        : troveManager.decreaseTroveColl(_borrower, _collChange);
        uint newDebt = (_isDebtIncrease) ? troveManager.increaseTroveDebt(_borrower, _debtChange)
                                        : troveManager.decreaseTroveDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndETHfromAdjustment
    (
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _rawDebtChange
    )
        internal
    {
        if (_isDebtIncrease) {
            _withdrawLUSD(_borrower, _debtChange, _rawDebtChange);
        } else {
            _repayLUSD(_borrower, _debtChange);
        }

        if (_isCollIncrease) {
            _activePoolAddColl(_collChange);
        } else {

            activePool.sendETH(_borrower, _collChange);
        }
    }


    function _activePoolAddColl(uint _amount) internal {
        (bool success, ) = address(activePool).call{value: _amount}("");
        assert(success == true);
    }


    function _withdrawLUSD(address _account, uint _LUSDAmount, uint _rawDebtIncrease) internal {
        activePool.increaseLUSDDebt(_rawDebtIncrease);
        lusdToken.mint(_account, _LUSDAmount);
    }


    function _repayLUSD(address _account, uint _LUSD) internal {
        activePool.decreaseLUSDDebt(_LUSD);
        lusdToken.burn(_account, _LUSD);
    }



    function _requireTroveisActive(address _borrower) internal view {
        uint status = troveManager.getTroveStatus(_borrower);
        require(status == 1, "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(address _borrower) internal view {
        uint status = troveManager.getTroveStatus(_borrower);
        require(status != 1, "BorrowerOps: Trove is active");
    }

    function _requireNotInRecoveryMode() internal view {
        require(_checkRecoveryMode() == false, "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireICRisAboveMCR(uint _newICR)  internal pure {
        require(_newICR >= MCR, "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireICRisAboveR_MCR(uint _newICR) internal pure {
        require(_newICR >= R_MCR, "BorrowerOps: In Recovery Mode new troves must have ICR >= R_MCR");
    }

    function _requireNewTCRisAboveCCR
    (
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        internal
        view
    {
        uint newTCR = _getNewTCRFromTroveChange(_collChange, _isCollIncrease, _debtChange, _isDebtIncrease, _price);
        require(newTCR >= CCR, "BorrowerOps: An operation that would result in TCR < CCR is not permitted");
    }

    function _requireLUSDRepaymentAllowed(uint _currentDebt, uint _debtRepayment) internal pure {
        require(_debtRepayment <= _currentDebt.sub(LUSD_GAS_COMPENSATION), "BorrowerOps: Amount repaid must not be larger than the Trove's debt");
    }

    function _requireCollAmountIsWithdrawable(uint _currentColl, uint _collWithdrawal)
        internal
        pure
    {
        require(_collWithdrawal <= _currentColl, "BorrowerOps: Insufficient balance for ETH withdrawal");
    }

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }




    function _getNewICRFromTroveChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        pure
        internal
        returns (uint)
    {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll.add(_collChange) :  _coll.sub(_collChange);
        newDebt = _isDebtIncrease ? _debt.add(_debtChange) : _debt.sub(_debtChange);

        uint newICR = LiquityMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewTCRFromTroveChange
    (
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        internal
        view
        returns (uint)
    {
        uint totalColl = activePool.getETH().add(defaultPool.getETH());
        uint totalDebt = activePool.getLUSDDebt().add(defaultPool.getLUSDDebt());

        totalColl = _isCollIncrease ? totalColl.add(_collChange) : totalColl.sub(_collChange);
        totalDebt = _isDebtIncrease ? totalDebt.add(_debtChange) : totalDebt = totalDebt.sub(_debtChange);

        uint newTCR = LiquityMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    function getCompositeDebt(uint _debt) external pure override returns (uint) {
        return _getCompositeDebt(_debt);
    }



    function _checkRecoveryMode() internal view returns (bool) {
        uint TCR = _getTCR();

        if (TCR < CCR) {
            return true;
        } else {
            return false;
        }
    }

    function _getTCR() internal view returns (uint TCR) {
        uint price = priceFeed.getPrice();
        uint activeColl = activePool.getETH();
        uint activeDebt = activePool.getLUSDDebt();
        uint liquidatedColl = defaultPool.getETH();
        uint closedDebt = defaultPool.getLUSDDebt();

        uint totalCollateral = activeColl.add(liquidatedColl);
        uint totalDebt = activeDebt.add(closedDebt);

        TCR = LiquityMath._computeCR(totalCollateral, totalDebt, price);

        return TCR;
    }
}
