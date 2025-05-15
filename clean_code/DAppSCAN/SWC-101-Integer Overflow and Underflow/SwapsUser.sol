pragma solidity 0.5.17;

import "../core/State.sol";
import "../feeds/IPriceFeeds.sol";
import "../events/SwapsEvents.sol";
import "../mixins/FeesHelper.sol";
import "./ISwapsImpl.sol";


contract SwapsUser is State, SwapsEvents, FeesHelper {

    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool bypassFee,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 sourceToDestSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            [
                sourceToken,
                destToken,
                address(this),
                address(this),
                user
            ],
            [
                minSourceTokenAmount,
                maxSourceTokenAmount,
                requiredDestTokenAmount
            ],
            loanId,
            bypassFee,
            loanDataBytes
        );


        _checkSwapSize(sourceToken, sourceTokenAmountUsed);


        sourceToDestSwapRate = IPriceFeeds(priceFeeds).checkPriceDisagreement(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit LoanSwap(
            loanId,
            sourceToken,
            destToken,
            user,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function _swapsCall(
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes32 loanId,
        bool miscBool,
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {









        require(vals[0] != 0, "sourceAmount == 0");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) {
            if (vals[2] == 0) {


                tradingFee = _getTradingFee(vals[0]);
                if (tradingFee != 0) {
                    _payTradingFee(
                        addrs[4],
                        loanId,
                        addrs[0],
                        tradingFee
                    );

                    vals[0] = vals[0]
                        .sub(tradingFee);
                }
            } else {


                tradingFee = _getTradingFee(vals[2]);

                if (tradingFee != 0) {
                    vals[2] = vals[2]
                        .add(tradingFee);
                }
            }
        }

        if (vals[1] == 0) {
            vals[1] = vals[0];
        } else {
            require(vals[0] <= vals[1], "min greater than max");
        }

        require(loanDataBytes.length == 0, "invalid state");
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall_internal(
            addrs,
            vals
        );

        if (vals[2] == 0) {

            require(sourceTokenAmountUsed == vals[0], "swap too large to fill");

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed + tradingFee;
            }
        } else {

            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(destTokenAmountReceived >= vals[2], "insufficient swap liquidity");

            if (tradingFee != 0) {
                _payTradingFee(
                    addrs[4],
                    loanId,
                    addrs[1],
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived - tradingFee;
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsCall_internal(
        address[5] memory addrs,
        uint256[3] memory vals)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data = abi.encodeWithSelector(
            ISwapsImpl(swapsImpl).dexSwap.selector,
            addrs[0],
            addrs[1],
            addrs[2],
            addrs[3],
            vals[0],
            vals[1],
            vals[2]
        );

        bool success;
        (success, data) = swapsImpl.delegatecall(data);
        require(success, "swap failed");

        (destTokenAmountReceived, sourceTokenAmountUsed) = abi.decode(data, (uint256, uint256));
    }

    function _swapsExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount)
        internal
        view
        returns (uint256)
    {
        uint256 tradingFee = _getTradingFee(sourceTokenAmount);
        if (tradingFee != 0) {
            sourceTokenAmount = sourceTokenAmount
                .sub(tradingFee);
        }

        uint256 sourceToDestRate = ISwapsImpl(swapsImpl).dexExpectedRate(
            sourceToken,
            destToken,
            sourceTokenAmount
        );
        uint256 sourceToDestPrecision = IPriceFeeds(priceFeeds).queryPrecision(
            sourceToken,
            destToken
        );

        return sourceTokenAmount
            .mul(sourceToDestRate)
            .div(sourceToDestPrecision);
    }

    function _checkSwapSize(
        address tokenAddress,
        uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (_maxSwapSize != 0) {
            uint256 amountInEth;
            if (tokenAddress == address(wethToken)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).amountInEth(tokenAddress, amount);
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}
