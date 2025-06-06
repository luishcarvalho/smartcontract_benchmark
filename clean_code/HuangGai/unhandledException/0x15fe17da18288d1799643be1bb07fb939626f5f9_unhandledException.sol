



pragma solidity ^0.5.17;

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

contract Context {
    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = (false, bytes(msg.data));
	 address(token).call(data);

        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface UniswapPair {
    function mint(address to) external returns (uint liquidity);
}

interface Oracle {
    function getPriceUSD(address reserve) external view returns (uint);
}

interface UniswapRouter {
  function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
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
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function factory() external view returns (address);
}

interface UniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract StableCreditProtocol is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;


    Oracle public constant LINK = Oracle(0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a);
    UniswapRouter public constant UNI = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


    uint public constant MAX = 7500;
    uint public constant BASE = 10000;


    mapping (address => mapping(address => uint)) public credit;

    mapping (address => mapping(address => uint)) public balances;

    mapping (address => address[]) public markets;

    event Borrow(address indexed borrower, address indexed borrowed, uint creditIn, uint amountOut);
    event Repay(address indexed borrower, address indexed repaid, uint creditOut, uint amountIn);
    event Deposit(address indexed creditor, address indexed collateral, uint creditOut, uint amountIn, uint creditMinted);
    event Withdraw(address indexed creditor, address indexed collateral, uint creditIn, uint creditOut, uint amountOut);

    constructor () public ERC20Detailed("StableCredit", "scUSD", 8) {}


    function borrowExactOut(address token, uint inMax, uint outExact) external {
        _transfer(msg.sender, address(this), inMax);

        IERC20(this).safeApprove(address(UNI), 0);
        IERC20(this).safeApprove(address(UNI), inMax);

        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = token;

        uint[] memory _amounts = UNI.swapTokensForExactTokens(outExact, inMax, _path, msg.sender, now.add(1800));
        _transfer(address(this), msg.sender, balanceOf(address(this)));

        emit Borrow(msg.sender, token, _amounts[0], _amounts[1]);
    }


    function borrowExactIn(address token, uint inExact, uint outMin) external {
        _transfer(msg.sender, address(this), inExact);

        IERC20(this).safeApprove(address(UNI), 0);
        IERC20(this).safeApprove(address(UNI), inExact);

        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = token;

        uint[] memory _amounts = UNI.swapExactTokensForTokens(inExact, outMin, _path, msg.sender, now.add(1800));

        emit Borrow(msg.sender, token, _amounts[0], _amounts[1]);
    }


    function repayExactOut(address token, uint inMax, uint outExact) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), inMax);

        IERC20(token).safeApprove(address(UNI), 0);
        IERC20(token).safeApprove(address(UNI), inMax);

        address[] memory _path = new address[](2);
        _path[0] = token;
        _path[1] = address(this);

        uint[] memory _amounts = UNI.swapTokensForExactTokens(outExact, inMax, _path, msg.sender, now.add(1800));
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        emit Repay(msg.sender, token, _amounts[1], _amounts[0]);
    }


    function repayExactIn(address token, uint inExact, uint outMin) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), inExact);

        IERC20(this).safeApprove(address(UNI), 0);
        IERC20(this).safeApprove(address(UNI), inExact);

        address[] memory _path = new address[](2);
        _path[0] = token;
        _path[1] = address(this);

        uint[] memory _amounts = UNI.swapExactTokensForTokens(inExact, outMin, _path, msg.sender, now.add(1800));
        emit Repay(msg.sender, token, _amounts[1], _amounts[0]);
    }

    function depositAll(address token) external {
        deposit(token, IERC20(token).balanceOf(msg.sender));
    }

    function deposit(address token, uint amount) public {
        _deposit(token, amount);
    }


    function _deposit(address token, uint amount) internal {
        uint _value = LINK.getPriceUSD(token).mul(amount).div(uint256(10)**ERC20Detailed(token).decimals());
        require(_value > 0, "!value");

        address _pair = UniswapFactory(UNI.factory()).getPair(token, address(this));
        if (_pair == address(0)) {
            _pair = UniswapFactory(UNI.factory()).createPair(token, address(this));
        }

        IERC20(token).safeTransferFrom(msg.sender, _pair, amount);
        _mint(_pair, _value);

        uint _before = IERC20(_pair).balanceOf(address(this));
        UniswapPair(_pair).mint(address(this));
        uint _after = IERC20(_pair).balanceOf(address(this));



        balances[msg.sender][token] = balances[msg.sender][token].add(_after.sub(_before));




        uint _credit = _value.mul(utilization(token)).div(BASE);
        credit[msg.sender][token] = credit[msg.sender][token].add(_credit);
        _mint(msg.sender, _credit);


        markets[msg.sender].push(token);
        emit Deposit(msg.sender, token, _credit, amount, _value);
    }

    function withdrawAll(address token) external {
        _withdraw(token, IERC20(this).balanceOf(msg.sender));
    }

    function withdraw(address token, uint amount) external {
        _withdraw(token, amount);
    }


    function _withdraw(address token, uint amount) internal {

        uint _credit = credit[msg.sender][token];
        uint _uni = balances[msg.sender][token];

        if (_credit < amount) {
            amount = _credit;
        }

        _burn(msg.sender, amount);
        credit[msg.sender][token] = credit[msg.sender][token].sub(amount);


        _uni = _uni.mul(amount).div(_credit);

        address _pair = UniswapFactory(UNI.factory()).getPair(token, address(this));

        IERC20(_pair).safeApprove(address(UNI), 0);
        IERC20(_pair).safeApprove(address(UNI), _uni);

        UNI.removeLiquidity(
          token,
          address(this),
          _uni,
          0,
          0,
          address(this),
          now.add(1800)
        );

        uint _amountA = IERC20(token).balanceOf(address(this));
        uint _amountB = balanceOf(address(this));

        uint _valueA = LINK.getPriceUSD(token).mul(_amountA).div(uint256(10)**ERC20Detailed(token).decimals());
        require(_valueA > 0, "!value");


        if (_valueA > _amountB) {
            _valueA = _amountB;
        }

        _burn(address(this), _valueA);

        IERC20(token).safeTransfer(msg.sender, _amountA);
        uint _left = balanceOf(address(this));
        if (_left > 0) {
            _transfer(address(this), msg.sender, _left);
        }
        emit Withdraw(msg.sender, token, amount, _left, _amountA);
    }


    function getMarkets(address owner) external view returns (address[] memory) {
        return markets[owner];
    }

    function utilization(address token) public view returns (uint) {
        return _utilization(token, 0);
    }


    function _utilization(address token, uint amount) internal view returns (uint) {
        address _pair = UniswapFactory(UNI.factory()).getPair(token, address(this));
        uint _ratio = BASE.sub(BASE.mul(balanceOf(_pair).add(amount)).div(totalSupply()));
        if (_ratio == 0) {
            return MAX;
        }
        return  _ratio > MAX ? MAX : _ratio;
    }
}
