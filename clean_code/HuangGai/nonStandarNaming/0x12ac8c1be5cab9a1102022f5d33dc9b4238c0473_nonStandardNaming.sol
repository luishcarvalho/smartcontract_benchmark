


pragma solidity 0.6.12;


library SafeMath {

    function ADD388(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB906(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB906(a, b, "SafeMath: subtraction overflow");
    }


    function SUB906(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL601(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV456(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV456(a, b, "SafeMath: division by zero");
    }


    function DIV456(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD78(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD78(a, b, "SafeMath: modulo by zero");
    }


    function MOD78(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


abstract contract Context {
    function _MSGSENDER877() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA207() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


interface IERC20 {

    function TOTALSUPPLY738() external view returns (uint256);


    function BALANCEOF68(address account) external view returns (uint256);


    function TRANSFER734(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE35(address owner, address spender) external view returns (uint256);


    function APPROVE429(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM531(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER657(address indexed from, address indexed to, uint256 value);


    event APPROVAL956(address indexed owner, address indexed spender, uint256 value);
}



library Address {

    function ISCONTRACT600(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function SENDVALUE944(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL15(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL15(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL15(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE358(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE499(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE499(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE499(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE358(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE358(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT600(target), "Address: call to non-contract");


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


    function NAME254() public view returns (string memory) {
        return _name;
    }


    function SYMBOL669() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS84() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY738() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF68(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER734(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER67(_MSGSENDER877(), recipient, amount);
        return true;
    }


    function ALLOWANCE35(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE429(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE455(_MSGSENDER877(), spender, amount);
        return true;
    }


    function TRANSFERFROM531(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER67(sender, recipient, amount);
        _APPROVE455(sender, _MSGSENDER877(), _allowances[sender][_MSGSENDER877()].SUB906(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE275(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE455(_MSGSENDER877(), spender, _allowances[_MSGSENDER877()][spender].ADD388(addedValue));
        return true;
    }


    function DECREASEALLOWANCE402(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE455(_MSGSENDER877(), spender, _allowances[_MSGSENDER877()][spender].SUB906(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER67(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER81(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB906(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD388(amount);
        emit TRANSFER657(sender, recipient, amount);
    }


    function _MINT823(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER81(address(0), account, amount);

        _totalSupply = _totalSupply.ADD388(amount);
        _balances[account] = _balances[account].ADD388(amount);
        emit TRANSFER657(address(0), account, amount);
    }


    function _BURN465(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER81(account, address(0), amount);

        _balances[account] = _balances[account].SUB906(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB906(amount);
        emit TRANSFER657(account, address(0), amount);
    }


    function _APPROVE455(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL956(owner, spender, amount);
    }


    function _SETUPDECIMALS854(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER81(address from, address to, uint256 amount) internal virtual { }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER331(IERC20 token, address to, uint256 value) internal {
        _CALLOPTIONALRETURN31(token, abi.encodeWithSelector(token.TRANSFER734.selector, to, value));
    }

    function SAFETRANSFERFROM748(IERC20 token, address from, address to, uint256 value) internal {
        _CALLOPTIONALRETURN31(token, abi.encodeWithSelector(token.TRANSFERFROM531.selector, from, to, value));
    }


    function SAFEAPPROVE284(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE35(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _CALLOPTIONALRETURN31(token, abi.encodeWithSelector(token.APPROVE429.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE243(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE35(address(this), spender).ADD388(value);
        _CALLOPTIONALRETURN31(token, abi.encodeWithSelector(token.APPROVE429.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE653(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE35(address(this), spender).SUB906(value, "SafeERC20: decreased allowance below zero");
        _CALLOPTIONALRETURN31(token, abi.encodeWithSelector(token.APPROVE429.selector, spender, newAllowance));
    }


    function _CALLOPTIONALRETURN31(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).FUNCTIONCALL15(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IVault is IERC20 {
    function TOKEN190() external view returns (address);

    function DECIMALS84() external view returns (uint8);

    function EARN763() external;

    function DEPOSIT115(uint256) external;

    function DEPOSITALL187() external;

    function WITHDRAW593(uint256) external;

    function WITHDRAWALL63() external;

    function DISTRIBUTE67() external;

    function SALVAGE929(address, uint256) external;

    function GETRATIO675() external view returns (uint256);
}

interface ICurveFi_2 {
    function GET_VIRTUAL_PRICE809() external view returns (uint256);

    function ADD_LIQUIDITY50(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    function REMOVE_LIQUIDITY_IMBALANCE11(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function REMOVE_LIQUIDITY517(uint256 _amount, uint256[2] calldata amounts)
        external;

    function EXCHANGE792(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function BALANCES2(int128) external view returns (uint256);
}

interface ICurve3Pool {
    function GET_VIRTUAL_PRICE809() external view returns (uint256);

    function ADD_LIQUIDITY50(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function REMOVE_LIQUIDITY_IMBALANCE11(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function REMOVE_LIQUIDITY517(uint256 _amount, uint256[3] calldata amounts)
        external;

    function EXCHANGE792(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function BALANCES2(uint256) external view returns (uint256);
}

interface ICurveFi_4 {
    function GET_VIRTUAL_PRICE809() external view returns (uint256);

    function ADD_LIQUIDITY50(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function REMOVE_LIQUIDITY_IMBALANCE11(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function REMOVE_LIQUIDITY517(uint256 _amount, uint256[4] calldata amounts)
        external;

    function EXCHANGE792(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function BALANCES2(int128) external view returns (uint256);
}

interface ICurveZap_4 {
    function ADD_LIQUIDITY50(
        uint256[4] calldata uamounts,
        uint256 min_mint_amount
    ) external;

    function REMOVE_LIQUIDITY517(uint256 _amount, uint256[4] calldata min_uamounts)
        external;

    function REMOVE_LIQUIDITY_IMBALANCE11(
        uint256[4] calldata uamounts,
        uint256 max_burn_amount
    ) external;

    function CALC_WITHDRAW_ONE_COIN560(uint256 _token_amount, int128 i)
        external
        returns (uint256);

    function REMOVE_LIQUIDITY_ONE_COIN125(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function REMOVE_LIQUIDITY_ONE_COIN125(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount,
        bool donate_dust
    ) external;

    function WITHDRAW_DONATED_DUST417() external;

    function COINS352(int128 arg0) external returns (address);

    function UNDERLYING_COINS1(int128 arg0) external returns (address);

    function CURVE335() external returns (address);

    function TOKEN190() external returns (address);
}

interface ICurveZap {
    function REMOVE_LIQUIDITY_ONE_COIN125(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;
}

interface ICurveGauge {
    function DEPOSIT115(uint256 _value) external;

    function DEPOSIT115(uint256 _value, address addr) external;

    function BALANCEOF68(address arg0) external view returns (uint256);

    function WITHDRAW593(uint256 _value) external;

    function WITHDRAW593(uint256 _value, bool claim_rewards) external;

    function CLAIM_REWARDS536() external;

    function CLAIM_REWARDS536(address addr) external;

    function CLAIMABLE_TOKENS440(address addr) external returns (uint256);

    function CLAIMABLE_REWARD978(address addr) external view returns (uint256);

    function INTEGRATE_FRACTION797(address arg0) external view returns (uint256);
}

interface ICurveMintr {
    function MINT951(address) external;

    function MINTED257(address arg0, address arg1) external view returns (uint256);
}

interface ICurveVotingEscrow {
    function LOCKED178(address arg0)
        external
        view
        returns (int128 amount, uint256 end);

    function LOCKED__END474(address _addr) external view returns (uint256);

    function CREATE_LOCK305(uint256, uint256) external;

    function INCREASE_AMOUNT922(uint256) external;

    function INCREASE_UNLOCK_TIME38(uint256 _unlock_time) external;

    function WITHDRAW593() external;

    function SMART_WALLET_CHECKER846() external returns (address);
}

interface ICurveSmartContractChecker {
    function WALLETS237(address) external returns (bool);

    function APPROVEWALLET249(address _wallet) external;
}

interface UniswapRouterV2 {
    function SWAPEXACTTOKENSFORTOKENS167(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function ADDLIQUIDITY947(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function ADDLIQUIDITYETH996(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function REMOVELIQUIDITY801(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function GETAMOUNTSOUT893(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function GETAMOUNTSIN14(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function SWAPETHFOREXACTTOKENS437(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function SWAPEXACTETHFORTOKENS898(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    event APPROVAL956(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event TRANSFER657(address indexed from, address indexed to, uint256 value);

    function NAME254() external pure returns (string memory);

    function SYMBOL669() external pure returns (string memory);

    function DECIMALS84() external pure returns (uint8);

    function TOTALSUPPLY738() external view returns (uint256);

    function BALANCEOF68(address owner) external view returns (uint256);

    function ALLOWANCE35(address owner, address spender)
        external
        view
        returns (uint256);

    function APPROVE429(address spender, uint256 value) external returns (bool);

    function TRANSFER734(address to, uint256 value) external returns (bool);

    function TRANSFERFROM531(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR578() external view returns (bytes32);

    function PERMIT_TYPEHASH551() external pure returns (bytes32);

    function NONCES443(address owner) external view returns (uint256);

    function PERMIT326(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event MINT405(address indexed sender, uint256 amount0, uint256 amount1);
    event BURN673(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event SWAP227(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event SYNC504(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY881() external pure returns (uint256);

    function FACTORY729() external view returns (address);

    function TOKEN0644() external view returns (address);

    function TOKEN1449() external view returns (address);

    function GETRESERVES964()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function PRICE0CUMULATIVELAST588() external view returns (uint256);

    function PRICE1CUMULATIVELAST951() external view returns (uint256);

    function KLAST390() external view returns (uint256);

    function MINT951(address to) external returns (uint256 liquidity);

    function BURN57(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function SWAP519(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function SKIM366(address to) external;

    function SYNC84() external;
}

interface IUniswapV2Factory {
    event PAIRCREATED988(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function GETPAIR36(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function ALLPAIRS303(uint256) external view returns (address pair);

    function ALLPAIRSLENGTH195() external view returns (uint256);

    function FEETO341() external view returns (address);

    function FEETOSETTER863() external view returns (address);

    function CREATEPAIR664(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface ICurveTBTC {
    function ADD_LIQUIDITY50(
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface IKeepRewardsClaimable {
  function CLAIM_REWARDS536() external;
}


abstract contract VoxStrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;


    uint256 public treasuryFee = 1000;
    uint256 public constant treasuryfeemax584 = 2000;
    uint256 public constant treasuryfeebase971 = 10000;

    uint256 public strategyFee = 500;
    uint256 public constant strategyfeemax620 = 5000;
    uint256 public constant strategyfeebase640 = 10000;

    uint256 public developerFee = 250;
    uint256 public constant developerfeemax597 = 500;
    uint256 public constant developerfeebase561 = 10000;


    uint256 public withdrawalFee = 15;
    uint256 public constant withdrawalfeemax274 = 15;
    uint256 public constant withdrawalfeebase605 = 10000;


    address public underlying;
    address public constant weth339 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant wbtc162 = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;


    address public governance;
    address public strategist;
    address public treasury;
    address public devfund;
    address public timelock;
    address public vault;


    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor(
        address _underlying,
        address _governance,
        address _strategist,
        address _treasury,
        address _devfund,
        address _timelock,
        address _vault
    ) public {
        require(_underlying != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_treasury != address(0));
        require(_devfund != address(0));
        require(_timelock != address(0));
        require(_vault != address(0));

        underlying = _underlying;
        governance = _governance;
        strategist = _strategist;
        treasury = _treasury;
        devfund = _devfund;
        timelock = _timelock;
        vault = _vault;
    }



    modifier RESTRICTED912 {
        require(
            msg.sender == tx.origin ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }



    function BALANCEOFUNDERLYING222() public view returns (uint256) {
        return IERC20(underlying).BALANCEOF68(address(this));
    }

    function BALANCEOFPOOL881() public virtual view returns (uint256);

    function BALANCEOF68() public view returns (uint256) {
        return BALANCEOFUNDERLYING222().ADD388(BALANCEOFPOOL881());
    }

    function GETNAME974() external virtual pure returns (string memory);



    function SETTREASURYFEE502(uint256 _treasuryFee) external {
        require(msg.sender == timelock, "!timelock");
        treasuryFee = _treasuryFee;
    }

    function SETSTRATEGYFEE761(uint256 _strategyFee) external {
        require(msg.sender == timelock, "!timelock");
        strategyFee = _strategyFee;
    }

    function SETDEVELOPERFEE113(uint256 _developerFee) external {
        require(msg.sender == timelock, "!timelock");
        developerFee = _developerFee;
    }

    function SETWITHDRAWALFEE980(uint256 _withdrawalFee) external {
        require(msg.sender == timelock, "!timelock");
        withdrawalFee = _withdrawalFee;
    }

    function SETSTRATEGIST654(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function SETGOVERNANCE136(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function SETTREASURY187(address _treasury) external {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
    }

    function SETDEVFUND591(address _devfund) external {
        require(msg.sender == devfund, "!devfund");
        devfund = _devfund;
    }

    function SETTIMELOCK277(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }


    function DEPOSIT115() public virtual;


    function SALVAGE929(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == governance, "!governance");
        require(underlying != address(_asset), "underlying");
        balance = _asset.BALANCEOF68(address(this));
        _asset.SAFETRANSFER331(treasury, balance);
    }


    function WITHDRAW593(uint256 _amount) external {
        require(msg.sender == vault, "!vault");
        uint256 _balance = IERC20(underlying).BALANCEOF68(address(this));
        if (_balance < _amount) {
            _amount = _WITHDRAWSOME235(_amount.SUB906(_balance));
            _amount = _amount.ADD388(_balance);
        }

        uint256 _withdrawalFee = _amount.MUL601(withdrawalFee).DIV456(withdrawalfeebase605);
        IERC20(underlying).SAFETRANSFER331(treasury, _withdrawalFee);

        require(vault != address(0), "!vault");
        IERC20(underlying).SAFETRANSFER331(vault, _amount.SUB906(_withdrawalFee));
    }


    function WITHDRAWALL63() external RESTRICTED912 returns (uint256 balance) {
        _WITHDRAWALL78();
        balance = IERC20(underlying).BALANCEOF68(address(this));

        require(vault != address(0), "!vault");
        IERC20(underlying).SAFETRANSFER331(vault, balance);
    }

    function _WITHDRAWALL78() internal {
        _WITHDRAWSOME235(BALANCEOFPOOL881());
    }

    function _WITHDRAWSOME235(uint256 _amount) internal virtual returns (uint256);

    function HARVEST372() public virtual;

    function _DISTRIBUTEANDDEPOSIT388() internal {
        uint256 _underlying = IERC20(underlying).BALANCEOF68(address(this));

        if (_underlying > 0) {

            IERC20(underlying).SAFETRANSFER331(
                treasury,
                _underlying.MUL601(treasuryFee).DIV456(treasuryfeebase971)
            );


            IERC20(underlying).SAFETRANSFER331(
                strategist,
                _underlying.MUL601(strategyFee).DIV456(strategyfeebase640)
            );


            IERC20(underlying).SAFETRANSFER331(
                devfund,
                _underlying.MUL601(developerFee).DIV456(developerfeebase561)
            );

            DEPOSIT115();
        }
    }



    function EXECUTE807(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");


        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {

                    revert(add(response, 0x20), size)
                }
        }
    }


    function _SWAPUNISWAP503(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));


        IERC20(_from).SAFEAPPROVE284(univ2Router2, 0);
        IERC20(_from).SAFEAPPROVE284(univ2Router2, _amount);

        address[] memory path;

        if (_from == weth339 || _to == weth339) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth339;
            path[2] = _to;
        }

        UniswapRouterV2(univ2Router2).SWAPEXACTTOKENSFORTOKENS167(
            _amount,
            0,
            path,
            address(this),
            now.ADD388(60)
        );
    }
}


abstract contract VoxStrategyCurveBase is VoxStrategyBase {

    address public curve;
    address public gauge;
    address public mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;


    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;


    address public renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;


    address public crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;


    address public keep = 0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC;
    address public keep_rewards = 0x6828bcF74279eE32f2723eC536c22c51Eed383C6;


    uint256 public keepCRV = 0;
    uint256 public keepCRVMax = 10000;

    constructor(
        address _curve,
        address _gauge,
        address _underlying,
        address _governance,
        address _strategist,
        address _treasury,
        address _devfund,
        address _timelock,
        address _vault
    )
        public
        VoxStrategyBase(_underlying, _governance, _strategist, _treasury, _devfund, _timelock, _vault)
    {
        curve = _curve;
        gauge = _gauge;
    }



    function BALANCEOFPOOL881() public override view returns (uint256) {
        return ICurveGauge(gauge).BALANCEOF68(address(this));
    }

    function GETHARVESTABLE58() external returns (uint256) {
        return ICurveGauge(gauge).CLAIMABLE_TOKENS440(address(this));
    }

    function GETMOSTPREMIUM814() public virtual view returns (address, uint256);



    function SETKEEPCRV171(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }



    function DEPOSIT115() public override {
        uint256 _underlying = IERC20(underlying).BALANCEOF68(address(this));
        if (_underlying > 0) {
            IERC20(underlying).SAFEAPPROVE284(gauge, 0);
            IERC20(underlying).SAFEAPPROVE284(gauge, _underlying);
            ICurveGauge(gauge).DEPOSIT115(_underlying);
        }
    }

    function _WITHDRAWSOME235(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICurveGauge(gauge).WITHDRAW593(_amount);
        return _amount;
    }
}

contract VoxStrategyCurveTBTC is VoxStrategyCurveBase {

    address public tbtc_pool = 0xaa82ca713D94bBA7A89CEAB55314F9EfFEdDc78c;
    address public tbtc_gauge = 0x6828bcF74279eE32f2723eC536c22c51Eed383C6;
    address public tbtc_crv = 0x64eda51d3Ad40D56b9dFc5554E06F94e1Dd786Fd;


    event HARVESTED180(address indexed token, uint256 amount);

    constructor(
        address _governance,
        address _strategist,
        address _treasury,
        address _devfund,
        address _timelock,
        address _vault
    )
        public
        VoxStrategyCurveBase(
            tbtc_pool,
            tbtc_gauge,
            tbtc_crv,
            _governance,
            _strategist,
            _treasury,
            _devfund,
            _timelock,
            _vault
        )
    {}



    function GETMOSTPREMIUM814()
        public
        override
        view
        returns (address, uint256)
    {
        return (wbtc162, 2);
    }

    function GETNAME974() external override pure returns (string memory) {
        return "VoxStrategyCurveTBTC";
    }



    function HARVEST372() public RESTRICTED912 override {

        (address to, uint256 toIndex) = GETMOSTPREMIUM814();



        ICurveMintr(mintr).MINT951(gauge);
        uint256 _crv = IERC20(crv).BALANCEOF68(address(this));
        if (_crv > 0) {


            uint256 _keepCRV = _crv.MUL601(keepCRV).DIV456(keepCRVMax);
            if (_keepCRV > 0) {
                IERC20(crv).SAFETRANSFER331(
                    treasury,
                    _keepCRV
                );
            }
            _crv = _crv.SUB906(_keepCRV);
            _SWAPUNISWAP503(crv, to, _crv);
        }


        IKeepRewardsClaimable(keep_rewards).CLAIM_REWARDS536();
        uint256 _keep = IERC20(keep).BALANCEOF68(address(this));
        if (_keep > 0) {
            _SWAPUNISWAP503(keep, to, _keep);
        }



        uint256 _to = IERC20(to).BALANCEOF68(address(this));
        if (_to > 0) {
            IERC20(to).SAFEAPPROVE284(curve, 0);
            IERC20(to).SAFEAPPROVE284(curve, _to);
            uint256[4] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveTBTC(curve).ADD_LIQUIDITY50(liquidity, 0);
        }



        _DISTRIBUTEANDDEPOSIT388();
        emit HARVESTED180(to, _to);
    }
}
