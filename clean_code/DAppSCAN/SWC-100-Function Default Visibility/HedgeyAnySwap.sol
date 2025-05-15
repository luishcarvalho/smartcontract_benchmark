    pragma solidity ^0.6.12;


    import "./libraries.sol"

    interface IWETH {
        function deposit() external payable;
        function transfer(address to, uint value) external returns (bool);
        function withdraw(uint) external;
    }

    interface IHedgeySwap {
        function hedgeySwap(address payable originalOwner, uint _c, uint totalPurchase, address[] memory path, bool cashBack) external;
    }


    interface IHedgey {
        function asset() external view returns (address asset);
        function pymtCurrency() external view returns (address pymtCurrency);
        function exercise(uint _c) external payable;

    }



    contract HedgeyAnySwap is ReentrancyGuard {
        using SafeMath for uint;
        using SafeERC20 for IERC20;


        address public factory;
        address payable public weth;
        uint8 public fee;

        constructor(address _factory, uint8 _fee, address payable _weth) public {
            factory = _factory;
            weth = _weth;
            fee = _fee;
        }




        receive() external payable {
        }



        function sortTokens(address tokenA, address tokenB) internal view returns (address token0, address token1) {
            require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
            (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
            require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
        }

        function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public view returns (uint amountOut) {
            require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
            require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
            uint amountInWithFee = amountIn.mul(10000 - fee);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(10000).add(amountInWithFee);
            amountOut = numerator / denominator;
        }


        function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public view returns (uint amountIn) {
            require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
            require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
            uint numerator = reserveIn.mul(amountOut).mul(10000);
            uint denominator = reserveOut.sub(amountOut).mul(10000 - fee);
            amountIn = (numerator / denominator).add(1);
        }


        function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
            require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
            amounts = new uint[](path.length);
            amounts[0] = amountIn;
            for (uint i; i < path.length - 1; i++) {
                (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
                amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            }
        }


        function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
            require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
            amounts = new uint[](path.length);
            amounts[amounts.length - 1] = amountOut;
            for (uint i = path.length - 1; i > 0; i--) {
                (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
                amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
            }
        }




        function getReserves(address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
            (address token0,) = sortTokens(tokenA, tokenB);
            address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        }




        function swap(bool send, address tokenIn, address tokenOut, uint _in, uint out, address to) internal {
            address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
            if (send) SafeERC20.safeTransfer(IERC20(tokenIn), pair, _in);
            address token0 = IUniswapV2Pair(pair).token0();
            if (tokenIn == token0) {
                IUniswapV2Pair(pair).swap(0, out, to, new bytes(0));
            } else {
                IUniswapV2Pair(pair).swap(out, 0, to, new bytes(0));
            }

        }


        function multiSwap(address[] memory path, uint amountOut, uint amountIn, address to) internal {
           require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
           require((amountOut > 0 && amountIn == 0) || (amountIn > 0 && amountOut == 0), "one of the amounts must be 0");
           uint[] memory amounts = (amountOut > 0) ? getAmountsIn(amountOut, path) : getAmountsOut(amountIn, path);
           for (uint i = 0; i < path.length - 1; i++) {
               address _to = (i < path.length - 2) ? IUniswapV2Factory(factory).getPair(path[i+1], path[i+2]) : to;
               swap((i == 0), path[i], path[i+1], amounts[i], amounts[i+1], _to);
           }
        }





        function flashSwap(address borrowedToken, address tokenDue, uint out, bytes memory data) internal {
            address pair = IUniswapV2Factory(factory).getPair(borrowedToken, tokenDue);
            address token0 = IUniswapV2Pair(pair).token0();
            if (borrowedToken == token0) {
                IUniswapV2Pair(pair).swap(0, out, address(this), data);
            } else {
                IUniswapV2Pair(pair).swap(out, 0, address(this), data);
            }
        }


        function uniswapV2Call(address sender, uint amount0, uint amount1, bytes memory data) external {

            address token0 = IUniswapV2Pair(msg.sender).token0();
            address token1 = IUniswapV2Pair(msg.sender).token1();
            (uint reserveA, uint reserveB) = getReserves(token0, token1);
            assert(msg.sender == IUniswapV2Factory(factory).getPair(token0, token1));
            (address payable _hedgey, uint _n, address[] memory path, bool optionType) = abi.decode(data, (address, uint, address[], bool));

            uint amountDue = amount0 == 0 ? getAmountIn(amount1, reserveA, reserveB) : getAmountIn(amount0, reserveB, reserveA);
            uint purchase = amount0 == 0 ? amount1 : amount0;
            if (optionType) {
                (address asset) = exerciseCall(_hedgey, _n, purchase);

                multiSwap(path, amountDue, 0, msg.sender);
            } else {

                (address paymentCurrency) = exercisePut(_hedgey, _n, purchase);

                multiSwap(path, amountDue, 0, msg.sender);
            }


        }



        function exerciseCall(address payable hedgeyCalls, uint _c, uint purchase) internal returns (address asset) {

            if(IHedgey(hedgeyCalls).pymtCurrency() == weth) {

                IWETH(weth).withdraw(purchase);
                IHedgey(hedgeyCalls).exercise{value: purchase}(_c);
            } else {
                SafeERC20.safeIncreaseAllowance(IERC20(IHedgey(hedgeyCalls).pymtCurrency()), hedgeyCalls, purchase);
                IHedgey(hedgeyCalls).exercise(_c);
            }


            asset = IHedgey(hedgeyCalls).asset();
        }


        function exercisePut(address payable hedgeyPuts, uint _p, uint sale) internal returns (address paymentCurrency) {
            if(IHedgey(hedgeyPuts).asset() == weth) {

                IWETH(weth).withdraw(sale);
                IHedgey(hedgeyPuts).exercise{value: sale}(_p);
            } else {
                SafeERC20.safeIncreaseAllowance(IERC20(IHedgey(hedgeyPuts).asset()), hedgeyPuts, sale);
                IHedgey(hedgeyPuts).exercise(_p);
            }

            paymentCurrency = IHedgey(hedgeyPuts).pymtCurrency();

        }


        function hedgeyCallSwap(address payable originalOwner, uint _c, uint totalPurchase, address[] memory path, bool cashBack) external payable nonReentrant {



            address[] memory _path = new address[](path.length - 1);
            for (uint i; i < path.length - 1; i++) {
                _path[i] = path[i];
            }
            bytes memory data = abi.encode(msg.sender, _c, _path, true);
            flashSwap(path[path.length - 2], path[path.length - 1], totalPurchase, data);

            if(cashBack) {

                if(IHedgey(msg.sender).pymtCurrency() == weth) {
                    multiSwap(path, 0, IERC20(path[0]).balanceOf(address(this)), address(this));

                    uint wethBalance = IERC20(weth).balanceOf(address(this));
                    IWETH(weth).withdraw(wethBalance);
                    originalOwner.transfer(wethBalance);
                } else {
                    multiSwap(path, 0, IERC20(path[0]).balanceOf(address(this)), originalOwner);
                }

            } else {
                if(IHedgey(msg.sender).asset() == weth) {
                    uint wethBalance = IERC20(weth).balanceOf(address(this));
                    IWETH(weth).withdraw(wethBalance);
                    originalOwner.transfer(wethBalance);
                } else {
                    SafeERC20.safeTransfer(IERC20(path[0]), originalOwner, IERC20(path[0]).balanceOf(address(this)));
                }

            }
        }

        function hedgeyPutSwap(address payable originalOwner, uint _p, uint assetAmount, address[] memory path) external payable nonReentrant {

            address[] memory _path = new address[](path.length - 1);
            for (uint i; i < path.length - 1; i++) {
                _path[i] = path[i];
            }
            bytes memory data = abi.encode(msg.sender, _p, _path, false);
            flashSwap(path[path.length - 2], path[path.length - 1], assetAmount, data);
            if(IHedgey(msg.sender).pymtCurrency() == weth) {
                uint wethBalance = IERC20(weth).balanceOf(address(this));
                IWETH(weth).withdraw(wethBalance);
                originalOwner.transfer(wethBalance);
            } else {
                SafeERC20.safeTransfer(IERC20(path[0]), originalOwner, IERC20(path[0]).balanceOf(address(this)));
            }

        }


    }


