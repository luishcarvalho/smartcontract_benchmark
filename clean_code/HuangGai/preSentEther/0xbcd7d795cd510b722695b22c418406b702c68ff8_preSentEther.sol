



pragma solidity =0.6.12;


interface ITitanFeeMaker {
    function depositLp(address _lpToken,uint256 _amount) external;
    function withdrawLp(address _lpToken,uint256 _amount) external;

    function withdrawETH(address to) external;
    function withdrawUSDT(address to) external;
    function withdrawTitan(uint256 amount) external;

    function chargeTitan(uint256 amount) external;
    function adjustTitanBonus(uint256 _BONUS_MULTIPLIER) external;
}

interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITitanSwapV1ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface ITitanSwapV1Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface ITitanSwapV1Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract TitanFeeMaker is Ownable,ITitanFeeMaker{
    using SafeMath for uint256;

    ITitanSwapV1Factory public factory;
    address public weth;
    address public titan;
    address public usdt;
    address public routerAddress;


    uint256 public BONUS_MULTIPLIER = 100;

    uint256 public constant BONUS_BASE_RATE = 100;

    uint256 public titanRewardAmount = 0;

    uint256 public titanRewardAmountAlready = 0;



    struct PoolInfo {
        address lpToken;
        uint256 lastRewardBlock;
        uint256 accTitanPerShare;
    }


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }


    mapping (address => PoolInfo) public poolInfo;
    mapping (address => mapping(address => UserInfo)) public userInfo;


    receive() external payable {
        assert(msg.sender == weth);
    }

    constructor(ITitanSwapV1Factory _factory,address _routerAddress,address _titan,address _weth,address _usdt) public {
        factory = _factory;
        titan = _titan;
        weth = _weth;
        usdt = _usdt;
        routerAddress = _routerAddress;
    }

    event createPool(address indexed lpToken,uint256 blockNumber);



    function updatePool(address _lpToken,uint256 _addLpAmount) private {
        PoolInfo storage pool =  poolInfo[_lpToken];

        if(address(this).balance == 0) {
            poolInfo[_lpToken] = PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: block.number,
            accTitanPerShare: 0
            });
            pool = poolInfo[_lpToken];
            emit createPool(_lpToken,block.number);
        }

        if(block.number < pool.lastRewardBlock) {
            return;
        }

        pool.lastRewardBlock = block.number;
        uint256 feeLpBalance = ITitanSwapV1Pair(pool.lpToken).balanceOf(address(this));
        if(address(this).balance == 0) {
           return;
        }
        uint256 titanFeeReward = convertLpToTitan(ITitanSwapV1Pair(pool.lpToken),feeLpBalance);
        if(address(this).balance == 0) {
            return;
        }

        titanFeeReward = titanFeeReward.mul(BONUS_MULTIPLIER).div(BONUS_BASE_RATE);
        titanRewardAmount = titanRewardAmount.add(titanFeeReward);
        uint256 lpSupply = ITitanSwapV1Pair(pool.lpToken).totalSupply().sub(_addLpAmount);
        pool.accTitanPerShare = pool.accTitanPerShare.add(titanFeeReward.mul(1e18).div(lpSupply));
    }


    function depositLp(address _lpToken,uint256 _amount) external override {
        if(_amount > 0) {
            require(msg.sender == routerAddress,'TitanSwapV1FeeMaker: must call by router');
        }
        updatePool(_lpToken,_amount);
        PoolInfo storage pool = poolInfo[_lpToken];
        UserInfo storage user = userInfo[_lpToken][tx.origin];
        if(user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTitanPerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                require(IERC20(titan).balanceOf(address(this)) >= pending,'TitanSwapV1FeeMaker: titan not enough');
                TransferHelper.safeTransfer(titan,tx.origin,pending);
                titanRewardAmountAlready = titanRewardAmountAlready.add(pending);
            }
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accTitanPerShare).div(1e18);
    }

    function withdrawLp(address _lpToken,uint256 _amount) external override {
        if(_amount > 0) {
            require(msg.sender == routerAddress,'TitanSwapV1FeeMaker: must call by router');
        }
        updatePool(_lpToken,0);
        PoolInfo storage pool = poolInfo[_lpToken];
        UserInfo storage user = userInfo[_lpToken][tx.origin];
        require(user.amount >= _amount,'remove lp not good');
        uint256 pending = user.amount.mul(pool.accTitanPerShare).div(1e18).sub(user.rewardDebt);
        if(pending > 0) {
             require(IERC20(titan).balanceOf(address(this)) >= pending,'TitanSwapV1FeeMaker: titan not enough');
            TransferHelper.safeTransfer(titan,tx.origin,pending);
            titanRewardAmountAlready = titanRewardAmountAlready.add(pending);
        }
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accTitanPerShare).div(1e18);
    }



    function convertLpToTitan(ITitanSwapV1Pair _pair,uint256 _feeLpBalance) private returns(uint256){

        uint256 beforeTitan = IERC20(titan).balanceOf(address(this));
        uint256 beforeWeth = IERC20(weth).balanceOf(address(this));
        uint256 beforeUsdt = IERC20(usdt).balanceOf(address(this));

        _pair.transfer(address(_pair),_feeLpBalance);
        _pair.burn(address(this));

        address token0 = _pair.token0();
        address token1 = _pair.token1();

        if(token0 == weth || token1 == weth) {

           _toWETH(token0);
           _toWETH(token1);
           uint256 wethAmount = IERC20(weth).balanceOf(address(this)).sub(beforeWeth);
           if(token0 == titan || token1 == titan) {
                ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,weth));
                (uint reserve0, uint reserve1,) = pair.getReserves();
                address _token0 = pair.token0();
                (uint reserveIn, uint reserveOut) = _token0 == titan ? (reserve0, reserve1) : (reserve1, reserve0);
                uint titanAmount = IERC20(titan).balanceOf(address(this)).sub(beforeTitan);
                uint256 titanWethAmount = reserveOut.mul(titanAmount).div(reserveIn);
                wethAmount = wethAmount.add(titanWethAmount);
           }

           return _wethToTitan(wethAmount);
        }

        if(token0 == usdt || token1 == usdt) {

            _toUSDT(token0);
            _toUSDT(token1);
           uint256 usdtAmount = IERC20(usdt).balanceOf(address(this)).sub(beforeUsdt);
           if(token0 == titan || token1 == titan) {
                ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,usdt));
                (uint reserve0, uint reserve1,) = pair.getReserves();
                address _token0 = pair.token0();
                (uint reserveIn, uint reserveOut) = _token0 == titan ? (reserve0, reserve1) : (reserve1, reserve0);
                uint titanAmount = IERC20(titan).balanceOf(address(this)).sub(beforeTitan);
                uint256 titanUsdtAmount = reserveOut.mul(titanAmount).div(reserveIn);
                usdtAmount = usdtAmount.add(titanUsdtAmount);
           }

           return _usdtToTitan(usdtAmount);
        }
        return 0;
    }

    function _toUSDT(address token) private returns (uint256) {
        if(token == usdt || token == titan) {
            return 0;
        }
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(token,usdt));
        if(address(pair) == address(0)) {
           return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);

        return swapTokenForWethOrUsdt(token,token0,pair,reserveIn,reserveOut);
    }

    function _toWETH(address token) private returns (uint256) {
        if(token == weth || token == titan) {
            return 0;
        }
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(token,weth));
        if(address(pair) == address(0)) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);

        return swapTokenForWethOrUsdt(token,token0,pair,reserveIn,reserveOut);
    }

    function swapTokenForWethOrUsdt(address token,address token0,ITitanSwapV1Pair pair,uint reserveIn,uint reserveOut) private returns (uint256) {

        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        TransferHelper.safeTransfer(token,address(pair),amountIn);

        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        return amountOut;
    }

    function _wethToTitan(uint256 amountIn) internal view returns (uint256) {
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,weth));
        require(address(pair) != address(0),'TitanSwapV1FeeMaker: titan/eth not exist');
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        return reserveOut.mul(amountIn).div(reserveIn);
    }

    function _usdtToTitan(uint256 amountIn) internal view returns (uint256) {
        ITitanSwapV1Pair pair = ITitanSwapV1Pair(factory.getPair(titan,usdt));
        require(address(pair) != address(0),'TitanSwapV1FeeMaker: titan/usdt not exist');
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == usdt ? (reserve0, reserve1) : (reserve1, reserve0);
        return reserveOut.mul(amountIn).div(reserveIn);
    }

    function withdrawETH(address to) external override onlyOwner{
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));

        IWETH(weth).withdraw(wethBalance);
        TransferHelper.safeTransferETH(to,wethBalance);

    }

     function withdrawUSDT(address to) external override onlyOwner{
        uint256 usdtBalance = IERC20(usdt).balanceOf(address(this));
        require(usdtBalance > 0,'TitanSwapV1FeeMaker: usdt amount == 0');
        TransferHelper.safeTransfer(usdt,to,usdtBalance);
    }

    function chargeTitan(uint256 _amount) external override {
        TransferHelper.safeTransferFrom(titan,msg.sender,address(this),_amount);
    }

    function withdrawTitan(uint256 _amount) external override onlyOwner {
        uint256 balance = IERC20(titan).balanceOf(address(this));
        require(balance >= _amount,'balance not enough');
        TransferHelper.safeTransfer(titan,msg.sender,_amount);
    }

    function adjustTitanBonus(uint256 _BONUS_MULTIPLIER) external override onlyOwner {
        require(_BONUS_MULTIPLIER >= 100,'number must >= 100');
        BONUS_MULTIPLIER = _BONUS_MULTIPLIER;
    }

}


library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library TitanSwapV1Library {
    using SafeMath for uint;


    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TitanSwapV1Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TitanSwapV1Library: ZERO_ADDRESS');
    }


    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = ITitanSwapV1Factory(factory).getPair(tokenA,tokenB);
    }


    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ITitanSwapV1Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }


    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'TitanSwapV1Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'TitanSwapV1Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }


    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TitanSwapV1Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TitanSwapV1Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }


    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'TitanSwapV1Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TitanSwapV1Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }


    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TitanSwapV1Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TitanSwapV1Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
