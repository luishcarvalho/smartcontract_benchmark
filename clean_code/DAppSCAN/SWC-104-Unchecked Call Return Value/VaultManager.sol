

pragma solidity 0.8.12;

import "./VaultManagerPermit.sol";







contract VaultManager is VaultManagerPermit, IVaultManagerFunctions {
    using SafeERC20 for IERC20;
    using Address for address;


    function initialize(
        ITreasury _treasury,
        IERC20 _collateral,
        IOracle _oracle,
        VaultParameters calldata params,
        string memory _symbol
    ) external initializer {
        if (_oracle.treasury() != _treasury) revert InvalidTreasury();
        treasury = _treasury;
        collateral = _collateral;
        _collatBase = 10**(IERC20Metadata(address(collateral)).decimals());
        stablecoin = IAgToken(_treasury.stablecoin());
        oracle = _oracle;
        string memory _name = string.concat("Angle Protocol ", _symbol, " Vault");
        name = _name;
        __ERC721Permit_init(_name);
        symbol = string.concat(_symbol, "-vault");

        interestAccumulator = BASE_INTEREST;
        lastInterestAccumulatorUpdated = block.timestamp;


        if (
            params.collateralFactor > params.liquidationSurcharge ||
            params.liquidationSurcharge > BASE_PARAMS ||
            BASE_PARAMS > params.targetHealthFactor ||
            params.maxLiquidationDiscount >= BASE_PARAMS ||
            params.baseBoost == 0
        ) revert InvalidSetOfParameters();

        debtCeiling = params.debtCeiling;
        collateralFactor = params.collateralFactor;
        targetHealthFactor = params.targetHealthFactor;
        interestRate = params.interestRate;
        liquidationSurcharge = params.liquidationSurcharge;
        maxLiquidationDiscount = params.maxLiquidationDiscount;
        whitelistingActivated = params.whitelistingActivated;
        yLiquidationBoost = [params.baseBoost];
        paused = true;
    }


    constructor(uint256 dust_, uint256 dustCollateral_) VaultManagerStorage(dust_, dustCollateral_) {}




    modifier onlyGovernor() {
        if (!treasury.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }


    modifier onlyGovernorOrGuardian() {
        if (!treasury.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }


    modifier onlyTreasury() {
        if (msg.sender != address(treasury)) revert NotTreasury();
        _;
    }


    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }






    function createVault(address toVault) external whenNotPaused returns (uint256) {
        return _mint(toVault);
    }


    function angle(
        ActionType[] memory actions,
        bytes[] memory datas,
        address from,
        address to
    ) external returns (PaymentData memory) {
        return angle(actions, datas, from, to, address(0), new bytes(0));
    }


    function angle(
        ActionType[] memory actions,
        bytes[] memory datas,
        address from,
        address to,
        address who,
        bytes memory repayData
    ) public whenNotPaused nonReentrant returns (PaymentData memory paymentData) {
        if (actions.length != datas.length || actions.length == 0) revert IncompatibleLengths();


        uint256 newInterestAccumulator;
        uint256 oracleValue;
        uint256 collateralAmount;
        uint256 stablecoinAmount;
        uint256 vaultID;
        for (uint256 i = 0; i < actions.length; i++) {
            ActionType action = actions[i];

            if (action == ActionType.createVault) {
                _mint(abi.decode(datas[i], (address)));
            } else if (action == ActionType.addCollateral) {
                (vaultID, collateralAmount) = abi.decode(datas[i], (uint256, uint256));
                if (vaultID == 0) vaultID = vaultIDCount;
                _addCollateral(vaultID, collateralAmount);
                paymentData.collateralAmountToReceive += collateralAmount;
            } else if (action == ActionType.permit) {
                address owner;
                bytes32 r;
                bytes32 s;




                (owner, collateralAmount, vaultID, stablecoinAmount, r, s) = abi.decode(
                    datas[i],
                    (address, uint256, uint256, uint256, bytes32, bytes32)
                );
                IERC20PermitUpgradeable(address(collateral)).permit(
                    owner,
                    address(this),
                    collateralAmount,
                    vaultID,
                    uint8(stablecoinAmount),
                    r,
                    s
                );
            } else {


                if (newInterestAccumulator == 0) newInterestAccumulator = _accrue();
                if (action == ActionType.repayDebt) {
                    (vaultID, stablecoinAmount) = abi.decode(datas[i], (uint256, uint256));
                    if (vaultID == 0) vaultID = vaultIDCount;
                    stablecoinAmount = _repayDebt(vaultID, stablecoinAmount, newInterestAccumulator);
                    uint256 stablecoinAmountPlusRepayFee = (stablecoinAmount * BASE_PARAMS) / (BASE_PARAMS - repayFee);
                    surplus += stablecoinAmountPlusRepayFee - stablecoinAmount;
                    paymentData.stablecoinAmountToReceive += stablecoinAmountPlusRepayFee;
                } else {

                    if (oracleValue == 0) oracleValue = oracle.read();
                    if (action == ActionType.closeVault) {
                        vaultID = abi.decode(datas[i], (uint256));
                        if (vaultID == 0) vaultID = vaultIDCount;
                        (stablecoinAmount, collateralAmount) = _closeVault(
                            vaultID,
                            oracleValue,
                            newInterestAccumulator
                        );
                        paymentData.collateralAmountToGive += collateralAmount;
                        paymentData.stablecoinAmountToReceive += stablecoinAmount;
                    } else if (action == ActionType.removeCollateral) {
                        (vaultID, collateralAmount) = abi.decode(datas[i], (uint256, uint256));
                        if (vaultID == 0) vaultID = vaultIDCount;
                        _removeCollateral(vaultID, collateralAmount, oracleValue, newInterestAccumulator);
                        paymentData.collateralAmountToGive += collateralAmount;
                    } else if (action == ActionType.borrow) {
                        (vaultID, stablecoinAmount) = abi.decode(datas[i], (uint256, uint256));
                        if (vaultID == 0) vaultID = vaultIDCount;
                        stablecoinAmount = _borrow(vaultID, stablecoinAmount, oracleValue, newInterestAccumulator);
                        paymentData.stablecoinAmountToGive += stablecoinAmount;
                    } else if (action == ActionType.getDebtIn) {
                        address vaultManager;
                        uint256 dstVaultID;
                        (vaultID, vaultManager, dstVaultID, stablecoinAmount) = abi.decode(
                            datas[i],
                            (uint256, address, uint256, uint256)
                        );
                        if (vaultID == 0) vaultID = vaultIDCount;
                        _getDebtIn(
                            vaultID,
                            IVaultManager(vaultManager),
                            dstVaultID,
                            stablecoinAmount,
                            oracleValue,
                            newInterestAccumulator
                        );
                    }
                }
            }
        }






        if (paymentData.stablecoinAmountToReceive >= paymentData.stablecoinAmountToGive) {
            uint256 stablecoinPayment = paymentData.stablecoinAmountToReceive - paymentData.stablecoinAmountToGive;
            if (paymentData.collateralAmountToGive >= paymentData.collateralAmountToReceive) {


                _handleRepay(

                    paymentData.collateralAmountToGive - paymentData.collateralAmountToReceive,
                    stablecoinPayment,
                    from,
                    to,
                    who,
                    repayData
                );
            } else {
                if (stablecoinPayment > 0) stablecoin.burnFrom(stablecoinPayment, from, msg.sender);

                collateral.safeTransferFrom(
                    msg.sender,
                    address(this),
                    paymentData.collateralAmountToReceive - paymentData.collateralAmountToGive
                );
            }
        } else {
            uint256 stablecoinPayment = paymentData.stablecoinAmountToGive - paymentData.stablecoinAmountToReceive;

            stablecoin.mint(to, stablecoinPayment);
            if (paymentData.collateralAmountToGive > paymentData.collateralAmountToReceive) {
                collateral.safeTransfer(to, paymentData.collateralAmountToGive - paymentData.collateralAmountToReceive);
            } else {
                uint256 collateralPayment = paymentData.collateralAmountToReceive - paymentData.collateralAmountToGive;
                if (collateralPayment > 0) {
                    if (repayData.length > 0) {
                        ISwapper(who).swap(
                            IERC20(address(stablecoin)),
                            collateral,
                            msg.sender,


                            collateralPayment,
                            stablecoinPayment,
                            repayData
                        );
                    }
                    collateral.safeTransferFrom(msg.sender, address(this), collateralPayment);
                }
            }
        }
    }


    function getDebtOut(
        uint256 vaultID,
        uint256 stablecoinAmount,
        uint256 senderBorrowFee,
        uint256 senderRepayFee
    ) external whenNotPaused {
        if (!treasury.isVaultManager(msg.sender)) revert NotVaultManager();



        uint256 _repayFee;
        if (repayFee > senderRepayFee) {
            _repayFee = repayFee - senderRepayFee;
        }



        uint256 _borrowFee;
        if (senderBorrowFee > borrowFee) {
            _borrowFee = senderBorrowFee - borrowFee;
        }

        uint256 stablecoinAmountLessFeePaid = (stablecoinAmount *
            (BASE_PARAMS - _repayFee) *
            (BASE_PARAMS - _borrowFee)) / (BASE_PARAMS**2);
        surplus += stablecoinAmount - stablecoinAmountLessFeePaid;
        _repayDebt(vaultID, stablecoinAmountLessFeePaid, 0);
    }




    function getVaultDebt(uint256 vaultID) external view returns (uint256) {
        return (vaultData[vaultID].normalizedDebt * _calculateCurrentInterestAccumulator()) / BASE_INTEREST;
    }


    function getTotalDebt() external view returns (uint256) {
        return (totalNormalizedDebt * _calculateCurrentInterestAccumulator()) / BASE_INTEREST;
    }






    function checkLiquidation(uint256 vaultID, address liquidator)
        external
        view
        returns (LiquidationOpportunity memory liqOpp)
    {
        liqOpp = _checkLiquidation(
            vaultData[vaultID],
            liquidator,
            oracle.read(),
            _calculateCurrentInterestAccumulator()
        );
    }











    function _isSolvent(
        Vault memory vault,
        uint256 oracleValue,
        uint256 newInterestAccumulator
    )
        internal
        view
        returns (
            uint256 healthFactor,
            uint256 currentDebt,
            uint256 collateralAmountInStable
        )
    {
        currentDebt = (vault.normalizedDebt * newInterestAccumulator) / BASE_INTEREST;
        collateralAmountInStable = (vault.collateralAmount * oracleValue) / _collatBase;
        if (currentDebt == 0) healthFactor = type(uint256).max;
        else healthFactor = (collateralAmountInStable * collateralFactor) / currentDebt;
    }







    function _calculateCurrentInterestAccumulator() internal view returns (uint256) {
        uint256 exp = block.timestamp - lastInterestAccumulatorUpdated;
        uint256 ratePerSecond = interestRate;
        if (exp == 0 || ratePerSecond == 0) return interestAccumulator;
        uint256 expMinusOne = exp - 1;
        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;
        uint256 basePowerTwo = (ratePerSecond * ratePerSecond + HALF_BASE_INTEREST) / BASE_INTEREST;
        uint256 basePowerThree = (basePowerTwo * ratePerSecond + HALF_BASE_INTEREST) / BASE_INTEREST;
        uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
        uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;
        return (interestAccumulator * (BASE_INTEREST + ratePerSecond * exp + secondTerm + thirdTerm)) / BASE_INTEREST;
    }










    function _closeVault(
        uint256 vaultID,
        uint256 oracleValue,
        uint256 newInterestAccumulator
    ) internal onlyApprovedOrOwner(msg.sender, vaultID) returns (uint256, uint256) {
        Vault memory vault = vaultData[vaultID];
        (uint256 healthFactor, uint256 currentDebt, ) = _isSolvent(vault, oracleValue, newInterestAccumulator);
        if (healthFactor <= BASE_PARAMS) revert InsolventVault();
        totalNormalizedDebt -= vault.normalizedDebt;
        _burn(vaultID);
        uint256 currentDebtPlusRepayFee = (currentDebt * BASE_PARAMS) / (BASE_PARAMS - repayFee);
        surplus += currentDebtPlusRepayFee - currentDebt;
        return (currentDebtPlusRepayFee, vault.collateralAmount);
    }




    function _addCollateral(uint256 vaultID, uint256 collateralAmount) internal {
        if (!_exists(vaultID)) revert NonexistentVault();
        vaultData[vaultID].collateralAmount += collateralAmount;
        emit CollateralAmountUpdated(vaultID, collateralAmount, 1);
    }







    function _removeCollateral(
        uint256 vaultID,
        uint256 collateralAmount,
        uint256 oracleValue,
        uint256 interestAccumulator_
    ) internal onlyApprovedOrOwner(msg.sender, vaultID) {
        vaultData[vaultID].collateralAmount -= collateralAmount;
        (uint256 healthFactor, , ) = _isSolvent(vaultData[vaultID], oracleValue, interestAccumulator_);
        if (healthFactor <= BASE_PARAMS) revert InsolventVault();
        emit CollateralAmountUpdated(vaultID, collateralAmount, 0);
    }







    function _borrow(
        uint256 vaultID,
        uint256 stablecoinAmount,
        uint256 oracleValue,
        uint256 newInterestAccumulator
    ) internal onlyApprovedOrOwner(msg.sender, vaultID) returns (uint256 toMint) {
        stablecoinAmount = _increaseDebt(vaultID, stablecoinAmount, oracleValue, newInterestAccumulator);
        uint256 borrowFeePaid = (borrowFee * stablecoinAmount) / BASE_PARAMS;
        surplus += borrowFeePaid;
        toMint = stablecoinAmount - borrowFeePaid;
    }













    function _getDebtIn(
        uint256 srcVaultID,
        IVaultManager vaultManager,
        uint256 dstVaultID,
        uint256 stablecoinAmount,
        uint256 oracleValue,
        uint256 newInterestAccumulator
    ) internal onlyApprovedOrOwner(msg.sender, srcVaultID) {
        emit DebtTransferred(srcVaultID, dstVaultID, address(vaultManager), stablecoinAmount);

        stablecoinAmount = _increaseDebt(srcVaultID, stablecoinAmount, oracleValue, newInterestAccumulator);
        if (address(vaultManager) == address(this)) {

            _repayDebt(dstVaultID, stablecoinAmount, newInterestAccumulator);
        } else {



            vaultManager.getDebtOut(dstVaultID, stablecoinAmount, borrowFee, repayFee);
        }
    }











    function _increaseDebt(
        uint256 vaultID,
        uint256 stablecoinAmount,
        uint256 oracleValue,
        uint256 newInterestAccumulator
    ) internal returns (uint256) {


        uint256 changeAmount = (stablecoinAmount * BASE_INTEREST) / newInterestAccumulator;

        if (vaultData[vaultID].normalizedDebt == 0)
            if (stablecoinAmount <= dust) revert DustyLeftoverAmount();
        vaultData[vaultID].normalizedDebt += changeAmount;
        totalNormalizedDebt += changeAmount;
        if (totalNormalizedDebt * newInterestAccumulator > debtCeiling * BASE_INTEREST) revert DebtCeilingExceeded();
        (uint256 healthFactor, , ) = _isSolvent(vaultData[vaultID], oracleValue, newInterestAccumulator);
        if (healthFactor <= BASE_PARAMS) revert InsolventVault();
        emit InternalDebtUpdated(vaultID, changeAmount, 1);
        return (changeAmount * newInterestAccumulator) / BASE_INTEREST;
    }











    function _repayDebt(
        uint256 vaultID,
        uint256 stablecoinAmount,
        uint256 newInterestAccumulator
    ) internal returns (uint256) {
        if (newInterestAccumulator == 0) newInterestAccumulator = _accrue();
        uint256 newVaultNormalizedDebt = vaultData[vaultID].normalizedDebt;


        uint256 changeAmount = (newVaultNormalizedDebt * newInterestAccumulator) / BASE_INTEREST;


        if (stablecoinAmount >= changeAmount) {
            stablecoinAmount = changeAmount;
            changeAmount = newVaultNormalizedDebt;
        } else {
            changeAmount = (stablecoinAmount * BASE_INTEREST) / newInterestAccumulator;
        }
        newVaultNormalizedDebt -= changeAmount;
        totalNormalizedDebt -= changeAmount;
        if (newVaultNormalizedDebt != 0 && newVaultNormalizedDebt * newInterestAccumulator <= dust * BASE_INTEREST)
            revert DustyLeftoverAmount();
        vaultData[vaultID].normalizedDebt = newVaultNormalizedDebt;
        emit InternalDebtUpdated(vaultID, changeAmount, 0);
        return stablecoinAmount;
    }











    function _handleRepay(
        uint256 collateralAmountToGive,
        uint256 stableAmountToRepay,
        address from,
        address to,
        address who,
        bytes memory data
    ) internal {
        if (collateralAmountToGive > 0) collateral.safeTransfer(to, collateralAmountToGive);
        if (stableAmountToRepay > 0) {
            if (data.length > 0) {
                ISwapper(who).swap(
                    collateral,
                    IERC20(address(stablecoin)),
                    from,
                    stableAmountToRepay,
                    collateralAmountToGive,
                    data
                );
            }
            stablecoin.burnFrom(stableAmountToRepay, from, msg.sender);
        }
    }




    function accrueInterestToTreasury() external onlyTreasury returns (uint256 surplusValue, uint256 badDebtValue) {
        _accrue();
        surplusValue = surplus;
        badDebtValue = badDebt;
        surplus = 0;
        badDebt = 0;
        if (surplusValue >= badDebtValue) {
            surplusValue -= badDebtValue;
            badDebtValue = 0;
            stablecoin.mint(address(treasury), surplusValue);
        } else {
            badDebtValue -= surplusValue;
            surplusValue = 0;
        }
        emit AccruedToTreasury(surplusValue, badDebtValue);
    }





    function _accrue() internal returns (uint256 newInterestAccumulator) {
        newInterestAccumulator = _calculateCurrentInterestAccumulator();
        uint256 interestAccrued = (totalNormalizedDebt * (newInterestAccumulator - interestAccumulator)) /
            BASE_INTEREST;
        surplus += interestAccrued;
        interestAccumulator = newInterestAccumulator;
        lastInterestAccumulatorUpdated = block.timestamp;
        emit InterestAccumulatorUpdated(newInterestAccumulator, block.timestamp);
        return newInterestAccumulator;
    }






    function liquidate(
        uint256[] memory vaultIDs,
        uint256[] memory amounts,
        address from,
        address to
    ) external returns (LiquidatorData memory) {
        return liquidate(vaultIDs, amounts, from, to, address(0), new bytes(0));
    }














    function liquidate(
        uint256[] memory vaultIDs,
        uint256[] memory amounts,
        address from,
        address to,
        address who,
        bytes memory data
    ) public whenNotPaused nonReentrant returns (LiquidatorData memory liqData) {
        if (vaultIDs.length != amounts.length || amounts.length == 0) revert IncompatibleLengths();

        liqData.oracleValue = oracle.read();
        liqData.newInterestAccumulator = _accrue();
        emit LiquidatedVaults(vaultIDs);
        for (uint256 i = 0; i < vaultIDs.length; i++) {
            Vault memory vault = vaultData[vaultIDs[i]];

            LiquidationOpportunity memory liqOpp = _checkLiquidation(
                vault,
                msg.sender,
                liqData.oracleValue,
                liqData.newInterestAccumulator
            );



            if (
                (liqOpp.thresholdRepayAmount > 0 && amounts[i] > liqOpp.thresholdRepayAmount) ||
                amounts[i] > liqOpp.maxStablecoinAmountToRepay
            ) amounts[i] = liqOpp.maxStablecoinAmountToRepay;


            uint256 collateralReleased = (amounts[i] * BASE_PARAMS * _collatBase) /
                (liqOpp.discount * liqData.oracleValue);


            if (vault.collateralAmount <= collateralReleased) {
                collateralReleased = vault.collateralAmount;

                totalNormalizedDebt -= vault.normalizedDebt;

                delete vaultData[vaultIDs[i]];
                liqData.badDebtFromLiquidation +=
                    liqOpp.currentDebt -
                    (amounts[i] * liquidationSurcharge) /
                    BASE_PARAMS;



                emit InternalDebtUpdated(vaultIDs[i], vault.normalizedDebt, 0);
            } else {
                vaultData[vaultIDs[i]].collateralAmount -= collateralReleased;

                _repayDebt(
                    vaultIDs[i],
                    (amounts[i] * liquidationSurcharge) / BASE_PARAMS,
                    liqData.newInterestAccumulator
                );
            }
            liqData.collateralAmountToGive += collateralReleased;
            liqData.stablecoinAmountToReceive += amounts[i];
        }

        surplus += (liqData.stablecoinAmountToReceive * (BASE_PARAMS - liquidationSurcharge)) / BASE_PARAMS;
        badDebt += liqData.badDebtFromLiquidation;
        _handleRepay(liqData.collateralAmountToGive, liqData.stablecoinAmountToReceive, from, to, who, data);
    }




    function _checkLiquidation(
        Vault memory vault,
        address liquidator,
        uint256 oracleValue,
        uint256 newInterestAccumulator
    ) internal view returns (LiquidationOpportunity memory liqOpp) {

        (uint256 healthFactor, uint256 currentDebt, uint256 collateralAmountInStable) = _isSolvent(
            vault,
            oracleValue,
            newInterestAccumulator
        );

        if (healthFactor >= BASE_PARAMS) revert HealthyVault();

        uint256 liquidationDiscount = (_computeLiquidationBoost(liquidator) * (BASE_PARAMS - healthFactor)) /
            BASE_PARAMS;


        liquidationDiscount = liquidationDiscount >= maxLiquidationDiscount
            ? BASE_PARAMS - maxLiquidationDiscount
            : BASE_PARAMS - liquidationDiscount;

        uint256 surcharge = liquidationSurcharge;


        uint256 maxAmountToRepay;
        uint256 thresholdRepayAmount;


        if (healthFactor * liquidationDiscount * surcharge >= collateralFactor * BASE_PARAMS**2) {




            maxAmountToRepay =
                ((targetHealthFactor * currentDebt - collateralAmountInStable * collateralFactor) *
                    BASE_PARAMS *
                    liquidationDiscount) /
                (surcharge * targetHealthFactor * liquidationDiscount - (BASE_PARAMS**2) * collateralFactor);



            if (currentDebt * BASE_PARAMS <= maxAmountToRepay * surcharge + dust * BASE_PARAMS) {



                maxAmountToRepay =
                    (vault.normalizedDebt * newInterestAccumulator * BASE_PARAMS) /
                    (surcharge * BASE_INTEREST) +
                    1;






                thresholdRepayAmount = ((currentDebt - dust) * BASE_PARAMS) / surcharge;
            }
        } else {





            maxAmountToRepay =
                (vault.collateralAmount * liquidationDiscount * oracleValue) /
                (BASE_PARAMS * _collatBase) +
                1;

            if (collateralAmountInStable > _dustCollateral)

                thresholdRepayAmount =
                    ((collateralAmountInStable - _dustCollateral) * liquidationDiscount) /
                    BASE_PARAMS;

            else thresholdRepayAmount = maxAmountToRepay;
        }
        liqOpp.maxStablecoinAmountToRepay = maxAmountToRepay;
        liqOpp.maxCollateralAmountGiven =
            (maxAmountToRepay * BASE_PARAMS * _collatBase) /
            (oracleValue * liquidationDiscount);
        liqOpp.thresholdRepayAmount = thresholdRepayAmount;
        liqOpp.discount = liquidationDiscount;
        liqOpp.currentDebt = currentDebt;
    }




    function _computeLiquidationBoost(address liquidator) internal view returns (uint256) {
        if (address(veBoostProxy) == address(0)) {
            return yLiquidationBoost[0];
        } else {
            uint256 adjustedBalance = veBoostProxy.adjusted_balance_of(liquidator);
            if (adjustedBalance >= xLiquidationBoost[1]) return yLiquidationBoost[1];
            else if (adjustedBalance <= xLiquidationBoost[0]) return yLiquidationBoost[0];
            else
                return
                    yLiquidationBoost[0] +
                    ((yLiquidationBoost[1] - yLiquidationBoost[0]) * (adjustedBalance - xLiquidationBoost[0])) /
                    (xLiquidationBoost[1] - xLiquidationBoost[0]);
        }
    }











    function setUint64(uint64 param, bytes32 what) external onlyGovernorOrGuardian {
        if (what == "CF") {
            if (param > liquidationSurcharge) revert TooHighParameterValue();
            collateralFactor = param;
        } else if (what == "THF") {
            if (param < BASE_PARAMS) revert TooSmallParameterValue();
            targetHealthFactor = param;
        } else if (what == "BF") {
            if (param > BASE_PARAMS) revert TooHighParameterValue();
            borrowFee = param;
        } else if (what == "RF") {



            if (param + liquidationSurcharge > BASE_PARAMS) revert TooHighParameterValue();
            repayFee = param;
        } else if (what == "IR") {
            _accrue();
            interestRate = param;
        } else if (what == "LS") {
            if (collateralFactor > param || param + repayFee > BASE_PARAMS) revert InvalidParameterValue();
            liquidationSurcharge = param;
        } else if (what == "MLD") {
            if (param > BASE_PARAMS) revert TooHighParameterValue();
            maxLiquidationDiscount = param;
        } else {
            revert InvalidParameterType();
        }
        emit FiledUint64(param, what);
    }




    function setDebtCeiling(uint256 _debtCeiling) external onlyGovernorOrGuardian {
        debtCeiling = _debtCeiling;
        emit DebtCeilingUpdated(_debtCeiling);
    }










    function setLiquidationBoostParameters(
        address _veBoostProxy,
        uint256[] memory xBoost,
        uint256[] memory yBoost
    ) external onlyGovernorOrGuardian {
        if (
            (xBoost.length != yBoost.length) ||
            (yBoost[0] == 0) ||
            ((_veBoostProxy != address(0)) && (xBoost[1] <= xBoost[0] || yBoost[1] < yBoost[0]))
        ) revert InvalidSetOfParameters();
        veBoostProxy = IVeBoostProxy(_veBoostProxy);
        xLiquidationBoost = xBoost;
        yLiquidationBoost = yBoost;
        emit LiquidationBoostParametersUpdated(_veBoostProxy, xBoost, yBoost);
    }


    function togglePause() external onlyGovernorOrGuardian {
        paused = !paused;
    }


    function setBaseURI(string memory baseURI_) external onlyGovernorOrGuardian {
        _baseURI = baseURI_;
    }





    function toggleWhitelist(address target) external onlyGovernor {
        if (target != address(0)) {
            isWhitelisted[target] = 1 - isWhitelisted[target];
        } else {
            whitelistingActivated = !whitelistingActivated;
        }
    }



    function setOracle(address _oracle) external onlyGovernor {
        if (IOracle(_oracle).treasury() != treasury) revert InvalidTreasury();
        oracle = IOracle(_oracle);
    }


    function setTreasury(address _treasury) external onlyTreasury {
        treasury = ITreasury(_treasury);


        oracle.setTreasury(_treasury);
    }
}
