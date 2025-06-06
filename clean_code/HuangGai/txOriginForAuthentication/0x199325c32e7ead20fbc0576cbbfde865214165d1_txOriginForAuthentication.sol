



pragma solidity 0.5.17;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0)
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(tx.origin == owner, "permission denied");

        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }







    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }






    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }










    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (from != msg.sender && _allowed[from][msg.sender] != uint256(-1))
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}

contract ERC20Mintable is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function _mint(address to, uint256 amount) internal {
        _balances[to] = _balances[to].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }
}

contract Seal is ERC20Mintable, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) public isMinter;

    constructor() public {
        name = "Seal Finance";
        symbol = "Seal";
        decimals = 18;
    }

    function setMinter(address minter, bool flag) external onlyOwner {
        isMinter[minter] = flag;
    }

    function mint(address to, uint256 amount) external {
        require(isMinter[msg.sender], "Not Minter");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (from != msg.sender && _allowed[from][msg.sender] != uint256(-1))
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(amount);
        require(_balances[from] >= amount, "insufficient-balance");
        _burn(from, amount);
    }

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

library UniswapV2Library {
    using SafeMath for uint;


    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }


    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ))));
    }


    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }


    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }


    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }


    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }


    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


contract Farm is Ownable {
    using SafeMath for uint256;

    Seal public seal;
    IUniswapV2Pair public cSeal;
    ERC20 public token;
    uint256 public today;
    uint256 public spawnRate;
    uint256 public withdrawRate;
    uint256 public timeLock;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) public depositTimeStamp;

    constructor(uint256 _spawnRate, uint256 _withdrawRate, uint256 _timeLock, address _seal, address _cSeal, address _token) public {
        today = now / 1 days;
        spawnRate = _spawnRate;
        withdrawRate = _withdrawRate;
        timeLock = _timeLock;
        seal = Seal(_seal);
        cSeal = IUniswapV2Pair(_cSeal);
        token = ERC20(_token);
    }

    function setParams(uint256 _spawnRate, uint256 _withdrawRate, uint256 _timeLock) external onlyOwner {
        require(_spawnRate <= 0.1e18);
        require(_withdrawRate >= 0.85e18 && _withdrawRate <= 1e18);
        require(_timeLock <= 15 days);
        spawnRate = _spawnRate;
        withdrawRate = _withdrawRate;
        timeLock = _timeLock;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalValue() public view returns(uint256) {
        return cSeal.balanceOf(address(this));
    }

    function deposit(uint256 amount) external returns (uint256 share) {
        if(totalSupply() > 0)
            share = totalSupply().mul(amount).div(totalValue());
        else
            share = amount;
        _balances[msg.sender] = _balances[msg.sender].add(share);
        depositTimeStamp[msg.sender] = now;
        _totalSupply = _totalSupply.add(share);
        require(cSeal.transferFrom(msg.sender, address(this), amount));
    }

    function withdraw(address to, uint256 share) external returns (uint256 amount) {
        require(depositTimeStamp[msg.sender].add(timeLock) <= now, "locked");
        amount = share.mul(totalValue()).div(totalSupply());
        if(share < _totalSupply)
            amount = amount.mul(withdrawRate).div(1e18);
        _balances[msg.sender] = _balances[msg.sender].sub(share);
        _totalSupply = _totalSupply.sub(share);
        require(cSeal.transfer(to, amount));
    }

    function rescueToken(ERC20 _token, uint256 _amount) onlyOwner public {
        require(_token != ERC20(address(cSeal)));
        _token.transfer(msg.sender, _amount);
    }

    function breed() external {
        require(now / 1 days > today);
        today += 1;

        uint256 sealPairAmount = seal.balanceOf(address(cSeal));
        uint256 tokenPairAmount = token.balanceOf(address(cSeal));
        uint256 newSeal = sealPairAmount.mul(spawnRate).div(1e18);
        uint256 amount = UniswapV2Library.getAmountOut(newSeal, sealPairAmount, tokenPairAmount);

        seal.mint(address(cSeal), newSeal);
        if(address(seal) < address(token))
            cSeal.swap(0, amount, address(this), "");
        else
            cSeal.swap(amount, 0, address(this), "");
        token.transfer(address(cSeal), amount);
        seal.mint(address(cSeal), newSeal);
        cSeal.mint(address(this));
    }
}
