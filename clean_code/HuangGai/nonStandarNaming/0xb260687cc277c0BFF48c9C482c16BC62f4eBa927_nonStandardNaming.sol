
















pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function SYMBOL460() external view returns (string memory);
    function DECIMALS840() external view returns (uint8);
    function BALANCEOF665(address) external view returns (uint256);
    function TOTALSUPPLY99() external view returns (uint256);

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


    function GETMETADATA955(address token) external view returns (TokenMetadata memory);


    function GETCOMPONENTS90(address token) external view returns (Component[] memory);
}



interface CToken {
    function ISCTOKEN28() external view returns (bool);
}



interface Exchange {
    function NAME692() external view returns (bytes32);
    function SYMBOL460() external view returns (bytes32);
    function DECIMALS840() external view returns (uint256);
}



interface Factory {
    function GETTOKEN449(address) external view returns (address);
}



contract UniswapV1TokenAdapter is TokenAdapter {

    address internal constant factory590 = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    address internal constant eth356 = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant sai_pool239 = 0x09cabEC1eAd1c0Ba254B09efb3EE13841712bE14;
    address internal constant csai_pool613 = 0x45A2FDfED7F7a2c791fb1bdF6075b83faD821ddE;


    function GETMETADATA955(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: GETPOOLNAME768(token),
            symbol: "UNI-V1",
            decimals: uint8(Exchange(token).DECIMALS840())
        });
    }


    function GETCOMPONENTS90(address token) external view override returns (Component[] memory) {
        address underlyingToken = Factory(factory590).GETTOKEN449(token);
        uint256 totalSupply = ERC20(token).TOTALSUPPLY99();
        string memory underlyingTokenType;
        Component[] memory underlyingTokens = new Component[](2);

        underlyingTokens[0] = Component({
            token: eth356,
            tokenType: "ERC20",
            rate: token.balance * 1e18 / totalSupply
        });

        try CToken(underlyingToken).ISCTOKEN28() returns (bool) {
            underlyingTokenType = "CToken";
        } catch {
            underlyingTokenType = "ERC20";
        }

        underlyingTokens[1] = Component({
            token: underlyingToken,
            tokenType: underlyingTokenType,
            rate: ERC20(underlyingToken).BALANCEOF665(token) * 1e18 / totalSupply
        });

        return underlyingTokens;
    }

    function GETPOOLNAME768(address token) internal view returns (string memory) {
        if (token == sai_pool239) {
            return "SAI pool";
        } else if (token == csai_pool613) {
            return "cSAI pool";
        } else {
            return string(abi.encodePacked(GETSYMBOL517(Factory(factory590).GETTOKEN449(token)), " pool"));
        }
    }

    function GETSYMBOL517(address token) internal view returns (string memory) {
        (, bytes memory returnData) = token.staticcall(
            abi.encodeWithSelector(ERC20(token).SYMBOL460.selector)
        );

        if (returnData.length == 32) {
            return CONVERTTOSTRING584(abi.decode(returnData, (bytes32)));
        } else {
            return abi.decode(returnData, (string));
        }
    }


    function CONVERTTOSTRING584(bytes32 data) internal pure returns (string memory) {
        uint256 length = 0;
        bytes memory result;

        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != byte(0)) {
                length++;
            }
        }

        result = new bytes(length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = data[i];
        }

        return string(result);
    }
}
