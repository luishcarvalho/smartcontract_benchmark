

pragma solidity 0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './BaseModule.sol';
import '../helpers/UniswapNFTHelper.sol';
import '../../interfaces/IPositionManager.sol';
import '../../interfaces/IUniswapAddressHolder.sol';
import '../../interfaces/actions/IClosePosition.sol';
import '../../interfaces/actions/ISwapToPositionRatio.sol';
import '../../interfaces/actions/IMint.sol';


contract IdleLiquidityModule is BaseModule {

    IUniswapAddressHolder public uniswapAddressHolder;




    constructor(address _uniswapAddressHolder, address _registry) BaseModule(_registry) {
        uniswapAddressHolder = IUniswapAddressHolder(_uniswapAddressHolder);
    }




    function rebalance(uint256 tokenId, IPositionManager positionManager)
        public
        onlyWhitelistedKeeper
        activeModule(address(positionManager), tokenId)
    {
        uint24 tickDistance = _checkDistanceFromRange(tokenId);
        (, bytes32 rebalanceDistance) = positionManager.getModuleInfo(tokenId, address(this));


        if (tickDistance > 0 && uint24(uint256(rebalanceDistance)) <= tickDistance) {
            (, , address token0, address token1, uint24 fee, , , , , , , ) = INonfungiblePositionManager(
                uniswapAddressHolder.nonfungiblePositionManagerAddress()
            ).positions(tokenId);


            (int24 tickLower, int24 tickUpper) = _calcTick(tokenId, fee);


            (, uint256 amount0Closed, uint256 amount1Closed) = IClosePosition(address(positionManager)).closePosition(
                tokenId,
                false
            );


            (uint256 token0Swapped, uint256 token1Swapped) = ISwapToPositionRatio(address(positionManager))
                .swapToPositionRatio(
                    ISwapToPositionRatio.SwapToPositionInput(
                        token0,
                        token1,
                        fee,
                        amount0Closed,
                        amount1Closed,
                        tickLower,
                        tickUpper
                    )
                );


            IMint(address(positionManager)).mint(
                IMint.MintInput(token0, token1, fee, tickLower, tickUpper, token0Swapped - 10, token1Swapped - 10)
            );
        }
    }




    function _checkDistanceFromRange(uint256 tokenId) internal view returns (uint24) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(uniswapAddressHolder.nonfungiblePositionManagerAddress()).positions(tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(
            UniswapNFTHelper._getPool(uniswapAddressHolder.uniswapV3FactoryAddress(), token0, token1, fee)
        );
        (, int24 tick, , , , , ) = pool.slot0();

        if (tick > tickUpper) {
            return uint24(tick - tickUpper);
        } else if (tick < tickLower) {
            return uint24(tickLower - tick);
        } else {
            return 0;
        }
    }






    function _calcTick(uint256 tokenId, uint24 fee) internal view returns (int24, int24) {
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = INonfungiblePositionManager(
            uniswapAddressHolder.nonfungiblePositionManagerAddress()
        ).positions(tokenId);

        int24 tickDelta = tickUpper - tickLower;

        IUniswapV3Pool pool = IUniswapV3Pool(
            UniswapNFTHelper._getPoolFromTokenId(
                tokenId,
                INonfungiblePositionManager(uniswapAddressHolder.nonfungiblePositionManagerAddress()),
                uniswapAddressHolder.uniswapV3FactoryAddress()
            )
        );

        (, int24 tick, , , , , ) = pool.slot0();
        int24 tickSpacing = int24(fee) / 50;

        return (((tick - tickDelta) / tickSpacing) * tickSpacing, ((tick + tickDelta) / tickSpacing) * tickSpacing);
    }
}
