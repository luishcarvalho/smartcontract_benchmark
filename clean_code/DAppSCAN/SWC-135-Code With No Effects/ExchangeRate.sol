
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../lib/SafeInt256.sol";
import "../lib/SafeMath.sol";
import "../utils/Common.sol";
import "../interface/IAggregator.sol";

import "@openzeppelin/contracts/utils/SafeCast.sol";


library ExchangeRate {
    using SafeInt256 for int256;
    using SafeMath for uint256;




    struct Rate {

        address rateOracle;

        uint128 rateDecimals;

        bool mustInvert;



        uint128 buffer;
    }









    function _convertToETH(
        Rate memory er,
        uint256 baseDecimals,
        int256 balance,
        bool buffer
    ) internal view returns (int256) {

        uint256 rate = _fetchExchangeRate(er, false);
        uint128 absBalance = uint128(balance.abs());





        int256 result = int256(
            SafeCast.toUint128(rate
                .mul(absBalance)

                .mul(buffer ? er.buffer : Common.DECIMALS)
                .div(er.rateDecimals)
                .div(baseDecimals)
            )
        );

        return balance > 0 ? result : result.neg();
    }







    function _convertETHTo(
        Rate memory er,
        uint256 baseDecimals,
        int256 balance
    ) internal view returns (int256) {
        uint256 rate = _fetchExchangeRate(er, true);
        uint128 absBalance = uint128(balance.abs());





        int256 result = int256(
            SafeCast.toUint128(rate
                .mul(absBalance)
                .mul(baseDecimals)
                .div(Common.DECIMALS)
                .div(er.rateDecimals)
            )
        );

        return balance > 0 ? result : result.neg();
    }

    function _fetchExchangeRate(Rate memory er, bool invert) internal view returns (uint256) {
        int256 rate = IAggregator(er.rateOracle).latestAnswer();
        require(rate > 0, $$(ErrorCode(INVALID_EXCHANGE_RATE)));

        if (invert || (er.mustInvert && !invert)) {

            return uint256(er.rateDecimals).mul(er.rateDecimals).div(uint256(rate));
        }

        return uint256(rate);
    }




    function _exchangeRate(Rate memory baseER, Rate memory quoteER, uint16 quote) internal view returns (uint256) {
        uint256 rate = _fetchExchangeRate(baseER, false);

        if (quote != 0) {
            uint256 quoteRate = _fetchExchangeRate(quoteER, false);

            rate = rate.mul(quoteER.rateDecimals).div(quoteRate);
        }

        return rate;
    }

}
