
















pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;



interface ProtocolAdapter {


    function ADAPTERTYPE67() external pure returns (string memory);


    function TOKENTYPE890() external pure returns (string memory);


    function GETBALANCE609(address token, address account) external view returns (uint256);
}



abstract contract DyDxAdapter {

    address internal constant solo634 = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    address internal constant weth612 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant sai129 = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address internal constant usdc544 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant dai140 = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function GETMARKETID905(address token) internal pure returns (uint256) {
        if (token == weth612) {
            return uint256(0);
        } else if (token == sai129) {
            return uint256(1);
        } else if (token == usdc544) {
            return uint256(2);
        } else if (token == dai140) {
            return uint256(3);
        } else {
            return uint256(-1);
        }
    }
}



struct Info {
    address owner;
    uint256 number;
}



struct Wei {
    bool sign;
    uint256 value;
}



interface SoloMargin {
    function GETACCOUNTWEI374(Info calldata, uint256) external view returns (Wei memory);
}



contract DyDxAssetAdapter is ProtocolAdapter, DyDxAdapter {

    string public constant override adaptertype368 = "Asset";

    string public constant override tokentype164 = "ERC20";


    function GETBALANCE609(address token, address account) external view override returns (uint256) {
        Wei memory accountWei = SoloMargin(solo634).GETACCOUNTWEI374(Info(account, 0), GETMARKETID905(token));
        return accountWei.sign ? accountWei.value : 0;
    }
}
