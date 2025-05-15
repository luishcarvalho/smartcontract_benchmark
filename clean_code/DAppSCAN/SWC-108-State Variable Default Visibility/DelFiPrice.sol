pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "./OpenOraclePriceData.sol";
import "./OpenOracleView.sol";





contract DelFiPrice is OpenOracleView {

    event PriceUpdated(string symbol, uint64 price);


    event PriceGuarded(string symbol, uint64 median, uint64 anchor);


    address anchor;


    uint256 upperBoundAnchorRatio;


    uint256 lowerBoundAnchorRatio;


    mapping(string => uint64) public prices;







    constructor(OpenOraclePriceData data_, address[] memory sources_, address anchor_, uint anchorToleranceMantissa_) public OpenOracleView(data_, sources_) {
        anchor = anchor_;
        require(anchorToleranceMantissa_ < 100e16, "Anchor Tolerance is too high");
        upperBoundAnchorRatio = 100e16 + anchorToleranceMantissa_;
        lowerBoundAnchorRatio = 100e16 - anchorToleranceMantissa_;
    }







    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external {
        require(messages.length == signatures.length, "messages and signatures must be 1:1");


        for (uint i = 0; i < messages.length; i++) {
            OpenOraclePriceData(address(data)).put(messages[i], signatures[i]);
        }


        for (uint i = 0; i < symbols.length; i++) {
            string memory symbol = symbols[i];
            uint64 medianPrice = medianPrice(symbol, sources);
            uint64 anchorPrice = OpenOraclePriceData(address(data)).getPrice(anchor, symbol);
            if (anchorPrice == 0) {
                emit PriceGuarded(symbol, medianPrice, anchorPrice);
            } else {
                uint256 anchorRatioMantissa = uint256(medianPrice) * 100e16 / anchorPrice;

                if (anchorRatioMantissa <= upperBoundAnchorRatio && anchorRatioMantissa >= lowerBoundAnchorRatio) {

                    if (prices[symbol] != medianPrice) {
                        prices[symbol] = medianPrice;
                        emit PriceUpdated(symbol, medianPrice);
                    }
                } else {
                    emit PriceGuarded(symbol, medianPrice, anchorPrice);
                }
            }
        }
    }







    function medianPrice(string memory symbol, address[] memory sources_) public view returns (uint64 median) {
        require(sources_.length > 0, "sources list must not be empty");

        uint N = sources_.length;
        uint64[] memory postedPrices = new uint64[](N);
        for (uint i = 0; i < N; i++) {
            postedPrices[i] = OpenOraclePriceData(address(data)).getPrice(sources_[i], symbol);
        }

        uint64[] memory sortedPrices = sort(postedPrices);

        if (N % 2 == 0) {
            uint64 left = sortedPrices[(N / 2) - 1];
            uint64 right = sortedPrices[N / 2];
            uint128 sum = uint128(left) + uint128(right);
            return uint64(sum / 2);
        } else {

            return sortedPrices[N / 2];
        }
    }






    function sort(uint64[] memory array) private pure returns (uint64[] memory) {
        uint N = array.length;
        for (uint i = 0; i < N; i++) {
            for (uint j = i + 1; j < N; j++) {
                if (array[i] > array[j]) {
                    uint64 tmp = array[i];
                    array[i] = array[j];
                    array[j] = tmp;
                }
            }
        }
        return array;
    }
}
