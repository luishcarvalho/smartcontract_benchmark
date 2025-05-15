

pragma solidity ^0.6.2;




abstract contract Context {
    function _MSGSENDER583() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA879() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



interface IERC20 {

    function TOTALSUPPLY430() external view returns (uint256);


    function BALANCEOF616(address account) external view returns (uint256);


    function TRANSFER244(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE387(address owner, address spender) external view returns (uint256);


    function APPROVE425(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM381(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER617(address indexed from, address indexed to, uint256 value);


    event APPROVAL460(address indexed owner, address indexed spender, uint256 value);
}



library SafeMath {

    function ADD135(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB321(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB321(a, b, "SafeMath: subtraction overflow");
    }


    function SUB321(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL733(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV136(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV136(a, b, "SafeMath: division by zero");
    }


    function DIV136(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD593(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD593(a, b, "SafeMath: modulo by zero");
    }


    function MOD593(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library Address {

    function ISCONTRACT469(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function SENDVALUE193(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL340(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL340(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL340(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE922(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE944(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE944(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE944(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE922(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE922(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT469(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }


    function NAME100() public view returns (string memory) {
        return _name;
    }


    function SYMBOL131() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS904() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY430() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF616(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER244(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER73(_MSGSENDER583(), recipient, amount);
        return true;
    }


    function ALLOWANCE387(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE425(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE319(_MSGSENDER583(), spender, amount);
        return true;
    }


    function TRANSFERFROM381(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER73(sender, recipient, amount);
        _APPROVE319(sender, _MSGSENDER583(), _allowances[sender][_MSGSENDER583()].SUB321(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE808(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE319(_MSGSENDER583(), spender, _allowances[_MSGSENDER583()][spender].ADD135(addedValue));
        return true;
    }


    function DECREASEALLOWANCE515(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE319(_MSGSENDER583(), spender, _allowances[_MSGSENDER583()][spender].SUB321(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER73(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER129(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB321(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD135(amount);
        emit TRANSFER617(sender, recipient, amount);
    }


    function _MINT517(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER129(address(0), account, amount);

        _totalSupply = _totalSupply.ADD135(amount);
        _balances[account] = _balances[account].ADD135(amount);
        emit TRANSFER617(address(0), account, amount);
    }


    function _BURN171(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER129(account, address(0), amount);

        _balances[account] = _balances[account].SUB321(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB321(amount);
        emit TRANSFER617(account, address(0), amount);
    }


    function _APPROVE319(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL460(owner, spender, amount);
    }


    function _SETUPDECIMALS874(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER129(address from, address to, uint256 amount) internal virtual { }
}



abstract contract ERC20Capped is ERC20 {
    uint256 private _cap;


    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }


    function CAP360() public view returns (uint256) {
        return _cap;
    }


    function _BEFORETOKENTRANSFER129(address from, address to, uint256 amount) internal virtual override {
        super._BEFORETOKENTRANSFER129(from, to, amount);

        if (from == address(0)) {
            require(TOTALSUPPLY430().ADD135(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }
}



contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED797(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER583();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED797(address(0), msgSender);
    }


    function OWNER971() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER607() {
        require(_owner == _MSGSENDER583(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP525() public virtual ONLYOWNER607 {
        emit OWNERSHIPTRANSFERRED797(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP777(address newOwner) public virtual ONLYOWNER607 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED797(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router01 {
    function FACTORY439() external pure returns (address);
    function WETH181() external pure returns (address);

    function ADDLIQUIDITY85(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function ADDLIQUIDITYETH216(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function REMOVELIQUIDITY344(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function REMOVELIQUIDITYETH742(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function REMOVELIQUIDITYWITHPERMIT491(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function REMOVELIQUIDITYETHWITHPERMIT317(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function SWAPEXACTTOKENSFORTOKENS917(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function SWAPTOKENSFOREXACTTOKENS879(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function SWAPEXACTETHFORTOKENS817(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function SWAPTOKENSFOREXACTETH856(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function SWAPEXACTTOKENSFORETH218(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function SWAPETHFOREXACTTOKENS998(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function QUOTE315(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function GETAMOUNTOUT816(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function GETAMOUNTIN684(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function GETAMOUNTSOUT241(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function GETAMOUNTSIN775(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function REMOVELIQUIDITYETHSUPPORTINGFEEONTRANSFERTOKENS846(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function REMOVELIQUIDITYETHWITHPERMITSUPPORTINGFEEONTRANSFERTOKENS1(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function SWAPEXACTTOKENSFORTOKENSSUPPORTINGFEEONTRANSFERTOKENS219(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function SWAPEXACTETHFORTOKENSSUPPORTINGFEEONTRANSFERTOKENS501(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function SWAPEXACTTOKENSFORETHSUPPORTINGFEEONTRANSFERTOKENS54(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event APPROVAL460(address indexed owner, address indexed spender, uint value);
    event TRANSFER617(address indexed from, address indexed to, uint value);

    function NAME100() external pure returns (string memory);
    function SYMBOL131() external pure returns (string memory);
    function DECIMALS904() external pure returns (uint8);
    function TOTALSUPPLY430() external view returns (uint);
    function BALANCEOF616(address owner) external view returns (uint);
    function ALLOWANCE387(address owner, address spender) external view returns (uint);

    function APPROVE425(address spender, uint value) external returns (bool);
    function TRANSFER244(address to, uint value) external returns (bool);
    function TRANSFERFROM381(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR749() external view returns (bytes32);
    function PERMIT_TYPEHASH945() external pure returns (bytes32);
    function NONCES546(address owner) external view returns (uint);

    function PERMIT654(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event MINT786(address indexed sender, uint amount0, uint amount1);
    event BURN405(address indexed sender, uint amount0, uint amount1, address indexed to);
    event SWAP722(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event SYNC303(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY735() external pure returns (uint);
    function FACTORY439() external view returns (address);
    function TOKEN0934() external view returns (address);
    function TOKEN1318() external view returns (address);
    function GETRESERVES691() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function PRICE0CUMULATIVELAST150() external view returns (uint);
    function PRICE1CUMULATIVELAST277() external view returns (uint);
    function KLAST634() external view returns (uint);

    function MINT615(address to) external returns (uint liquidity);
    function BURN664(address to) external returns (uint amount0, uint amount1);
    function SWAP816(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function SKIM21(address to) external;
    function SYNC269() external;

    function INITIALIZE267(address, address) external;
}

interface IUniswapV2Factory {
    event PAIRCREATED762(address indexed token0, address indexed token1, address pair, uint);

    function FEETO789() external view returns (address);
    function FEETOSETTER578() external view returns (address);

    function GETPAIR592(address tokenA, address tokenB) external view returns (address pair);
    function ALLPAIRS410(uint) external view returns (address pair);
    function ALLPAIRSLENGTH90() external view returns (uint);

    function CREATEPAIR614(address tokenA, address tokenB) external returns (address pair);

    function SETFEETO894(address) external;
    function SETFEETOSETTER1(address) external;
}

interface IWETH {
    function DEPOSIT145() external payable;
    function TRANSFER244(address to, uint value) external returns (bool);
    function WITHDRAW78(uint) external;
}

contract CGLB is ERC20Capped, Ownable {

    using SafeMath for uint;

    address public UNIPAIR;
    address public DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IUniswapV2Router02 public UNIROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public UNIFACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    bool public isRunning = false;
    bool private liquidityFlag;
    uint public constant supplycap690 = (10**4)*(10**18);
    uint public constant tokensforinitialliquidity143 = 3*(10**3)*(10**18);

    bytes32 public airdropRoot;
    mapping (address => bool) public claimedAirdrop;

    string public website = "www.cglb.fi";

    constructor() public ERC20Capped(supplycap690) ERC20("Cant go lower boys", "CGLB") {
        airdropRoot = 0x185065ab3d54b516ee3ed54dc30e04758300a4b41e207cf3ba91715f378d7728;
    }


    function TRANSFER244(address recipient, uint256 amount)
    public override
    returns (bool) {
        require(msg.sender == UNIPAIR || msg.sender == address(UNIROUTER));
        super.TRANSFER244(recipient, amount);
        return true;
    }

    function TRANSFERFROM381(address sender, address recipient, uint256 amount)
    public override
    returns (bool) {
        require(liquidityFlag);
        _TRANSFER73(sender, recipient, amount);
        return true;
    }

    function ADDLIQUIDITYTOUNISWAPPAIR951(
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountDAIDesired,
        uint256 amountDAImin
        ) public payable {
        require(isRunning);
        require(IERC20(DAI).TRANSFERFROM381(msg.sender, address(this), amountDAIDesired));
        require(IERC20(DAI).APPROVE425(address(UNIROUTER), amountDAIDesired));
        _TRANSFER73(msg.sender, address(this), amountTokenDesired);
        liquidityFlag = true;
        (uint amountToken, uint amountDAI, uint liquidity) = UNIROUTER.ADDLIQUIDITY85(
            address(this),
            DAI,
            amountTokenDesired,
            amountDAIDesired,
            amountTokenMin,
            amountDAImin,
            msg.sender,
            now + 10 minutes
        );
        liquidityFlag = false;

        if (amountTokenDesired - amountToken > 0 ) _TRANSFER73(address(this), msg.sender, amountTokenDesired-amountToken);
        if (amountDAIDesired - amountDAI > 0) require(IERC20(DAI).TRANSFER244(msg.sender, amountDAIDesired - amountDAI));
     }

     function ADDINITIALLIQUIDITYWITHPAIR729() public ONLYOWNER607 {
         CREATEUNISWAPPAIR64();
         uint256 amountDAI = IERC20(DAI).BALANCEOF616(address(this));
         require(IERC20(DAI).TRANSFER244(UNIPAIR, amountDAI));
         _MINT517(UNIPAIR, tokensforinitialliquidity143);
         IUniswapV2Pair(UNIPAIR).MINT615(msg.sender);
         isRunning = true;
     }

     function ADDINITIALLIQUIDITY209() public ONLYOWNER607 {
         uint256 amountDAI = IERC20(DAI).BALANCEOF616(address(this));
         require(IERC20(DAI).TRANSFER244(UNIPAIR, amountDAI));
         _MINT517(UNIPAIR, tokensforinitialliquidity143);
         IUniswapV2Pair(UNIPAIR).MINT615(msg.sender);
         isRunning = true;
     }

    function SETAIRDROPROOT894(bytes32 _root) public ONLYOWNER607 {
        airdropRoot = _root;
    }

    function SETPAIR246(address _pair) public ONLYOWNER607 {
        UNIPAIR = _pair;
    }

     function CREATEUNISWAPPAIR64() internal {
         require(UNIPAIR == address(0), "Token: pool already created");
         UNIPAIR = UNIFACTORY.CREATEPAIR614(
             DAI,
             address(this)
         );
     }

     function CHECKPROOF499(bytes memory proof, bytes32 root, bytes32 hash) internal view returns (bool) {
       bytes32 el;
       bytes32 h = hash;

       for (uint256 i = 32; i <= proof.length; i += 32) {
           assembly {
               el := mload(add(proof, i))
           }

           if (h < el) {
               h = keccak256(abi.encodePacked(h, el));
           } else {
               h = keccak256(abi.encodePacked(el, h));
           }
       }

       return h == root;
     }

     function CLAIMAIRDROP701(bytes memory proof, uint amount) public {
         require(!claimedAirdrop[msg.sender]);
         bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount));
         require(CHECKPROOF499(proof, airdropRoot, hash), "Invalid proof");
         claimedAirdrop[msg.sender] = true;
         _MINT517(msg.sender, amount);
     }

     function WITHDRAWERC20742(address token) ONLYOWNER607 public {
         uint balance = IERC20(token).BALANCEOF616(address(this));
         require(IERC20(token).TRANSFER244(msg.sender, balance));
     }
}
