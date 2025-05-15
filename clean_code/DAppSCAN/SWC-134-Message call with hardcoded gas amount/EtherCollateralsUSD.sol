pragma solidity ^0.5.16;


import "./Owned.sol";
import "./Pausable.sol";
import "openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol";
import "./MixinResolver.sol";
import "./interfaces/IEtherCollateralsUSD.sol";


import "./SafeDecimalMath.sol";


import "./interfaces/ISystemStatus.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IExchangeRates.sol";

import "@nomiclabs/buidler/console.sol";




contract EtherCollateralsUSD is Owned, Pausable, ReentrancyGuard, MixinResolver, IEtherCollateralsUSD {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    bytes32 internal constant ETH = "ETH";


    uint256 internal constant ONE_THOUSAND = 1e18 * 1000;
    uint256 internal constant ONE_HUNDRED = 1e18 * 100;

    uint256 internal constant SECONDS_IN_A_YEAR = 31536000;


    address internal constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    bytes32 private constant sUSD = "sUSD";
    bytes32 public constant COLLATERAL = "ETH";




    uint256 public collateralizationRatio = SafeDecimalMath.unit() * 150;


    uint256 public interestRate = (5 * SafeDecimalMath.unit()) / 100;
    uint256 public interestPerSecond = interestRate.div(SECONDS_IN_A_YEAR);


    uint256 public issueFeeRate = (5 * SafeDecimalMath.unit()) / 1000;


    uint256 public issueLimit = SafeDecimalMath.unit() * 10000000;


    uint256 public minLoanCollateralSize = SafeDecimalMath.unit() * 1;


    uint256 public accountLoanLimit = 50;


    bool public loanLiquidationOpen = false;


    uint256 public liquidationDeadline;


    uint256 public liquidationRatio = (150 * SafeDecimalMath.unit()) / 100;


    uint256 public liquidationPenalty = SafeDecimalMath.unit() / 10;




    uint256 public totalIssuedSynths;


    uint256 public totalLoansCreated;


    uint256 public totalOpenLoanCount;


    struct SynthLoanStruct {

        address payable account;

        uint256 collateralAmount;

        uint256 loanAmount;

        uint256 mintingFee;

        uint256 timeCreated;

        uint256 loanID;

        uint256 timeClosed;

        uint256 loanInterestRate;

        uint256 accruedInterest;

        uint40 lastInterestAccrued;
    }


    mapping(address => SynthLoanStruct[]) public accountsSynthLoans;


    mapping(address => uint256) public accountOpenLoanCounter;







































































































































































    function calculateAmountToLiquidate(uint debtBalance, uint collateral) public view returns (uint) {
        uint unit = SafeDecimalMath.unit();
        uint ratio = liquidationRatio;

        uint dividend = debtBalance.sub(collateral.divideDecimal(ratio));
        uint divisor = unit.sub(unit.add(liquidationPenalty).divideDecimal(ratio));

        return dividend.divideDecimal(divisor);
    }

    function openLoanIDsByAccount(address _account) external view returns (uint256[] memory) {
        SynthLoanStruct[] memory synthLoans = accountsSynthLoans[_account];

        uint256[] memory _openLoanIDs = new uint256[](synthLoans.length);
        uint256 _counter = 0;

        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].timeClosed == 0) {
                _openLoanIDs[_counter] = synthLoans[i].loanID;
                _counter++;
            }
        }

        uint256[] memory _result = new uint256[](_counter);


        for (uint256 j = 0; j < _counter; j++) {
            _result[j] = _openLoanIDs[j];
        }

        return _result;
    }

    function getLoan(address _account, uint256 _loanID)
        external
        view
        returns (
            address account,
            uint256 collateralAmount,
            uint256 loanAmount,
            uint256 timeCreated,
            uint256 loanID,
            uint256 timeClosed,
            uint256 accruedInterest,
            uint256 totalInterest,
            uint256 totalFees
        )
    {
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);
        account = synthLoan.account;
        collateralAmount = synthLoan.collateralAmount;
        loanAmount = synthLoan.loanAmount;
        timeCreated = synthLoan.timeCreated;
        loanID = synthLoan.loanID;
        timeClosed = synthLoan.timeClosed;
        accruedInterest = synthLoan.accruedInterest;
        totalInterest = synthLoan.accruedInterest.add(
            accruedInterestOnLoan(synthLoan.loanAmount, _timeSinceInterestAccrual(synthLoan))
        );
        totalFees = totalInterest.add(synthLoan.mintingFee);
    }

    function getLoanCollateralRatio(address _account, uint256 _loanID) external view returns (uint256 loanCollateralRatio) {

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);

        (loanCollateralRatio, , ) = _loanCollateralRatio(synthLoan);
    }

    function _loanCollateralRatio(SynthLoanStruct memory _loan)
        internal
        view
        returns (
            uint256 loanCollateralRatio,
            uint256 collateralValue,
            uint256 interestAmount
        )
    {

        interestAmount = accruedInterestOnLoan(_loan.loanAmount, _timeSinceInterestAccrual(_loan));

        collateralValue = _loan.collateralAmount.multiplyDecimal(exchangeRates().rateForCurrency(COLLATERAL));

        loanCollateralRatio = collateralValue.divideDecimal(_loan.loanAmount.add(interestAmount));
    }

    function timeSinceInterestAccrualOnLoan(address _account, uint256 _loanID) external view returns (uint256) {

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);

        return _timeSinceInterestAccrual(synthLoan);
    }



    function openLoan(uint256 _loanAmount)
        external
        payable
        notPaused
        nonReentrant
        ETHRateNotInvalid
        returns (uint256 loanID)
    {
        systemStatus().requireIssuanceActive();


        require(
            msg.value >= minLoanCollateralSize,
            "Not enough ETH to create this loan. Please see the minLoanCollateralSize"
        );


        require(loanLiquidationOpen == false, "Loans are now being liquidated");


        require(accountsSynthLoans[msg.sender].length < accountLoanLimit, "Each account is limted to 50 loans");


        uint256 maxLoanAmount = loanAmountFromCollateral(msg.value);



        require(_loanAmount <= maxLoanAmount, "Loan amount exceeds max borrowing power");

        uint256 mintingFee = _calculateMintingFee(_loanAmount);
        uint256 loanAmountMinusFee = _loanAmount.sub(mintingFee);


        require(totalIssuedSynths.add(_loanAmount) <= issueLimit, "Loan Amount exceeds the supply cap.");


        loanID = _incrementTotalLoansCounter();


        SynthLoanStruct memory synthLoan = SynthLoanStruct({
            account: msg.sender,
            collateralAmount: msg.value,
            loanAmount: _loanAmount,
            mintingFee: mintingFee,
            timeCreated: now,
            loanID: loanID,
            timeClosed: 0,
            loanInterestRate: interestRate,
            accruedInterest: 0,
            lastInterestAccrued: 0
        });


        if (mintingFee > 0) {
            synthsUSD().issue(FEE_ADDRESS, mintingFee);
            feePool().recordFeePaid(mintingFee);
        }


        accountsSynthLoans[msg.sender].push(synthLoan);


        totalIssuedSynths = totalIssuedSynths.add(_loanAmount);


        synthsUSD().issue(msg.sender, loanAmountMinusFee);


        emit LoanCreated(msg.sender, loanID, _loanAmount);
    }

    function closeLoan(uint256 loanID) external nonReentrant ETHRateNotInvalid {
        _closeLoan(msg.sender, loanID, false);
    }


    function depositCollateral(address account, uint256 loanID) external payable notPaused {
        systemStatus().requireIssuanceActive();


        require(loanLiquidationOpen == false, "Loans are now being liquidated");


        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);


        require(synthLoan.loanID > 0, "Loan does not exist");
        require(synthLoan.timeClosed == 0, "Loan already closed");

        uint256 totalCollateral = synthLoan.collateralAmount.add(msg.value);

        _updateLoanCollateral(synthLoan, totalCollateral);


        emit CollateralDeposited(account, loanID, msg.value, totalCollateral);
    }


    function withdrawCollateral(uint256 loanID, uint256 withdrawAmount)
        external
        payable
        notPaused
        nonReentrant
        ETHRateNotInvalid
    {
        systemStatus().requireIssuanceActive();


        require(loanLiquidationOpen == false, "Loans are now being liquidated");


        SynthLoanStruct memory synthLoan = _getLoanFromStorage(msg.sender, loanID);


        _checkLoanIsOpen(synthLoan);

        uint256 collateralAfter = synthLoan.collateralAmount.sub(withdrawAmount);

        SynthLoanStruct memory loanAfter = _updateLoanCollateral(synthLoan, collateralAfter);


        (uint256 collateralRatioAfter, , ) = _loanCollateralRatio(loanAfter);

        require(collateralRatioAfter > liquidationRatio, "Collateral ratio below liquidation after withdraw");


        msg.sender.transfer(withdrawAmount);


        emit CollateralWithdrawn(msg.sender, loanID, withdrawAmount, loanAfter.collateralAmount);
    }

    function repayLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _repayAmount
    ) external nonReentrant ETHRateNotInvalid {
        systemStatus().requireSystemActive();


        require(IERC20(address(synthsUSD())).balanceOf(msg.sender) >= _repayAmount, "Not enough sUSD balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);


        _checkLoanIsOpen(synthLoan);


        uint256 interestAmount = accruedInterestOnLoan(synthLoan.loanAmount, _timeSinceInterestAccrual(synthLoan));



        uint256 newLoanAmount = synthLoan.loanAmount.add(interestAmount).sub(_repayAmount);


        synthsUSD().burn(msg.sender, _repayAmount);


        totalIssuedSynths = totalIssuedSynths.sub(_repayAmount);


        _updateLoan(synthLoan, newLoanAmount, interestAmount, now);

        emit LoanRepaid(_loanCreatorsAddress, _loanID, _repayAmount, newLoanAmount);
    }


    function liquidateLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _debtToCover
    ) external nonReentrant ETHRateNotInvalid {
        systemStatus().requireSystemActive();


        require(IERC20(address(synthsUSD())).balanceOf(msg.sender) >= _debtToCover, "Not enough sUSD balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);


        _checkLoanIsOpen(synthLoan);

        (uint256 collateralRatio, uint256 collateralValue, uint256 interestAmount) = _loanCollateralRatio(synthLoan);

        require(collateralRatio < liquidationRatio, "Collateral ratio above liquidation ratio");


        uint256 totalLoanAmount = synthLoan.loanAmount.add(interestAmount);
        uint256 liquidationAmount = calculateAmountToLiquidate(totalLoanAmount, collateralValue);

        uint256 amountToLiquidate = liquidationAmount > _debtToCover ? liquidationAmount : _debtToCover;


        synthsUSD().burn(msg.sender, amountToLiquidate);


        totalIssuedSynths = totalIssuedSynths.sub(amountToLiquidate);


        uint256 collateralRedeemed = exchangeRates().effectiveValue(sUSD, amountToLiquidate, COLLATERAL);


        uint256 totalCollateralLiquidated = collateralRedeemed.multiplyDecimal(
            SafeDecimalMath.unit().add(liquidationPenalty)
        );


        _updateLoan(synthLoan, totalLoanAmount.sub(amountToLiquidate), interestAmount, now);


        msg.sender.transfer(totalCollateralLiquidated);


        emit LoanPartiallyLiquidated(
            _loanCreatorsAddress,
            _loanID,
            msg.sender,
            amountToLiquidate,
            totalCollateralLiquidated
        );
    }


    function liquidateUnclosedLoan(address _loanCreatorsAddress, uint256 _loanID) external nonReentrant ETHRateNotInvalid {
        require(loanLiquidationOpen, "Liquidation is not open");

        _closeLoan(_loanCreatorsAddress, _loanID, true);

        emit LoanLiquidated(_loanCreatorsAddress, _loanID, msg.sender);
    }



    function _closeLoan(
        address account,
        uint256 loanID,
        bool liquidation
    ) private {
        systemStatus().requireIssuanceActive();


        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);


        _checkLoanIsOpen(synthLoan);



        uint256 interestAmount = accruedInterestOnLoan(synthLoan.loanAmount, _timeSinceInterestAccrual(synthLoan));
        uint256 repayAmount = synthLoan.loanAmount.add(interestAmount);

        uint256 totalAccruedInterest = synthLoan.accruedInterest.add(interestAmount);

        require(
            IERC20(address(synthsUSD())).balanceOf(msg.sender) >= repayAmount,
            "You do not have the required Synth balance to close this loan."
        );


        _recordLoanClosure(synthLoan);


        totalIssuedSynths = totalIssuedSynths.sub(synthLoan.loanAmount);


        synthsUSD().burn(msg.sender, repayAmount);


        synthsUSD().issue(FEE_ADDRESS, totalAccruedInterest);
        feePool().recordFeePaid(totalAccruedInterest);

        uint256 remainingCollateral = synthLoan.collateralAmount;

        if (liquidation) {

            uint256 collateralRedeemed = exchangeRates().effectiveValue(sUSD, repayAmount, COLLATERAL);


            uint256 totalCollateralLiquidated = collateralRedeemed.multiplyDecimal(
                SafeDecimalMath.unit().add(liquidationPenalty)
            );



            remainingCollateral = remainingCollateral.sub(totalCollateralLiquidated);


            msg.sender.transfer(totalCollateralLiquidated);
        }


        synthLoan.account.transfer(remainingCollateral);


        emit LoanClosed(account, loanID, totalAccruedInterest);
    }

    function _getLoanFromStorage(address account, uint256 loanID) private view returns (SynthLoanStruct memory) {
        SynthLoanStruct[] memory synthLoans = accountsSynthLoans[account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == loanID) {
                return synthLoans[i];
            }
        }
    }

    function _updateLoan(
        SynthLoanStruct memory _synthLoan,
        uint256 _newLoanAmount,
        uint256 _newAccruedInterest,
        uint256 _lastInterestAccrued
    ) private {

        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].loanAmount = _newLoanAmount;
                synthLoans[i].accruedInterest = synthLoans[i].accruedInterest.add(_newAccruedInterest);
                synthLoans[i].lastInterestAccrued = uint40(_lastInterestAccrued);
            }
        }
    }

    function _updateLoanCollateral(SynthLoanStruct memory _synthLoan, uint256 _newCollateralAmount)
        private
        returns (SynthLoanStruct memory)
    {

        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].collateralAmount = _newCollateralAmount;
                return synthLoans[i];
            }
        }
    }

    function _recordLoanClosure(SynthLoanStruct memory synthLoan) private {

        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == synthLoan.loanID) {

                synthLoans[i].timeClosed = now;
            }
        }


        totalOpenLoanCount = totalOpenLoanCount.sub(1);
    }

    function _incrementTotalLoansCounter() private returns (uint256) {

        totalOpenLoanCount = totalOpenLoanCount.add(1);

        totalLoansCreated = totalLoansCreated.add(1);

        return totalLoansCreated;
    }

    function _calculateMintingFee(uint256 _loanAmount) private view returns (uint256 mintingFee) {
        mintingFee = _loanAmount.multiplyDecimalRound(issueFeeRate);
    }

    function _timeSinceInterestAccrual(SynthLoanStruct memory _synthLoan) private view returns (uint256 timeSinceAccrual) {


        uint256 lastInterestAccrual = _synthLoan.lastInterestAccrued > 0
            ? uint256(_synthLoan.lastInterestAccrued)
            : _synthLoan.timeCreated;



        timeSinceAccrual = _synthLoan.timeClosed > 0
            ? _synthLoan.timeClosed.sub(lastInterestAccrual)
            : now.sub(lastInterestAccrual);
    }

    function _checkLoanIsOpen(SynthLoanStruct memory _synthLoan) internal pure {
        require(_synthLoan.loanID > 0, "Loan does not exist");
        require(_synthLoan.timeClosed == 0, "Loan already closed");
    }


















































