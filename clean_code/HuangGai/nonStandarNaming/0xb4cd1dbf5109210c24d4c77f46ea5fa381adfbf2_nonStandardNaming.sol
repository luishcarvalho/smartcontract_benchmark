



pragma solidity ^0.6.12;

abstract contract Context {
    function _MSGSENDER292() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA848() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


interface IERC20 {

    function TOTALSUPPLY965() external view returns (uint256);


    function BALANCEOF795(address account) external view returns (uint256);


    function TRANSFER536(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE225(address owner, address spender) external view returns (uint256);


    function APPROVE133(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM756(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER325(address indexed from, address indexed to, uint256 value);


    event APPROVAL100(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function ADD676(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB200(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB200(a, b, "SafeMath: subtraction overflow");
    }


    function SUB200(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL199(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV336(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV336(a, b, "SafeMath: division by zero");
    }


    function DIV336(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD258(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD258(a, b, "SafeMath: modulo by zero");
    }


    function MOD258(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library Address {

    function ISCONTRACT4(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function SENDVALUE907(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL885(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL885(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL885(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE995(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE204(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE204(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE204(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE995(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE995(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT4(target), "Address: call to non-contract");


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


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER58(IERC20 token, address to, uint256 value) internal {
        _CALLOPTIONALRETURN724(token, abi.encodeWithSelector(token.TRANSFER536.selector, to, value));
    }

    function SAFETRANSFERFROM571(IERC20 token, address from, address to, uint256 value) internal {
        _CALLOPTIONALRETURN724(token, abi.encodeWithSelector(token.TRANSFERFROM756.selector, from, to, value));
    }


    function SAFEAPPROVE498(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE225(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _CALLOPTIONALRETURN724(token, abi.encodeWithSelector(token.APPROVE133.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE127(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE225(address(this), spender).ADD676(value);
        _CALLOPTIONALRETURN724(token, abi.encodeWithSelector(token.APPROVE133.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE22(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE225(address(this), spender).SUB200(value, "SafeERC20: decreased allowance below zero");
        _CALLOPTIONALRETURN724(token, abi.encodeWithSelector(token.APPROVE133.selector, spender, newAllowance));
    }


    function _CALLOPTIONALRETURN724(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).FUNCTIONCALL885(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED970(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER292();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED970(address(0), msgSender);
    }


    function OWNER239() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER200() {
        require(_owner == _MSGSENDER292(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP850() public virtual ONLYOWNER200 {
        emit OWNERSHIPTRANSFERRED970(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP80(address newOwner) public virtual ONLYOWNER200 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED970(_owner, newOwner);
        _owner = newOwner;
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


    function NAME337() public view returns (string memory) {
        return _name;
    }


    function SYMBOL333() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS747() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY965() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF795(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER536(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER104(_MSGSENDER292(), recipient, amount);
        return true;
    }


    function ALLOWANCE225(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE133(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE753(_MSGSENDER292(), spender, amount);
        return true;
    }


    function TRANSFERFROM756(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER104(sender, recipient, amount);
        _APPROVE753(sender, _MSGSENDER292(), _allowances[sender][_MSGSENDER292()].SUB200(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE697(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE753(_MSGSENDER292(), spender, _allowances[_MSGSENDER292()][spender].ADD676(addedValue));
        return true;
    }


    function DECREASEALLOWANCE977(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE753(_MSGSENDER292(), spender, _allowances[_MSGSENDER292()][spender].SUB200(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER104(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER536(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB200(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD676(amount);
        emit TRANSFER325(sender, recipient, amount);
    }


    function _MINT956(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER536(address(0), account, amount);

        _totalSupply = _totalSupply.ADD676(amount);
        _balances[account] = _balances[account].ADD676(amount);
        emit TRANSFER325(address(0), account, amount);
    }


    function _BURN958(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER536(account, address(0), amount);

        _balances[account] = _balances[account].SUB200(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB200(amount);
        emit TRANSFER325(account, address(0), amount);
    }


    function _APPROVE753(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL100(owner, spender, amount);
    }


    function _SETUPDECIMALS722(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER536(address from, address to, uint256 amount) internal virtual { }
}


contract HuoguoToken is ERC20("HUOGUO.finance", "HUOGUO"), Ownable {

    function MINT320(address _to, uint256 _amount) public ONLYOWNER200 {
        _MINT956(_to, _amount);
    }
}

contract HuoguoChef is Ownable {
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
        uint256 accHuoguoPerShare;
    }


    HuoguoToken public huoguo;

    address public devaddr;

    uint256 public bonusEndBlock;

    uint256 public huoguoPerBlock;

    uint256 public constant bonus_multiplier198 = 1;


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    event DEPOSIT766(address indexed user, uint256 indexed pid, uint256 amount);
    event WITHDRAW854(address indexed user, uint256 indexed pid, uint256 amount);
    event EMERGENCYWITHDRAW584(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        HuoguoToken _huoguo,
        address _devaddr,
        uint256 _huoguoPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        huoguo = _huoguo;
        devaddr = _devaddr;
        huoguoPerBlock = _huoguoPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function POOLLENGTH693() external view returns (uint256) {
        return poolInfo.length;
    }



    function ADD676(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public ONLYOWNER200 {
        if (_withUpdate) {
            MASSUPDATEPOOLS170();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.ADD676(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accHuoguoPerShare: 0
        }));
    }


    function SET574(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public ONLYOWNER200 {
        if (_withUpdate) {
            MASSUPDATEPOOLS170();
        }
        totalAllocPoint = totalAllocPoint.SUB200(poolInfo[_pid].allocPoint).ADD676(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function GETMULTIPLIER700(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.SUB200(_from).MUL199(bonus_multiplier198);
        } else if (_from >= bonusEndBlock) {
            return _to.SUB200(_from);
        } else {
            return bonusEndBlock.SUB200(_from).MUL199(bonus_multiplier198).ADD676(
                _to.SUB200(bonusEndBlock)
            );
        }
    }


    function PENDINGHUOGUO703(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accHuoguoPerShare = pool.accHuoguoPerShare;
        uint256 lpSupply = pool.lpToken.BALANCEOF795(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = GETMULTIPLIER700(pool.lastRewardBlock, block.number);
            uint256 huoguoReward = multiplier.MUL199(huoguoPerBlock).MUL199(pool.allocPoint).DIV336(totalAllocPoint);
            accHuoguoPerShare = accHuoguoPerShare.ADD676(huoguoReward.MUL199(1e12).DIV336(lpSupply));
        }
        return user.amount.MUL199(accHuoguoPerShare).DIV336(1e12).SUB200(user.rewardDebt);
    }


    function MASSUPDATEPOOLS170() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            UPDATEPOOL251(pid);
        }
    }

    function MINT320(uint256 amount) public ONLYOWNER200{
        huoguo.MINT320(devaddr, amount);
    }

    function UPDATEPOOL251(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.BALANCEOF795(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = GETMULTIPLIER700(pool.lastRewardBlock, block.number);
        uint256 huoguoReward = multiplier.MUL199(huoguoPerBlock).MUL199(pool.allocPoint).DIV336(totalAllocPoint);
        huoguo.MINT320(devaddr, huoguoReward.DIV336(20));
        huoguo.MINT320(address(this), huoguoReward);
        pool.accHuoguoPerShare = pool.accHuoguoPerShare.ADD676(huoguoReward.MUL199(1e12).DIV336(lpSupply));
        pool.lastRewardBlock = block.number;
    }


    function DEPOSIT520(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UPDATEPOOL251(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.MUL199(pool.accHuoguoPerShare).DIV336(1e12).SUB200(user.rewardDebt);
            SAFEHUOGUOTRANSFER588(msg.sender, pending);
        }
        pool.lpToken.SAFETRANSFERFROM571(address(msg.sender), address(this), _amount);
        user.amount = user.amount.ADD676(_amount);
        user.rewardDebt = user.amount.MUL199(pool.accHuoguoPerShare).DIV336(1e12);
        emit DEPOSIT766(msg.sender, _pid, _amount);
    }


    function WITHDRAW519(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        UPDATEPOOL251(_pid);
        uint256 pending = user.amount.MUL199(pool.accHuoguoPerShare).DIV336(1e12).SUB200(user.rewardDebt);
        SAFEHUOGUOTRANSFER588(msg.sender, pending);
        user.amount = user.amount.SUB200(_amount);
        user.rewardDebt = user.amount.MUL199(pool.accHuoguoPerShare).DIV336(1e12);
        pool.lpToken.SAFETRANSFER58(address(msg.sender), _amount);
        emit WITHDRAW854(msg.sender, _pid, _amount);
    }


    function EMERGENCYWITHDRAW628(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.SAFETRANSFER58(address(msg.sender), user.amount);
        emit EMERGENCYWITHDRAW584(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    function SAFEHUOGUOTRANSFER588(address _to, uint256 _amount) internal {
        uint256 huoguoBal = huoguo.BALANCEOF795(address(this));
        if (_amount > huoguoBal) {
            huoguo.TRANSFER536(_to, huoguoBal);
        } else {
            huoguo.TRANSFER536(_to, _amount);
        }
    }


    function DEV515(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
