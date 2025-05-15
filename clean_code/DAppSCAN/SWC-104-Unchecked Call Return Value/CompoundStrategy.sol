pragma solidity 0.5.11;






import { ICERC20 } from "./ICompound.sol";
import {
    IERC20,
    InitializableAbstractStrategy
} from "../utils/InitializableAbstractStrategy.sol";

contract CompoundStrategy is InitializableAbstractStrategy {
    event SkippedWithdrawal(address asset, uint256 amount);







    function deposit(address _asset, uint256 _amount)
        external
        onlyVault
        returns (uint256 amountDeposited)
    {
        require(_amount > 0, "Must deposit something");

        ICERC20 cToken = _getCTokenFor(_asset);
        require(cToken.mint(_amount) == 0, "cToken mint failed");

        amountDeposited = _amount;

        emit Deposit(_asset, address(cToken), amountDeposited);
    }








    function withdraw(
        address _recipient,
        address _asset,
        uint256 _amount
    ) external onlyVault returns (uint256 amountWithdrawn) {
        require(_amount > 0, "Must withdraw something");
        require(_recipient != address(0), "Must specify recipient");

        ICERC20 cToken = _getCTokenFor(_asset);

        uint256 cTokensToRedeem = _convertUnderlyingToCToken(cToken, _amount);
        if (cTokensToRedeem == 0) {
            emit SkippedWithdrawal(_asset, _amount);
            return 0;
        }

        amountWithdrawn = _amount;

        require(cToken.redeemUnderlying(_amount) == 0, "Redeem failed");

        IERC20(_asset).safeTransfer(_recipient, amountWithdrawn);

        emit Withdrawal(_asset, address(cToken), amountWithdrawn);
    }




    function liquidate() external onlyVaultOrGovernor {
        for (uint256 i = 0; i < assetsMapped.length; i++) {

            ICERC20 cToken = _getCTokenFor(assetsMapped[i]);
            if (cToken.balanceOf(address(this)) > 0) {

                cToken.redeem(cToken.balanceOf(address(this)));

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

        ICERC20 cToken = _getCTokenFor(_asset);
        balance = _checkBalance(cToken);
    }







    function _checkBalance(ICERC20 _cToken)
        internal
        view
        returns (uint256 balance)
    {
        uint256 cTokenBalance = _cToken.balanceOf(address(this));
        uint256 exchangeRate = _cToken.exchangeRateStored();

        balance = cTokenBalance.mul(exchangeRate).div(1e18);
    }





    function supportsAsset(address _asset) external view returns (bool) {
        return assetToPToken[_asset] != address(0);
    }





    function safeApproveAllTokens() external {
        uint256 assetCount = assetsMapped.length;
        for (uint256 i = 0; i < assetCount; i++) {
            address asset = assetsMapped[i];
            address cToken = assetToPToken[asset];

            IERC20(asset).safeApprove(cToken, 0);
            IERC20(asset).safeApprove(cToken, uint256(-1));
        }
    }







    function _abstractSetPToken(address _asset, address _cToken) internal {

        IERC20(_asset).safeApprove(_cToken, 0);
        IERC20(_asset).safeApprove(_cToken, uint256(-1));
    }







    function _getCTokenFor(address _asset) internal view returns (ICERC20) {
        address cToken = assetToPToken[_asset];
        require(cToken != address(0), "cToken does not exist");
        return ICERC20(cToken);
    }








    function _convertUnderlyingToCToken(ICERC20 _cToken, uint256 _underlying)
        internal
        view
        returns (uint256 amount)
    {
        uint256 exchangeRate = _cToken.exchangeRateStored();


        amount = _underlying.mul(1e18).div(exchangeRate);
    }
}
