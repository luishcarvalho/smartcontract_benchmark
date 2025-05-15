pragma solidity ^0.5.16;

import "./CToken.sol";
import "./ComptrollerStorage.sol";




interface ComptrollerInterfaceExtension {
    function checkMembership(address account, CToken cToken) external view returns (bool);

    function updateCTokenVersion(address cToken, ComptrollerV2Storage.Version version) external;
}






contract CCollateralCapErc20 is CToken, CCollateralCapErc20Interface {










    function initialize(address underlying_,
                        ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {

        super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);


        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }









    function mint(uint mintAmount) external returns (uint) {
        (uint err,) = mintInternal(mintAmount);
        return err;
    }







    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(redeemTokens);
    }







    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(redeemAmount);
    }






    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(borrowAmount);
    }






    function repayBorrow(uint repayAmount) external returns (uint) {
        (uint err,) = repayBorrowInternal(repayAmount);
        return err;
    }







    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        (uint err,) = repayBorrowBehalfInternal(borrower, repayAmount);
        return err;
    }









    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint) {
        (uint err,) = liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
        return err;
    }






    function _addReserves(uint addAmount) external returns (uint) {
        return _addReservesInternal(addAmount);
    }





    function _setCollateralCap(uint newCollateralCap) external {
        require(msg.sender == admin, "only admin can set collateral cap");

        collateralCap = newCollateralCap;
        emit NewCollateralCap(address(this), newCollateralCap);
    }




    function gulp() external nonReentrant {
        uint256 cashOnChain = getCashOnChain();
        uint256 cashPrior = getCashPrior();

        uint excessCash = sub_(cashOnChain, cashPrior);
        totalReserves = add_(totalReserves, excessCash);
        internalCash = cashOnChain;
    }







    function flashLoan(address receiver, uint amount, bytes calldata params) external nonReentrant {
        uint cashOnChainBefore = getCashOnChain();
        uint cashBefore = getCashPrior();
        require(cashBefore >= amount, "INSUFFICIENT_LIQUIDITY");


        uint totalFee = div_(mul_(amount, flashFeeBips), 10000);


        doTransferOut(address(uint160(receiver)), amount);


        IFlashloanReceiver(receiver).executeOperation(msg.sender, underlying, amount, totalFee, params);


        uint cashOnChainAfter = getCashOnChain();
        require(cashOnChainAfter == add_(cashOnChainBefore, totalFee), "BALANCE_INCONSISTENT");


        uint reservesFee = mul_ScalarTruncate(Exp({mantissa: reserveFactorMantissa}), totalFee);
        totalReserves = add_(totalReserves, reservesFee);
        internalCash = add_(cashBefore, totalFee);

        emit Flashloan(receiver, amount, totalFee, reservesFee);
    }







    function registerCollateral(address account) external returns (uint) {

        initializeAccountCollateralTokens(account);

        require(msg.sender == address(comptroller), "only comptroller may register collateral for user");

        uint amount = sub_(accountTokens[account], accountCollateralTokens[account]);
        return increaseUserCollateralInternal(account, amount);
    }






    function unregisterCollateral(address account) external {

        initializeAccountCollateralTokens(account);

        require(msg.sender == address(comptroller), "only comptroller may unregister collateral for user");

        decreaseUserCollateralInternal(account, accountCollateralTokens[account]);
    }









    function getCashPrior() internal view returns (uint) {
        return internalCash;
    }






    function getCashOnChain() internal view returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(this));
    }






    function initializeAccountCollateralTokens(address account) internal {







        if (!isCollateralTokenInit[account]) {
            if (ComptrollerInterfaceExtension(address(comptroller)).checkMembership(account, CToken(this))) {
                accountCollateralTokens[account] = accountTokens[account];
                totalCollateralTokens = add_(totalCollateralTokens, accountTokens[account]);

                emit UserCollateralChanged(account, accountCollateralTokens[account]);
            }
            isCollateralTokenInit[account] = true;
        }
    }










    function doTransferIn(address from, uint amount) internal returns (uint) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        uint balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    success := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");


        uint balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
        uint transferredIn = sub_(balanceAfter, balanceBefore);
        internalCash = add_(internalCash, transferredIn);
        return transferredIn;
    }










    function doTransferOut(address payable to, uint amount) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    success := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
        internalCash = sub_(internalCash, amount);
    }










    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {

        initializeAccountCollateralTokens(src);
        initializeAccountCollateralTokens(dst);







        uint bufferTokens = sub_(accountTokens[src], accountCollateralTokens[src]);
        uint collateralTokens = 0;
        if (tokens > bufferTokens) {
            collateralTokens = sub_(tokens, bufferTokens);
        }





        uint allowed = comptroller.transferAllowed(address(this), src, dst, collateralTokens);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
        }













































    function getCTokenBalanceInternal(address account) internal view returns (uint) {
        if (isCollateralTokenInit[account]) {
            return accountCollateralTokens[account];
        } else {



            return accountTokens[account];
        }
    }







    function increaseUserCollateralInternal(address account, uint amount) internal returns (uint) {
        uint totalCollateralTokensNew = add_(totalCollateralTokens, amount);
        if (collateralCap == 0 || (collateralCap != 0 && totalCollateralTokensNew <= collateralCap)) {



            totalCollateralTokens = totalCollateralTokensNew;
            accountCollateralTokens[account] = add_(accountCollateralTokens[account], amount);

            emit UserCollateralChanged(account, accountCollateralTokens[account]);
            return amount;
        } else if (collateralCap > totalCollateralTokens) {


            uint gap = sub_(collateralCap, totalCollateralTokens);
            totalCollateralTokens = add_(totalCollateralTokens, gap);
            accountCollateralTokens[account] = add_(accountCollateralTokens[account], gap);

            emit UserCollateralChanged(account, accountCollateralTokens[account]);
            return gap;
        }
        return 0;
    }






    function decreaseUserCollateralInternal(address account, uint amount) internal {
        require(comptroller.redeemAllowed(address(this), account, amount) == 0, "comptroller rejection");

        totalCollateralTokens = sub_(totalCollateralTokens, amount);
        accountCollateralTokens[account] = sub_(accountCollateralTokens[account], amount);

        emit UserCollateralChanged(account, accountCollateralTokens[account]);
    }

    struct MintLocalVars {
        uint exchangeRateMantissa;
        uint mintTokens;
        uint actualMintAmount;
    }








    function mintFresh(address minter, uint mintAmount) internal returns (uint, uint) {

        initializeAccountCollateralTokens(minter);




























        vars.actualMintAmount = doTransferIn(minter, mintAmount);





        vars.mintTokens = div_ScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));






        totalSupply = add_(totalSupply, vars.mintTokens);
        accountTokens[minter] = add_(accountTokens[minter], vars.mintTokens);




        if (ComptrollerInterfaceExtension(address(comptroller)).checkMembership(minter, CToken(this))) {
            increaseUserCollateralInternal(minter, vars.mintTokens);
        }


























    function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal returns (uint) {

        initializeAccountCollateralTokens(redeemer);

        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        RedeemLocalVars memory vars;











            vars.redeemTokens = redeemTokensIn;
            vars.redeemAmount = mul_ScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
        } else {





            vars.redeemTokens = div_ScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
            vars.redeemAmount = redeemAmountIn;
        }







        uint bufferTokens = sub_(accountTokens[redeemer], accountCollateralTokens[redeemer]);
        uint collateralTokens = 0;
        if (vars.redeemTokens > bufferTokens) {
            collateralTokens = sub_(vars.redeemTokens, bufferTokens);
        }





















        doTransferOut(redeemer, vars.redeemAmount);






        totalSupply = sub_(totalSupply, vars.redeemTokens);
        accountTokens[redeemer] = sub_(accountTokens[redeemer], vars.redeemTokens);




        if (collateralTokens > 0) {
            decreaseUserCollateralInternal(redeemer, collateralTokens);
        }





















    function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal returns (uint) {

        initializeAccountCollateralTokens(liquidator);
        initializeAccountCollateralTokens(borrower);



















        accountTokens[borrower] = sub_(accountTokens[borrower], seizeTokens);
        accountTokens[liquidator] = add_(accountTokens[liquidator], seizeTokens);
        accountCollateralTokens[borrower] = sub_(accountCollateralTokens[borrower], seizeTokens);
        accountCollateralTokens[liquidator] = add_(accountCollateralTokens[liquidator], seizeTokens);













