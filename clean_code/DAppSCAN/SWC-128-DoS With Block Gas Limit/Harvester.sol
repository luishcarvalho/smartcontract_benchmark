
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import { StableMath } from "../utils/StableMath.sol";
import { Governable } from "../governance/Governable.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { IUniswapV2Router } from "../interfaces/uniswap/IUniswapV2Router02.sol";
import "../utils/Helpers.sol";

contract Harvester is Governable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using StableMath for uint256;

    event UniswapUpdated(address _address);
    event SupportedStrategyUpdate(address _address, bool _isSupported);
    event RewardTokenConfigUpdated(
        address _tokenAddress,
        uint16 _allowedSlippageBps,
        uint16 _harvestRewardBps,
        address _uniswapV2CompatibleAddr,
        uint256 _liquidationLimit,
        bool _doSwapRewardToken
    );


    struct RewardTokenConfig {

        uint16 allowedSlippageBps;

        uint16 harvestRewardBps;


        address uniswapV2CompatibleAddr;



        bool doSwapRewardToken;




        uint256 liquidationLimit;
    }

    mapping(address => RewardTokenConfig) public rewardTokenConfigs;
    mapping(address => bool) public supportedStrategies;

    address public immutable vaultAddress;
    address public immutable usdtAddress;





    address public rewardProceedsAddress;






    constructor(address _vaultAddress, address _usdtAddress) {
        require(address(_vaultAddress) != address(0));
        require(address(_usdtAddress) != address(0));
        vaultAddress = _vaultAddress;
        usdtAddress = _usdtAddress;
    }








    modifier onlyVaultOrGovernor() {
        require(
            msg.sender == vaultAddress || isGovernor(),
            "Caller is not the Vault or Governor"
        );
        _;
    }





    function setRewardsProceedsAddress(address _rewardProceedsAddress)
        external
        onlyGovernor
    {
        require(
            _rewardProceedsAddress != address(0),
            "Rewards proceeds address should be a non zero address"
        );

        rewardProceedsAddress = _rewardProceedsAddress;
    }















    function setRewardTokenConfig(
        address _tokenAddress,
        uint16 _allowedSlippageBps,
        uint16 _harvestRewardBps,
        address _uniswapV2CompatibleAddr,
        uint256 _liquidationLimit,
        bool _doSwapRewardToken
    ) external onlyGovernor {
        require(
            _allowedSlippageBps <= 1000,
            "Allowed slippage should not be over 10%"
        );
        require(
            _harvestRewardBps <= 1000,
            "Harvest reward fee should not be over 10%"
        );
        require(
            _uniswapV2CompatibleAddr != address(0),
            "Uniswap compatible address should be non zero address"
        );

        RewardTokenConfig memory tokenConfig = RewardTokenConfig({
            allowedSlippageBps: _allowedSlippageBps,
            harvestRewardBps: _harvestRewardBps,
            uniswapV2CompatibleAddr: _uniswapV2CompatibleAddr,
            doSwapRewardToken: _doSwapRewardToken,
            liquidationLimit: _liquidationLimit
        });

        address oldUniswapAddress = rewardTokenConfigs[_tokenAddress]
            .uniswapV2CompatibleAddr;
        rewardTokenConfigs[_tokenAddress] = tokenConfig;

        IERC20 token = IERC20(_tokenAddress);

        address priceProvider = IVault(vaultAddress).priceProvider();



        IOracle(priceProvider).price(_tokenAddress);


        if (



            oldUniswapAddress != address(0) &&
            oldUniswapAddress != _uniswapV2CompatibleAddr
        ) {
            token.safeApprove(oldUniswapAddress, 0);
        }


        if (oldUniswapAddress != _uniswapV2CompatibleAddr) {
            token.safeApprove(_uniswapV2CompatibleAddr, 0);
            token.safeApprove(_uniswapV2CompatibleAddr, type(uint256).max);
        }

        emit RewardTokenConfigUpdated(
            _tokenAddress,
            _allowedSlippageBps,
            _harvestRewardBps,
            _uniswapV2CompatibleAddr,
            _liquidationLimit,
            _doSwapRewardToken
        );
    }






    function setSupportedStrategy(address _strategyAddress, bool _isSupported)
        external
        onlyVaultOrGovernor
    {
        supportedStrategies[_strategyAddress] = _isSupported;
        emit SupportedStrategyUpdate(_strategyAddress, _isSupported);
    }











    function transferToken(address _asset, uint256 _amount)
        external
        onlyGovernor
    {
        IERC20(_asset).safeTransfer(governor(), _amount);
    }





    function harvest() external onlyGovernor nonReentrant {
        _harvest();
    }




    function swap() external onlyGovernor nonReentrant {
        _swap(rewardProceedsAddress);
    }





    function harvestAndSwap() external onlyGovernor nonReentrant {
        _harvest();
        _swap(rewardProceedsAddress);
    }





    function harvest(address _strategyAddr) external onlyGovernor nonReentrant {
        _harvest(_strategyAddr);
    }







    function harvestAndSwap(address _strategyAddr) external nonReentrant {

        _harvestAndSwap(_strategyAddr, msg.sender);
    }








    function harvestAndSwap(address _strategyAddr, address _rewardTo)
        external
        nonReentrant
    {

        _harvestAndSwap(_strategyAddr, _rewardTo);
    }






    function swapRewardToken(address _swapToken)
        external
        onlyGovernor
        nonReentrant
    {
        _swap(_swapToken, rewardProceedsAddress);
    }




    function _harvest() internal {
        address[] memory allStrategies = IVault(vaultAddress)
            .getAllStrategies();
        for (uint256 i = 0; i < allStrategies.length; i++) {
            _harvest(allStrategies[i]);
        }
    }








    function _harvestAndSwap(address _strategyAddr, address _rewardTo)
        internal
    {
        _harvest(_strategyAddr);

        IStrategy strategy = IStrategy(_strategyAddr);
        address[] memory rewardTokens = strategy.getRewardTokenAddresses();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _swap(rewardTokens[i], _rewardTo);
        }
    }






    function _harvest(address _strategyAddr) internal {
        require(
            supportedStrategies[_strategyAddr],
            "Not a valid strategy address"
        );

        IStrategy strategy = IStrategy(_strategyAddr);
        strategy.collectRewardTokens();
    }







    function _swap(address _rewardTo) internal {
        address[] memory allStrategies = IVault(vaultAddress)
            .getAllStrategies();

        for (uint256 i = 0; i < allStrategies.length; i++) {
            IStrategy strategy = IStrategy(allStrategies[i]);
            address[] memory rewardTokenAddresses = strategy
                .getRewardTokenAddresses();

            for (uint256 j = 0; j < rewardTokenAddresses.length; j++) {
                _swap(rewardTokenAddresses[j], _rewardTo);
            }
        }
    }







    function _swap(address _swapToken, address _rewardTo) internal {
        RewardTokenConfig memory tokenConfig = rewardTokenConfigs[_swapToken];





        if (!tokenConfig.doSwapRewardToken) {
            return;
        }

        address priceProvider = IVault(vaultAddress).priceProvider();

        IERC20 swapToken = IERC20(_swapToken);
        uint256 balance = swapToken.balanceOf(address(this));

        if (balance == 0) {
            return;
        }

        uint256 balanceToSwap = Math.min(balance, tokenConfig.liquidationLimit);


        uint256 oraclePrice = IOracle(priceProvider).price(_swapToken);

        uint256 minExpected = (balanceToSwap *
            oraclePrice *
            (1e4 - tokenConfig.allowedSlippageBps)).scaleBy(
            6,
            Helpers.getDecimals(_swapToken) + 8
        ) / 1e4;


        address[] memory path = new address[](3);
        path[0] = _swapToken;
        path[1] = IUniswapV2Router(tokenConfig.uniswapV2CompatibleAddr).WETH();
        path[2] = usdtAddress;


        IUniswapV2Router(tokenConfig.uniswapV2CompatibleAddr)
            .swapExactTokensForTokens(
                balanceToSwap,
                minExpected,
                path,
                address(this),
                block.timestamp
            );

        IERC20 usdt = IERC20(usdtAddress);
        uint256 usdtBalance = usdt.balanceOf(address(this));

        uint256 vaultBps = 1e4 - tokenConfig.harvestRewardBps;
        uint256 rewardsProceedsShare = (usdtBalance * vaultBps) / 1e4;

        require(
            vaultBps > tokenConfig.harvestRewardBps,
            "Address receiving harvest incentive is receiving more rewards than the rewards proceeds address"
        );

        usdt.safeTransfer(rewardProceedsAddress, rewardsProceedsShare);
        usdt.safeTransfer(
            _rewardTo,
            usdtBalance - rewardsProceedsShare
        );
    }
}
