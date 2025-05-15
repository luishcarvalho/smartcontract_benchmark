














pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;



interface ICoFiXERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);



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


interface ICoFiXPair is ICoFiXERC20 {

    struct OraclePrice {
        uint256 ethAmount;
        uint256 erc20Amount;
        uint256 blockNum;
        uint256 K;
        uint256 theta;
    }


    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, address outToken, uint outAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address outToken,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function mint(address to) external payable returns (uint liquidity, uint oracleFeeChange);
    function burn(address outToken, address to) external payable returns (uint amountOut, uint oracleFeeChange);
    function swapWithExact(address outToken, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo);
    function swapForExact(address outToken, uint amountOutExact, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo);
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, string memory, string memory) external;





    function getNAVPerShare(uint256 ethAmount, uint256 erc20Amount) external view returns (uint256 navps);
}


interface ICoFiXFactory {

    event PairCreated(address indexed token, address pair, uint256);
    event NewGovernance(address _new);
    event NewController(address _new);
    event NewFeeReceiver(address _new);
    event NewFeeVaultForLP(address token, address feeVault);
    event NewVaultForLP(address _new);
    event NewVaultForTrader(address _new);
    event NewVaultForCNode(address _new);




    function createPair(
        address token
        )
        external
        returns (address pair);

    function getPair(address token) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function getTradeMiningStatus(address token) external view returns (bool status);
    function setTradeMiningStatus(address token, bool status) external;
    function getFeeVaultForLP(address token) external view returns (address feeVault);
    function setFeeVaultForLP(address token, address feeVault) external;

    function setGovernance(address _new) external;
    function setController(address _new) external;
    function setFeeReceiver(address _new) external;
    function setVaultForLP(address _new) external;
    function setVaultForTrader(address _new) external;
    function setVaultForCNode(address _new) external;
    function getController() external view returns (address controller);
    function getFeeReceiver() external view returns (address feeReceiver);
    function getVaultForLP() external view returns (address vaultForLP);
    function getVaultForTrader() external view returns (address vaultForTrader);
    function getVaultForCNode() external view returns (address vaultForCNode);
}


interface ICoFiXController {

    event NewK(address token, int128 K, int128 sigma, uint256 T, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum, uint256 tIdx, uint256 sigmaIdx, int128 K0);
    event NewGovernance(address _new);
    event NewOracle(address _priceOracle);
    event NewKTable(address _kTable);
    event NewTimespan(uint256 _timeSpan);
    event NewKRefreshInterval(uint256 _interval);
    event NewKLimit(int128 maxK0);
    event NewGamma(int128 _gamma);
    event NewTheta(address token, uint32 theta);

    function addCaller(address caller) external;

    function queryOracle(address token, uint8 op, bytes memory data) external payable returns (uint256 k, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum, uint256 theta);
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



contract CoFiXERC20 is ICoFiXERC20 {
    using SafeMath for uint;

    string public constant nameForDomain = 'CoFiX Pool Token';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;

    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(nameForDomain)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'CERC20: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'CERC20: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}



library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {

        (bool success, bytes memory data) = (false, bytes(msg.data));
	 token.call(abi.encodeWithSelector(0x095ea7b3, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {

        (bool success, bytes memory data) = (false, bytes(msg.data));
	 token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {

        (bool success, bytes memory data) = (false, bytes(msg.data));
	 token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = (false, bytes(msg.data));
	 to.call{value:value}(new bytes(0));

        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}




contract CoFiXPair is ICoFiXPair, CoFiXERC20 {
    using SafeMath for uint;

    enum CoFiX_OP { QUERY, MINT, BURN, SWAP_WITH_EXACT, SWAP_FOR_EXACT }

    uint public override constant MINIMUM_LIQUIDITY = 10**9;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    uint256 constant public K_BASE = 1E8;
    uint256 constant public NAVPS_BASE = 1E18;
    uint256 constant public THETA_BASE = 1E8;

    string public name;
    string public symbol;

    address public override immutable factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint private unlocked = 1;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, address outToken, uint outAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address outToken,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    modifier lock() {
        require(unlocked == 1, "CPair: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        factory = msg.sender;
    }

    receive() external payable {}


    function initialize(address _token0, address _token1, string memory _name, string memory _symbol) external override {
        require(msg.sender == factory, "CPair: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
        name = _name;
        symbol = _symbol;
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = (false, bytes(msg.data));
	 token.call(abi.encodeWithSelector(SELECTOR, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), "CPair: TRANSFER_FAILED");
    }


    function _update(uint balance0, uint balance1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), "CPair: OVERFLOW");
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }


    function mint(address to) external payable override lock returns (uint liquidity, uint oracleFeeChange) {
        address _token0 = token0;
        address _token1 = token1;
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        uint256 _ethBalanceBefore = address(this).balance;
        {
            bytes memory data = abi.encode(msg.sender, to, amount0, amount1);

            OraclePrice memory _op;
            (_op.K, _op.ethAmount, _op.erc20Amount, _op.blockNum, _op.theta) = _queryOracle(_token1, CoFiX_OP.MINT, data);
            uint256 navps = calcNAVPerShareForMint(_reserve0, _reserve1, _op);
            if (totalSupply == 0) {
                liquidity = calcLiquidity(amount0, amount1, navps, _op).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY);
            } else {
                liquidity = calcLiquidity(amount0, amount1, navps, _op);
            }
        }
        oracleFeeChange = msg.value.sub(_ethBalanceBefore.sub(address(this).balance));

        require(liquidity > 0, "CPair: SHORT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1);
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);

        emit Mint(msg.sender, amount0, amount1);
    }


    function burn(address outToken, address to) external payable override lock returns (uint amountOut, uint oracleFeeChange) {
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint256 _ethBalanceBefore = address(this).balance;
        uint256 fee;
        {
            bytes memory data = abi.encode(msg.sender, outToken, to, liquidity);

            OraclePrice memory _op;
            (_op.K, _op.ethAmount, _op.erc20Amount, _op.blockNum, _op.theta) = _queryOracle(_token1, CoFiX_OP.BURN, data);
            if (outToken == _token0) {
                (amountOut, fee) = calcOutToken0ForBurn(liquidity, _op);
            } else if (outToken == _token1) {
                (amountOut, fee) = calcOutToken1ForBurn(liquidity, _op);
            }  else {
                revert("CPair: wrong outToken");
            }
        }
        oracleFeeChange = msg.value.sub(_ethBalanceBefore.sub(address(this).balance));

        require(amountOut > 0, "CPair: SHORT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(outToken, to, amountOut);
        if (fee > 0) {
            if (ICoFiXFactory(factory).getTradeMiningStatus(_token1)) {

                _safeSendFeeForCoFiHolder(_token0, fee);
            } else {
                _safeSendFeeForLP(_token0, _token1, fee);
            }
        }
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);

        emit Burn(msg.sender, outToken, amountOut, to);
    }



    function swapWithExact(address outToken, address to)
        external
        payable override lock
        returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo)
    {

        address _token0 = token0;
        address _token1 = token1;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));


        {
            uint256 _ethBalanceBefore = address(this).balance;
            (uint112 _reserve0, uint112 _reserve1) = getReserves();

            if (outToken == _token1) {
                amountIn = balance0.sub(_reserve0);
            } else if (outToken == _token0) {
                amountIn = balance1.sub(_reserve1);
            } else {
                revert("CPair: wrong outToken");
            }
            require(amountIn > 0, "CPair: wrong amountIn");
            bytes memory data = abi.encode(msg.sender, outToken, to, amountIn);

            OraclePrice memory _op;
            (_op.K, _op.ethAmount, _op.erc20Amount, _op.blockNum, _op.theta) = _queryOracle(_token1, CoFiX_OP.SWAP_WITH_EXACT, data);
            if (outToken == _token1) {
                (amountOut, tradeInfo[0]) = calcOutToken1(amountIn, _op);
                tradeInfo[1] = _reserve0;
                tradeInfo[2] = uint256(_reserve1).mul(_op.ethAmount).div(_op.erc20Amount);
            } else if (outToken == _token0) {
                (amountOut, tradeInfo[0]) = calcOutToken0(amountIn, _op);
                tradeInfo[1] = uint256(_reserve1).mul(_op.ethAmount).div(_op.erc20Amount);
                tradeInfo[2] = _reserve0;
            }
            oracleFeeChange = msg.value.sub(_ethBalanceBefore.sub(address(this).balance));
            tradeInfo[3] = calcNAVPerShare(_reserve0, _reserve1, _op.ethAmount, _op.erc20Amount);
        }

        require(to != _token0 && to != _token1, "CPair: INVALID_TO");

        _safeTransfer(outToken, to, amountOut);
        if (tradeInfo[0] > 0) {
            if (ICoFiXFactory(factory).getTradeMiningStatus(_token1)) {

                _safeSendFeeForCoFiHolder(_token0, tradeInfo[0]);
            } else {
                _safeSendFeeForLP(_token0, _token1, tradeInfo[0]);
                tradeInfo[0] = 0;
            }
        }
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);

        emit Swap(msg.sender, amountIn, amountOut, outToken, to);
    }


    function swapForExact(address outToken, uint amountOutExact, address to)
        external
        payable override lock
        returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo)
    {

        address _token0 = token0;
        address _token1 = token1;
        OraclePrice memory _op;



        {
            uint256 _ethBalanceBefore = address(this).balance;
            bytes memory data = abi.encode(msg.sender, outToken, amountOutExact, to);

            (_op.K, _op.ethAmount, _op.erc20Amount, _op.blockNum, _op.theta) = _queryOracle(_token1, CoFiX_OP.SWAP_FOR_EXACT, data);
            oracleFeeChange = msg.value.sub(_ethBalanceBefore.sub(address(this).balance));
        }

        {
            uint256 balance0 = IERC20(_token0).balanceOf(address(this));
            uint256 balance1 = IERC20(_token1).balanceOf(address(this));
            (uint112 _reserve0, uint112 _reserve1) = getReserves();

            if (outToken == _token1) {
                amountIn = balance0.sub(_reserve0);
                tradeInfo[1] = _reserve0;
                tradeInfo[2] = uint256(_reserve1).mul(_op.ethAmount).div(_op.erc20Amount);
            } else if (outToken == _token0) {
                amountIn = balance1.sub(_reserve1);
                tradeInfo[1] = uint256(_reserve1).mul(_op.ethAmount).div(_op.erc20Amount);
                tradeInfo[2] = _reserve0;
            } else {
                revert("CPair: wrong outToken");
            }
            require(amountIn > 0, "CPair: wrong amountIn");
            tradeInfo[3] = calcNAVPerShare(_reserve0, _reserve1, _op.ethAmount, _op.erc20Amount);
        }

        {
            uint _amountInNeeded;
            uint _amountInLeft;
            if (outToken == _token1) {
                (_amountInNeeded, tradeInfo[0]) = calcInNeededToken0(amountOutExact, _op);
                _amountInLeft = amountIn.sub(_amountInNeeded);
                if (_amountInLeft > 0) {
                    _safeTransfer(_token0, to, _amountInLeft);
                }
            } else if (outToken == _token0) {
                (_amountInNeeded, tradeInfo[0]) = calcInNeededToken1(amountOutExact, _op);
                _amountInLeft = amountIn.sub(_amountInNeeded);
                if (_amountInLeft > 0) {
                    _safeTransfer(_token1, to, _amountInLeft);
                }
            }
            require(_amountInNeeded <= amountIn, "CPair: insufficient amountIn");
            require(_amountInNeeded > 0, "CPair: wrong amountIn needed");
        }

        {
            require(to != _token0 && to != _token1, "CPair: INVALID_TO");

            amountOut = amountOutExact;
            _safeTransfer(outToken, to, amountOut);
            if (tradeInfo[0] > 0) {
                if (ICoFiXFactory(factory).getTradeMiningStatus(_token1)) {

                    _safeSendFeeForCoFiHolder(_token0, tradeInfo[0]);
                } else {
                    _safeSendFeeForLP(_token0, _token1, tradeInfo[0]);
                    tradeInfo[0] = 0;
                }
            }
            uint256 balance0 = IERC20(_token0).balanceOf(address(this));
            uint256 balance1 = IERC20(_token1).balanceOf(address(this));

            _update(balance0, balance1);
            if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
        }

        emit Swap(msg.sender, amountIn, amountOut, outToken, to);
    }


    function skim(address to) external override lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }


    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }



    function calcNAVPerShareForMint(uint256 balance0, uint256 balance1, OraclePrice memory _op) public view returns (uint256 navps) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            navps = NAVPS_BASE;
        } else {









            uint256 kbaseSubK = K_BASE.sub(_op.K);
            uint256 balance1MulEthKbase = balance1.mul(_op.ethAmount).mul(K_BASE);
            uint256 balance0MulErcKbsk = balance0.mul(_op.erc20Amount).mul(kbaseSubK);
            navps = NAVPS_BASE.mul( (balance1MulEthKbase).add(balance0MulErcKbsk) ).div(_totalSupply).div(_op.erc20Amount).div(kbaseSubK);
        }
    }



    function calcNAVPerShareForBurn(uint256 balance0, uint256 balance1, OraclePrice memory _op) public view returns (uint256 navps) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            navps = NAVPS_BASE;
        } else {









            uint256 kbaseAddK = K_BASE.add(_op.K);
            uint256 balance1MulEthKbase = balance1.mul(_op.ethAmount).mul(K_BASE);
            uint256 balance0MulErcKbsk = balance0.mul(_op.erc20Amount).mul(kbaseAddK);
            navps = NAVPS_BASE.mul( (balance1MulEthKbase).add(balance0MulErcKbsk) ).div(_totalSupply).div(_op.erc20Amount).div(kbaseAddK);
        }
    }



    function calcNAVPerShare(uint256 balance0, uint256 balance1, uint256 ethAmount, uint256 erc20Amount) public view returns (uint256 navps) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            navps = NAVPS_BASE;
        } else {








            uint256 balance1MulEth = balance1.mul(ethAmount);
            uint256 balance0MulErc = balance0.mul(erc20Amount);
            navps = NAVPS_BASE.mul( (balance1MulEth).add(balance0MulErc) ).div(_totalSupply).div(erc20Amount);
        }
    }


    function calcLiquidity(uint256 amount0, uint256 amount1, uint256 navps, OraclePrice memory _op) public pure returns (uint256 liquidity) {













        uint256 amnt0MulNbaseDivN = amount0.mul(NAVPS_BASE).div(navps);
        uint256 amnt1MulNbaseEthKbase = amount1.mul(NAVPS_BASE).mul(_op.ethAmount).mul(K_BASE);
        liquidity = ( amnt0MulNbaseDivN ).add( amnt1MulNbaseEthKbase.div(navps).div(_op.erc20Amount).div(K_BASE.add(_op.K)) );
    }



    function getNAVPerShareForMint(OraclePrice memory _op) public view returns (uint256 navps) {
        return calcNAVPerShareForMint(reserve0, reserve1, _op);
    }



    function getNAVPerShareForBurn(OraclePrice memory _op) external view returns (uint256 navps) {
        return calcNAVPerShareForBurn(reserve0, reserve1, _op);
    }



    function getNAVPerShare(uint256 ethAmount, uint256 erc20Amount) external override view returns (uint256 navps) {
        return calcNAVPerShare(reserve0, reserve1, ethAmount, erc20Amount);
    }



    function getLiquidity(uint256 amount0, uint256 amount1, OraclePrice memory _op) external view returns (uint256 liquidity) {
        uint256 navps = getNAVPerShareForMint(_op);
        return calcLiquidity(amount0, amount1, navps, _op);
    }


    function calcOutToken0ForBurn(uint256 liquidity, OraclePrice memory _op) public view returns (uint256 amountOut, uint256 fee) {






        uint256 navps = calcNAVPerShareForBurn(reserve0, reserve1, _op);
        amountOut = liquidity.mul(navps).mul(THETA_BASE.sub(_op.theta)).div(NAVPS_BASE).div(THETA_BASE);
        if (_op.theta != 0) {

            fee = liquidity.mul(navps).mul(_op.theta).div(NAVPS_BASE).div(THETA_BASE);
        }
        return (amountOut, fee);
    }



    function calcOutToken1ForBurn(uint256 liquidity, OraclePrice memory _op) public view returns (uint256 amountOut, uint256 fee) {






        uint256 navps = calcNAVPerShareForBurn(reserve0, reserve1, _op);
        uint256 liqMulMany = liquidity.mul(navps).mul(_op.erc20Amount).mul(K_BASE.sub(_op.K)).mul(THETA_BASE.sub(_op.theta));
        amountOut = liqMulMany.div(NAVPS_BASE).div(_op.ethAmount).div(K_BASE).div(THETA_BASE);
        if (_op.theta != 0) {

            fee = liquidity.mul(navps).mul(_op.theta).div(NAVPS_BASE).div(THETA_BASE);
        }
        return (amountOut, fee);
    }


    function calcOutToken0(uint256 amountIn, OraclePrice memory _op) public pure returns (uint256 amountOut, uint256 fee) {







        amountOut = amountIn.mul(_op.ethAmount).mul(K_BASE).mul(THETA_BASE.sub(_op.theta)).div(_op.erc20Amount).div(K_BASE.add(_op.K)).div(THETA_BASE);
        if (_op.theta != 0) {

            fee = amountIn.mul(_op.ethAmount).mul(K_BASE).mul(_op.theta).div(_op.erc20Amount).div(K_BASE.add(_op.K)).div(THETA_BASE);
        }
        return (amountOut, fee);
    }


    function calcOutToken1(uint256 amountIn, OraclePrice memory _op) public pure returns (uint256 amountOut, uint256 fee) {






        amountOut = amountIn.mul(_op.erc20Amount).mul(K_BASE.sub(_op.K)).mul(THETA_BASE.sub(_op.theta)).div(_op.ethAmount).div(K_BASE).div(THETA_BASE);
        if (_op.theta != 0) {

            fee = amountIn.mul(_op.theta).div(THETA_BASE);
        }
        return (amountOut, fee);
    }


    function calcInNeededToken0(uint256 amountOut, OraclePrice memory _op) public pure returns (uint256 amountInNeeded, uint256 fee) {


        amountInNeeded = amountOut.mul(_op.ethAmount).mul(K_BASE).mul(THETA_BASE).div(_op.erc20Amount).div(K_BASE.sub(_op.K)).div(THETA_BASE.sub(_op.theta));
        if (_op.theta != 0) {

            fee = amountInNeeded.mul(_op.theta).div(THETA_BASE);
        }
        return (amountInNeeded, fee);
    }


    function calcInNeededToken1(uint256 amountOut, OraclePrice memory _op) public pure returns (uint256 amountInNeeded, uint256 fee) {


        amountInNeeded = amountOut.mul(_op.erc20Amount).mul(K_BASE.add(_op.K)).mul(THETA_BASE).div(_op.ethAmount).div(K_BASE).div(THETA_BASE.sub(_op.theta));
        if (_op.theta != 0) {

            fee = amountInNeeded.mul(_op.ethAmount).mul(K_BASE).mul(_op.theta).div(_op.erc20Amount).div(K_BASE.add(_op.K)).div(THETA_BASE);
        }
        return (amountInNeeded, fee);
    }

    function _queryOracle(address token, CoFiX_OP op, bytes memory data) internal returns (uint256, uint256, uint256, uint256, uint256) {
        return ICoFiXController(ICoFiXFactory(factory).getController()).queryOracle{value: msg.value}(token, uint8(op), data);
    }


    function _safeSendFeeForCoFiHolder(address _token0, uint256 _fee) internal {
        address feeReceiver = ICoFiXFactory(factory).getFeeReceiver();
        if (feeReceiver == address(0)) {
            return;
        }
        _safeSendFee(_token0, feeReceiver, _fee);
    }


    function _safeSendFeeForLP(address _token0, address _token1, uint256 _fee) internal {
        address feeVault = ICoFiXFactory(factory).getFeeVaultForLP(_token1);
        if (feeVault == address(0)) {
            return;
        }
        _safeSendFee(_token0, feeVault, _fee);
    }

    function _safeSendFee(address _token0, address _receiver, uint256 _fee) internal {
        uint256 wethBal = IERC20(_token0).balanceOf(address(this));
        if (_fee > wethBal) {
            _fee = wethBal;
        }
        if (_fee > 0) _safeTransfer(_token0, _receiver, _fee);
    }
}


