pragma solidity 0.5.11;







import "./VaultStorage.sol";
import { IMinMaxOracle } from "../interfaces/IMinMaxOracle.sol";
import { IUniswapV2Router } from "../interfaces/uniswap/IUniswapV2Router02.sol";

contract VaultAdmin is VaultStorage {



    modifier onlyVaultOrGovernor() {
        require(
            msg.sender == address(this) || isGovernor(),
            "Caller is not the Vault or Governor"
        );
        _;
    }









    function setPriceProvider(address _priceProvider) external onlyGovernor {
        priceProvider = _priceProvider;
    }





    function setRedeemFeeBps(uint256 _redeemFeeBps) external onlyGovernor {
        redeemFeeBps = _redeemFeeBps;
    }






    function setVaultBuffer(uint256 _vaultBuffer) external onlyGovernor {
        vaultBuffer = _vaultBuffer;
    }






    function setAutoAllocateThreshold(uint256 _threshold)
        external
        onlyGovernor
    {
        autoAllocateThreshold = _threshold;
    }






    function setRebaseThreshold(uint256 _threshold) external onlyGovernor {
        rebaseThreshold = _threshold;
    }






    function setRebaseHooksAddr(address _address) external onlyGovernor {
        rebaseHooksAddr = _address;
    }






    function setUniswapAddr(address _address) external onlyGovernor {
        uniswapAddr = _address;
    }






    function supportAsset(address _asset) external onlyGovernor {
        require(!assets[_asset].isSupported, "Asset already supported");

        assets[_asset] = Asset({ isSupported: true });
        allAssets.push(_asset);

        emit AssetSupported(_asset);
    }






    function addStrategy(address _addr, uint256 _targetWeight)
        external
        onlyGovernor
    {
        require(!strategies[_addr].isSupported, "Strategy already added");

        strategies[_addr] = Strategy({
            isSupported: true,
            targetWeight: _targetWeight
        });
        allStrategies.push(_addr);

        emit StrategyAdded(_addr);
    }







    function removeStrategy(address _addr) external onlyGovernor {
        require(strategies[_addr].isSupported, "Strategy not added");



        uint256 strategyIndex = allStrategies.length;
        for (uint256 i = 0; i < allStrategies.length; i++) {
            if (allStrategies[i] == _addr) {
                strategyIndex = i;
                break;
            }
        }

        if (strategyIndex < allStrategies.length) {

            allStrategies[strategyIndex] = allStrategies[allStrategies.length -
                1];
            allStrategies.length--;


            IStrategy strategy = IStrategy(_addr);
            strategy.liquidate();


            _harvest(_addr);

            emit StrategyRemoved(_addr);
        }



        strategies[_addr].isSupported = false;
        strategies[_addr].targetWeight = 0;
    }







    function setStrategyWeights(
        address[] calldata _strategyAddresses,
        uint256[] calldata _weights
    ) external onlyGovernor {
        require(
            _strategyAddresses.length == _weights.length,
            "Parameter length mismatch"
        );

        for (uint256 i = 0; i < _strategyAddresses.length; i++) {
            strategies[_strategyAddresses[i]].targetWeight = _weights[i];
        }

        emit StrategyWeightsUpdated(_strategyAddresses, _weights);
    }








    function pauseRebase() external onlyGovernor {
        rebasePaused = true;
    }




    function unpauseRebase() external onlyGovernor {
        rebasePaused = false;
    }




    function pauseDeposits() external onlyGovernor {
        depositPaused = true;

        emit DepositsPaused();
    }




    function unpauseDeposits() external onlyGovernor {
        depositPaused = false;

        emit DepositsUnpaused();
    }












    function transferToken(address _asset, uint256 _amount)
        external
        onlyGovernor
    {

        IERC20(_asset).transfer(governor(), _amount);
    }





    function harvest() external onlyGovernor {
        for (uint256 i = 0; i < allStrategies.length; i++) {
            _harvest(allStrategies[i]);
        }
    }






    function harvest(address _strategyAddr) external onlyVaultOrGovernor {
        _harvest(_strategyAddr);
    }







    function _harvest(address _strategyAddr) internal {
        IStrategy strategy = IStrategy(_strategyAddr);
        address rewardTokenAddress = strategy.rewardTokenAddress();
        if (rewardTokenAddress != address(0)) {
            strategy.collectRewardToken();

            if (uniswapAddr != address(0)) {
                IERC20 rewardToken = IERC20(strategy.rewardTokenAddress());
                uint256 rewardTokenAmount = rewardToken.balanceOf(
                    address(this)
                );
                if (rewardTokenAmount > 0) {

                    rewardToken.safeApprove(uniswapAddr, 0);
                    rewardToken.safeApprove(uniswapAddr, rewardTokenAmount);


                    address[] memory path = new address[](3);
                    path[0] = strategy.rewardTokenAddress();
                    path[1] = IUniswapV2Router(uniswapAddr).WETH();
                    path[2] = allAssets[1];

                    IUniswapV2Router(uniswapAddr).swapExactTokensForTokens(
                        rewardTokenAmount,
                        uint256(0),
                        path,
                        address(this),
                        now.add(1800)
                    );
                }
            }
        }
    }











    function priceUSDMint(string calldata symbol) external returns (uint256) {
        return _priceUSDMint(symbol);
    }







    function _priceUSDMint(string memory symbol) internal returns (uint256) {


        return IMinMaxOracle(priceProvider).priceMin(symbol).scaleBy(10);
    }







    function priceUSDRedeem(string calldata symbol) external returns (uint256) {


        return _priceUSDRedeem(symbol);
    }







    function _priceUSDRedeem(string memory symbol) internal returns (uint256) {


        return IMinMaxOracle(priceProvider).priceMax(symbol).scaleBy(10);
    }
}
