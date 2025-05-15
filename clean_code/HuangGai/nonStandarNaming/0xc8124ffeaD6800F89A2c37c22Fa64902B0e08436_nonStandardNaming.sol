



pragma solidity 0.6.6;




abstract contract Context {
    function _MSGSENDER742() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA476() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED603(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER742();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED603(address(0), msgSender);
    }


    function OWNER943() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER460() {
        require(_owner == _MSGSENDER742(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP291() public virtual ONLYOWNER460 {
        emit OWNERSHIPTRANSFERRED603(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP407(address newOwner) public virtual ONLYOWNER460 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED603(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract PriceProvider is Ownable {

    address public manager;

    string public providerName;

    uint8 public constant decimals686 = 2;
    bool public updateRequred;



    constructor(string memory _providerName, address _manager, bool _updateRequred) public Ownable() {
        providerName = _providerName;
        manager = _manager;
        updateRequred = _updateRequred;
    }



    function SETMANAGER980(address _manager) external ONLYOWNER460 {
        manager = _manager;
    }



    function LASTPRICE690() public virtual view returns (uint32);
}



interface IERC20 {

    function TOTALSUPPLY861() external view returns (uint256);


    function BALANCEOF276(address account) external view returns (uint256);


    function TRANSFER827(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE661(address owner, address spender) external view returns (uint256);


    function APPROVE898(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM273(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER185(address indexed from, address indexed to, uint256 value);


    event APPROVAL8(address indexed owner, address indexed spender, uint256 value);
}


abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    function NAME190() public view returns (string memory) {
        return _name;
    }


    function SYMBOL403() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS571() public view returns (uint8) {
        return _decimals;
    }
}


library FixedPoint {


    struct uq112x112 {
        uint224 _x;
    }



    struct uq144x112 {
        uint _x;
    }

    uint8 private constant resolution887 = 112;


    function ENCODE375(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << resolution887);
    }


    function ENCODE144305(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << resolution887);
    }


    function DIV530(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }



    function MUL252(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }



    function FRACTION125(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << resolution887) / denominator);
    }


    function DECODE122(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> resolution887);
    }


    function DECODE144956(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> resolution887);
    }
}

interface IUniswapV2Pair {
    event APPROVAL8(address indexed owner, address indexed spender, uint value);
    event TRANSFER185(address indexed from, address indexed to, uint value);

    function NAME190() external pure returns (string memory);
    function SYMBOL403() external pure returns (string memory);
    function DECIMALS571() external pure returns (uint8);
    function TOTALSUPPLY861() external view returns (uint);
    function BALANCEOF276(address owner) external view returns (uint);
    function ALLOWANCE661(address owner, address spender) external view returns (uint);

    function APPROVE898(address spender, uint value) external returns (bool);
    function TRANSFER827(address to, uint value) external returns (bool);
    function TRANSFERFROM273(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR374() external view returns (bytes32);
    function PERMIT_TYPEHASH748() external pure returns (bytes32);
    function NONCES344(address owner) external view returns (uint);

    function PERMIT537(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event MINT421(address indexed sender, uint amount0, uint amount1);
    event BURN632(address indexed sender, uint amount0, uint amount1, address indexed to);
    event SWAP642(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event SYNC872(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY496() external pure returns (uint);
    function FACTORY810() external view returns (address);
    function TOKEN0628() external view returns (address);
    function TOKEN1909() external view returns (address);
    function GETRESERVES186() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function PRICE0CUMULATIVELAST525() external view returns (uint);
    function PRICE1CUMULATIVELAST405() external view returns (uint);
    function KLAST975() external view returns (uint);

    function MINT537(address to) external returns (uint liquidity);
    function BURN439(address to) external returns (uint amount0, uint amount1);
    function SWAP853(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function SKIM750(address to) external;
    function SYNC911() external;

    function INITIALIZE196(address, address) external;
}


library UniswapV2OracleLibrary {
    using FixedPoint for *;


    function CURRENTBLOCKTIMESTAMP220() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }


    function CURRENTCUMULATIVEPRICES765(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = CURRENTBLOCKTIMESTAMP220();
        price0Cumulative = IUniswapV2Pair(pair).PRICE0CUMULATIVELAST525();
        price1Cumulative = IUniswapV2Pair(pair).PRICE1CUMULATIVELAST405();


        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).GETRESERVES186();
        if (blockTimestampLast != blockTimestamp) {

            uint32 timeElapsed = blockTimestamp - blockTimestampLast;


            price0Cumulative += uint(FixedPoint.FRACTION125(reserve1, reserve0)._x) * timeElapsed;

            price1Cumulative += uint(FixedPoint.FRACTION125(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}



library SafeMath {

    function ADD549(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB879(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB879(a, b, "SafeMath: subtraction overflow");
    }


    function SUB879(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL252(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV530(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV530(a, b, "SafeMath: division by zero");
    }


    function DIV530(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD417(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD417(a, b, "SafeMath: modulo by zero");
    }


    function MOD417(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library UniswapV2Library {
    using SafeMath for uint;


    function SORTTOKENS809(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }


    function PAIRFOR391(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = SORTTOKENS809(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ))));
    }


    function GETRESERVES186(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = SORTTOKENS809(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(PAIRFOR391(factory, tokenA, tokenB)).GETRESERVES186();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }


    function QUOTE986(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.MUL252(reserveB) / reserveA;
    }


    function GETAMOUNTOUT221(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.MUL252(997);
        uint numerator = amountInWithFee.MUL252(reserveOut);
        uint denominator = reserveIn.MUL252(1000).ADD549(amountInWithFee);
        amountOut = numerator / denominator;
    }


    function GETAMOUNTIN900(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.MUL252(amountOut).MUL252(1000);
        uint denominator = reserveOut.SUB879(amountOut).MUL252(997);
        amountIn = (numerator / denominator).ADD549(1);
    }


    function GETAMOUNTSOUT486(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = GETRESERVES186(factory, path[i], path[i + 1]);
            amounts[i + 1] = GETAMOUNTOUT221(amounts[i], reserveIn, reserveOut);
        }
    }


    function GETAMOUNTSIN740(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = GETRESERVES186(factory, path[i - 1], path[i]);
            amounts[i - 1] = GETAMOUNTIN900(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract PriceProviderUniswap is PriceProvider {

    using FixedPoint for *;
    using SafeMath for uint;

    IUniswapV2Pair public immutable pair;

    address immutable weth;
    address public immutable stableToken;

    uint priceCumulativeLast;
    uint price1CumulativeLast;
    uint32 blockTimestampLast;
    bool wethIsToken0;
    FixedPoint.uq112x112 priceAverage;



    constructor(address _manager, address _factory, address _weth, address _stableToken) public PriceProvider("Uniswap", _manager, true) {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.PAIRFOR391(_factory, _weth, _stableToken));
        pair = _pair;
        weth = _weth;
        if (_weth == _pair.TOKEN0628()) {
            wethIsToken0 = true;
        } else {
            wethIsToken0 = false;
        }
        stableToken = _stableToken;

        if (wethIsToken0 == true) {
            priceCumulativeLast = _pair.PRICE0CUMULATIVELAST525();
        } else {
            priceCumulativeLast = _pair.PRICE1CUMULATIVELAST405();
        }

        (,,blockTimestampLast) = _pair.GETRESERVES186();
    }

    function UPDATE754() external {
        require(msg.sender == manager, "manager!");
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.CURRENTCUMULATIVEPRICES765(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;



        if (wethIsToken0 == true) {
            priceAverage = FixedPoint.uq112x112(uint224((price0Cumulative - priceCumulativeLast) / timeElapsed));
            priceCumulativeLast = price0Cumulative;
        } else {
            priceAverage = FixedPoint.uq112x112(uint224((price1Cumulative - priceCumulativeLast) / timeElapsed));
            priceCumulativeLast = price1Cumulative;
        }

        blockTimestampLast = blockTimestamp;
    }



    function LASTPRICE690() public override view returns (uint32 price) {
        uint amountOut = priceAverage.MUL252(1 ether).DECODE144956();
        uint8 stableTokenDecimals = ERC20Detailed(stableToken).DECIMALS571();
        if (stableTokenDecimals >= decimals686) {
            price = uint32(amountOut.DIV530(10 ** uint(stableTokenDecimals - decimals686)));
        } else {
            price = uint32(amountOut.MUL252(10 ** uint(decimals686 - stableTokenDecimals)));
        }
    }
}
