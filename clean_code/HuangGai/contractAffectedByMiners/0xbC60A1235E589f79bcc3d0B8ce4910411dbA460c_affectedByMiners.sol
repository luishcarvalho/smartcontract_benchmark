





pragma solidity 0.6.12;














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

interface ITokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IValueLiquidPool {
    function swapExactAmountIn(address tokenIn, uint tokenAmountIn, address tokenOut, uint minAmountOut, uint maxPrice) external returns (uint tokenAmountOut, uint spotPriceAfter);
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}



contract UniswapRouterSupportingFeeOnTransferTokens is IValueLiquidPool, IUniswapRouter {
    using SafeMath for uint256;

    address public governance;

    IUniswapRouter public unirouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public performanceFee = 0;

    mapping(address => mapping(address => address[])) public uniswapPaths;
    mapping(address => bool) public hasTransferFee;

    constructor(address _tokenHasTransferFee) public {
        hasTransferFee[_tokenHasTransferFee] = true;
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function approveForSpender(ITokenInterface _token, address _spender, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        _token.approve(_spender, _amount);
    }

    function setUnirouter(IUniswapRouter _unirouter) external {
        require(msg.sender == governance, "!governance");
        unirouter = _unirouter;
    }

    function setPerformanceFee(uint256 _performanceFee) public {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function setHasTransferFee(address _token, bool _hasFee) public {
        require(msg.sender == governance, "!governance");
        hasTransferFee[_token] = _hasFee;
    }

    function setUnirouterPath(address _input, address _output, address [] memory _path) public {
        require(msg.sender == governance, "!governance");
        uniswapPaths[_input][_output] = _path;
    }

    function swapExactAmountIn(address _tokenIn, uint _tokenAmountIn, address _tokenOut, uint _minAmountOut, uint) external override returns (uint _tokenAmountOut, uint) {
        address[] memory path = uniswapPaths[_tokenIn][_tokenOut];
        if (block.timestamp == 0) {

            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        }
        ITokenInterface input = ITokenInterface(_tokenIn);
        ITokenInterface output = ITokenInterface(_tokenOut);
        input.transferFrom(msg.sender, address(this), _tokenAmountIn);
        if (block.gaslimit > 0) {
            uint256 performanceFeeAmount = _tokenAmountIn.mul(performanceFee).div(FEE_DENOMINATOR);
            _tokenAmountIn = _tokenAmountIn.sub(performanceFeeAmount);
            input.transfer(governance, performanceFeeAmount);
        }
        if (hasTransferFee[_tokenIn] || hasTransferFee[_tokenOut]) {

            unirouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(_tokenAmountIn, _minAmountOut, path, msg.sender, now.add(1800));
        } else {

            unirouter.swapExactTokensForTokens(_tokenAmountIn, _minAmountOut, path, msg.sender, now.add(1800));
        }
        _tokenAmountOut = output.balanceOf(address(this));
        output.transfer(msg.sender, _tokenAmountOut);
    }

    function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external override returns (uint256[] memory amounts) {
        ITokenInterface input = ITokenInterface(_path[0]);
        input.transferFrom(msg.sender, address(this), _amountIn);
        if (block.timestamp > 0) {
            uint256 performanceFeeAmount = _amountIn.mul(performanceFee).div(FEE_DENOMINATOR);
            _amountIn = _amountIn.sub(performanceFeeAmount);
            input.transfer(governance, performanceFeeAmount);
        }
        amounts = unirouter.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _to, _deadline);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external override returns (uint256[] memory amounts) {
        ITokenInterface input = ITokenInterface(_path[0]);
        input.transferFrom(msg.sender, address(this), _amountIn);
        if (block.timestamp > 0) {
            uint256 performanceFeeAmount = _amountIn.mul(performanceFee).div(FEE_DENOMINATOR);
            _amountIn = _amountIn.sub(performanceFeeAmount);
            input.transfer(governance, performanceFeeAmount);
        }
        amounts = unirouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, _amountOutMin, _path, _to, _deadline);
    }







    function governanceRecoverUnsupported(ITokenInterface _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}
