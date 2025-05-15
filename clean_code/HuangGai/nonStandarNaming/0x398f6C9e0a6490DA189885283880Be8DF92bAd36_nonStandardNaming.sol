



pragma solidity ^0.6.2;




interface IERC20 {

    function TOTALSUPPLY709() external view returns (uint256);


    function BALANCEOF1000(address account) external view returns (uint256);


    function TRANSFER912(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE643(address owner, address spender) external view returns (uint256);


    function APPROVE378(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM696(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER249(address indexed from, address indexed to, uint256 value);


    event APPROVAL928(address indexed owner, address indexed spender, uint256 value);
}



abstract contract Context {
    function _MSGSENDER905() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA980() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED618(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER905();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED618(address(0), msgSender);
    }


    function OWNER941() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER378() {
        require(_owner == _MSGSENDER905(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP149() public virtual ONLYOWNER378 {
        emit OWNERSHIPTRANSFERRED618(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP687(address newOwner) public virtual ONLYOWNER378 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED618(_owner, newOwner);
        _owner = newOwner;
    }
}



library SafeMath {

    function ADD236(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB786(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB786(a, b, "SafeMath: subtraction overflow");
    }


    function SUB786(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL747(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV140(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV140(a, b, "SafeMath: division by zero");
    }


    function DIV140(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD599(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD599(a, b, "SafeMath: modulo by zero");
    }


    function MOD599(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library Address {

    function ISCONTRACT863(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function SENDVALUE275(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL887(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL887(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL887(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE192(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE672(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE672(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE672(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE192(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE192(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT863(target), "Address: call to non-contract");


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



contract ReentrancyGuard {











    uint256 private constant _not_entered586 = 1;
    uint256 private constant _entered769 = 2;

    uint256 private _status;

    constructor () internal {
        _status = _not_entered586;
    }


    modifier NONREENTRANT44() {

        require(_status != _entered769, "ReentrancyGuard: reentrant call");


        _status = _entered769;

        _;



        _status = _not_entered586;
    }
}



library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER115(IERC20 token, address to, uint256 value) internal {
        _CALLOPTIONALRETURN516(token, abi.encodeWithSelector(token.TRANSFER912.selector, to, value));
    }

    function SAFETRANSFERFROM287(IERC20 token, address from, address to, uint256 value) internal {
        _CALLOPTIONALRETURN516(token, abi.encodeWithSelector(token.TRANSFERFROM696.selector, from, to, value));
    }


    function SAFEAPPROVE190(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE643(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _CALLOPTIONALRETURN516(token, abi.encodeWithSelector(token.APPROVE378.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE374(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE643(address(this), spender).ADD236(value);
        _CALLOPTIONALRETURN516(token, abi.encodeWithSelector(token.APPROVE378.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE80(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE643(address(this), spender).SUB786(value, "SafeERC20: decreased allowance below zero");
        _CALLOPTIONALRETURN516(token, abi.encodeWithSelector(token.APPROVE378.selector, spender, newAllowance));
    }


    function _CALLOPTIONALRETURN516(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).FUNCTIONCALL887(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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


    function NAME654() public view returns (string memory) {
        return _name;
    }


    function SYMBOL381() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS442() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY709() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF1000(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER912(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER205(_MSGSENDER905(), recipient, amount);
        return true;
    }


    function ALLOWANCE643(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE378(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE516(_MSGSENDER905(), spender, amount);
        return true;
    }


    function TRANSFERFROM696(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER205(sender, recipient, amount);
        _APPROVE516(sender, _MSGSENDER905(), _allowances[sender][_MSGSENDER905()].SUB786(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE9(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE516(_MSGSENDER905(), spender, _allowances[_MSGSENDER905()][spender].ADD236(addedValue));
        return true;
    }


    function DECREASEALLOWANCE999(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE516(_MSGSENDER905(), spender, _allowances[_MSGSENDER905()][spender].SUB786(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER205(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER183(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB786(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD236(amount);
        emit TRANSFER249(sender, recipient, amount);
    }


    function _MINT985(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER183(address(0), account, amount);

        _totalSupply = _totalSupply.ADD236(amount);
        _balances[account] = _balances[account].ADD236(amount);
        emit TRANSFER249(address(0), account, amount);
    }


    function _BURN126(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER183(account, address(0), amount);

        _balances[account] = _balances[account].SUB786(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB786(amount);
        emit TRANSFER249(account, address(0), amount);
    }


    function _APPROVE516(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL928(owner, spender, amount);
    }


    function _SETUPDECIMALS502(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER183(address from, address to, uint256 amount) internal virtual { }
}


contract YieldDelegatingVaultEvent2 {

    event NEWTREASURY741(address oldTreasury, address newTreasury);


    event NEWDELEGATEPERCENT315(uint256 oldDelegatePercent, uint256 newDelegatePercent);


    event NEWREWARDPERTOKEN257(uint256 oldRewardPerToken, uint256 newRewardPerToken);
}



library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }


    function _ADD330(Set storage set, bytes32 value) private returns (bool) {
        if (!_CONTAINS441(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }


    function _REMOVE267(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }


    function _CONTAINS441(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }


    function _LENGTH266(Set storage set) private view returns (uint256) {
        return set._values.length;
    }


    function _AT20(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }


    function ADD236(AddressSet storage set, address value) internal returns (bool) {
        return _ADD330(set._inner, bytes32(uint256(value)));
    }


    function REMOVE884(AddressSet storage set, address value) internal returns (bool) {
        return _REMOVE267(set._inner, bytes32(uint256(value)));
    }


    function CONTAINS556(AddressSet storage set, address value) internal view returns (bool) {
        return _CONTAINS441(set._inner, bytes32(uint256(value)));
    }


    function LENGTH118(AddressSet storage set) internal view returns (uint256) {
        return _LENGTH266(set._inner);
    }


    function AT34(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_AT20(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }


    function ADD236(UintSet storage set, uint256 value) internal returns (bool) {
        return _ADD330(set._inner, bytes32(value));
    }


    function REMOVE884(UintSet storage set, uint256 value) internal returns (bool) {
        return _REMOVE267(set._inner, bytes32(value));
    }


    function CONTAINS556(UintSet storage set, uint256 value) internal view returns (bool) {
        return _CONTAINS441(set._inner, bytes32(value));
    }


    function LENGTH118(UintSet storage set) internal view returns (uint256) {
        return _LENGTH266(set._inner);
    }


    function AT34(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_AT20(set._inner, index));
    }
}



abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant default_admin_role567 = 0x00;


    event ROLEADMINCHANGED88(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);


    event ROLEGRANTED826(bytes32 indexed role, address indexed account, address indexed sender);


    event ROLEREVOKED185(bytes32 indexed role, address indexed account, address indexed sender);


    function HASROLE367(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.CONTAINS556(account);
    }


    function GETROLEMEMBERCOUNT938(bytes32 role) public view returns (uint256) {
        return _roles[role].members.LENGTH118();
    }


    function GETROLEMEMBER19(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.AT34(index);
    }


    function GETROLEADMIN235(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }


    function GRANTROLE137(bytes32 role, address account) public virtual {
        require(HASROLE367(_roles[role].adminRole, _MSGSENDER905()), "AccessControl: sender must be an admin to grant");

        _GRANTROLE954(role, account);
    }


    function REVOKEROLE670(bytes32 role, address account) public virtual {
        require(HASROLE367(_roles[role].adminRole, _MSGSENDER905()), "AccessControl: sender must be an admin to revoke");

        _REVOKEROLE460(role, account);
    }


    function RENOUNCEROLE777(bytes32 role, address account) public virtual {
        require(account == _MSGSENDER905(), "AccessControl: can only renounce roles for self");

        _REVOKEROLE460(role, account);
    }


    function _SETUPROLE461(bytes32 role, address account) internal virtual {
        _GRANTROLE954(role, account);
    }


    function _SETROLEADMIN512(bytes32 role, bytes32 adminRole) internal virtual {
        emit ROLEADMINCHANGED88(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _GRANTROLE954(bytes32 role, address account) private {
        if (_roles[role].members.ADD236(account)) {
            emit ROLEGRANTED826(role, account, _MSGSENDER905());
        }
    }

    function _REVOKEROLE460(bytes32 role, address account) private {
        if (_roles[role].members.REMOVE884(account)) {
            emit ROLEREVOKED185(role, account, _MSGSENDER905());
        }
    }
}


contract YDVRewardsDistributor is AccessControl, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public rewardToken;
    address[] public ydvs;
    bytes32 public constant ydv_rewards665 = keccak256("YDV_REWARDS");

    constructor(address _rally) public {
        rewardToken = IERC20(_rally);
        _SETUPROLE461(default_admin_role567, msg.sender);
    }

    function TRANSFERREWARD486(uint256 _amount) external {
        require (HASROLE367(ydv_rewards665, msg.sender), "only ydv rewards");
        rewardToken.SAFETRANSFER115(msg.sender, _amount);
    }

    function ADDYDV918(address _ydv) external ONLYOWNER378 {
        GRANTROLE137(ydv_rewards665, _ydv);
        ydvs.push(_ydv);
    }

    function YDVSLENGTH403() external view returns (uint256) {
        return ydvs.length;
    }
}


interface Vault {
    function BALANCEOF1000(address) external view returns (uint256);
    function TOKEN783() external view returns (address);
    function CLAIMINSURANCE535() external;
    function GETPRICEPERFULLSHARE194() external view returns (uint256);
    function DEPOSIT941(uint) external;
    function WITHDRAW419(uint) external;
}


contract YDVErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        REJECTION
    }

    enum FailureInfo {
        SET_INDIVIDUAL_SOFT_CAP_CHECK,
        SET_GLOBAL_SOFT_CAP_CHECK
    }


    event FAILURE308(uint error, uint info, uint detail);


    function FAIL273(Error err, FailureInfo info) internal returns (uint) {
        emit FAILURE308(uint(err), uint(info), 0);

        return uint(err);
    }


    function FAILOPAQUE544(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit FAILURE308(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}


contract RallyToken is ERC20 {


    uint256 public constant token_supply159 = 15 * 10**9 * 10**18;

    constructor (
        address _escrow
    ) public ERC20(
	"Rally",
	"RLY"
    ) {
        _MINT985(_escrow, token_supply159);
    }
}


contract NoMintLiquidityRewardPools is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;











    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRallyPerShare;
    }


    RallyToken public rally;

    uint256 public rallyPerBlock;


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    event DEPOSIT927(address indexed user, uint256 indexed pid, uint256 amount);
    event WITHDRAW385(address indexed user, uint256 indexed pid, uint256 amount);
    event EMERGENCYWITHDRAW903(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        RallyToken _rally,
        uint256 _rallyPerBlock,
        uint256 _startBlock
    ) public {
        rally = _rally;
        rallyPerBlock = _rallyPerBlock;
        startBlock = _startBlock;
    }

    function POOLLENGTH610() external view returns (uint256) {
        return poolInfo.length;
    }



    function ADD236(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public ONLYOWNER378 {
        if (_withUpdate) {
            MASSUPDATEPOOLS681();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.ADD236(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRallyPerShare: 0
        }));
    }


    function SET138(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public ONLYOWNER378 {
        if (_withUpdate) {
            MASSUPDATEPOOLS681();
        }
        totalAllocPoint = totalAllocPoint.SUB786(poolInfo[_pid].allocPoint).ADD236(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function SETRALLYPERBLOCK200(uint256 _rallyPerBlock) public ONLYOWNER378 {
        MASSUPDATEPOOLS681();
        rallyPerBlock = _rallyPerBlock;
    }


    function PENDINGRALLY232(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRallyPerShare = pool.accRallyPerShare;
        uint256 lpSupply = pool.lpToken.BALANCEOF1000(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number.SUB786(pool.lastRewardBlock);
            uint256 rallyReward = multiplier.MUL747(rallyPerBlock).MUL747(pool.allocPoint).DIV140(totalAllocPoint);
            accRallyPerShare = accRallyPerShare.ADD236(rallyReward.MUL747(1e12).DIV140(lpSupply));
        }
        return user.amount.MUL747(accRallyPerShare).DIV140(1e12).SUB786(user.rewardDebt);
    }


    function MASSUPDATEPOOLS681() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            UPDATEPOOL112(pid);
        }
    }



    function UPDATEPOOL112(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.BALANCEOF1000(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.SUB786(pool.lastRewardBlock);
        uint256 rallyReward = multiplier.MUL747(rallyPerBlock).MUL747(pool.allocPoint).DIV140(totalAllocPoint);
        pool.accRallyPerShare = pool.accRallyPerShare.ADD236(rallyReward.MUL747(1e12).DIV140(lpSupply));
        pool.lastRewardBlock = block.number;
    }


    function DEPOSIT941(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UPDATEPOOL112(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.MUL747(pool.accRallyPerShare).DIV140(1e12).SUB786(user.rewardDebt);
            if(pending > 0) {
                SAFERALLYTRANSFER520(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.SAFETRANSFERFROM287(address(msg.sender), address(this), _amount);
            user.amount = user.amount.ADD236(_amount);
        }
        user.rewardDebt = user.amount.MUL747(pool.accRallyPerShare).DIV140(1e12);
        emit DEPOSIT927(msg.sender, _pid, _amount);
    }


    function WITHDRAW419(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        UPDATEPOOL112(_pid);
        uint256 pending = user.amount.MUL747(pool.accRallyPerShare).DIV140(1e12).SUB786(user.rewardDebt);
        if(pending > 0) {
            SAFERALLYTRANSFER520(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.SUB786(_amount);
            pool.lpToken.SAFETRANSFER115(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.MUL747(pool.accRallyPerShare).DIV140(1e12);
        emit WITHDRAW385(msg.sender, _pid, _amount);
    }


    function EMERGENCYWITHDRAW757(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.SAFETRANSFER115(address(msg.sender), user.amount);
        emit EMERGENCYWITHDRAW903(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    function SAFERALLYTRANSFER520(address _to, uint256 _amount) internal {
        uint256 rallyBal = rally.BALANCEOF1000(address(this));
        if (_amount > rallyBal) {
            rally.TRANSFER912(_to, rallyBal);
        } else {
            rally.TRANSFER912(_to, _amount);
        }
    }
}


contract YieldDelegatingVaultStorage2 {
    address public vault;
    YDVRewardsDistributor rewards;
    IERC20 public rally;
    address public treasury;
    IERC20 public token;
    uint256 public delegatePercent;

    mapping(address => uint256) public rewardDebt;
    uint256 public totalDeposits;

    uint256 public rewardPerToken;
    uint256 public accRallyPerShare;

    bool public lrEnabled;
    uint256 public pid;
    NoMintLiquidityRewardPools lrPools;
}


contract YieldDelegatingVault2 is ERC20, YieldDelegatingVaultStorage2, YieldDelegatingVaultEvent2, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor (
        address _vault,
        address _rewards,
        address _treasury,
        uint256 _delegatePercent,
        uint256 _rewardPerToken
    ) public ERC20(
        string(abi.encodePacked("rally delegating ", ERC20(Vault(_vault).TOKEN783()).NAME654())),
        string(abi.encodePacked("rd", ERC20(Vault(_vault).TOKEN783()).SYMBOL381()))
    ) {
        _SETUPDECIMALS502(ERC20(Vault(_vault).TOKEN783()).DECIMALS442());
        token = IERC20(Vault(_vault).TOKEN783());
        vault = _vault;
        rewards = YDVRewardsDistributor(_rewards);
        rally = rewards.rewardToken();
	treasury = _treasury;
        delegatePercent = _delegatePercent;
        rewardPerToken = _rewardPerToken;
	totalDeposits = 0;
        accRallyPerShare = 0;
        lrEnabled = false;
    }

    function SETTREASURY672(address newTreasury) public ONLYOWNER378 {
        require(newTreasury != address(0), "treasure should be valid address");

        address oldTreasury = treasury;
        treasury = newTreasury;

        emit NEWTREASURY741(oldTreasury, newTreasury);
    }

    function SETNEWREWARDPERTOKEN724(uint256 newRewardPerToken) public ONLYOWNER378 {
        uint256 oldRewardPerToken = rewardPerToken;
        rewardPerToken = newRewardPerToken;

        emit NEWREWARDPERTOKEN257(oldRewardPerToken, newRewardPerToken);
    }

    function EARNED974(address account) public view returns (uint256) {
        return BALANCEFORREWARDSCALC156(account).MUL747(accRallyPerShare).DIV140(1e12).SUB786(rewardDebt[account]);
    }

    function BALANCE265() public view returns (uint256) {
        return (IERC20(vault)).BALANCEOF1000(address(this));
    }




    function BALANCEFORREWARDSCALC156(address account) internal view returns (uint256) {
        if (lrEnabled) {
          (uint256 amount, ) = lrPools.userInfo(pid, account);
          return BALANCEOF1000(account).ADD236(amount);
        }
        return BALANCEOF1000(account);
    }

    function DEPOSITALL490() external {
        DEPOSIT941(token.BALANCEOF1000(msg.sender));
    }

    function DEPOSIT941(uint256 _amount) public NONREENTRANT44 {
        uint256 pending = EARNED974(msg.sender);
        if (pending > 0) {
            SAFERALLYTRANSFER520(msg.sender, pending);
        }
        uint256 _pool = BALANCE265();

        uint256 _before = token.BALANCEOF1000(address(this));
        token.SAFETRANSFERFROM287(msg.sender, address(this), _amount);
        uint256 _after = token.BALANCEOF1000(address(this));
        _amount = _after.SUB786(_before);

        totalDeposits = totalDeposits.ADD236(_amount);

        token.APPROVE378(vault, _amount);
        Vault(vault).DEPOSIT941(_amount);
        uint256 _after_pool = BALANCE265();

        uint256 _new_shares = _after_pool.SUB786(_pool);


        uint256 shares = 0;
        if (TOTALSUPPLY709() == 0) {
            shares = _new_shares;
        } else {
            shares = (_new_shares.MUL747(TOTALSUPPLY709())).DIV140(_pool);
        }
        _MINT985(msg.sender, shares);
        rewardDebt[msg.sender] = BALANCEFORREWARDSCALC156(msg.sender).MUL747(accRallyPerShare).DIV140(1e12);
    }

    function DEPOSITYTOKEN556(uint256 _yamount) public NONREENTRANT44 {
        uint256 pending = EARNED974(msg.sender);
        if (pending > 0) {
            SAFERALLYTRANSFER520(msg.sender, pending);
        }

        uint256 _before = IERC20(vault).BALANCEOF1000(address(this));
        IERC20(vault).SAFETRANSFERFROM287(msg.sender, address(this), _yamount);
        uint256 _after = IERC20(vault).BALANCEOF1000(address(this));
        _yamount = _after.SUB786(_before);

        uint _underlyingAmount = _yamount.MUL747(Vault(vault).GETPRICEPERFULLSHARE194()).DIV140(1e18);
        totalDeposits = totalDeposits.ADD236(_underlyingAmount);


        uint256 shares = 0;
        if (TOTALSUPPLY709() == 0) {
            shares = _yamount;
        } else {
            shares = (_yamount.MUL747(TOTALSUPPLY709())).DIV140(_before);
        }
        _MINT985(msg.sender, shares);
        rewardDebt[msg.sender] = BALANCEFORREWARDSCALC156(msg.sender).MUL747(accRallyPerShare).DIV140(1e12);
    }

    function WITHDRAWALL908() external {
        WITHDRAW419(BALANCEOF1000(msg.sender));
    }

    function WITHDRAW419(uint256 _shares) public NONREENTRANT44 {
        uint256 pending = EARNED974(msg.sender);
        if (pending > 0) {
            SAFERALLYTRANSFER520(msg.sender, pending);
        }

        uint256 r = (BALANCE265().MUL747(_shares)).DIV140(TOTALSUPPLY709());
        _BURN126(msg.sender, _shares);
        SAFEREDUCETOTALDEPOSITS144(r.MUL747(Vault(vault).GETPRICEPERFULLSHARE194()).DIV140(1e18));

        rewardDebt[msg.sender] = BALANCEFORREWARDSCALC156(msg.sender).MUL747(accRallyPerShare).DIV140(1e12);

        uint256 _before = token.BALANCEOF1000(address(this));
        Vault(vault).WITHDRAW419(r);
        uint256 _after = token.BALANCEOF1000(address(this));

        uint256 toTransfer = _after.SUB786(_before);
        token.SAFETRANSFER115(msg.sender, toTransfer);
    }


    function SAFEREDUCETOTALDEPOSITS144(uint256 _amount) internal {
        if (_amount > totalDeposits) {
          totalDeposits = 0;
        } else {
          totalDeposits = totalDeposits.SUB786(_amount);
        }
    }

    function WITHDRAWYTOKEN466(uint256 _shares) public NONREENTRANT44 {
        uint256 pending = EARNED974(msg.sender);
        if (pending > 0) {
            SAFERALLYTRANSFER520(msg.sender, pending);
        }
        uint256 r = (BALANCE265().MUL747(_shares)).DIV140(TOTALSUPPLY709());
        _BURN126(msg.sender, _shares);
        rewardDebt[msg.sender] = BALANCEFORREWARDSCALC156(msg.sender).MUL747(accRallyPerShare).DIV140(1e12);
        uint256 _amount = r.MUL747(Vault(vault).GETPRICEPERFULLSHARE194()).DIV140(1e18);

        SAFEREDUCETOTALDEPOSITS144(_amount);

        IERC20(vault).SAFETRANSFER115(msg.sender, r);
    }


    function SAFERALLYTRANSFER520(address _to, uint256 _amount) internal {
        uint256 rallyBal = rally.BALANCEOF1000(address(this));
        if (_amount > rallyBal) {
            rally.TRANSFER912(_to, rallyBal);
        } else {
            rally.TRANSFER912(_to, _amount);
        }
    }


    function AVAILABLEYIELD882() public view returns (uint256) {
        uint256 totalValue = BALANCE265().MUL747(Vault(vault).GETPRICEPERFULLSHARE194()).DIV140(1e18);
        if (totalValue > totalDeposits) {
            uint256 earnings = totalValue.SUB786(totalDeposits);
            return earnings.MUL747(1e18).DIV140(Vault(vault).GETPRICEPERFULLSHARE194());
        }
        return 0;
    }




    function HARVEST82() public ONLYOWNER378 {
        uint256 _availableYield = AVAILABLEYIELD882();
        if (_availableYield > 0) {
            uint256 rallyReward = _availableYield.MUL747(delegatePercent).DIV140(10000).MUL747(rewardPerToken).DIV140(1e18);
            rewards.TRANSFERREWARD486(rallyReward);
            IERC20(vault).SAFETRANSFER115(treasury, _availableYield.MUL747(delegatePercent).DIV140(10000));
            accRallyPerShare = accRallyPerShare.ADD236(rallyReward.MUL747(1e12).DIV140(TOTALSUPPLY709()));
            totalDeposits = BALANCE265().MUL747(Vault(vault).GETPRICEPERFULLSHARE194()).DIV140(1e18);
        }
    }


    function ENABLELIQUIDITYREWARDS505(address _lrPools, uint256 _pid) public ONLYOWNER378 {
      (IERC20 lpToken,,,) =  NoMintLiquidityRewardPools(_lrPools).poolInfo(_pid);
      require(address(lpToken) == address(this), "invalid liquidity rewards setup");
      require(lrEnabled == false, "liquidity rewards already enabled");
      lrEnabled = true;
      lrPools = NoMintLiquidityRewardPools(_lrPools);
      pid = _pid;
    }


    function _TRANSFER205(address sender, address recipient, uint256 amount) internal override {
      require(lrEnabled, "transfer rejected");
      require(sender == address(lrPools) || recipient == address(lrPools), "transfer rejected");
      super._TRANSFER205(sender, recipient, amount);
    }
}
