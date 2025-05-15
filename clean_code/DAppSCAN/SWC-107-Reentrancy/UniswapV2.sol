


pragma solidity ^0.7.4;

import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {CreditManager} from "../credit/CreditManager.sol";
import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";
import "../integrations/uniswap/IUniswapV2Router02.sol";


contract UniswapV2Adapter is IUniswapV2Router02 {
    ICreditManager public creditManager;
    ICreditFilter public creditFilter;
    using SafeMath for uint256;
    address public swapContract;




    constructor(address _creditManager, address _swapContract) {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
        swapContract = _swapContract;
    }















    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            swapContract,
            path[0]
        );

        bytes memory data = abi.encodeWithSelector(
            bytes4(0x8803dbee),
            amountOut,
            amountInMax,
            path,
            creditAccount,
            deadline
        );

        amounts = abi.decode(
            creditManager.executeOrder(msg.sender, swapContract, data),
            (uint256[])
        );


        creditFilter.checkCollateralChange(
            creditAccount,
            path[0],
            path[path.length - 1],
            amounts[0],
            amounts[amounts.length - 1]
        );
    }















    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            swapContract,
            path[0]
        );

        bytes memory data = abi.encodeWithSelector(
            bytes4(0x38ed1739),
            amountIn,
            amountOutMin,
            path,
            creditAccount,
            deadline
        );

        amounts = abi.decode(
            creditManager.executeOrder(msg.sender, swapContract, data),
            (uint256[])
        );

        creditFilter.checkCollateralChange(
            creditAccount,
            path[0],
            path[path.length - 1],
            amounts[0],
            amounts[amounts.length - 1]
        );
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountETH) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountETH) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable override {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function factory() external view override returns (address) {
        return IUniswapV2Router02(swapContract).factory();
    }

    function WETH() external view override returns (address) {
        return IUniswapV2Router02(swapContract).WETH();
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountA, uint256 amountB) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override returns (uint256 amountToken, uint256 amountETH) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountA, uint256 amountB) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountToken, uint256 amountETH) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable override returns (uint256[] memory amounts) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable override returns (uint256[] memory amounts) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external view override returns (uint256 amountB) {
        return
            IUniswapV2Router02(swapContract).quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view override returns (uint256 amountOut) {
        return
            IUniswapV2Router02(swapContract).getAmountOut(
                amountIn,
                reserveIn,
                reserveOut
            );
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view override returns (uint256 amountIn) {
        return
            IUniswapV2Router02(swapContract).getAmountIn(
                amountOut,
                reserveIn,
                reserveOut
            );
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        return IUniswapV2Router02(swapContract).getAmountsOut(amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        return IUniswapV2Router02(swapContract).getAmountsOut(amountOut, path);
    }
}
