pragma solidity 0.5.11;






import "./IAave.sol";
import {
    IERC20,
    InitializableAbstractStrategy
} from "../utils/InitializableAbstractStrategy.sol";

contract AaveStrategy is InitializableAbstractStrategy {
    uint16 constant referralCode = 92;







    function deposit(address _asset, uint256 _amount)
        external
        onlyVault
        returns (uint256 amountDeposited)
    {
        require(_amount > 0, "Must deposit something");

        IAaveAToken aToken = _getATokenFor(_asset);

        _getLendingPool().deposit(_asset, _amount, referralCode);
        amountDeposited = _amount;

        emit Deposit(_asset, address(aToken), amountDeposited);
    }









    function withdraw(
        address _recipient,
        address _asset,
        uint256 _amount
    ) external onlyVault returns (uint256 amountWithdrawn) {
        require(_amount > 0, "Must withdraw something");
        require(_recipient != address(0), "Must specify recipient");

        IAaveAToken aToken = _getATokenFor(_asset);

        amountWithdrawn = _amount;
        uint256 balance = aToken.balanceOf(address(this));

        aToken.redeem(_amount);
        IERC20(_asset).safeTransfer(
            _recipient,
            IERC20(_asset).balanceOf(address(this))
        );

        emit Withdrawal(_asset, address(aToken), amountWithdrawn);
    }




    function liquidate() external onlyVaultOrGovernor {
        for (uint256 i = 0; i < assetsMapped.length; i++) {

            IAaveAToken aToken = _getATokenFor(assetsMapped[i]);
            uint256 balance = aToken.balanceOf(address(this));
            if (balance > 0) {
                aToken.redeem(balance);

                IERC20 asset = IERC20(assetsMapped[i]);
                asset.safeTransfer(
                    vaultAddress,
                    asset.balanceOf(address(this))
                );
            }
        }
    }






    function checkBalance(address _asset)
        external
        view
        returns (uint256 balance)
    {

        IAaveAToken aToken = _getATokenFor(_asset);
        balance = aToken.balanceOf(address(this));
    }





    function supportsAsset(address _asset) external view returns (bool) {
        return assetToPToken[_asset] != address(0);
    }





    function safeApproveAllTokens() external onlyGovernor {
        uint256 assetCount = assetsMapped.length;
        address lendingPoolVault = _getLendingPoolCore();


        for (uint256 i = 0; i < assetCount; i++) {
            address asset = assetsMapped[i];

            IERC20(asset).safeApprove(lendingPoolVault, 0);
            IERC20(asset).safeApprove(lendingPoolVault, uint256(-1));
        }
    }







    function _abstractSetPToken(address _asset, address _aToken) internal {
        address lendingPoolVault = _getLendingPoolCore();
        IERC20(_asset).safeApprove(lendingPoolVault, 0);
        IERC20(_asset).safeApprove(lendingPoolVault, uint256(-1));
    }







    function _getATokenFor(address _asset) internal view returns (IAaveAToken) {
        address aToken = assetToPToken[_asset];
        require(aToken != address(0), "aToken does not exist");
        return IAaveAToken(aToken);
    }






    function _getLendingPool() internal view returns (IAaveLendingPool) {
        address lendingPool = ILendingPoolAddressesProvider(platformAddress)
            .getLendingPool();
        require(lendingPool != address(0), "Lending pool does not exist");
        return IAaveLendingPool(lendingPool);
    }






    function _getLendingPoolCore() internal view returns (address payable) {
        address payable lendingPoolCore = ILendingPoolAddressesProvider(
            platformAddress
        )
            .getLendingPoolCore();
        require(
            lendingPoolCore != address(uint160(address(0))),
            "Lending pool core does not exist"
        );
        return lendingPoolCore;
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }
}
