

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IUniswap {

  function SWAPEXACTTOKENSFORETH436(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

  function SWAPEXACTETHFORTOKENS487(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    function TOTALSUPPLY323() external view returns (uint256);
    function BALANCEOF269(address account) external view returns (uint256);
    function TRANSFER6(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE471(address owner, address spender) external view returns (uint256);
    function APPROVE639(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM45(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER853(address indexed from, address indexed to, uint256 value);
    event APPROVAL183(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }


    function _MSGSENDER264() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA366() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address payable private _owner;

    event OWNERSHIPTRANSFERRED175(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _MSGSENDER264();
        emit OWNERSHIPTRANSFERRED175(address(0), _owner);
    }
    function OWNER564() public view returns (address payable) {
        return _owner;
    }
    modifier ONLYOWNER780() {
        require(ISOWNER198(), "Ownable: caller is not the owner");
        _;
    }
    function ISOWNER198() public view returns (bool) {
        return _MSGSENDER264() == _owner;
    }
    function RENOUNCEOWNERSHIP104() public ONLYOWNER780 {
        emit OWNERSHIPTRANSFERRED175(_owner, address(0));
        _owner = address(0);
    }
    function TRANSFEROWNERSHIP788(address payable newOwner) public ONLYOWNER780 {
        _TRANSFEROWNERSHIP70(newOwner);
    }
    function _TRANSFEROWNERSHIP70(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED175(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    function TOTALSUPPLY323() public view returns (uint256) {
        return _totalSupply;
    }
    function BALANCEOF269(address account) public view returns (uint256) {
        return _balances[account];
    }
    function TRANSFER6(address recipient, uint256 amount) public returns (bool) {
        _TRANSFER918(_MSGSENDER264(), recipient, amount);
        return true;
    }
    function ALLOWANCE471(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function APPROVE639(address spender, uint256 amount) public returns (bool) {
        _APPROVE444(_MSGSENDER264(), spender, amount);
        return true;
    }
    function TRANSFERFROM45(address sender, address recipient, uint256 amount) public returns (bool) {
        _TRANSFER918(sender, recipient, amount);
        _APPROVE444(sender, _MSGSENDER264(), _allowances[sender][_MSGSENDER264()].SUB46(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function INCREASEALLOWANCE61(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE444(_MSGSENDER264(), spender, _allowances[_MSGSENDER264()][spender].ADD992(addedValue));
        return true;
    }
    function DECREASEALLOWANCE74(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE444(_MSGSENDER264(), spender, _allowances[_MSGSENDER264()][spender].SUB46(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _TRANSFER918(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB46(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD992(amount);
        emit TRANSFER853(sender, recipient, amount);
    }
    function _MINT980(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD992(amount);
        _balances[account] = _balances[account].ADD992(amount);
        emit TRANSFER853(address(0), account, amount);
    }
    function _BURN375(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].SUB46(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB46(amount);
        emit TRANSFER853(account, address(0), amount);
    }
    function _APPROVE444(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL183(owner, spender, amount);
    }
    function _BURNFROM405(address account, uint256 amount) internal {
        _BURN375(account, amount);
        _APPROVE444(account, _MSGSENDER264(), _allowances[account][_MSGSENDER264()].SUB46(amount, "ERC20: burn amount exceeds allowance"));
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
    function NAME61() public view returns (string memory) {
        return _name;
    }
    function SYMBOL851() public view returns (string memory) {
        return _symbol;
    }
    function DECIMALS917() public view returns (uint8) {
        return _decimals;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier NONREENTRANT890() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

library SafeMath {
    function ADD992(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function SUB46(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB46(a, b, "SafeMath: subtraction overflow");
    }
    function SUB46(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function MUL613(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function DIV312(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV312(a, b, "SafeMath: division by zero");
    }
    function DIV312(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function MOD928(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD928(a, b, "SafeMath: modulo by zero");
    }
    function MOD928(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function ISCONTRACT42(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function TOPAYABLE515(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function SENDVALUE559(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER60(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN106(token, abi.encodeWithSelector(token.TRANSFER6.selector, to, value));
    }

    function SAFETRANSFERFROM510(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN106(token, abi.encodeWithSelector(token.TRANSFERFROM45.selector, from, to, value));
    }

    function SAFEAPPROVE585(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.ALLOWANCE471(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN106(token, abi.encodeWithSelector(token.APPROVE639.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE437(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE471(address(this), spender).ADD992(value);
        CALLOPTIONALRETURN106(token, abi.encodeWithSelector(token.APPROVE639.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE12(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE471(address(this), spender).SUB46(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN106(token, abi.encodeWithSelector(token.APPROVE639.selector, spender, newAllowance));
    }
    function CALLOPTIONALRETURN106(IERC20 token, bytes memory data) private {
        require(address(token).ISCONTRACT42(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Compound {
    function MINT570 ( uint256 mintAmount ) external returns ( uint256 );
    function REDEEM919(uint256 redeemTokens) external returns (uint256);
    function EXCHANGERATESTORED297() external view returns (uint);
}

interface Fulcrum {
    function MINT570(address receiver, uint256 amount) external payable returns (uint256 mintAmount);
    function BURN957(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
    function ASSETBALANCEOF748(address _owner) external view returns (uint256 balance);
}

interface ILendingPoolAddressesProvider {
    function GETLENDINGPOOL795() external view returns (address);
}

interface Aave {
    function DEPOSIT261(address _reserve, uint256 _amount, uint16 _referralCode) external;
}

interface AToken {
    function REDEEM919(uint256 amount) external;
}

interface IIEarnManager {
    function RECOMMEND876(address _token) external view returns (
      string memory choice,
      uint256 capr,
      uint256 iapr,
      uint256 aapr,
      uint256 dapr
    );
}

contract Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
        Deposit,
        Withdraw
    }

    enum AssetDenomination {
        Wei
    }

    enum AssetReference {
        Delta
    }

    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;
        uint256 number;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

contract DyDx is Structs {
    function GETACCOUNTWEI173(Info memory account, uint256 marketId) public view returns (Wei memory);
    function OPERATE410(Info[] memory, ActionArgs[] memory) public;
}

interface LendingPoolAddressesProvider {
    function GETLENDINGPOOL795() external view returns (address);
    function GETLENDINGPOOLCORE176() external view returns (address);
}

contract yTUSD is ERC20, ERC20Detailed, ReentrancyGuard, Structs, Ownable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  uint256 public pool;
  address public token;
  address public compound;
  address public fulcrum;
  address public aave;
  address public aavePool;
  address public aaveToken;
  address public dydx;
  uint256 public dToken;
  address public apr;
  address public chai;

  address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public tusd = 0x0000000000085d4780B73119b644AE5ecd22b376;
  address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address payable public retirementYeldTreasury;
  IERC20 public yeldToken;
  uint256 public maximumTokensToBurn = 50000 * 1e18;




  mapping(bytes32 => uint256) public numberOfParticipants;
  mapping(address => uint256) public depositBlockStarts;
  uint256 public constant onedayinblocks32 = 6500;
  uint256 public yeldToRewardPerDay = 100e18;
  uint256 public constant onemillion240 = 1e6;


  enum Lender {
      NONE,
      DYDX,
      COMPOUND,
      AAVE,
      FULCRUM
  }

  Lender public provider = Lender.NONE;

  constructor (address _yeldToken, address payable _retirementYeldTreasury) public payable ERC20Detailed("yearn TUSD", "yTUSD", 18) {
    token = address(0x0000000000085d4780B73119b644AE5ecd22b376);
    apr = address(0xdD6d648C991f7d47454354f4Ef326b04025a48A8);
    dydx = address(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    aave = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    aavePool = address(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3);
    fulcrum = address(0x493C57C4763932315A328269E1ADaD09653B9081);
    aaveToken = address(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d);
    compound = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    chai = address(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    dToken = 3;
    yeldToken = IERC20(_yeldToken);
    retirementYeldTreasury = _retirementYeldTreasury;
    APPROVETOKEN94();
  }


  function () external payable {}

  function SETRETIREMENTYELDTREASURY648(address payable _treasury) public ONLYOWNER780 {
    retirementYeldTreasury = _treasury;
  }


  function SETUNISWAPROUTER36(address _uniswapRouter) public ONLYOWNER780 {
    uniswapRouter = _uniswapRouter;
  }

  function EXTRACTTOKENSIFSTUCK789(address _token, uint256 _amount) public ONLYOWNER780 {
    IERC20(_token).TRANSFER6(msg.sender, _amount);
  }

  function EXTRACTETHIFSTUCK584() public ONLYOWNER780 {
    OWNER564().transfer(address(this).balance);
  }

  function CHANGEYELDTOREWARDPERDAY778(uint256 _amount) public ONLYOWNER780 {
    yeldToRewardPerDay = _amount;
  }

  function GETGENERATEDYELDS438() public view returns(uint256) {
    uint256 blocksPassed;
    if (depositBlockStarts[msg.sender] > 0) {
      blocksPassed = block.number.SUB46(depositBlockStarts[msg.sender]);
    } else {
      blocksPassed = 0;
    }






    uint256 ibalance = BALANCEOF269(msg.sender);
    uint256 accomulatedStablecoins = (CALCPOOLVALUEINTOKEN983().MUL613(ibalance)).DIV312(_totalSupply);
    uint256 generatedYelds = accomulatedStablecoins.DIV312(onemillion240).MUL613(yeldToRewardPerDay.DIV312(1e18)).MUL613(blocksPassed).DIV312(onedayinblocks32);
    return generatedYelds;
  }

  function EXTRACTYELDEARNINGSWHILEKEEPINGDEPOSIT225() public {
    uint256 ibalance = BALANCEOF269(msg.sender);
    uint256 accomulatedStablecoins = (CALCPOOLVALUEINTOKEN983().MUL613(ibalance)).DIV312(_totalSupply);
    require(depositBlockStarts[msg.sender] > 0 && accomulatedStablecoins > 0, 'Must have deposited stablecoins beforehand');
    uint256 generatedYelds = GETGENERATEDYELDS438();
    depositBlockStarts[msg.sender] = block.number;
    yeldToken.TRANSFER6(msg.sender, generatedYelds);
  }

  function DEPOSIT261(uint256 _amount)
      external
      NONREENTRANT890
  {
    require(_amount > 0, "deposit must be greater than 0");
    pool = CALCPOOLVALUEINTOKEN983();
    IERC20(token).SAFETRANSFERFROM510(msg.sender, address(this), _amount);


    if (GETGENERATEDYELDS438() > 0) EXTRACTYELDEARNINGSWHILEKEEPINGDEPOSIT225();
    depositBlockStarts[msg.sender] = block.number;



    uint256 shares = 0;
    if (pool == 0) {
      shares = _amount;
      pool = _amount;
    } else {
      shares = (_amount.MUL613(_totalSupply)).DIV312(pool);
    }
    pool = CALCPOOLVALUEINTOKEN983();
    _MINT980(msg.sender, shares);
    REBALANCE90();
  }


  function TUSDTOETH442(uint256 _amount) internal returns(uint256) {
      IERC20(tusd).SAFEAPPROVE585(uniswapRouter, 0);
      IERC20(tusd).SAFEAPPROVE585(uniswapRouter, _amount);
      address[] memory path = new address[](2);
      path[0] = tusd;
      path[1] = weth;




      uint[] memory amounts = IUniswap(uniswapRouter).SWAPEXACTTOKENSFORETH436(_amount, uint(0), path, address(this), now.ADD992(1800));
      return amounts[1];
  }



  function BUYNBURN597(uint256 _ethToSwap) internal returns(uint256) {
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = address(yeldToken);

    uint[] memory amounts = IUniswap(uniswapRouter).SWAPEXACTETHFORTOKENS487.value(_ethToSwap)(uint(0), path, address(0), now.ADD992(1800));
    return amounts[1];
  }


  function WITHDRAW331(uint256 _shares)
      external
      NONREENTRANT890
  {
      require(_shares > 0, "withdraw must be greater than 0");
      uint256 ibalance = BALANCEOF269(msg.sender);
      require(_shares <= ibalance, "insufficient balance");
      pool = CALCPOOLVALUEINTOKEN983();
      uint256 stablecoinsToWithdraw = (pool.MUL613(_shares)).DIV312(_totalSupply);
      _balances[msg.sender] = _balances[msg.sender].SUB46(_shares, "redeem amount exceeds balance");
      _totalSupply = _totalSupply.SUB46(_shares);
      emit TRANSFER853(msg.sender, address(0), _shares);
      uint256 b = IERC20(token).BALANCEOF269(address(this));
      if (b < stablecoinsToWithdraw) {
        _WITHDRAWSOME967(stablecoinsToWithdraw.SUB46(b));
      }


      uint256 generatedYelds = GETGENERATEDYELDS438();

      uint256 onePercent = stablecoinsToWithdraw.DIV312(100);
      depositBlockStarts[msg.sender] = block.number;
      yeldToken.TRANSFER6(msg.sender, generatedYelds);



      uint256 stakingProfits = TUSDTOETH442(onePercent);
      uint256 tokensAlreadyBurned = yeldToken.BALANCEOF269(address(0));
      if (tokensAlreadyBurned < maximumTokensToBurn) {

        uint256 ethToSwap = stakingProfits.MUL613(98).DIV312(100);

        BUYNBURN597(ethToSwap);

        uint256 retirementYeld = stakingProfits.MUL613(2).DIV312(100);

        retirementYeldTreasury.transfer(retirementYeld);
      } else {

        uint256 retirementYeld = stakingProfits;

        retirementYeldTreasury.transfer(retirementYeld);
      }
      IERC20(token).SAFETRANSFER60(msg.sender, stablecoinsToWithdraw.SUB46(onePercent));


      pool = CALCPOOLVALUEINTOKEN983();
      REBALANCE90();
  }

  function RECOMMEND876() public view returns (Lender) {
    (,uint256 capr,uint256 iapr,uint256 aapr,uint256 dapr) = IIEarnManager(apr).RECOMMEND876(token);
    uint256 max = 0;
    if (capr > max) {
      max = capr;
    }
    if (iapr > max) {
      max = iapr;
    }
    if (aapr > max) {
      max = aapr;
    }
    if (dapr > max) {
      max = dapr;
    }

    Lender newProvider = Lender.NONE;
    if (max == capr) {
      newProvider = Lender.COMPOUND;
    } else if (max == iapr) {
      newProvider = Lender.FULCRUM;
    } else if (max == aapr) {
      newProvider = Lender.AAVE;
    } else if (max == dapr) {
      newProvider = Lender.DYDX;
    }
    return newProvider;
  }

  function GETAAVE657() public view returns (address) {
    return LendingPoolAddressesProvider(aave).GETLENDINGPOOL795();
  }
  function GETAAVECORE248() public view returns (address) {
    return LendingPoolAddressesProvider(aave).GETLENDINGPOOLCORE176();
  }

  function APPROVETOKEN94() public {
      IERC20(token).SAFEAPPROVE585(compound, uint(-1));
      IERC20(token).SAFEAPPROVE585(dydx, uint(-1));
      IERC20(token).SAFEAPPROVE585(GETAAVECORE248(), uint(-1));
      IERC20(token).SAFEAPPROVE585(fulcrum, uint(-1));
  }

  function BALANCE782() public view returns (uint256) {
    return IERC20(token).BALANCEOF269(address(this));
  }
  function BALANCEDYDXAVAILABLE330() public view returns (uint256) {
      return IERC20(token).BALANCEOF269(dydx);
  }
  function BALANCEDYDX86() public view returns (uint256) {
      Wei memory bal = DyDx(dydx).GETACCOUNTWEI173(Info(address(this), 0), dToken);
      return bal.value;
  }
  function BALANCECOMPOUND355() public view returns (uint256) {
      return IERC20(compound).BALANCEOF269(address(this));
  }
  function BALANCECOMPOUNDINTOKEN294() public view returns (uint256) {

    uint256 b = BALANCECOMPOUND355();
    if (b > 0) {
      b = b.MUL613(Compound(compound).EXCHANGERATESTORED297()).DIV312(1e18);
    }
    return b;
  }
  function BALANCEFULCRUMAVAILABLE395() public view returns (uint256) {
      return IERC20(chai).BALANCEOF269(fulcrum);
  }
  function BALANCEFULCRUMINTOKEN503() public view returns (uint256) {
    uint256 b = BALANCEFULCRUM271();
    if (b > 0) {
      b = Fulcrum(fulcrum).ASSETBALANCEOF748(address(this));
    }
    return b;
  }
  function BALANCEFULCRUM271() public view returns (uint256) {
    return IERC20(fulcrum).BALANCEOF269(address(this));
  }
  function BALANCEAAVEAVAILABLE892() public view returns (uint256) {
      return IERC20(token).BALANCEOF269(aavePool);
  }
  function BALANCEAAVE873() public view returns (uint256) {
    return IERC20(aaveToken).BALANCEOF269(address(this));
  }

  function REBALANCE90() public {
    Lender newProvider = RECOMMEND876();

    if (newProvider != provider) {
      _WITHDRAWALL499();
    }

    if (BALANCE782() > 0) {
      if (newProvider == Lender.DYDX) {
        _SUPPLYDYDX870(BALANCE782());
      } else if (newProvider == Lender.FULCRUM) {
        _SUPPLYFULCRUM37(BALANCE782());
      } else if (newProvider == Lender.COMPOUND) {
        _SUPPLYCOMPOUND942(BALANCE782());
      } else if (newProvider == Lender.AAVE) {
        _SUPPLYAAVE258(BALANCE782());
      }
    }

    provider = newProvider;
  }

  function _WITHDRAWALL499() internal {
    uint256 amount = BALANCECOMPOUND355();
    if (amount > 0) {
      _WITHDRAWSOMECOMPOUND259(BALANCECOMPOUNDINTOKEN294().SUB46(1));
    }
    amount = BALANCEDYDX86();
    if (amount > 0) {
      if (amount > BALANCEDYDXAVAILABLE330()) {
        amount = BALANCEDYDXAVAILABLE330();
      }
      _WITHDRAWDYDX942(amount);
    }
    amount = BALANCEFULCRUM271();
    if (amount > 0) {
      if (amount > BALANCEFULCRUMAVAILABLE395().SUB46(1)) {
        amount = BALANCEFULCRUMAVAILABLE395().SUB46(1);
      }
      _WITHDRAWSOMEFULCRUM209(amount);
    }
    amount = BALANCEAAVE873();
    if (amount > 0) {
      if (amount > BALANCEAAVEAVAILABLE892()) {
        amount = BALANCEAAVEAVAILABLE892();
      }
      _WITHDRAWAAVE427(amount);
    }
  }

  function _WITHDRAWSOMECOMPOUND259(uint256 _amount) internal {
    uint256 b = BALANCECOMPOUND355();
    uint256 bT = BALANCECOMPOUNDINTOKEN294();
    require(bT >= _amount, "insufficient funds");

    uint256 amount = (b.MUL613(_amount)).DIV312(bT).ADD992(1);
    _WITHDRAWCOMPOUND330(amount);
  }

  function _WITHDRAWSOMEFULCRUM209(uint256 _amount) internal {
    uint256 b = BALANCEFULCRUM271();
    uint256 bT = BALANCEFULCRUMINTOKEN503();
    require(bT >= _amount, "insufficient funds");

    uint256 amount = (b.MUL613(_amount)).DIV312(bT).ADD992(1);
    _WITHDRAWFULCRUM371(amount);
  }


  function _WITHDRAWSOME967(uint256 _amount) internal returns (bool) {
    uint256 origAmount = _amount;

    uint256 amount = BALANCECOMPOUND355();
    if (amount > 0) {
      if (_amount > BALANCECOMPOUNDINTOKEN294().SUB46(1)) {
        _WITHDRAWSOMECOMPOUND259(BALANCECOMPOUNDINTOKEN294().SUB46(1));
        _amount = origAmount.SUB46(IERC20(token).BALANCEOF269(address(this)));
      } else {
        _WITHDRAWSOMECOMPOUND259(_amount);
        return true;
      }
    }

    amount = BALANCEDYDX86();
    if (amount > 0) {
      if (_amount > BALANCEDYDXAVAILABLE330()) {
        _WITHDRAWDYDX942(BALANCEDYDXAVAILABLE330());
        _amount = origAmount.SUB46(IERC20(token).BALANCEOF269(address(this)));
      } else {
        _WITHDRAWDYDX942(_amount);
        return true;
      }
    }

    amount = BALANCEFULCRUM271();
    if (amount > 0) {
      if (_amount > BALANCEFULCRUMAVAILABLE395().SUB46(1)) {
        amount = BALANCEFULCRUMAVAILABLE395().SUB46(1);
        _WITHDRAWSOMEFULCRUM209(BALANCEFULCRUMAVAILABLE395().SUB46(1));
        _amount = origAmount.SUB46(IERC20(token).BALANCEOF269(address(this)));
      } else {
        _WITHDRAWSOMEFULCRUM209(amount);
        return true;
      }
    }

    amount = BALANCEAAVE873();
    if (amount > 0) {
      if (_amount > BALANCEAAVEAVAILABLE892()) {
        _WITHDRAWAAVE427(BALANCEAAVEAVAILABLE892());
        _amount = origAmount.SUB46(IERC20(token).BALANCEOF269(address(this)));
      } else {
        _WITHDRAWAAVE427(_amount);
        return true;
      }
    }

    return true;
  }

  function _SUPPLYDYDX870(uint256 amount) internal {
      Info[] memory infos = new Info[](1);
      infos[0] = Info(address(this), 0);

      AssetAmount memory amt = AssetAmount(true, AssetDenomination.Wei, AssetReference.Delta, amount);
      ActionArgs memory act;
      act.actionType = ActionType.Deposit;
      act.accountId = 0;
      act.amount = amt;
      act.primaryMarketId = dToken;
      act.otherAddress = address(this);

      ActionArgs[] memory args = new ActionArgs[](1);
      args[0] = act;

      DyDx(dydx).OPERATE410(infos, args);
  }

  function _SUPPLYAAVE258(uint amount) internal {
      Aave(GETAAVE657()).DEPOSIT261(token, amount, 0);
  }
  function _SUPPLYFULCRUM37(uint amount) internal {
      require(Fulcrum(fulcrum).MINT570(address(this), amount) > 0, "FULCRUM: supply failed");
  }
  function _SUPPLYCOMPOUND942(uint amount) internal {
      require(Compound(compound).MINT570(amount) == 0, "COMPOUND: supply failed");
  }
  function _WITHDRAWAAVE427(uint amount) internal {
      AToken(aaveToken).REDEEM919(amount);
  }
  function _WITHDRAWFULCRUM371(uint amount) internal {
      require(Fulcrum(fulcrum).BURN957(address(this), amount) > 0, "FULCRUM: withdraw failed");
  }
  function _WITHDRAWCOMPOUND330(uint amount) internal {
      require(Compound(compound).REDEEM919(amount) == 0, "COMPOUND: withdraw failed");
  }

  function _WITHDRAWDYDX942(uint256 amount) internal {
      Info[] memory infos = new Info[](1);
      infos[0] = Info(address(this), 0);

      AssetAmount memory amt = AssetAmount(false, AssetDenomination.Wei, AssetReference.Delta, amount);
      ActionArgs memory act;
      act.actionType = ActionType.Withdraw;
      act.accountId = 0;
      act.amount = amt;
      act.primaryMarketId = dToken;
      act.otherAddress = address(this);

      ActionArgs[] memory args = new ActionArgs[](1);
      args[0] = act;

      DyDx(dydx).OPERATE410(infos, args);
  }

  function CALCPOOLVALUEINTOKEN983() public view returns (uint) {
    return BALANCECOMPOUNDINTOKEN294()
      .ADD992(BALANCEFULCRUMINTOKEN503())
      .ADD992(BALANCEDYDX86())
      .ADD992(BALANCEAAVE873())
      .ADD992(BALANCE782());
  }

  function GETPRICEPERFULLSHARE370() public view returns (uint) {
    uint _pool = CALCPOOLVALUEINTOKEN983();
    return _pool.MUL613(1e18).DIV312(_totalSupply);
  }
}
