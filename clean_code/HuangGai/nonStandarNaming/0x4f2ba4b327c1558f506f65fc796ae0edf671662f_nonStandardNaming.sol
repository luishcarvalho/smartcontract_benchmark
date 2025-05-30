



pragma solidity ^0.5.16;

interface IERC20 {
    function TOTALSUPPLY668() external view returns (uint256);
    function BALANCEOF856(address account) external view returns (uint256);
    function TRANSFER590(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE439(address owner, address spender) external view returns (uint256);
    function APPROVE165(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM946(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER113(address indexed from, address indexed to, uint256 value);
    event APPROVAL275(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }


    function _MSGSENDER204() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA645() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED90(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _MSGSENDER204();
        emit OWNERSHIPTRANSFERRED90(address(0), _owner);
    }
    function OWNER726() public view returns (address) {
        return _owner;
    }
    modifier ONLYOWNER38() {
        require(ISOWNER90(), "Ownable: caller is not the owner");
        _;
    }
    function ISOWNER90() public view returns (bool) {
        return _MSGSENDER204() == _owner;
    }
    function RENOUNCEOWNERSHIP524() public ONLYOWNER38 {
        emit OWNERSHIPTRANSFERRED90(_owner, address(0));
        _owner = address(0);
    }
    function TRANSFEROWNERSHIP660(address newOwner) public ONLYOWNER38 {
        _TRANSFEROWNERSHIP31(newOwner);
    }
    function _TRANSFEROWNERSHIP31(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED90(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    function TOTALSUPPLY668() public view returns (uint256) {
        return _totalSupply;
    }
    function BALANCEOF856(address account) public view returns (uint256) {
        return _balances[account];
    }
    function TRANSFER590(address recipient, uint256 amount) public returns (bool) {
        _TRANSFER132(_MSGSENDER204(), recipient, amount);
        return true;
    }
    function ALLOWANCE439(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function APPROVE165(address spender, uint256 amount) public returns (bool) {
        _APPROVE48(_MSGSENDER204(), spender, amount);
        return true;
    }
    function TRANSFERFROM946(address sender, address recipient, uint256 amount) public returns (bool) {
        _TRANSFER132(sender, recipient, amount);
        _APPROVE48(sender, _MSGSENDER204(), _allowances[sender][_MSGSENDER204()].SUB641(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function INCREASEALLOWANCE241(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE48(_MSGSENDER204(), spender, _allowances[_MSGSENDER204()][spender].ADD348(addedValue));
        return true;
    }
    function DECREASEALLOWANCE811(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE48(_MSGSENDER204(), spender, _allowances[_MSGSENDER204()][spender].SUB641(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _TRANSFER132(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB641(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD348(amount);
        emit TRANSFER113(sender, recipient, amount);
    }
    function _MINT225(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD348(amount);
        _balances[account] = _balances[account].ADD348(amount);
        emit TRANSFER113(address(0), account, amount);
    }
    function _BURN186(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].SUB641(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB641(amount);
        emit TRANSFER113(account, address(0), amount);
    }
    function _APPROVE48(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL275(owner, spender, amount);
    }
    function _BURNFROM442(address account, uint256 amount) internal {
        _BURN186(account, amount);
        _APPROVE48(account, _MSGSENDER204(), _allowances[account][_MSGSENDER204()].SUB641(amount, "ERC20: burn amount exceeds allowance"));
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
    function NAME591() public view returns (string memory) {
        return _name;
    }
    function SYMBOL151() public view returns (string memory) {
        return _symbol;
    }
    function DECIMALS443() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function ADD348(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function SUB641(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB641(a, b, "SafeMath: subtraction overflow");
    }
    function SUB641(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function MUL714(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function DIV963(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV963(a, b, "SafeMath: division by zero");
    }
    function DIV963(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function MOD537(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD537(a, b, "SafeMath: modulo by zero");
    }
    function MOD537(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function ISCONTRACT792(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function TOPAYABLE613(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function SENDVALUE471(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER595(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN929(token, abi.encodeWithSelector(token.TRANSFER590.selector, to, value));
    }

    function SAFETRANSFERFROM895(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN929(token, abi.encodeWithSelector(token.TRANSFERFROM946.selector, from, to, value));
    }

    function SAFEAPPROVE173(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.ALLOWANCE439(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN929(token, abi.encodeWithSelector(token.APPROVE165.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE700(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE439(address(this), spender).ADD348(value);
        CALLOPTIONALRETURN929(token, abi.encodeWithSelector(token.APPROVE165.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE390(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE439(address(this), spender).SUB641(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN929(token, abi.encodeWithSelector(token.APPROVE165.selector, spender, newAllowance));
    }
    function CALLOPTIONALRETURN929(IERC20 token, bytes memory data) private {
        require(address(token).ISCONTRACT792(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Controller {
    function WITHDRAW362(address, uint) external;
    function BALANCEOF856(address) external view returns (uint);
    function EARN394(address, uint) external;
    function WANT709(address) external view returns (address);
}

interface Aave {
    function BORROW427(address _reserve, uint _amount, uint _interestRateModel, uint16 _referralCode) external;
    function SETUSERUSERESERVEASCOLLATERAL395(address _reserve, bool _useAsCollateral) external;
    function REPAY171(address _reserve, uint _amount, address payable _onBehalfOf) external payable;
    function GETUSERACCOUNTDATA396(address _user)
        external
        view
        returns (
            uint totalLiquidityETH,
            uint totalCollateralETH,
            uint totalBorrowsETH,
            uint totalFeesETH,
            uint availableBorrowsETH,
            uint currentLiquidationThreshold,
            uint ltv,
            uint healthFactor
        );
    function GETUSERRESERVEDATA201(address _reserve, address _user)
        external
        view
        returns (
            uint currentATokenBalance,
            uint currentBorrowBalance,
            uint principalBorrowBalance,
            uint borrowRateMode,
            uint borrowRate,
            uint liquidityRate,
            uint originationFee,
            uint variableBorrowIndex,
            uint lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );
}

interface AaveToken {
    function UNDERLYINGASSETADDRESS967() external view returns (address);
}

interface Oracle {
    function GETASSETPRICE895(address reserve) external view returns (uint);
    function LATESTANSWER820() external view returns (uint);
}

interface LendingPoolAddressesProvider {
    function GETLENDINGPOOL689() external view returns (address);
    function GETLENDINGPOOLCORE785() external view returns (address);
    function GETPRICEORACLE709() external view returns (address);
}

contract yDelegatedVault is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    address public governance;
    address public controller;
    uint public insurance;
    uint public healthFactor = 4;

    address public constant aave533 = address(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    constructor (address _token, address _controller) public ERC20Detailed(
        string(abi.encodePacked("yearn ", ERC20Detailed(_token).NAME591())),
        string(abi.encodePacked("y", ERC20Detailed(_token).SYMBOL151())),
        ERC20Detailed(_token).DECIMALS443()
    ) {
        token = IERC20(_token);
        governance = msg.sender;
        controller = _controller;
    }

    function DEBT414() public view returns (uint) {
        address _reserve = Controller(controller).WANT709(address(this));
        (,uint currentBorrowBalance,,,,,,,,) = Aave(GETAAVE93()).GETUSERRESERVEDATA201(_reserve, address(this));
        return currentBorrowBalance;
    }

    function CREDIT327() public view returns (uint) {
        return Controller(controller).BALANCEOF856(address(this));
    }



    function LOCKED694() public view returns (uint) {
        return CREDIT327().MUL714(1e18).DIV963(DEBT414());
    }

    function DEBTSHARE933(address _lp) public view returns (uint) {
        return DEBT414().MUL714(BALANCEOF856(_lp)).MUL714(TOTALSUPPLY668());
    }

    function GETAAVE93() public view returns (address) {
        return LendingPoolAddressesProvider(aave533).GETLENDINGPOOL689();
    }

    function GETAAVECORE229() public view returns (address) {
        return LendingPoolAddressesProvider(aave533).GETLENDINGPOOLCORE785();
    }

    function SETHEALTHFACTOR690(uint _hf) external {
        require(msg.sender == governance, "!governance");
        healthFactor = _hf;
    }

    function ACTIVATE169() public {
        Aave(GETAAVE93()).SETUSERUSERESERVEASCOLLATERAL395(UNDERLYING289(), true);
    }

    function REPAY171(address reserve, uint amount) public  {

        IERC20(reserve).APPROVE165(address(GETAAVECORE229()), 0);
        IERC20(reserve).APPROVE165(address(GETAAVECORE229()), amount);
        Aave(GETAAVE93()).REPAY171(reserve, amount, address(uint160(address(this))));
    }

    function REPAYALL522() public {
        address _reserve = RESERVE164();
        uint _amount = IERC20(_reserve).BALANCEOF856(address(this));
        REPAY171(_reserve, _amount);
    }


    function HARVEST865(address reserve, uint amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).SAFETRANSFER595(controller, amount);
    }


    function BALANCE541() public view returns (uint) {
        return token.BALANCEOF856(address(this)).SUB641(insurance);
    }

    function SETCONTROLLER494(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function GETAAVEORACLE538() public view returns (address) {
        return LendingPoolAddressesProvider(aave533).GETPRICEORACLE709();
    }

    function GETRESERVEPRICEETH945(address reserve) public view returns (uint) {
        return Oracle(GETAAVEORACLE538()).GETASSETPRICE895(reserve);
    }

    function SHOULDREBALANCE804() external view returns (bool) {
        return (OVER549() > 0);
    }

    function OVER549() public view returns (uint) {
        OVER549(0);
    }

    function GETUNDERLYINGPRICEETH537(uint _amount) public view returns (uint) {
        return _amount.MUL714(GETUNDERLYINGPRICE909()).DIV963(uint(10)**ERC20Detailed(address(token)).DECIMALS443());
    }

    function OVER549(uint _amount) public view returns (uint) {
        address _reserve = RESERVE164();
        uint _eth = GETUNDERLYINGPRICEETH537(_amount);
        (uint _maxSafeETH,uint _totalBorrowsETH,) = MAXSAFEETH837();
        _maxSafeETH = _maxSafeETH.MUL714(105).DIV963(100);
        if (_eth > _maxSafeETH) {
            _maxSafeETH = 0;
        } else {
            _maxSafeETH = _maxSafeETH.SUB641(_eth);
        }
        if (_maxSafeETH < _totalBorrowsETH) {
            uint _over = _totalBorrowsETH.MUL714(_totalBorrowsETH.SUB641(_maxSafeETH)).DIV963(_totalBorrowsETH);
            _over = _over.MUL714(uint(10)**ERC20Detailed(_reserve).DECIMALS443()).DIV963(GETRESERVEPRICE515());
            return _over;
        } else {
            return 0;
        }
    }

    function _REBALANCE677(uint _amount) internal {
        uint _over = OVER549(_amount);
        if (_over > 0) {
            Controller(controller).WITHDRAW362(address(this), _over);
            REPAYALL522();
        }
    }

    function REBALANCE176() external {
        _REBALANCE677(0);
    }

    function CLAIMINSURANCE254() external {
        require(msg.sender == controller, "!controller");
        token.SAFETRANSFER595(controller, insurance);
        insurance = 0;
    }

    function MAXSAFEETH837() public view returns (uint maxBorrowsETH, uint totalBorrowsETH, uint availableBorrowsETH) {
         (,,uint _totalBorrowsETH,,uint _availableBorrowsETH,,,) = Aave(GETAAVE93()).GETUSERACCOUNTDATA396(address(this));
        uint _maxBorrowETH = (_totalBorrowsETH.ADD348(_availableBorrowsETH));
        return (_maxBorrowETH.DIV963(healthFactor), _totalBorrowsETH, _availableBorrowsETH);
    }

    function SHOULDBORROW22() external view returns (bool) {
        return (AVAILABLETOBORROWRESERVE235() > 0);
    }

    function AVAILABLETOBORROWETH693() public view returns (uint) {
        (uint _maxSafeETH,uint _totalBorrowsETH, uint _availableBorrowsETH) = MAXSAFEETH837();
        _maxSafeETH = _maxSafeETH.MUL714(95).DIV963(100);
        if (_maxSafeETH > _totalBorrowsETH) {
            return _availableBorrowsETH.MUL714(_maxSafeETH.SUB641(_totalBorrowsETH)).DIV963(_availableBorrowsETH);
        } else {
            return 0;
        }
    }

    function AVAILABLETOBORROWRESERVE235() public view returns (uint) {
        address _reserve = RESERVE164();
        uint _available = AVAILABLETOBORROWETH693();
        if (_available > 0) {
            return _available.MUL714(uint(10)**ERC20Detailed(_reserve).DECIMALS443()).DIV963(GETRESERVEPRICE515());
        } else {
            return 0;
        }
    }

    function GETRESERVEPRICE515() public view returns (uint) {
        return GETRESERVEPRICEETH945(RESERVE164());
    }

    function GETUNDERLYINGPRICE909() public view returns (uint) {
        return GETRESERVEPRICEETH945(UNDERLYING289());
    }

    function EARN394() external {
        address _reserve = RESERVE164();
        uint _borrow = AVAILABLETOBORROWRESERVE235();
        if (_borrow > 0) {
            Aave(GETAAVE93()).BORROW427(_reserve, _borrow, 2, 7);
        }

        uint _balance = IERC20(_reserve).BALANCEOF856(address(this));
        if (_balance > 0) {
            IERC20(_reserve).SAFETRANSFER595(controller, _balance);
            Controller(controller).EARN394(address(this), _balance);
        }
    }

    function DEPOSITALL399() external {
        DEPOSIT764(token.BALANCEOF856(msg.sender));
    }

    function DEPOSIT764(uint _amount) public {
        uint _pool = BALANCE541();
        token.SAFETRANSFERFROM895(msg.sender, address(this), _amount);



        uint _insurance = _amount.MUL714(50).DIV963(10000);
        _amount = _amount.SUB641(_insurance);
        insurance = insurance.ADD348(_insurance);




        uint shares = 0;
        if (TOTALSUPPLY668() == 0) {
            shares = _amount;
            ACTIVATE169();
        } else {
            shares = (_amount.MUL714(TOTALSUPPLY668())).DIV963(_pool);
        }
        _MINT225(msg.sender, shares);
    }

    function RESERVE164() public view returns (address) {
        return Controller(controller).WANT709(address(this));
    }

    function UNDERLYING289() public view returns (address) {
        return AaveToken(address(token)).UNDERLYINGASSETADDRESS967();
    }

    function WITHDRAWALL686() public {
        WITHDRAW362(BALANCEOF856(msg.sender));
    }


    function MAXWITHDRAWAL697(address account) public view returns (uint) {
        uint _balance = BALANCEOF856(account);
        uint _safeWithdraw = _balance.MUL714(LOCKED694()).DIV963(1e18);
        if (_safeWithdraw > _balance) {
            return _balance;
        } else {
            uint _diff = _balance.SUB641(_safeWithdraw);
            return _balance.SUB641(_diff.MUL714(2));
        }
    }

    function SAFEWITHDRAW954() external {
        WITHDRAW362(MAXWITHDRAWAL697(msg.sender));
    }


    function WITHDRAW362(uint _shares) public {
        uint r = (BALANCE541().MUL714(_shares)).DIV963(TOTALSUPPLY668());
        _BURN186(msg.sender, _shares);
        _REBALANCE677(r);
        token.SAFETRANSFER595(msg.sender, r);

    }

    function GETPRICEPERFULLSHARE836() external view returns (uint) {
        return BALANCE541().MUL714(1e18).DIV963(TOTALSUPPLY668());
    }
}
