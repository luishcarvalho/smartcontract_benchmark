
pragma solidity ^0.8.0;

import "./ABDKMath64x64.sol";




library Units {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    uint256 internal constant YEAR = 31556952;
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant PERCENTAGE = 1e4;







    function scaleUp(uint256 value, uint256 factor) internal pure returns (uint256 y) {
        y = value * factor;
    }





    function scaleDown(uint256 value, uint256 factor) internal pure returns (uint256 y) {
        y = value / factor;
    }






    function scaleToX64(uint256 value, uint256 factor) internal pure returns (int128 y) {
        uint256 scaleFactor = PRECISION / factor;
        y = value.divu(scaleFactor);
    }





    function scalefromX64(int128 value, uint256 factor) internal pure returns (uint256 y) {
        uint256 scaleFactor = PRECISION / factor;
        y = value.mulu(scaleFactor);
    }





    function percentage(uint256 denorm) internal pure returns (int128) {

        return denorm.divu(PERCENTAGE);
    }




    function percentage(int128 denorm) internal pure returns (uint256) {
        return denorm.mulu(PERCENTAGE);
    }





    function toYears(uint256 s) internal pure returns (int128) {
        return s.divu(YEAR);
    }
}
