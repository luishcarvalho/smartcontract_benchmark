












pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;







library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient ;

        uint256 remainder ;

        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z ;

        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}



interface IChainlink {
    function latestAnswer() external view returns (uint256);
}




contract ChainlinkYFIUSDCPriceOracleProxy {
    using SafeMath for uint256;

    address public yfiEth ;

    address public EthUsd ;


    function getPrice() external view returns (uint256) {
        uint256 yfiEthPrice ;

        uint256 EthUsdPrice ;

        return yfiEthPrice.mul(EthUsdPrice).div(10**20);
    }
}
