pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./LPToken.sol";
import "./MathUtils.sol";








library SwapUtils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using MathUtils for uint256;







































































































    function getA(Swap storage self) external view returns (uint256) {
        return _getA(self);
    }






    function _getA(Swap storage self) internal view returns (uint256) {
        return _getAPrecise(self).div(A_PRECISION);
    }






    function getAPrecise(Swap storage self) external view returns (uint256) {
        return _getAPrecise(self);
    }






    function _getAPrecise(Swap storage self) internal view returns (uint256) {
        uint256 t1 = self.futureATime;
        uint256 A1 = self.futureA;

        if (block.timestamp < t1) {
            uint256 t0 = self.initialATime;
            uint256 A0 = self.initialA;
            if (A1 > A0) {

                return A0.add(A1.sub(A0).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
            } else {

                return A0.sub(A0.sub(A1).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
            }
        } else {
            return A1;
        }
    }





    function getPoolPrecisionDecimals() external pure returns (uint8) {
        return POOL_PRECISION_DECIMALS;
    }





    function getAPrecision() external pure returns (uint256) {
        return A_PRECISION;
    }





    function getDepositTimestamp(Swap storage self, address user) external view returns (uint256) {
        return self.depositTimestamp[user];
    }







    function calculateWithdrawOneToken(
        Swap storage self, uint256 tokenAmount, uint8 tokenIndex
    ) public view returns(uint256, uint256) {

        uint256 dy;
        uint256 newY;

        (dy, newY) = calculateWithdrawOneTokenDY(self, tokenIndex, tokenAmount);



        return (dy, _xp(self)[tokenIndex].sub(newY).div(
            self.tokenPrecisionMultipliers[tokenIndex]).sub(dy));
    }







    function calculateWithdrawOneTokenDY(
        Swap storage self, uint8 tokenIndex, uint256 tokenAmount
    ) internal view returns(uint256, uint256) {
        require(tokenIndex < self.pooledTokens.length, "Token index out of range");



        uint256[] memory xp = _xp(self);
        CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0);
        v.D0 = getD(xp, _getAPrecise(self));
        v.D1 = v.D0.sub(tokenAmount.mul(v.D0).div(self.lpToken.totalSupply()));

        require(tokenAmount <= xp[tokenIndex], "Cannot withdraw more than available");

        v.newY = getYD(_getAPrecise(self), tokenIndex, xp, v.D1);

        uint256[] memory xpReduced = new uint256[](xp.length);

        v.feePerToken = feePerToken(self);
        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            uint256 xpi = xp[i];



            xpReduced[i] = xpi.sub(
                ((i == tokenIndex) ?
                    xpi.mul(v.D1).div(v.D0).sub(v.newY) :
                    xpi.sub(xpi.mul(v.D1).div(v.D0))
                ).mul(v.feePerToken).div(FEE_DENOMINATOR));
        }

        uint256 dy = xpReduced[tokenIndex].sub(
            getYD(_getAPrecise(self), tokenIndex, xpReduced, v.D1));
        dy = dy.sub(1).div(self.tokenPrecisionMultipliers[tokenIndex]);

        return (dy, v.newY);
    }




















    function getYD(uint256 _A, uint8 tokenIndex, uint256[] memory xp, uint256 D)
        internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(tokenIndex < numTokens, "Token not found");

        uint256 c = D;
        uint256 s;
        uint256 nA = _A.mul(numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            if (i != tokenIndex) {
                s = s.add(xp[i]);
                c = c.mul(D).div(xp[i].mul(numTokens));




            } else {
                continue;
            }
        }
        c = c.mul(D).div(nA.mul(numTokens).div(A_PRECISION));

        uint256 b = s.add(D.mul(A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = D;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(D));
            if(y.within1(yPrev)) {
                break;
            }
        }
        return y;
    }









    function getD(uint256[] memory xp, uint256 _A)
        internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        uint256 s;
        for (uint256 i = 0; i < numTokens; i++) {
            s = s.add(xp[i]);
        }
        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 D = s;
        uint256 nA = _A.mul(numTokens);

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = D;
            for (uint256 j = 0; j < numTokens; j++) {
                dP = dP.mul(D).div(xp[j].mul(numTokens));



            }
            prevD = D;
            D = nA.mul(s).div(A_PRECISION).add(dP.mul(numTokens)).mul(D).div(
                nA.div(A_PRECISION).sub(1).mul(D).add(numTokens.add(1).mul(dP)));
            if (D.within1(prevD)) {
                break;
            }
        }
        return D;
    }





    function getD(Swap storage self)
        internal view returns (uint256) {
        return getD(_xp(self), _getAPrecise(self));
    }














    function _xp(
        uint256[] memory _balances,
        uint256[] memory precisionMultipliers
    ) internal pure returns (uint256[] memory) {
        uint256 numTokens = _balances.length;
        require(
            numTokens == precisionMultipliers.length,
            "Balances must map to token precision multipliers"
        );
        uint256[] memory xp = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            xp[i] = _balances[i].mul(precisionMultipliers[i]);
        }
        return xp;
    }







    function _xp(Swap storage self, uint256[] memory _balances)
        internal view returns (uint256[] memory) {
        return _xp(_balances, self.tokenPrecisionMultipliers);
    }






    function _xp(Swap storage self) internal view returns (uint256[] memory) {
        return _xp(self.balances, self.tokenPrecisionMultipliers);
    }





    function getVirtualPrice(Swap storage self) external view returns (uint256) {
        uint256 D = getD(_xp(self), _getAPrecise(self));
        uint256 supply = self.lpToken.totalSupply();
        return D.mul(10 ** uint256(ERC20Detailed(self.lpToken).decimals())).div(supply);
    }













    function getY(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 x,
        uint256[] memory xp
    ) internal view returns (uint256) {
        uint256 numTokens = self.pooledTokens.length;
        require(tokenIndexFrom != tokenIndexTo, "Can't compare token to itself");
        require(
            tokenIndexFrom < numTokens && tokenIndexTo < numTokens,
            "Tokens must be in pool"
        );

        uint256 _A = _getAPrecise(self);
        uint256 D = getD(xp, _A);
        uint256 c = D;
        uint256 s;
        uint256 nA = numTokens.mul(_A);

        uint256 _x;
        for (uint256 i = 0; i < numTokens; i++) {
            if (i == tokenIndexFrom) {
                _x = x;
            } else if (i != tokenIndexTo) {
                _x = xp[i];
            }
            else {
                continue;
            }
            s = s.add(_x);
            c = c.mul(D).div(_x.mul(numTokens));



        }
        c = c.mul(D).div(nA.mul(numTokens).div(A_PRECISION));
        uint256 b = s.add(D.mul(A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = D;


        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(D));
            if (y.within1(yPrev)) {
                break;
            }
        }
        return y;
    }








    function calculateSwap(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx
    ) external view returns(uint256 dy) {
        (dy, ) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx);
    }













    function _calculateSwap(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx
    ) internal view returns(uint256 dy, uint256 dyFee) {
        uint256[] memory xp = _xp(self);
        require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "Token index out of range");
        uint256 x = dx.mul(self.tokenPrecisionMultipliers[tokenIndexFrom]).add(
            xp[tokenIndexFrom]);
        uint256 y = getY(self, tokenIndexFrom, tokenIndexTo, x, xp);
        dy = xp[tokenIndexTo].sub(y).sub(1);
        dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
        dy = dy.sub(dyFee).div(self.tokenPrecisionMultipliers[tokenIndexTo]);
    }









    function calculateRemoveLiquidity(Swap storage self, uint256 amount)
    external view returns (uint256[] memory) {
        return _calculateRemoveLiquidity(self, amount);
    }

    function _calculateRemoveLiquidity(Swap storage self, uint256 amount)
    internal view returns (uint256[] memory) {
        uint256 totalSupply = self.lpToken.totalSupply();
        require(amount <= totalSupply, "Cannot exceed total supply");
        uint256[] memory amounts = new uint256[](self.pooledTokens.length);

        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            amounts[i] = self.balances[i].mul(amount).div(totalSupply);
        }
        return amounts;
    }







    function calculateCurrentWithdrawFee(Swap storage self, address user) public view returns (uint256) {
        uint256 endTime = self.depositTimestamp[user].add(4 weeks);
        if (endTime > block.timestamp) {
            uint256 timeLeftover = endTime.sub(block.timestamp);
            return self.defaultWithdrawFee
            .mul(self.withdrawFeeMultiplier[user])
            .mul(timeLeftover)
            .div(4 weeks)
            .div(FEE_DENOMINATOR);
        }
    }














    function calculateTokenAmount(
        Swap storage self, uint256[] calldata amounts, bool deposit
    ) external view returns(uint256) {
        uint256 numTokens = self.pooledTokens.length;
        uint256 _A = _getAPrecise(self);
        uint256 D0 = getD(_xp(self, self.balances), _A);
        uint256[] memory balances1 = self.balances;
        for (uint256 i = 0; i < numTokens; i++) {
            if (deposit) {
                balances1[i] = balances1[i].add(amounts[i]);
            } else {
                require(amounts[i] <= balances1[i], "Cannot withdraw more than available");
                balances1[i] = balances1[i].sub(amounts[i]);
            }
        }
        uint256 D1 = getD(_xp(self, balances1), _A);
        uint256 totalSupply = self.lpToken.totalSupply();
        return (deposit ? D1.sub(D0) : D0.sub(D1)).mul(totalSupply).div(D0);
    }






    function getAdminBalance(Swap storage self, uint256 index) external view returns (uint256) {
        require(index < self.pooledTokens.length, "Token index out of range");
        return self.pooledTokens[index].balanceOf(address(this)).sub(self.balances[index]);
    }





    function feePerToken(Swap storage self)
    internal view returns(uint256) {
        return self.swapFee.mul(self.pooledTokens.length).div(
            self.pooledTokens.length.sub(1).mul(4));
    }










    function swap(
        Swap storage self, uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx,
        uint256 minDy
    ) external {
        require(dx <= self.pooledTokens[tokenIndexFrom].balanceOf(msg.sender), "Cannot swap more than you own");
        (uint256 dy, uint256 dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx);
        require(dy >= minDy, "Swap didn't result in min tokens");

        uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(self.tokenPrecisionMultipliers[tokenIndexTo]);

        self.balances[tokenIndexFrom] = self.balances[tokenIndexFrom].add(dx);
        self.balances[tokenIndexTo] = self.balances[tokenIndexTo].sub(dy).sub(dyAdminFee);

        self.pooledTokens[tokenIndexFrom].safeTransferFrom(
            msg.sender, address(this), dx);
        self.pooledTokens[tokenIndexTo].safeTransfer(msg.sender, dy);

        emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);
    }







    function addLiquidity(Swap storage self, uint256[] calldata amounts, uint256 minToMint)
        external {
        require(
            amounts.length == self.pooledTokens.length,
            "Amounts must map to pooled tokens"
        );

        uint256[] memory fees = new uint256[](self.pooledTokens.length);


        uint256 D0;
        if (self.lpToken.totalSupply() != 0) {
            D0 = getD(self);
        }
        uint256[] memory newBalances = self.balances;

        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            require(
                self.lpToken.totalSupply() != 0 || amounts[i] > 0,
                "If token supply is zero, must supply all tokens in pool"
            );
            newBalances[i] = self.balances[i].add(amounts[i]);
        }


        uint256 D1 = getD(_xp(self, newBalances), _getAPrecise(self));
        require(D1 > D0, "D should increase after additional liquidity");


        uint256 D2 = D1;
        if (self.lpToken.totalSupply() != 0) {
            uint256 feePerToken_ = feePerToken(self);
            for (uint256 i = 0; i < self.pooledTokens.length; i++) {
                uint256 idealBalance = D1.mul(self.balances[i]).div(D0);
                fees[i] = feePerToken_.mul(
                    idealBalance.difference(newBalances[i])).div(FEE_DENOMINATOR);
                self.balances[i] = newBalances[i].sub(
                    fees[i].mul(self.adminFee).div(FEE_DENOMINATOR));
                newBalances[i] = newBalances[i].sub(fees[i]);
            }
            D2 = getD(_xp(self, newBalances), _getAPrecise(self));
        } else {

            self.balances = newBalances;
        }

        uint256 toMint;
        if (self.lpToken.totalSupply() == 0) {
            toMint = D1;
        } else {
            toMint = D2.sub(D0).mul(self.lpToken.totalSupply()).div(D0);
        }

        require(toMint >= minToMint, "Couldn't mint min requested LP tokens");


        _updateUserWithdrawFee(self, msg.sender, toMint);


        self.lpToken.mint(msg.sender, toMint);

        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            if (amounts[i] != 0) {
                self.pooledTokens[i].safeTransferFrom(
                    msg.sender, address(this), amounts[i]);
            }
        }

        emit AddLiquidity(
            msg.sender, amounts, fees, D1, self.lpToken.totalSupply()
        );
    }










    function updateUserWithdrawFee(Swap storage self, address user, uint256 toMint) external {
        _updateUserWithdrawFee(self, user, toMint);
    }

    function _updateUserWithdrawFee(Swap storage self, address user, uint256 toMint) internal {
        uint256 currentFee = calculateCurrentWithdrawFee(self, user);
        uint256 currentBalance = self.lpToken.balanceOf(user);



        self.withdrawFeeMultiplier[user] = currentBalance.mul(currentFee)
            .add(toMint.mul(self.defaultWithdrawFee.add(1))).mul(FEE_DENOMINATOR)
            .div(toMint.add(currentBalance).mul(self.defaultWithdrawFee.add(1)));

        self.depositTimestamp[user] = block.timestamp;
    }








    function removeLiquidity(
        Swap storage self, uint256 amount, uint256[] calldata minAmounts
    ) external {
        require(amount <= self.lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(
            minAmounts.length == self.pooledTokens.length,
            "Min amounts should correspond to pooled tokens"
        );

        uint256 adjustedAmount = amount
            .mul(FEE_DENOMINATOR.sub(calculateCurrentWithdrawFee(self, msg.sender)))
            .div(FEE_DENOMINATOR);

        uint256[] memory amounts = _calculateRemoveLiquidity(self, adjustedAmount);

        for (uint256 i = 0; i < amounts.length; i++) {
            require(
                amounts[i] >= minAmounts[i],
                "Resulted in fewer tokens than expected"
            );
            self.balances[i] = self.balances[i].sub(amounts[i]);
        }

        self.lpToken.burnFrom(msg.sender, amount);

        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            self.pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidity(
            msg.sender, amounts, self.lpToken.totalSupply()
        );
    }







    function removeLiquidityOneToken(
        Swap storage self, uint256 tokenAmount, uint8 tokenIndex,
        uint256 minAmount
    ) external {
        uint256 totalSupply = self.lpToken.totalSupply();
        uint256 numTokens = self.pooledTokens.length;
        require(tokenAmount <= self.lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(tokenIndex < numTokens, "Token not found");

        uint256 dyFee;
        uint256 dy;

        (dy, dyFee) = calculateWithdrawOneToken(self, tokenAmount, tokenIndex);
        dy = dy
        .mul(FEE_DENOMINATOR.sub(calculateCurrentWithdrawFee(self, msg.sender)))
        .div(FEE_DENOMINATOR);

        require(dy >= minAmount, "The min amount of tokens wasn't met");

        self.balances[tokenIndex] = self.balances[tokenIndex].sub(
            dy.add(dyFee.mul(self.adminFee).div(FEE_DENOMINATOR))
        );
        self.lpToken.burnFrom(msg.sender, tokenAmount);
        self.pooledTokens[tokenIndex].safeTransfer(msg.sender, dy);

        emit RemoveLiquidityOne(
            msg.sender, tokenAmount, totalSupply, tokenIndex, dy
        );
    }









    function removeLiquidityImbalance(
        Swap storage self, uint256[] memory amounts, uint256 maxBurnAmount
    ) public {
        require(
            amounts.length == self.pooledTokens.length,
            "Amounts should correspond to pooled tokens"
        );
        require(maxBurnAmount <= self.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, ">LP.balanceOf");

        uint256 tokenSupply = self.lpToken.totalSupply();
        uint256 _fee = feePerToken(self);

        uint256[] memory balances1 = self.balances;

        uint256 D0 = getD(_xp(self), _getAPrecise(self));
        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            require(amounts[i] <= balances1[i], "Cannot withdraw more than available");
            balances1[i] = balances1[i].sub(amounts[i]);
        }
        uint256 D1 = getD(_xp(self, balances1), _getAPrecise(self));
        uint256[] memory fees = new uint256[](self.pooledTokens.length);

        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            uint256 idealBalance = D1.mul(self.balances[i]).div(D0);
            uint256 difference = idealBalance.difference(balances1[i]);
            fees[i] = _fee.mul(difference).div(FEE_DENOMINATOR);
            self.balances[i] = balances1[i].sub(fees[i].mul(self.adminFee).div(
                FEE_DENOMINATOR));
            balances1[i] = balances1[i].sub(fees[i]);
        }

        uint256 D2 = getD(_xp(self, balances1), _getAPrecise(self));

        uint256 tokenAmount = D0.sub(D2).mul(tokenSupply).div(D0);
        require(tokenAmount != 0, "Burnt amount cannot be zero");
        tokenAmount = tokenAmount
            .add(1)
            .mul(FEE_DENOMINATOR)
            .div(FEE_DENOMINATOR.sub(calculateCurrentWithdrawFee(self, msg.sender)));

        require(
            tokenAmount <= maxBurnAmount,
            "More expensive than the max burn amount"
        );

        self.lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            self.pooledTokens[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(
            msg.sender, amounts, fees, D1, tokenSupply.sub(tokenAmount));
    }





    function withdrawAdminFees(Swap storage self, address to) external {
        for (uint256 i = 0; i < self.pooledTokens.length; i++) {
            IERC20 token = self.pooledTokens[i];
            uint256 balance = token.balanceOf(address(this)).sub(self.balances[i]);
            if (balance != 0) {
                token.safeTransfer(to, balance);
            }
        }
    }






    function setAdminFee(Swap storage self, uint256 newAdminFee) external {
        require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
        self.adminFee = newAdminFee;

        emit NewAdminFee(newAdminFee);
    }






    function setSwapFee(Swap storage self, uint256 newSwapFee) external {
        require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
        self.swapFee = newSwapFee;

        emit NewSwapFee(newSwapFee);
    }





    function setDefaultWithdrawFee(Swap storage self, uint256 newWithdrawFee) external {
        require(newWithdrawFee <= MAX_WITHDRAW_FEE, "Fee is too high");
        self.defaultWithdrawFee = newWithdrawFee;

        emit NewWithdrawFee(newWithdrawFee);
    }








    function rampA(Swap storage self, uint256 futureA_, uint256 futureTime_) external {
        require(
            block.timestamp >= self.initialATime.add(1 days),
            "New ramp cannot be started until 1 day has passed"
        );
        require(futureTime_ >= block.timestamp.add(MIN_RAMP_TIME), "Insufficient ramp time");
        require(futureA_ > 0 && futureA_ < MAX_A, "futureA_ must be between 0 and MAX_A");

        uint256 initialAPrecise = _getAPrecise(self);
        uint256 futureAPrecise = futureA_.mul(A_PRECISION);

        if (futureAPrecise < initialAPrecise) {
            require(futureAPrecise.mul(MAX_A_CHANGE) >= initialAPrecise, "futureA_ is too small");
        } else {
            require(futureAPrecise <= initialAPrecise.mul(MAX_A_CHANGE), "futureA_ is too large");
        }

        self.initialA = initialAPrecise;
        self.futureA = futureAPrecise;
        self.initialATime = block.timestamp;
        self.futureATime = futureTime_;

        emit RampA(initialAPrecise, futureAPrecise, block.timestamp, futureTime_);
    }





    function stopRampA(Swap storage self) external {
        require(self.futureATime > block.timestamp, "Ramp is already stopped");
        uint256 currentA = _getAPrecise(self);

        self.initialA = currentA;
        self.futureA = currentA;
        self.initialATime = block.timestamp;
        self.futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}
