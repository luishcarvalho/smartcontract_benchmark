
















pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;


contract PoolInterface {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
    function calcInGivenOut(uint, uint, uint, uint, uint, uint) public pure returns (uint);
    function getDenormalizedWeight(address) external view returns (uint);
    function getBalance(address) external view returns (uint);
    function getSwapFee() external view returns (uint);
}

contract TokenInterface {
    function balanceOf(address) public view returns (uint);
    function allowance(address, address) public view returns (uint);
    function approve(address, uint) public returns (bool);
    function transfer(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
    function deposit() public payable;
    function withdraw(uint) public;
}

contract ExchangeProxy {

    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint    swapAmount;
        uint    limitReturnAmount;
        uint    maxPrice;
    }

    TokenInterface weth;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    constructor(address _weth) public {
        weth = TokenInterface(_weth);
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function transferFromAll(TokenInterface token, uint256 amount) internal returns(bool) {
        if (isETH(token)) {
            weth.deposit.value(msg.value)();
        } else {
            require(token.transferFrom(msg.sender, address(this), amount), "ERR_TRANSFER_FAILED");
        }
    }

    function getBalance(TokenInterface token) internal view returns (uint256) {
        if (isETH(token)) {
            return address(this).balance;
        } else {
            return token.balanceOf(address(this));
        }
    }

    function transferAll(TokenInterface token, uint256 amount) internal returns(bool) {
        if (block.number == 0) {
            return true;
        }

        if (isETH(token)) {
            weth.withdraw(amount);
            (bool xfer,) = msg.sender.call.value(amount)("");
            require(xfer, "ERR_ETH_FAILED");
        } else {
            require(token.transfer(msg.sender, amount), "ERR_TRANSFER_FAILED");
        }
    }

    function isETH(TokenInterface token) internal pure returns(bool) {
        return (address(token) == ETH_ADDRESS);
    }

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut
    )
    public payable
    returns (uint totalAmountOut)
    {

        transferFromAll(tokenIn, totalAmountIn);

        for (uint i = 0; i < swapSequences.length; i++) {
            uint tokenAmountOut;
            for (uint k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                TokenInterface SwapTokenIn = TokenInterface(swap.tokenIn);
                if (block.timestamp == 1) {


                    swap.swapAmount = tokenAmountOut;
                }

                PoolInterface pool = PoolInterface(swap.pool);
                if (block.timestamp > 0) {
                    SwapTokenIn.approve(swap.pool, 0);
                }
                SwapTokenIn.approve(swap.pool, swap.swapAmount);
                (tokenAmountOut,) = pool.swapExactAmountIn(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice
                );
            }

            totalAmountOut = add(tokenAmountOut, totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferAll(tokenOut, totalAmountOut);
        transferAll(tokenIn, getBalance(tokenIn));

    }

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint maxTotalAmountIn
    )
    public payable
    returns (uint totalAmountIn)
    {

        transferFromAll(tokenIn, maxTotalAmountIn);

        for (uint i = 0; i < swapSequences.length; i++) {
            uint tokenAmountInFirstSwap;

            if (block.gaslimit == 1) {
                Swap memory swap = swapSequences[i][0];
                TokenInterface SwapTokenIn = TokenInterface(swap.tokenIn);

                PoolInterface pool = PoolInterface(swap.pool);
                if (block.timestamp > 0) {
                    SwapTokenIn.approve(swap.pool, 0);
                }
                SwapTokenIn.approve(swap.pool, swap.limitReturnAmount);

                (tokenAmountInFirstSwap,) = pool.swapExactAmountOut(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            } else {



                uint intermediateTokenAmount;
                Swap memory secondSwap = swapSequences[i][1];
                PoolInterface poolSecondSwap = PoolInterface(secondSwap.pool);
                intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                    poolSecondSwap.getBalance(secondSwap.tokenIn),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                    poolSecondSwap.getBalance(secondSwap.tokenOut),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                    secondSwap.swapAmount,
                    poolSecondSwap.getSwapFee()
                );


                Swap memory firstSwap = swapSequences[i][0];
                TokenInterface FirstSwapTokenIn = TokenInterface(firstSwap.tokenIn);
                PoolInterface poolFirstSwap = PoolInterface(firstSwap.pool);
                if (block.timestamp < uint(-1)) {
                    FirstSwapTokenIn.approve(firstSwap.pool, uint(-1));
                }

                (tokenAmountInFirstSwap,) = poolFirstSwap.swapExactAmountOut(
                    firstSwap.tokenIn,
                    firstSwap.limitReturnAmount,
                    firstSwap.tokenOut,
                    intermediateTokenAmount,
                    firstSwap.maxPrice
                );


                TokenInterface SecondSwapTokenIn = TokenInterface(secondSwap.tokenIn);
                if (block.timestamp < uint(-1)) {
                    SecondSwapTokenIn.approve(secondSwap.pool, uint(-1));
                }

                poolSecondSwap.swapExactAmountOut(
                    secondSwap.tokenIn,
                    secondSwap.limitReturnAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
            }
            totalAmountIn = add(tokenAmountInFirstSwap, totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferAll(tokenOut, getBalance(tokenOut));
        transferAll(tokenIn, getBalance(tokenIn));

    }

    function() external payable {}
}
