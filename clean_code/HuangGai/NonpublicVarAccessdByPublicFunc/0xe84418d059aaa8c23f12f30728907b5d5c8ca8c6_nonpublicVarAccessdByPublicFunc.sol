




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

library Math {



    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }




    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }





    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IChainLinkFeed {
    function latestAnswer() external view returns (int256);
}

interface IKeep3rV1 {
    function totalBonded() external view returns (uint);
    function bonds(address keeper, address credit) external view returns (uint);
}

contract Keep3rV1Helper {
    using SafeMath for uint;

    IChainLinkFeed internal constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    IKeep3rV1 internal constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    uint constant internal BOOST = 25;
    uint constant internal BASE = 10;
    uint constant internal TARGETBOND = 100e18;

    function getQuoteLimitFor(address origin, uint gasUsed) external view returns (uint) {
        uint _gas = gasUsed.mul(uint(FASTGAS.latestAnswer()));
        _gas = _gas.mul(BOOST).div(BASE);
        uint _bond = Math.min(KP3R.bonds(origin, address(KP3R)), TARGETBOND);
        return _gas.mul(_bond).div(TARGETBOND);
    }

    function getQuoteLimit(uint gasUsed) external view returns (uint) {
        uint _gas = gasUsed.mul(uint(FASTGAS.latestAnswer()));
        _gas = _gas.mul(BOOST).div(BASE);
        uint _bond = Math.min(KP3R.bonds(tx.origin, address(KP3R)), TARGETBOND);
        return _gas.mul(_bond).div(TARGETBOND);
    }
}
