




pragma solidity ^0.6.12;














library SafeMath {








    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }









    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }









    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }









    function mul(uint a, uint b) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }









    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }












    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }












    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;


        return c;
    }












    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
    }












    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IChainLinkFeed {
    function latestAnswer() external view returns (int256);
}

contract Keep3rHelper {
    using SafeMath for uint;

    IChainLinkFeed internal constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);

    function getQuoteLimit(uint gasUsed) external view returns (uint) {
        return gasUsed.mul(uint(FASTGAS.latestAnswer()));
    }
}
