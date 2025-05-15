













pragma solidity 0.6.12;

import "./BToken.sol";
import "./BMath.sol";
import "../interfaces/IPoolRestrictions.sol";
import "../interfaces/BPoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract BPool is BToken, BMath, BPoolInterface {
    using SafeERC20 for IERC20;

    struct Record {
        bool bound;
        uint index;
        uint denorm;
        uint balance;
    }









































































































































    function isBound(address t)
        external view override
        returns (bool)
    {
        return _records[t].bound;
    }





    function getNumTokens()
        external view
        returns (uint)
    {
        return _tokens.length;
    }





    function getCurrentTokens()
        external view override
        _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }





    function getFinalTokens()
        external view override
        _viewlock_
        returns (address[] memory tokens)
    {
        _requireContractIsFinalized();
        return _tokens;
    }






    function getDenormalizedWeight(address token)
        external view override
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return _getDenormWeight(token);
    }





    function getTotalDenormalizedWeight()
        external view override
        _viewlock_
        returns (uint)
    {
        return _getTotalWeight();
    }






    function getNormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return bdiv(_getDenormWeight(token), _getTotalWeight());
    }






    function getBalance(address token)
        external view override
        _viewlock_
        returns (uint)
    {

        _requireTokenIsBound(token);
        return _records[token].balance;
    }







    function isSwapsDisabled()
        external view override
        returns (bool)
    {
        return _swapsDisabled;
    }





    function isFinalized()
        external view override
        returns (bool)
    {
        return _finalized;
    }





    function getSwapFee()
        external view override
        _viewlock_
        returns (uint)
    {
        return _swapFee;
    }








    function getCommunityFee()
        external view override
        _viewlock_
        returns (uint communitySwapFee, uint communityJoinFee, uint communityExitFee, address communityFeeReceiver)
    {
        return (_communitySwapFee, _communityJoinFee, _communityExitFee, _communityFeeReceiver);
    }





    function getController()
        external view
        _viewlock_
        returns (address)
    {
        return _controller;
    }





    function getWrapper()
        external view
        _viewlock_
        returns (address)
    {
        return _wrapper;
    }





    function getWrapperMode()
        external view
        _viewlock_
        returns (bool)
    {
        return _wrapperMode;
    }





    function getRestrictions()
        external view override
        _viewlock_
        returns (address)
    {
        return address(_restrictions);
    }








    function setSwapFee(uint swapFee)
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _requireFeeInBounds(swapFee);
        _swapFee = swapFee;
    }









    function setCommunityFeeAndReceiver(
        uint communitySwapFee,
        uint communityJoinFee,
        uint communityExitFee,
        address communityFeeReceiver
    )
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _requireFeeInBounds(communitySwapFee);
        _requireFeeInBounds(communityJoinFee);
        _requireFeeInBounds(communityExitFee);
        _communitySwapFee = communitySwapFee;
        _communityJoinFee = communityJoinFee;
        _communityExitFee = communityExitFee;
        _communityFeeReceiver = communityFeeReceiver;
    }





    function setRestrictions(IPoolRestrictions restrictions)
        external
        _logs_
        _lock_
    {
        _onlyController();
        _restrictions = restrictions;
    }





    function setController(address manager)
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _controller = manager;
    }





    function setSwapsDisabled(bool disabled_)
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _swapsDisabled = disabled_;
    }






    function setWrapper(address wrapper, bool wrapperMode)
        external
        _logs_
        _lock_
    {
        _onlyController();
        _wrapper = wrapper;
        _wrapperMode = wrapperMode;
    }




    function finalize()
        external override
        _logs_
        _lock_
    {
        _onlyController();
        _requireContractIsNotFinalized();
        require(_tokens.length >= MIN_BOUND_TOKENS, "MIN_TOKENS");

        _finalized = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }













    function callVoting(address voting, bytes4 signature, bytes calldata args, uint256 value)
        external override
        _logs_
        _lock_
    {
        require(_restrictions.isVotingSignatureAllowed(voting, signature), "NOT_ALLOWED_SIG");
        _onlyController();

        (bool success, bytes memory data) = voting.call{ value: value }(abi.encodePacked(signature, args));
        require(success, "NOT_SUCCESS");
        emit LOG_CALL_VOTING(voting, success, signature, args, data);
    }









    function bind(address token, uint balance, uint denorm)
        public override
        virtual
        _logs_

    {
        _onlyController();
        require(!_records[token].bound, "IS_BOUND");

        require(_tokens.length < MAX_BOUND_TOKENS, "MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0,
            balance: 0
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }







    function rebind(address token, uint balance, uint denorm)
        public override
        virtual
        _logs_
        _lock_
    {
        _onlyController();
        _requireTokenIsBound(token);

        require(denorm >= MIN_WEIGHT && denorm <= MAX_WEIGHT, "WEIGHT_BOUNDS");
        require(balance >= MIN_BALANCE, "MIN_BALANCE");



        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _addTotalWeight(bsub(denorm, oldWeight));
        } else if (denorm < oldWeight) {
            _subTotalWeight(bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;


        uint oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
            _pushUnderlying(token, msg.sender, tokenBalanceWithdrawn);
        }
    }






    function unbind(address token)
        public override
        virtual
        _logs_
        _lock_
    {
        _onlyController();
        _requireTokenIsBound(token);

        uint tokenBalance = _records[token].balance;

        _subTotalWeight(_records[token].denorm);



        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({
            bound: false,
            index: 0,
            denorm: 0,
            balance: 0
        });

        _pushUnderlying(token, msg.sender, tokenBalance);
    }





    function gulp(address token)
        external override
    {
    }










    function getSpotPrice(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound && _records[tokenOut].bound, "NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, _getDenormWeight(tokenIn), outRecord.balance, _getDenormWeight(tokenOut), _swapFee);
    }







    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        _requireTokenIsBound(tokenIn);
        _requireTokenIsBound(tokenOut);
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, _getDenormWeight(tokenIn), outRecord.balance, _getDenormWeight(tokenOut), 0);
    }

  function calcTokensForAmount(uint256 _amount) external view returns (address[] memory tokens, uint256[] memory amounts)
  {
    tokens = _tokens;
    amounts = new uint256[](tokens.length);
    uint poolTotal = totalSupply();
    uint256 ratio = bdiv(_amount, poolTotal);

    for (uint256 i = 0; i < tokens.length; i++) {
      address t = tokens[i];
      uint256 bal = _records[t].balance;
      uint256 amount = bmul(ratio, bal);
      amounts[i] = amount;
    }
  }









    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external override
        _logs_
        _lock_
    {
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireContractIsFinalized();

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        _requireMathApprox(ratio);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            _requireMathApprox(tokenAmountIn);
            require(tokenAmountIn < maxAmountsIn[i], "LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }







        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);


    }












    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external override
        _logs_
        _lock_
    {
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireContractIsFinalized();

        (uint poolAmountInAfterFee, uint poolAmountInFee) = calcAmountWithCommunityFee(
            poolAmountIn,
            _communityExitFee,
            msg.sender
        );

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountInAfterFee, poolTotal);
        _requireMathApprox(ratio);

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_communityFeeReceiver, poolAmountInFee);
        _burnPoolShare(poolAmountInAfterFee);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            _requireMathApprox(tokenAmountOut);
            require(tokenAmountOut > minAmountsOut[i], "LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, address(this), poolAmountInFee);
    }













    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    )
        external override
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {
        _checkSwapsDisabled();
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);
        _requireTokenIsBound(tokenOut);

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    _getDenormWeight(tokenIn),
                                    outRecord.balance,
                                    _getDenormWeight(tokenOut),
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "LIMIT_PRICE");

        (uint tokenAmountInAfterFee, uint tokenAmountInFee) = calcAmountWithCommunityFee(
                                                                tokenAmountIn,
                                                                _communitySwapFee,
                                                                msg.sender
                                                            );

        require(tokenAmountInAfterFee <= bmul(inRecord.balance, MAX_IN_RATIO), "MAX_IN_RATIO");

        tokenAmountOut = calcOutGivenIn(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            tokenAmountInAfterFee,
                            _swapFee
                        );
        require(tokenAmountOut >= minAmountOut, "LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountInAfterFee);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                _getDenormWeight(tokenIn),
                                outRecord.balance,
                                _getDenormWeight(tokenOut),
                                _swapFee
                            );
        require(
            spotPriceAfter >= spotPriceBefore &&
            spotPriceBefore <= bdiv(tokenAmountInAfterFee, tokenAmountOut),
            "MATH_APPROX"
        );
        require(spotPriceAfter <= maxPrice, "LIMIT_PRICE");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountInAfterFee, tokenAmountOut);

        _pullCommunityFeeUnderlying(tokenIn, msg.sender, tokenAmountInFee);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountInAfterFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenIn, tokenAmountInFee);

        return (tokenAmountOut, spotPriceAfter);
    }















    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external override
        _logs_
        _lock_
        returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        _checkSwapsDisabled();
        _preventSameTxOrigin();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);
        _requireTokenIsBound(tokenOut);

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "OUT_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    _getDenormWeight(tokenIn),
                                    outRecord.balance,
                                    _getDenormWeight(tokenOut),
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "LIMIT_PRICE");

        (uint tokenAmountOutAfterFee, uint tokenAmountOutFee) = calcAmountWithCommunityFee(
            tokenAmountOut,
            _communitySwapFee,
            msg.sender
        );

        tokenAmountIn = calcInGivenOut(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            tokenAmountOut,
                            _swapFee
                        );
        require(tokenAmountIn <= maxAmountIn, "LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                _getDenormWeight(tokenIn),
                                outRecord.balance,
                                _getDenormWeight(tokenOut),
                                _swapFee
                            );
        require(
            spotPriceAfter >= spotPriceBefore &&
            spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOutAfterFee),
            "MATH_APPROX"
        );
        require(spotPriceAfter <= maxPrice, "LIMIT_PRICE");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOutAfterFee);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOutAfterFee);
        _pushUnderlying(tokenOut, _communityFeeReceiver, tokenAmountOutFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenOut, tokenAmountOutFee);

        return (tokenAmountIn, spotPriceAfter);
    }













    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
        external override
        _logs_
        _lock_
        returns (uint poolAmountOut)

    {
        _checkSwapsDisabled();
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "MAX_IN_RATIO");

        (uint tokenAmountInAfterFee, uint tokenAmountInFee) = calcAmountWithCommunityFee(
            tokenAmountIn,
            _communityJoinFee,
            msg.sender
        );

        Record storage inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            _totalSupply,
                            _getTotalWeight(),
                            tokenAmountInAfterFee,
                            _swapFee
                        );

        require(poolAmountOut >= minPoolAmountOut, "LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountInAfterFee);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountInAfterFee);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullCommunityFeeUnderlying(tokenIn, msg.sender, tokenAmountInFee);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountInAfterFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenIn, tokenAmountInFee);

        return poolAmountOut;
    }












    function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn)
        external override
        _logs_
        _lock_
        returns (uint tokenAmountIn)
    {
        _checkSwapsDisabled();
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenIn);

        Record storage inRecord = _records[tokenIn];

        (uint poolAmountOutAfterFee, uint poolAmountOutFee) = calcAmountWithCommunityFee(
            poolAmountOut,
            _communityJoinFee,
            msg.sender
        );

        tokenAmountIn = calcSingleInGivenPoolOut(
                            inRecord.balance,
                            _getDenormWeight(tokenIn),
                            _totalSupply,
                            _getTotalWeight(),
                            poolAmountOut,
                            _swapFee
                        );

        _requireMathApprox(tokenAmountIn);
        require(tokenAmountIn <= maxAmountIn, "LIMIT_IN");

        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "MAX_IN_RATIO");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOutAfterFee);
        _pushPoolShare(_communityFeeReceiver, poolAmountOutFee);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, address(this), poolAmountOutFee);

        return tokenAmountIn;
    }













    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
        external override
        _logs_
        _lock_
        returns (uint tokenAmountOut)
    {
        _checkSwapsDisabled();
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenOut);

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            _totalSupply,
                            _getTotalWeight(),
                            poolAmountIn,
                            _swapFee
                        );

        require(tokenAmountOut >= minAmountOut, "LIMIT_OUT");

        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "OUT_RATIO");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        (uint tokenAmountOutAfterFee, uint tokenAmountOutFee) = calcAmountWithCommunityFee(
            tokenAmountOut,
            _communityExitFee,
            msg.sender
        );

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOutAfterFee);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOutAfterFee);
        _pushUnderlying(tokenOut, _communityFeeReceiver, tokenAmountOutFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenOut, tokenAmountOutFee);

        return tokenAmountOutAfterFee;
    }













    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn)
        external override
        _logs_
        _lock_
        returns (uint poolAmountIn)
    {
        _checkSwapsDisabled();
        _preventSameTxOrigin();
        _requireContractIsFinalized();
        _onlyWrapperOrNotWrapperMode();
        _requireTokenIsBound(tokenOut);
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "OUT_RATIO");

        Record storage outRecord = _records[tokenOut];

        (uint tokenAmountOutAfterFee, uint tokenAmountOutFee) = calcAmountWithCommunityFee(
            tokenAmountOut,
            _communityExitFee,
            msg.sender
        );

        poolAmountIn = calcPoolInGivenSingleOut(
                            outRecord.balance,
                            _getDenormWeight(tokenOut),
                            _totalSupply,
                            _getTotalWeight(),
                            tokenAmountOut,
                            _swapFee
                        );

        _requireMathApprox(poolAmountIn);
        require(poolAmountIn <= maxPoolAmountIn, "LIMIT_IN");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOutAfterFee);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOutAfterFee);
        _pushUnderlying(tokenOut, _communityFeeReceiver, tokenAmountOutFee);

        emit LOG_COMMUNITY_FEE(msg.sender, _communityFeeReceiver, tokenOut, tokenAmountOutFee);

        return poolAmountIn;
    }




















































































































































    function calcAmountWithCommunityFee(
        uint tokenAmountIn,
        uint communityFee,
        address operator
    )
        public view override
        returns (uint tokenAmountInAfterFee, uint tokenAmountFee)
    {
        if (address(_restrictions) != address(0) && _restrictions.isWithoutFee(operator)) {
            return (tokenAmountIn, 0);
        }
        uint adjustedIn = bsub(BONE, communityFee);
        tokenAmountInAfterFee = bmul(tokenAmountIn, adjustedIn);
        tokenAmountFee = bsub(tokenAmountIn, tokenAmountInAfterFee);
        return (tokenAmountInAfterFee, tokenAmountFee);
    }





    function getMinWeight()
        external view override
        returns (uint)
    {
        return MIN_WEIGHT;
    }





    function getMaxBoundTokens()
        external view override
        returns (uint)
    {
      return MAX_BOUND_TOKENS;
    }
}
