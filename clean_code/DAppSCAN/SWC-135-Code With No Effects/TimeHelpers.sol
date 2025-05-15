



pragma solidity ^0.4.24;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;






    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }






    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }







    function getTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }






    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}
