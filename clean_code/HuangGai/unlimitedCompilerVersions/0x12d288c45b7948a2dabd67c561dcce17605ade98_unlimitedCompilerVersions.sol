




pragma solidity ^0.6.6;

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

contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
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


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }







    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}





contract YolexExchange {
  using SafeMath for uint256;
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  IUniswapV2Router02 public uniswapRouter;
  address owner;
  address newOwner;

  constructor() public {
    owner = msg.sender;
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

 modifier onlyOwner(){
      require(msg.sender == owner, "permission failed");
      _;
 }

function getEstimatedETHforToken(uint _amount, address _tokenAddress) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(_amount, getPathForETHtoToken(_tokenAddress));
  }

function getPathForETHtoToken(address _tokenAddress) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = _tokenAddress;

    return path;
  }

function convertEthToToken(uint deadline, uint _amountOutMin, uint amountWithFees, address _tokenAddress) public payable returns(uint[] memory) {
    uint[] memory result = uniswapRouter.swapExactETHForTokens{value: amountWithFees}(_amountOutMin, getPathForETHtoToken(_tokenAddress), msg.sender, deadline);
    return result;

}

function convertEthToTokenSupportTokensWithFees(uint deadline, uint _amountOutMin, uint amountWithFees, address _tokenAddress) public payable returns(bool) {
    uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountWithFees}(_amountOutMin,
    getPathForETHtoToken(_tokenAddress), msg.sender, deadline);
    return true;
}



function getPathForTokenToETH(address _tokenAddress) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = _tokenAddress;
    path[1] = uniswapRouter.WETH();

    return path;
  }


function getEstimatedTokenToETH(uint _amount, address _tokenAddress) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(_amount, getPathForTokenToETH(_tokenAddress));
}

function convertTokenToETH(uint deadline, uint _amountIn, uint _amountOutMin, address _tokenAddress, uint _allowedAmount, uint _amountWithFees) public returns(uint){
    ERC20 token = ERC20(_tokenAddress);
    uint allowance = token.allowance(address(this), UNISWAP_ROUTER_ADDRESS);
    if (allowance < _amountIn) {
        transferFromUserAccount(_amountIn, _tokenAddress);
        token.approve(UNISWAP_ROUTER_ADDRESS, _allowedAmount);
        uniswapRouter.swapExactTokensForETH(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
    } else {
        transferFromUserAccount(_amountIn, _tokenAddress);
        uniswapRouter.swapExactTokensForETH(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
    }
 }

 function convertTokenToEthSupportTokensWithFees(uint deadline, uint _amountIn, uint _amountOutMin, address _tokenAddress, uint _allowedAmount, uint _amountWithFees) public payable returns(bool) {
    ERC20 token = ERC20(_tokenAddress);
    uint allowance = token.allowance(address(this), UNISWAP_ROUTER_ADDRESS);
    if (allowance < _amountIn) {
        transferFromUserAccount(_amountIn, _tokenAddress);
        token.approve(UNISWAP_ROUTER_ADDRESS, _allowedAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
    } else {
        transferFromUserAccount(_amountIn, _tokenAddress);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(_amountWithFees, _amountOutMin, getPathForTokenToETH(_tokenAddress), msg.sender, deadline);
    }
}



function transferFromUserAccount(uint _amountIn, address _tokenAddress) internal returns(bool){
  ERC20 token = ERC20(_tokenAddress);
  bool response = token.transferFrom(msg.sender, address(this), _amountIn);
  return response;
  }

 function checkAllowance(address _spender, address _tokenAddress) external view returns(uint){
   ERC20 token = ERC20(_tokenAddress);
   uint allowed = token.allowance(msg.sender, _spender);
   return allowed;
 }

 function assignOwner(address _newOwner) external onlyOwner returns(address){
     newOwner = _newOwner;
     return newOwner;
 }

 function acceptOwnership() external returns(address){
     require(msg.sender == newOwner, "msg.sender should match newOwner");
     owner = newOwner;
     return owner;
 }

 function transferToWallet(uint _amount, address payable _receipient) external onlyOwner returns(bool){
     _receipient.transfer(_amount);
      return true;
 }

  function transferToWalletTokens(uint _amount, address _receipient, address _tokenAddress) external onlyOwner returns(bool){
     ERC20 token = ERC20(_tokenAddress);
     token.transfer(_receipient, _amount);
     return true;

 }


  receive() payable external {}
}
