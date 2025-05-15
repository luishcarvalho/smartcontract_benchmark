
pragma solidity 0.7.6;


import "./LPoolInterface.sol";
import "../lib/Exponential.sol";
import "../Adminable.sol";
import "../lib/CarefulMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../DelegateInterface.sol";
import "../ControllerInterface.sol";
import "../IWETH.sol";






contract LPool is DelegateInterface, Adminable, LPoolInterface, Exponential, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    constructor() {

    }








    function initialize(
        address underlying_,
        bool isWethPool_,
        address controller_,
        uint256 baseRatePerBlock_,
        uint256 multiplierPerBlock_,
        uint256 jumpMultiplierPerBlock_,
        uint256 kink_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_) public {
        require(underlying_ != address(0), "underlying_ address cannot be 0");
        require(controller_ != address(0), "controller_ address cannot be 0");
        require(msg.sender == admin, "Only allow to be called by admin");
        require(accrualBlockNumber == 0 && borrowIndex == 0, "inited once");


        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "Initial Exchange Rate Mantissa should be greater zero");

        controller = controller_;
        isWethPool = isWethPool_;

        baseRatePerBlock = baseRatePerBlock_;
        multiplierPerBlock = multiplierPerBlock_;
        jumpMultiplierPerBlock = jumpMultiplierPerBlock_;
        kink = kink_;


        accrualBlockNumber = getBlockNumber();
        borrowIndex = 1e25;

        borrowCapFactorMantissa = 0.8e18;

        reserveFactorMantissa = 0.2e18;


        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        _notEntered = true;


        underlying = underlying_;
        IERC20(underlying).totalSupply();
    }










    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (bool) {
        require(dst != address(0), "dst address cannot be 0");














































    function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount);
    }








    function transferFrom(address src, address dst, uint256 amount) external override nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount);
    }









    function approve(address spender, uint256 amount) external override returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }







    function allowance(address owner, address spender) external override view returns (uint256) {
        return transferAllowances[owner][spender];
    }






    function balanceOf(address owner) external override view returns (uint256) {
        return accountTokens[owner];
    }







    function balanceOfUnderlying(address owner) external override returns (uint) {
        Exp memory exchangeRate = Exp({mantissa : exchangeRateCurrent()});
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
        require(mErr == MathError.NO_ERROR, "calc failed");
        return balance;
    }








    function mint(uint mintAmount) external override nonReentrant {
        accrueInterest();

        mintFresh(msg.sender, mintAmount);
    }

    function mintEth() external payable override nonReentrant {
        require(isWethPool, "not eth pool");
        accrueInterest();
        mintFresh(msg.sender, msg.value);
    }






    function redeem(uint redeemTokens) external override nonReentrant {
        accrueInterest();

        redeemFresh(msg.sender, redeemTokens, 0);
    }






    function redeemUnderlying(uint redeemAmount) external override nonReentrant {
        accrueInterest();

        redeemFresh(msg.sender, 0, redeemAmount);
    }

    function borrowBehalf(address borrower, uint borrowAmount) external override nonReentrant {
        accrueInterest();

        borrowFresh(payable(borrower), msg.sender, borrowAmount);
    }






    function repayBorrowBehalf(address borrower, uint repayAmount) external override nonReentrant {
        accrueInterest();

        repayBorrowFresh(msg.sender, borrower, repayAmount, false);
    }

    function repayBorrowEndByOpenLev(address borrower, uint repayAmount) external override nonReentrant {
        accrueInterest();
        repayBorrowFresh(msg.sender, borrower, repayAmount, true);
    }










    function getCashPrior() internal view returns (uint) {
        IERC20 token = IERC20(underlying);
        return token.balanceOf(address(this));
    }










    function doTransferIn(address from, uint amount, bool convertWeth) internal returns (uint) {
        uint balanceBefore = IERC20(underlying).balanceOf(address(this));
        if (isWethPool && convertWeth) {
            IWETH(underlying).deposit{value : msg.value}();
        } else {
            IERC20(underlying).transferFrom(from, address(this), amount);
        }

        uint balanceAfter = IERC20(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "transfer overflow");
        return balanceAfter - balanceBefore;
    }










    function doTransferOut(address payable to, uint amount, bool convertWeth) internal {
        if (isWethPool && convertWeth) {
            IWETH(underlying).withdraw(amount);
            to.transfer(amount);
        } else {
            IERC20(underlying).safeTransfer(to, amount);
        }
    }

    function availableForBorrow() external view override returns (uint){
        uint cash = getCashPrior();
        (MathError err0, uint sum) = addThenSubUInt(cash, totalBorrows, totalReserves);
        if (err0 != MathError.NO_ERROR) {
            return 0;
        }
        (MathError err1, uint maxAvailable) = mulScalarTruncate(Exp({mantissa : sum}), borrowCapFactorMantissa);
        if (err1 != MathError.NO_ERROR) {
            return 0;
        }
        if (totalBorrows > maxAvailable) {
            return 0;
        }
        return maxAvailable - totalBorrows;
    }








    function getAccountSnapshot(address account) external override view returns (uint, uint, uint) {
        uint cTokenBalance = accountTokens[account];
        uint borrowBalance;
        uint exchangeRateMantissa;

        MathError mErr;

        (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
        if (mErr != MathError.NO_ERROR) {
            return (0, 0, 0);
        }

        (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
        if (mErr != MathError.NO_ERROR) {
            return (0, 0, 0);
        }

        return (cTokenBalance, borrowBalance, exchangeRateMantissa);
    }





    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }





    function borrowRatePerBlock() external override view returns (uint) {
        return getBorrowRateInternal(getCashPrior(), totalBorrows, totalReserves);
    }





    function supplyRatePerBlock() external override view returns (uint) {
        return getSupplyRateInternal(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    function utilizationRate(uint cash, uint borrows, uint reserves) internal pure returns (uint) {

        if (borrows == 0) {
            return 0;
        }
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }







    function getBorrowRateInternal(uint cash, uint borrows, uint reserves) internal view returns (uint) {
        uint util = utilizationRate(cash, borrows, reserves);
        if (util <= kink) {
            return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
        } else {
            uint normalRate = kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
            uint excessUtil = util.sub(kink);
            return excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(normalRate);
        }
    }







    function getSupplyRateInternal(uint cash, uint borrows, uint reserves, uint reserveFactor) internal view returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactor);
        uint borrowRate = getBorrowRateInternal(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }




    function totalBorrowsCurrent() external override view returns (uint) {










































    function borrowBalanceCurrent(address account) external view override returns (uint) {
        (MathError err0, uint borrowIndex) = calCurrentBorrowIndex();
        require(err0 == MathError.NO_ERROR, "calc borrow index fail");
        (MathError err1, uint result) = borrowBalanceStoredInternalWithBorrowerIndex(account, borrowIndex);
        require(err1 == MathError.NO_ERROR, "calc fail");
        return result;
    }

    function borrowBalanceStored(address account) external override view returns (uint){
        return accountBorrows[account].principal;
    }







    function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint) {
        return borrowBalanceStoredInternalWithBorrowerIndex(account, borrowIndex);
    }





    function borrowBalanceStoredInternalWithBorrowerIndex(address account, uint borrowIndex) internal view returns (MathError, uint) {











        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }




        (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        return (MathError.NO_ERROR, result);
    }




    function exchangeRateCurrent() public override nonReentrant returns (uint) {
        accrueInterest();
        return exchangeRateStored();
    }






    function exchangeRateStored() public override view returns (uint) {
        (MathError err, uint result) = exchangeRateStoredInternal();
        require(err == MathError.NO_ERROR, "calc fail");
        return result;
    }






    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {




            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        } else {




            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;
            MathError mathErr;

            (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, exchangeRate.mantissa);
        }
    }





    function getCash() external override view returns (uint) {
        return getCashPrior();
    }

    function calCurrentBorrowIndex() internal view returns (MathError, uint) {

























    function accrueInterest() public override {
































        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint borrowIndexNew;
        uint totalReservesNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa : borrowRateMantissa}), blockDelta);
        require(mathErr == MathError.NO_ERROR, 'calc interest factor error');

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        require(mathErr == MathError.NO_ERROR, 'calc interest acc error');

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        require(mathErr == MathError.NO_ERROR, 'calc total borrows error');

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa : reserveFactorMantissa}), interestAccumulated, reservesPrior);
        require(mathErr == MathError.NO_ERROR, 'calc total reserves error');

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        require(mathErr == MathError.NO_ERROR, 'calc borrows index error');





























    function mintFresh(address minter, uint mintAmount) internal sameBlock returns (uint) {
        MintLocalVars memory vars;
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        require(vars.mathErr == MathError.NO_ERROR, 'calc exchangerate error');









        vars.actualMintAmount = doTransferIn(minter, mintAmount, true);






        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa : vars.exchangeRateMantissa}));
        require(vars.mathErr == MathError.NO_ERROR, "calc mint token error");








        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "calc supply new failed");

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "calc tokens new ailed");































    function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal sameBlock {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one be zero");

        RedeemLocalVars memory vars;












            vars.redeemTokens = redeemTokensIn;

            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa : vars.exchangeRateMantissa}), redeemTokensIn);
            require(vars.mathErr == MathError.NO_ERROR, 'calc redeem amount error');
        } else {






            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa : vars.exchangeRateMantissa}));
            require(vars.mathErr == MathError.NO_ERROR, 'calc redeem tokens error');
            vars.redeemAmount = redeemAmountIn;
        }









        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
        require(vars.mathErr == MathError.NO_ERROR, 'calc supply new error');

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
        require(vars.mathErr == MathError.NO_ERROR, 'calc token new error');
        require(getCashPrior() >= vars.redeemAmount, 'cash < redeem');







        doTransferOut(redeemer, vars.redeemAmount, true);























    function borrowFresh(address payable borrower, address payable payee, uint borrowAmount) internal sameBlock {













        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        require(vars.mathErr == MathError.NO_ERROR, 'calc acc borrows error');

        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, 'calc acc borrows error');

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, 'calc total borrows error');







        doTransferOut(payee, borrowAmount, false);




























    function repayBorrowFresh(address payer, address borrower, uint repayAmount, bool isEnd) internal sameBlock returns (uint) {


























        vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount, false);

        if (isEnd) {
            vars.actualRepayAmount = vars.accountBorrows;
        }





        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);

        require(vars.mathErr == MathError.NO_ERROR, "calc acc borrows error");

        if (vars.actualRepayAmount > totalBorrows) {
            vars.totalBorrowsNew = 0;
        } else {
            vars.totalBorrowsNew = totalBorrows - vars.actualRepayAmount;
        }




















    function setController(address newController) external override onlyAdmin {
        address oldController = controller;

        controller = newController;

        emit NewController(oldController, newController);
    }

    function setBorrowCapFactorMantissa(uint newBorrowCapFactorMantissa) external override onlyAdmin {
        borrowCapFactorMantissa = newBorrowCapFactorMantissa;
    }

    function setInterestParams(uint baseRatePerBlock_, uint multiplierPerBlock_, uint jumpMultiplierPerBlock_, uint kink_) external override onlyAdmin {

        if (baseRatePerBlock != 0) {
            accrueInterest();
        }
        baseRatePerBlock = baseRatePerBlock_;
        multiplierPerBlock = multiplierPerBlock_;
        jumpMultiplierPerBlock = jumpMultiplierPerBlock_;
        kink = kink_;
        emit NewInterestParam(baseRatePerBlock_, multiplierPerBlock_, jumpMultiplierPerBlock_, kink_);
    }

    function setReserveFactor(uint newReserveFactorMantissa) external override onlyAdmin {
        accrueInterest();
        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;
        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);
    }

    function addReserves(uint addAmount) external override {
        accrueInterest();
        uint totalReservesNew;
        uint actualAddAmount;
        actualAddAmount = doTransferIn(msg.sender, addAmount, true);
        totalReservesNew = totalReserves.add(actualAddAmount);
        totalReserves = totalReservesNew;
        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);
    }

    function reduceReserves(address payable to, uint reduceAmount) external override onlyAdmin {
        accrueInterest();
        uint totalReservesNew;
        totalReservesNew = totalReserves.sub(reduceAmount);
        totalReserves = totalReservesNew;
        doTransferOut(to, reduceAmount, true);
        emit ReservesReduced(to, reduceAmount, totalReservesNew);
    }

    modifier sameBlock() {
        require(accrualBlockNumber == getBlockNumber(), 'not same block');
        _;
    }

}

