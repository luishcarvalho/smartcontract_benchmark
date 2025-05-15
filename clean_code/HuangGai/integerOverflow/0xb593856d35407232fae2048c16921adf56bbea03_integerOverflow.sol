




pragma solidity ^0.6.6;





interface IERC20 {



    function totalSupply() external view returns (uint);




    function balanceOf(address account) external view returns (uint);








    function transfer(address recipient, uint amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint);















    function approve(address spender, uint amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint value);





    event Approval(address indexed owner, address indexed spender, uint value);
}

















library SafeMath {








    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;


        return c;
    }









    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "TimeLoans::SafeMath: subtraction underflow");
    }









    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }









    function mul(uint a, uint b) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }









    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }












    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }












    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;


        return c;
    }












    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }












    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Factory {
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

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapOracleRouter {
    function quote(address tokenIn, address tokenOut, uint amountIn) external view returns (uint amountOut);
}

contract TimeLoanPair {
    using SafeMath for uint;


    string public constant name = "Time Loan Pair LP";


    string public symbol;


    uint8 public constant decimals = 18;


    uint public totalSupply = 0;

    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");


    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");


    mapping (address => uint) public nonces;


    event Transfer(address indexed from, address indexed to, uint amount);


    event Approval(address indexed owner, address indexed spender, uint amount);


    IUniswapV2Router02 public constant UNI = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


    IUniswapOracleRouter public constant ORACLE = IUniswapOracleRouter(0x0b5A6b318c39b60e7D8462F888e7fbA89f75D02F);


    address public pair;


    address public token0;


    address public token1;



    event Deposited(address indexed creditor, address indexed collateral, uint shares, uint credit);

    event Withdrew(address indexed creditor, address indexed collateral, uint shares, uint credit);


    event Borrowed(uint id, address indexed borrower, address indexed collateral, address indexed borrowed, uint creditIn, uint amountOut, uint created, uint expire);

    event Repaid(uint id, address indexed borrower, address indexed collateral, address indexed borrowed, uint creditIn, uint amountOut, uint created, uint expire);

    event Closed(uint id, address indexed borrower, address indexed collateral, address indexed borrowed, uint creditIn, uint amountOut, uint created, uint expire);


    uint public constant FEE = 600;


    uint public constant BUFFER = 105000;


    uint public constant LTV = 80000;


    uint public constant BASE = 100000;


    uint public constant DELAY = 6600;


    struct position {
        address owner;
        address collateral;
        address borrowed;
        uint creditIn;
        uint amountOut;
        uint liquidityInUse;
        uint created;
        uint expire;
        bool open;
    }


    position[] public positions;


    uint public nextIndex;


    uint public processedIndex;


    mapping(address => uint[]) public loans;


    constructor(IUniswapV2Pair _pair) public {
        symbol = string(abi.encodePacked(IUniswapV2Pair(_pair.token0()).symbol(), "-", IUniswapV2Pair(_pair.token1()).symbol()));
        pair = address(_pair);
        token0 = _pair.token0();
        token1 = _pair.token1();
    }


    uint public liquidityDeposits;

    uint public liquidityWithdrawals;

    uint public liquidityAdded;

    uint public liquidityRemoved;

    uint public liquidityInUse;

    uint public liquidityFreed;





    function liquidityBalance() public view returns (uint) {
        return liquidityDeposits
                .sub(liquidityWithdrawals)
                .add(liquidityAdded)
                .sub(liquidityRemoved)
                .add(liquidityFreed)
                .sub(liquidityInUse);
    }

    function _mint(address dst, uint amount) internal {

        totalSupply = totalSupply.add(amount);


        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {

        totalSupply = totalSupply.sub(amount, "TimeLoans::_burn: underflow");


        balances[dst] = balances[dst].sub(amount, "TimeLoans::_burn: underflow");
        emit Transfer(dst, address(0), amount);
    }





    function withdrawAll() external returns (bool) {
        return withdraw(balances[msg.sender]);
    }






    function withdraw(uint _shares) public returns (bool) {
        uint r = liquidityBalance().mul(_shares).div(totalSupply);
        _burn(msg.sender, _shares);

        require(IERC20(pair).balanceOf(address(this)) > r, "TimeLoans::withdraw: insufficient liquidity to withdraw, try depositLiquidity()");

        IERC20(pair).transfer(msg.sender, r);
        liquidityWithdrawals = liquidityWithdrawals.add(r);
        emit Withdrew(msg.sender, pair, _shares, r);
        return true;
    }





    function depositAll() external returns (bool) {
        return deposit(IERC20(pair).balanceOf(msg.sender));
    }






    function deposit(uint amount) public returns (bool) {
        IERC20(pair).transferFrom(msg.sender, address(this), amount);
        uint _shares = 0;
        if (liquidityBalance() == 0) {
            _shares = amount;
        } else {
            _shares = amount.mul(totalSupply).div(liquidityBalance());
        }
        _mint(msg.sender, _shares);
        liquidityDeposits = liquidityDeposits.add(amount);

        emit Deposited(msg.sender, pair, _shares, amount);
        return true;
    }






    function closeInBatches(uint size) external returns (uint) {
        uint i = processedIndex;
        for (; i < size; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }





    function closeAllOpen() external returns (uint) {
        uint i = processedIndex;
        for (; i < nextIndex; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }






    function close(uint id) public returns (bool) {
        position storage _pos = positions[id];
        if (_pos.owner == address(0x0)) {
            return false;
        }
        if (!_pos.open) {
            return false;
        }
        if (_pos.expire > block.number) {
            return false;
        }
        _pos.open = false;
        liquidityInUse = liquidityInUse.sub(_pos.liquidityInUse, "TimeLoans::close: liquidityInUse overflow");
        liquidityFreed = liquidityFreed.add(_pos.liquidityInUse);
        emit Closed(id, _pos.owner, _pos.collateral, _pos.borrowed, _pos.creditIn, _pos.amountOut, _pos.created, _pos.expire);
        return true;
    }






    function liquidityOf(address asset) public view returns (uint) {
        return IERC20(asset).balanceOf(address(this)).
                add(IERC20(asset).balanceOf(pair)
                    .mul(IERC20(pair).balanceOf(address(this)))
                    .div(IERC20(pair).totalSupply()));
    }






    function calculateLiquidityToBurn(address asset, uint amount) public view returns (uint) {
        return IERC20(pair).totalSupply()
                .mul(amount)
                .div(IERC20(asset).balanceOf(pair));
    }






    function _withdrawLiquidity(address asset, uint amount) internal returns (uint withdrew) {
        withdrew = calculateLiquidityToBurn(asset, amount);
        withdrew = withdrew.mul(BUFFER).div(BASE);

        uint _amountAMin = 0;
        uint _amountBMin = 0;
        if (asset == token0) {
            _amountAMin = amount;
        } else if (asset == token1) {
            _amountBMin = amount;
        }
        IERC20(pair).approve(address(UNI), withdrew);
        UNI.removeLiquidity(token0, token1, withdrew, _amountAMin, _amountBMin, address(this), now.add(1800));
        liquidityRemoved = liquidityRemoved.add(withdrew);
    }








    function quote(address collateral, address borrow, uint amount) external view returns (uint minOut) {
        uint _received = (amount.sub(amount.mul(FEE).div(BASE))).mul(LTV).div(BASE);
        return ORACLE.quote(collateral, borrow, _received);
    }




    function depositLiquidity() external {
        require(msg.sender == tx.origin, "TimeLoans::depositLiquidity: not an EOA keeper");
        IERC20(token0).approve(address(UNI), IERC20(token0).balanceOf(address(this)));
        IERC20(token1).approve(address(UNI), IERC20(token1).balanceOf(address(this)));
        (,,uint _added) = UNI.addLiquidity(token0, token1, IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), 0, 0, address(this), now.add(1800));
        liquidityAdded = liquidityAdded.add(_added);
    }








    function loan(address collateral, address borrow, uint amount, uint outMin) external returns (uint) {
        uint _before = IERC20(collateral).balanceOf(address(this));
        IERC20(collateral).transferFrom(msg.sender, address(this), amount);
        uint _after = IERC20(collateral).balanceOf(address(this));

        uint _received = _after.sub(_before);
        uint _fee = _received.mul(FEE).div(BASE);
        _received = _received.sub(_fee);

        uint _ltv = _received.mul(LTV).div(BASE);

        uint _amountOut = ORACLE.quote(collateral, borrow, _ltv);
        require(_amountOut >= outMin, "TimeLoans::loan: slippage");
        require(liquidityOf(borrow) > _amountOut, "TimeLoans::loan: insufficient liquidity");

        uint _available = IERC20(borrow).balanceOf(address(this));
        uint _withdrew = 0;
        if (_available < _amountOut) {
            _withdrew = _withdrawLiquidity(borrow, _amountOut.sub(_available));
            liquidityInUse = liquidityInUse.add(_withdrew);
        }

        positions.push(position(msg.sender, collateral, borrow, _received, _amountOut, _withdrew, block.number, block.number.add(DELAY), true));
        loans[msg.sender].push(nextIndex);

        IERC20(borrow).transfer(msg.sender, _amountOut);
        emit Borrowed(nextIndex, msg.sender, collateral, borrow, _received, _amountOut, block.number, block.number.add(DELAY));
        return nextIndex++;
    }






    function repay(uint id) external returns (bool) {
        position storage _pos = positions[id];
        require(_pos.open, "TimeLoans::repay: position is already closed");
        require(_pos.expire < block.number, "TimeLoans::repay: position already expired");
        IERC20(_pos.borrowed).transferFrom(msg.sender, address(this), _pos.amountOut);
        uint _available = IERC20(_pos.collateral).balanceOf(address(this));
        if (_available < _pos.creditIn) {
            _withdrawLiquidity(_pos.collateral, _pos.creditIn.sub(_available));
        }
        IERC20(_pos.collateral).transfer(msg.sender, _pos.creditIn);
        _pos.open = false;
        positions[id] = _pos;
        emit Repaid(id, _pos.owner, _pos.collateral, _pos.borrowed, _pos.creditIn, _pos.amountOut, _pos.created, _pos.expire);
        return true;
    }







    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }









    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }











    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "TimeLoans::permit: invalid signature");
        require(signatory == owner, "TimeLoans::permit: unauthorized");
        require(now <= deadline, "TimeLoans::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }






    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }







    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }








    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "TimeLoans::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "TimeLoans::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "TimeLoans::_transferTokens: cannot transfer to the zero address");

        balances[src] = balances[src].sub(amount, "TimeLoans::_transferTokens: transfer amount exceeds balance");
        balances[dst] = balances[dst].add(amount, "TimeLoans::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract TimeLoanPairFactory {
    mapping(address => address) public pairs;
    address[] public deployed;

    function deploy(IUniswapV2Pair _pair) external returns (address) {
        require(pairs[address(_pair)] == address(0x0), "TimeLoanPairFactory::deploy: pair already created");
        pairs[address(_pair)] = address(new TimeLoanPair(_pair));
        deployed.push(address(_pair));
        return pairs[address(_pair)];
    }
}
