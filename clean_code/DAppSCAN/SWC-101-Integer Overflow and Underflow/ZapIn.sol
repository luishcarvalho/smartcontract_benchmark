

pragma solidity 0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '../helpers/UniswapNFTHelper.sol';
import '../helpers/SwapHelper.sol';
import '../helpers/ERC20Helper.sol';
import '../utils/Storage.sol';
import '../../interfaces/IPositionManager.sol';
import '../../interfaces/actions/IZapIn.sol';

contract ZapIn is IZapIn {





    event ZappedIn(address indexed positionManager, uint256 tokenId, address tokenIn, uint256 amountIn);










    function zapIn(
        address tokenIn,
        uint256 amountIn,
        address token0,
        address token1,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) public override returns (uint256 tokenId) {
        require(token0 != token1, 'ZapIn::zapIn: token0 and token1 cannot be the same');
        (token0, token1) = _reorderTokens(token0, token1);

        StorageStruct storage Storage = PositionManagerStorage.getStorage();
        ERC20Helper._pullTokensIfNeeded(tokenIn, Storage.owner, amountIn);

        ERC20Helper._approveToken(tokenIn, Storage.uniswapAddressHolder.swapRouterAddress(), amountIn);

        (, int24 tickPool, , , , , ) = IUniswapV3Pool(
            UniswapNFTHelper._getPool(Storage.uniswapAddressHolder.uniswapV3FactoryAddress(), token0, token1, fee)
        ).slot0();

        uint256 amountInTo0 = (amountIn * 1e18) / (SwapHelper.getRatioFromRange(tickPool, tickLower, tickUpper) + 1e18);
        uint256 amountInTo1 = amountIn - amountInTo0;

        ERC20Helper._approveToken(tokenIn, Storage.uniswapAddressHolder.swapRouterAddress(), amountIn);

        if (tokenIn != token0) {
            amountInTo0 = ISwapRouter(Storage.uniswapAddressHolder.swapRouterAddress()).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: token0,
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp + 120,
                    amountIn: amountInTo0,
                    amountOutMinimum: 1,
                    sqrtPriceLimitX96: 0
                })
            );
        }


        if (tokenIn != token1) {
            ERC20Helper._approveToken(tokenIn, Storage.uniswapAddressHolder.swapRouterAddress(), amountIn);
            amountInTo1 = ISwapRouter(Storage.uniswapAddressHolder.swapRouterAddress()).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: token1,
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp + 120,
                    amountIn: amountInTo1,
                    amountOutMinimum: 1,
                    sqrtPriceLimitX96: 0
                })
            );
        }

        (tokenId, , ) = _mint(token0, token1, fee, tickLower, tickUpper, amountInTo0, amountInTo1);

        emit ZappedIn(address(this), tokenId, tokenIn, amountIn);
    }









    function _mint(
        address token0Address,
        address token1Address,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    )
        internal
        returns (
            uint256 tokenId,
            uint256 amount0Deposited,
            uint256 amount1Deposited
        )
    {
        StorageStruct storage Storage = PositionManagerStorage.getStorage();

        ERC20Helper._approveToken(
            token0Address,
            Storage.uniswapAddressHolder.nonfungiblePositionManagerAddress(),
            amount0Desired
        );
        ERC20Helper._approveToken(
            token1Address,
            Storage.uniswapAddressHolder.nonfungiblePositionManagerAddress(),
            amount1Desired
        );

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0Address,
            token1: token1Address,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 120
        });

        (tokenId, , amount0Deposited, amount1Deposited) = INonfungiblePositionManager(
            Storage.uniswapAddressHolder.nonfungiblePositionManagerAddress()
        ).mint(params);

        IPositionManager(address(this)).middlewareDeposit(tokenId);
    }






    function _reorderTokens(address token0, address token1) internal pure returns (address, address) {
        if (token0 > token1) {
            return (token1, token0);
        } else {
            return (token0, token1);
        }
    }
}
