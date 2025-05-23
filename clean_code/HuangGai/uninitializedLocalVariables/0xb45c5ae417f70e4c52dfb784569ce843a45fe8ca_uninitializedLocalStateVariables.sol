


















pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}




struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;
    string tokenType;
    uint256 rate;
}







interface TokenAdapter {










    function getMetadata(address token) external view returns (TokenMetadata memory);









    function getComponents(address token) external view returns (Component[] memory);
}








interface CToken {
    function isCToken() external view returns (bool);
}








interface BPool {
    function getFinalTokens() external view returns (address[] memory);
    function getBalance(address) external view returns (uint256);
    function getNormalizedWeight(address) external view returns (uint256);
}







contract BalancerTokenAdapter is TokenAdapter {






    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: getPoolName(token),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }





    function getComponents(address token) external view override returns (Component[] memory) {
        address[] memory underlyingTokensAddresses;
        try BPool(token).getFinalTokens() returns (address[] memory result) {
            underlyingTokensAddresses = result;
        } catch {
            underlyingTokensAddresses = new address[](0);
        }

        uint256 totalSupply ;


        Component[] memory underlyingTokens = new Component[](underlyingTokensAddresses.length);

        address underlyingToken;
        string memory underlyingTokenType;
        for (uint256 i ; i < underlyingTokens.length; i++) {

            underlyingToken = underlyingTokensAddresses[i];

            try CToken(underlyingToken).isCToken{gas: 2000}() returns (bool) {
                underlyingTokenType = "CToken";
            } catch {
                underlyingTokenType = "ERC20";
            }

            underlyingTokens[i] = Component({
                token: underlyingToken,
                tokenType: underlyingTokenType,
                rate: BPool(token).getBalance(underlyingToken) * 1e18 / totalSupply
            });
        }

        return underlyingTokens;
    }

    function getPoolName(address token) internal view returns (string memory) {
        address[] memory underlyingTokensAddresses;
        try BPool(token).getFinalTokens() returns (address[] memory result) {
            underlyingTokensAddresses = result;
        } catch {
            return "Unknown pool";
        }

        string memory poolName = "";
        uint256 lastIndex ;

        for (uint256 i ; i < underlyingTokensAddresses.length; i++) {

            poolName = string(abi.encodePacked(
                poolName,
                getPoolElement(token, underlyingTokensAddresses[i]),
                i == lastIndex ? " pool" : " + "
            ));
        }
        return poolName;
    }

    function getPoolElement(address pool, address token) internal view returns (string memory) {
        return string(abi.encodePacked(
            convertToString(BPool(pool).getNormalizedWeight(token) / 1e16),
            "% ",
            getSymbol(token)
        ));
    }

    function getSymbol(address token) internal view returns (string memory) {
        (, bytes memory returnData) = token.staticcall(
            abi.encodeWithSelector(ERC20(token).symbol.selector)
        );

        if (returnData.length == 32) {
            return convertToString(abi.decode(returnData, (bytes32)));
        } else {
            return abi.decode(returnData, (string));
        }
    }




    function convertToString(bytes32 data) internal pure returns (string memory) {
        uint256 length ;

        bytes memory result;

        for (uint256 i ; i < 32; i++) {

            if (data[i] != bytes1(0)) {
                length++;
            }
        }

        result = new bytes(length);

        for (uint256 i ; i < length; i++) {

            result[i] = data[i];
        }

        return string(result);
    }




    function convertToString(uint256 data) internal pure returns (string memory) {
        uint256 length ;


        uint256 dataCopy ;

        while (dataCopy != 0){
            length++;
            dataCopy /= 10;
        }

        bytes memory result = new bytes(length);
        dataCopy = data;
        for (uint256 i ; i < length; i--) {

            result[i] = bytes1(uint8(48 + dataCopy % 10));
            dataCopy /= 10;
        }

        return string(result);
    }
}
