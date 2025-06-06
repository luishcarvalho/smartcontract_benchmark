


















pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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








interface YToken {
    function token() external view returns (address);
    function getPricePerFullShare() external view returns (uint256);
}







contract IearnTokenAdapter is TokenAdapter {





    function getMetadata(address token) public view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: ERC20(token).name(),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }





    function getComponents(address token) public view override returns (Component[] memory) {
        Component[] memory underlyingTokens = new Component[](1);

        underlyingTokens[0] = Component({
            token: YToken(token).token(),
            tokenType: "ERC20",
            rate: YToken(token).getPricePerFullShare()
        });

        return underlyingTokens;
    }
}
