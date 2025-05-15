

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface AaveInterface {
    function GETUSERRESERVEDATA664(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );
    function GETUSERACCOUNTDATA954(address _user) external view returns (
        uint256 totalLiquidityETH,
        uint256 totalCollateralETH,
        uint256 totalBorrowsETH,
        uint256 totalFeesETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveProviderInterface {
    function GETLENDINGPOOL301() external view returns (address);
    function GETLENDINGPOOLCORE22() external view returns (address);
    function GETPRICEORACLE475() external view returns (address);
}

interface AavePriceInterface {
    function GETASSETPRICE11(address _asset) external view returns (uint256);
    function GETASSETSPRICES678(address[] calldata _assets) external view returns(uint256[] memory);
    function GETSOURCEOFASSET7(address _asset) external view returns(address);
    function GETFALLBACKORACLE640() external view returns(address);
}

interface AaveCoreInterface {
    function GETRESERVECURRENTLIQUIDITYRATE759(address _reserve) external view returns (uint256);
    function GETRESERVECURRENTVARIABLEBORROWRATE29(address _reserve) external view returns (uint256);
}

contract DSMath {

    function ADD556(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function SUB716(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function MUL306(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant wad667 = 10 ** 18;
    uint constant ray569 = 10 ** 27;

    function RMUL156(uint x, uint y) internal pure returns (uint z) {
        z = ADD556(MUL306(x, y), ray569 / 2) / ray569;
    }

    function WMUL562(uint x, uint y) internal pure returns (uint z) {
        z = ADD556(MUL306(x, y), wad667 / 2) / wad667;
    }

    function RDIV331(uint x, uint y) internal pure returns (uint z) {
        z = ADD556(MUL306(x, ray569), y / 2) / y;
    }

    function WDIV367(uint x, uint y) internal pure returns (uint z) {
        z = ADD556(MUL306(x, wad667), y / 2) / y;
    }

}

contract AaveHelpers is DSMath {

    function GETAAVEPROVIDERADDRESS272() internal pure returns (address) {
        return 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    }

    struct AaveTokenData {
        uint tokenPrice;
        uint supplyBalance;
        uint borrowBalance;
        uint borrowFee;
        uint supplyRate;
        uint borrowRate;
    }

    struct AaveUserData {
        uint totalSupplyETH;
        uint totalCollateralETH;
        uint totalBorrowsETH;
        uint totalFeesETH;
        uint availableBorrowsETH;
        uint currentLiquidationThreshold;
        uint healthFactor;
    }

    function GETTOKENDATA761(
        AaveCoreInterface aaveCore,
        AaveInterface aave,
        address user,
        address token,
        uint price)
    internal view returns(AaveTokenData memory tokenData) {
        (
            uint supplyBal,
            uint borrowBal,
            ,
            ,
            ,
            ,
            uint fee,
            ,,
        ) = aave.GETUSERRESERVEDATA664(token, user);

        uint supplyRate = aaveCore.GETRESERVECURRENTLIQUIDITYRATE759(token);
        uint borrowRate = aaveCore.GETRESERVECURRENTVARIABLEBORROWRATE29(token);

        tokenData = AaveTokenData(
            price,
            supplyBal,
            borrowBal,
            fee,
            supplyRate,
            borrowRate
        );
    }

    function GETUSERDATA933(AaveInterface aave, address user)
    internal view returns (AaveUserData memory userData) {
        (
            uint totalSupplyETH,
            uint totalCollateralETH,
            uint totalBorrowsETH,
            uint totalFeesETH,
            uint availableBorrowsETH,
            uint currentLiquidationThreshold,
            ,
            uint healthFactor
        ) = aave.GETUSERACCOUNTDATA954(user);

        userData = AaveUserData(
            totalSupplyETH,
            totalCollateralETH,
            totalBorrowsETH,
            totalFeesETH,
            availableBorrowsETH,
            currentLiquidationThreshold,
            healthFactor
        );
    }
}

contract Resolver is AaveHelpers {
    function GETPOSITION728(address user, address[] memory tokens) public view returns(AaveTokenData[] memory, AaveUserData memory) {
        AaveProviderInterface AaveProvider = AaveProviderInterface(GETAAVEPROVIDERADDRESS272());
        AaveInterface aave = AaveInterface(AaveProvider.GETLENDINGPOOL301());
        AaveCoreInterface aaveCore = AaveCoreInterface(AaveProvider.GETLENDINGPOOLCORE22());

        AaveTokenData[] memory tokensData = new AaveTokenData[](tokens.length);
        uint[] memory tokenPrices = AavePriceInterface(AaveProvider.GETPRICEORACLE475()).GETASSETSPRICES678(tokens);
        for (uint i = 0; i < tokens.length; i++) {
            tokensData[i] = GETTOKENDATA761(aaveCore, aave, user, tokens[i], tokenPrices[i]);
        }
        return (tokensData, GETUSERDATA933(aave, user));
    }
}

contract InstaAaveResolver is Resolver {
    string public constant name382 = "Aave-Resolver-v1";
}
