
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Decimals.sol";
import "./balancer-core-v2/lib/math/LogExpMath.sol";
import "./balancer-core-v2/lib/math/FixedPoint.sol";
import "./balancer-core-v2/vault/interfaces/IMinimalSwapInfoPool.sol";
import "./balancer-core-v2/vault/interfaces/IVault.sol";
import "./balancer-core-v2/pools/BalancerPoolToken.sol";

contract ConvergentCurvePool is IMinimalSwapInfoPool, BalancerPoolToken {
    using LogExpMath for uint256;
    using FixedPoint for uint256;


    IERC20 public immutable underlying;
    uint8 public immutable underlyingDecimals;

    IERC20 public immutable bond;
    uint8 public immutable bondDecimals;

    uint256 public immutable expiration;

    uint256 public immutable unitSeconds;


    IVault private immutable _vault;
    bytes32 private immutable _poolId;


    uint128 public feesUnderlying;
    uint128 public feesBond;

    address public governance;

    uint256 public immutable percentFee;

    uint256 public immutable percentFeeGov;













    constructor(
        IERC20 _underlying,
        IERC20 _bond,
        uint256 _expiration,
        uint256 _unitSeconds,
        IVault vault,
        uint256 _percentFee,
        uint256 _percentFeeGov,
        address _governance,
        string memory name,
        string memory symbol
    ) BalancerPoolToken(name, symbol) {

        bytes32 poolId = vault.registerPool(
            IVault.PoolSpecialization.TWO_TOKEN
        );

        IERC20[] memory tokens = new IERC20[](2);
        if (_underlying < _bond) {
            tokens[0] = _underlying;
            tokens[1] = _bond;
        } else {
            tokens[0] = _bond;
            tokens[1] = _underlying;
        }




        vault.registerTokens(poolId, tokens, new address[](2));


        _vault = vault;
        _poolId = poolId;
        percentFee = _percentFee;
        percentFeeGov = _percentFeeGov;
        underlying = _underlying;
        underlyingDecimals = IERC20Decimals(address(_underlying)).decimals();
        bond = _bond;
        bondDecimals = IERC20Decimals(address(_bond)).decimals();
        expiration = _expiration;
        unitSeconds = _unitSeconds;
        governance = _governance;
    }


    function getRate() external override view returns (uint256) {

        return FixedPoint.ONE;
    }



    function getVault() external view returns (IVault) {
        return _vault;
    }



    function getPoolId() external view returns (bytes32) {
        return _poolId;
    }








    function onSwapGivenIn(
        IPoolSwapStructs.SwapRequestGivenIn calldata request,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) public override returns (uint256) {


        uint256 amountTokenIn = _tokenToFixed(
            request.amountIn,
            request.tokenIn
        );




        (uint256 tokenInReserve, uint256 tokenOutReserve) = _adjustedReserve(
            currentBalanceTokenIn,
            request.tokenIn,
            currentBalanceTokenOut,
            request.tokenOut
        );

        tokenInReserve = _tokenToFixed(tokenInReserve, request.tokenIn);
        tokenOutReserve = _tokenToFixed(tokenOutReserve, request.tokenOut);


        uint256 quote = solveTradeInvariant(
            amountTokenIn,
            tokenInReserve,
            tokenOutReserve,
            true
        );


        quote = _assignTradeFee(amountTokenIn, quote, request.tokenOut, false);
        return _fixedToToken(quote, request.tokenOut);
    }







    function onSwapGivenOut(
        IPoolSwapStructs.SwapRequestGivenOut calldata request,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) public override returns (uint256) {


        uint256 amountTokenOut = _tokenToFixed(
            request.amountOut,
            request.tokenOut
        );




        (uint256 tokenInReserve, uint256 tokenOutReserve) = _adjustedReserve(
            currentBalanceTokenIn,
            request.tokenIn,
            currentBalanceTokenOut,
            request.tokenOut
        );


        tokenInReserve = _tokenToFixed(tokenInReserve, request.tokenIn);
        tokenOutReserve = _tokenToFixed(tokenOutReserve, request.tokenOut);


        uint256 quote = solveTradeInvariant(
            amountTokenOut,
            tokenOutReserve,
            tokenInReserve,
            false
        );

        quote = _assignTradeFee(quote, amountTokenOut, request.tokenOut, true);

        return _fixedToToken(quote, request.tokenIn);
    }



    function _getSortedBalances(uint256[] memory currentBalances)
        internal
        view
        returns (uint256 underlyingBalance, uint256 bondBalance)
    {
        if (underlying < bond) {
            underlyingBalance = currentBalances[0];
            bondBalance = currentBalances[1];
        } else {
            underlyingBalance = currentBalances[1];
            bondBalance = currentBalances[0];
        }
    }



    function onJoinPool(
        bytes32,
        address,
        address recipient,
        uint256[] calldata currentBalances,
        uint256,
        uint256 protocolSwapFee,
        bytes calldata userData
    )
        external
        override
        returns (
            uint256[] memory amountsIn,
            uint256[] memory dueProtocolFeeAmounts
        )
    {

        require(msg.sender == address(_vault), "Non Vault caller");
        uint256[2] memory maxAmountsIn = abi.decode(userData, (uint256[2]));
        require(
            currentBalances.length == 2 && maxAmountsIn.length == 2,
            "Invalid format"
        );



        {
            (
                uint256 localFeeUnderlying,
                uint256 localFeeBond
            ) = _mintGovernanceLP(currentBalances);
            dueProtocolFeeAmounts = new uint256[](2);


            if (underlying < bond) {
                dueProtocolFeeAmounts[0] = localFeeUnderlying.mul(
                    protocolSwapFee
                );
                dueProtocolFeeAmounts[1] = localFeeBond.mul(protocolSwapFee);
            } else {
                dueProtocolFeeAmounts[1] = localFeeUnderlying.mul(
                    protocolSwapFee
                );
                dueProtocolFeeAmounts[0] = localFeeBond.mul(protocolSwapFee);
            }
        }

        {
            (uint256 callerUsedUnderlying, uint256 callerUsedBond) = _mintLP(
                maxAmountsIn[0],
                maxAmountsIn[1],
                currentBalances,
                recipient
            );

            amountsIn = new uint256[](2);


            if (underlying < bond) {
                amountsIn[0] = callerUsedUnderlying;
                amountsIn[1] = callerUsedBond;
            } else {
                amountsIn[1] = callerUsedUnderlying;
                amountsIn[0] = callerUsedBond;
            }
        }
    }














    function onExitPool(
        bytes32,
        address,
        address recipient,
        uint256[] calldata currentBalances,
        uint256,
        uint256 protocolSwapFee,
        bytes calldata userData
    )
        external
        override
        returns (
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {

        require(msg.sender == address(_vault), "Non Vault caller");
        uint256[2] memory minAmountsOut = abi.decode(userData, (uint256[2]));
        require(
            currentBalances.length == 2 && minAmountsOut.length == 2,
            "Invalid format"
        );



        {
            (
                uint256 localFeeUnderlying,
                uint256 localFeeBond
            ) = _mintGovernanceLP(currentBalances);

            dueProtocolFeeAmounts = new uint256[](2);


            if (underlying < bond) {
                dueProtocolFeeAmounts[0] = localFeeUnderlying.mul(
                    protocolSwapFee
                );
                dueProtocolFeeAmounts[1] = localFeeBond.mul(protocolSwapFee);
            } else {
                dueProtocolFeeAmounts[1] = localFeeUnderlying.mul(
                    protocolSwapFee
                );
                dueProtocolFeeAmounts[0] = localFeeBond.mul(protocolSwapFee);
            }
        }

        {
            (uint256 releasedUnderlying, uint256 releasedBond) = _burnLP(
                minAmountsOut[0],
                minAmountsOut[1],
                currentBalances,
                recipient
            );

            amountsOut = new uint256[](2);


            if (underlying < bond) {
                amountsOut[0] = releasedUnderlying;
                amountsOut[1] = releasedBond;
            } else {
                amountsOut[1] = releasedUnderlying;
                amountsOut[0] = releasedBond;
            }
        }
    }













    function solveTradeInvariant(
        uint256 amountX,
        uint256 reserveX,
        uint256 reserveY,
        bool out
    ) public view returns (uint256) {

        uint256 a = _getYieldExponent();

        uint256 xBeforePowA = LogExpMath.pow(reserveX, a);

        uint256 yBeforePowA = LogExpMath.pow(reserveY, a);

        uint256 xAfterPowA = out
            ? LogExpMath.pow(reserveX + amountX, a)
            : LogExpMath.pow(reserveX.sub(amountX), a);


        uint256 yAfter = (xBeforePowA + yBeforePowA).sub(xAfterPowA);

        yAfter = LogExpMath.pow(yAfter, uint256(FixedPoint.ONE).div(a));

        return out ? reserveY.sub(yAfter) : yAfter.sub(reserveY);
    }












    function _assignTradeFee(
        uint256 amountIn,
        uint256 amountOut,
        IERC20 outputToken,
        bool isInputTrade
    ) internal returns (uint256) {

        if (isInputTrade) {

            if (outputToken == bond) {

                uint256 impliedYieldFee = percentFee.mul(
                    amountOut.sub(amountIn)
                );

                feesUnderlying += uint128(
                    _fixedToToken(impliedYieldFee, underlying)
                );

                return amountIn.add(impliedYieldFee);
            } else {

                uint256 impliedYieldFee = percentFee.mul(
                    amountIn.sub(amountOut)
                );

                feesBond += uint128(_fixedToToken(impliedYieldFee, bond));

                return amountIn.add(impliedYieldFee);
            }
        } else {
            if (outputToken == bond) {

                uint256 impliedYieldFee = percentFee.mul(
                    amountOut.sub(amountIn)
                );

                feesBond += uint128(_fixedToToken(impliedYieldFee, bond));

                return amountOut.sub(impliedYieldFee);
            } else {

                uint256 impliedYieldFee = percentFee.mul(
                    amountIn.sub(amountOut)
                );

                feesUnderlying += uint128(
                    _fixedToToken(impliedYieldFee, underlying)
                );

                return amountOut.sub(impliedYieldFee);
            }
        }
    }







    function _mintLP(
        uint256 inputUnderlying,
        uint256 inputBond,
        uint256[] memory currentBalances,
        address recipient
    ) internal returns (uint256, uint256) {


        (uint256 reserveUnderlying, uint256 reserveBond) = _getSortedBalances(
            currentBalances
        );

        uint256 localTotalSupply = totalSupply();

        if (localTotalSupply == 0) {


            _mintPoolTokens(recipient, inputUnderlying);
            return (inputUnderlying, 0);
        }



        uint256 underlyingPerBond = reserveUnderlying.div(reserveBond);

        uint256 neededUnderlying = underlyingPerBond.mul(inputBond);


        if (neededUnderlying > inputUnderlying) {


            uint256 mintAmount = (inputUnderlying.mul(localTotalSupply)).div(
                reserveUnderlying
            );


            _mintPoolTokens(recipient, mintAmount);


            return (inputUnderlying, inputUnderlying.div(underlyingPerBond));
        } else {


            uint256 mintAmount = (neededUnderlying.mul(localTotalSupply)).div(
                reserveUnderlying
            );

            _mintPoolTokens(recipient, mintAmount);

            return (neededUnderlying, inputBond);
        }
    }








    function _burnLP(
        uint256 minOutputUnderlying,
        uint256 minOutputBond,
        uint256[] memory currentBalances,
        address source
    ) internal returns (uint256, uint256) {
        (uint256 reserveUnderlying, uint256 reserveBond) = _getSortedBalances(
            currentBalances
        );

        uint256 localTotalSupply = totalSupply();

        uint256 underlyingPerBond = reserveUnderlying.div(reserveBond);

        if (minOutputUnderlying > minOutputBond.mul(underlyingPerBond)) {



            uint256 burned = (minOutputUnderlying.mul(localTotalSupply)).div(
                reserveUnderlying
            );
            _burnPoolTokens(source, burned);


            return (
                minOutputUnderlying,
                minOutputUnderlying.div(underlyingPerBond)
            );
        } else {


            uint256 burned = (minOutputBond.mul(localTotalSupply)).div(
                reserveBond
            );
            _burnPoolTokens(source, burned);


            return (minOutputBond.mul(underlyingPerBond), minOutputBond);
        }
    }




    function _mintGovernanceLP(uint256[] memory currentBalances)
        internal
        returns (uint256, uint256)
    {
        if (percentFeeGov == 0) {
            return (feesUnderlying, feesBond);
        }



        uint256 localFeeUnderlying = uint256(feesUnderlying);
        uint256 localFeeBond = uint256(feesBond);
        (uint256 feesUsedUnderlying, uint256 feesUsedBond) = _mintLP(
            localFeeUnderlying.mul(percentFeeGov),
            localFeeBond.mul(percentFeeGov),
            currentBalances,
            governance
        );


        require(
            localFeeUnderlying >= (feesUsedUnderlying).div(percentFeeGov),
            "Underflow"
        );
        require(localFeeBond >= (feesUsedBond).div(percentFeeGov), "Underflow");

        (feesUnderlying, feesBond) = (
            uint128(
                localFeeUnderlying - (feesUsedUnderlying).div(percentFeeGov)
            ),
            uint128(localFeeBond - (feesUsedBond).div(percentFeeGov))
        );

        return (localFeeUnderlying, localFeeBond);
    }



    function _getYieldExponent() internal virtual view returns (uint256) {

        uint256 timeTillExpiry = block.timestamp < expiration
            ? expiration - block.timestamp
            : 0;
        timeTillExpiry *= 1e18;

        timeTillExpiry = timeTillExpiry.div(unitSeconds * 1e18);
        uint256 result = uint256(FixedPoint.ONE).sub(timeTillExpiry);
        return result;
    }






    function _adjustedReserve(
        uint256 reserveTokenIn,
        IERC20 tokenIn,
        uint256 reserveTokenOut,
        IERC20 tokenOut
    ) internal view returns (uint256, uint256) {


        if (tokenIn == underlying && tokenOut == bond) {

            return (reserveTokenIn, reserveTokenOut + totalSupply());
        } else if (tokenIn == bond && tokenOut == underlying) {

            return (reserveTokenIn + totalSupply(), reserveTokenOut);
        }

        revert("Token request doesn't match stored");
    }





    function _tokenToFixed(uint256 amount, IERC20 token)
        internal
        view
        returns (uint256)
    {

        if (token == underlying) {
            return _normalize(amount, underlyingDecimals, 18);
        } else if (token == bond) {
            return _normalize(amount, bondDecimals, 18);
        }

        revert("Called with non pool token");
    }






    function _fixedToToken(uint256 amount, IERC20 token)
        internal
        view
        returns (uint256)
    {
        if (token == underlying) {

            return _normalize(amount, 18, underlyingDecimals);
        } else if (token == bond) {

            return _normalize(amount, 18, bondDecimals);
        }

        revert("Called with non pool token");
    }






    function _normalize(
        uint256 amount,
        uint8 decimalsBefore,
        uint8 decimalsAfter
    ) internal view returns (uint256) {

        if (decimalsBefore > decimalsAfter) {

            amount = amount / 10**(decimalsBefore - decimalsAfter);

        } else if (decimalsBefore < decimalsAfter) {

            amount = amount * 10**(decimalsAfter - decimalsBefore);
        }

        return amount;
    }
}
