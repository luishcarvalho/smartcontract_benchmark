


pragma solidity ^0.7.4;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ISwapRouter} from "../integrations/uniswap/IUniswapV3.sol";
import {BytesLib} from "../integrations/uniswap/BytesLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {CreditManager} from "../credit/CreditManager.sol";

import "hardhat/console.sol";


contract UniswapV3Adapter is ISwapRouter {
    using BytesLib for bytes;
    using SafeMath for uint256;

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;
    address public swapContract;


    uint256 private constant ADDR_SIZE = 20;




    constructor(address _creditManager, address _swapContract) {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
        swapContract = _swapContract;
    }




    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            swapContract,
            params.tokenIn
        );

        ExactInputSingleParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;


        bytes memory data = abi.encodeWithSelector(
            bytes4(0x414bf389),
            paramsUpdate
        );

        uint256 balanceBefore = IERC20(paramsUpdate.tokenIn).balanceOf(
            creditAccount
        );


        bytes memory result = creditManager.executeOrder(
            msg.sender,
            swapContract,
            data
        );
        (amountOut) = abi.decode(result, (uint256));

        creditFilter.checkCollateralChange(
            creditAccount,
            params.tokenIn,
            params.tokenOut,
            balanceBefore.sub(
                IERC20(paramsUpdate.tokenIn).balanceOf(creditAccount)
            ),
            amountOut
        );
    }




    function exactInput(ExactInputParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );


        (address tokenIn, address tokenOut) = _extractTokens(params.path);

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            swapContract,
            tokenIn
        );

        ExactInputParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;


        bytes memory data = abi.encodeWithSelector(
            bytes4(0xc04b8d59),
            paramsUpdate
        );

        uint256 balanceBefore = IERC20(tokenIn).balanceOf(creditAccount);

        bytes memory result = creditManager.executeOrder(
            msg.sender,
            swapContract,
            data
        );
        (amountOut) = abi.decode(result, (uint256));

        creditFilter.checkCollateralChange(
            creditAccount,
            tokenIn,
            tokenOut,
            balanceBefore.sub(IERC20(tokenIn).balanceOf(creditAccount)),
            amountOut
        );
    }




    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );


        creditManager.provideCreditAccountAllowance(
            creditAccount,
            swapContract,
            params.tokenIn
        );

        ExactOutputSingleParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;


        bytes memory data = abi.encodeWithSelector(
            bytes4(0xdb3e2198),
            paramsUpdate
        );

        uint256 balanceBefore = IERC20(paramsUpdate.tokenOut).balanceOf(
            creditAccount
        );

        bytes memory result = creditManager.executeOrder(
            msg.sender,
            swapContract,
            data
        );
        (amountIn) = abi.decode(result, (uint256));

        creditFilter.checkCollateralChange(
            creditAccount,
            params.tokenIn,
            params.tokenOut,
            amountIn,
            IERC20(paramsUpdate.tokenOut).balanceOf(creditAccount).sub(
                balanceBefore
            )
        );
    }




    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );


        (address tokenOut, address tokenIn) = _extractTokens(params.path);

        console.log(tokenIn);
        console.log(tokenOut);


        creditManager.provideCreditAccountAllowance(
            creditAccount,
            swapContract,
            tokenIn
        );

        ExactOutputParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;

        bytes memory data = abi.encodeWithSelector(
            bytes4(0xf28c0498),
            paramsUpdate
        );

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(creditAccount);

        {
            bytes memory result = creditManager.executeOrder(
                msg.sender,
                swapContract,
                data
            );
            (amountIn) = abi.decode(result, (uint256));
        }

        console.log("balanceBefore");
        console.log(balanceBefore);
        console.log(IERC20(tokenOut).balanceOf(creditAccount));

        creditFilter.checkCollateralChange(
            creditAccount,
            tokenIn,
            tokenOut,
            amountIn,
            IERC20(tokenOut).balanceOf(creditAccount).sub(balanceBefore)
        );
    }

    function _extractTokens(bytes memory path)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        tokenA = path.toAddress(0);
        tokenB = path.toAddress(path.length - ADDR_SIZE);
    }
}
