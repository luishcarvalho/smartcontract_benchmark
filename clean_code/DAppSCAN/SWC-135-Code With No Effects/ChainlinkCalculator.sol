

pragma solidity 0.8.9;
pragma abicoder v1;

import "../interfaces/AggregatorInterface.sol";


contract ChainlinkCalculator {
    uint256 private constant _SPREAD_DENOMINATOR = 1e9;
    uint256 private constant _ORACLE_EXPIRATION_TIME = 30 minutes;
    uint256 private constant _INVERSE_MASK = 1 << 255;








    function singlePrice(AggregatorInterface oracle, uint256 inverseAndSpread, uint256 amount) external view returns(uint256) {

        require(oracle.latestTimestamp() + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data");
        bool inverse = inverseAndSpread & _INVERSE_MASK > 0;
        uint256 spread = inverseAndSpread & (~_INVERSE_MASK);
        if (inverse) {
            return amount * spread * 1e18 / uint256(oracle.latestAnswer()) / _SPREAD_DENOMINATOR;
        } else {
            return amount * spread * uint256(oracle.latestAnswer()) / 1e18 / _SPREAD_DENOMINATOR;
        }
    }



    function doublePrice(AggregatorInterface oracle1, AggregatorInterface oracle2, uint256 spread, uint256 amount) external view returns(uint256) {

        require(oracle1.latestTimestamp() + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data O1");

        require(oracle2.latestTimestamp() + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data O2");

        return amount * spread * uint256(oracle1.latestAnswer()) / uint256(oracle2.latestAnswer()) / _SPREAD_DENOMINATOR;
    }
}
