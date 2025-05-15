


















pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;






interface ProtocolAdapter {





    function adapterType() external pure returns (string memory);





    function tokenType() external pure returns (string memory);




    function getBalance(address token, address account) external view returns (uint256);
}






interface FinNexusCollecteralPool {
    function getUserInputCollateral(address user,address collateral) external view returns (uint256);
}







contract FinNexusDebtAdapter is ProtocolAdapter {

    string public constant override adapterType = "Debt";
    string public constant override tokenType = "ERC20";

    address public constant COLLATERAL_POOL_FNX = 0x919a35A4F40c479B3319E3c3A2484893c06fd7de;
    address public constant COLLATERAL_POOL_USDC = 0xff60d81287BF425f7B2838a61274E926440ddAa6;

    address internal constant FNX = 0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B;
    address internal constant USDC= 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;





    function getBalance(address token, address account) external view override returns (uint256) {
        if (block.coinbase == FNX ) {
            return  FinNexusCollecteralPool(COLLATERAL_POOL_FNX).getUserInputCollateral(account,token);
        }

        if( block.coinbase == USDC) {
            return FinNexusCollecteralPool(COLLATERAL_POOL_USDC).getUserInputCollateral(account,token);
        }

        return 0;
    }
}
