





pragma solidity 0.6.12;















library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


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




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


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











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}













contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}










library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}





interface Stakeable {
    function deposit(uint) external;
    function withdraw(uint) external;
}








contract TokenTimelock {
    using SafeERC20 for IERC20;


    IERC20 private _token;


    address private _beneficiary;


    uint256 private _releaseTime;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime) public {

        require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
    }




    function token() public view returns (IERC20) {
        return _token;
    }




    function beneficiary() public view returns (address) {
        return _beneficiary;
    }




    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }




    function release() public virtual {

        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount);
    }
}

contract HolderTimelock is TokenTimelock {
  constructor(
    IERC20 _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
    TokenTimelock(_token, _beneficiary, _releaseTime)

  {}
}













contract HolderTVLLock is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant RELEASE_PERCENT = 2;
    uint256 private constant RELEASE_INTERVAL = 1 weeks;


    IERC20 private _token;


    address private _beneficiary;


    uint256 private _lastReleaseTime;


    uint256 private _firstReleaseTime;


    uint256 private _lastReleaseTVL;


    uint256 private _released;

    event TVLReleasePerformed(uint256 newTVL);

    constructor (IERC20 token, address beneficiary, uint256 firstReleaseTime) public {

        transferOwnership(beneficiary);


        require(firstReleaseTime > block.timestamp, "release time before current time");
        _token = token;
        _beneficiary = beneficiary;
        _firstReleaseTime = firstReleaseTime;
    }




    function token() public view returns (IERC20) {
        return _token;
    }




    function beneficiary() public view returns (address) {
        return _beneficiary;
    }




    function lastReleaseTime() public view returns (uint256) {
        return _lastReleaseTime;
    }




    function lastReleaseTVL() public view returns (uint256) {
        return _lastReleaseTVL;
    }






    function release(uint256 _newTVL) public onlyOwner {

        require(block.timestamp >= _firstReleaseTime, "current time before release time");
        require(block.timestamp > _lastReleaseTime + RELEASE_INTERVAL, "release interval is not passed");
        require(_newTVL > _lastReleaseTVL, "only release if TVL is higher");


        uint256 balance = _token.balanceOf(address(this));
        uint256 totalBalance = balance.add(_released);

        uint256 amount = totalBalance.mul(RELEASE_PERCENT).div(100);
        require(balance > amount, "available balance depleted");

        _token.safeTransfer(_beneficiary, amount);
	    _lastReleaseTime = block.timestamp;
	    _lastReleaseTVL = _newTVL;
	    _released = _released.add(amount);

        emit TVLReleasePerformed(_newTVL);
    }
}







contract HolderVesting is Ownable {






    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant RELEASE_INTERVAL = 1 weeks;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);


    address private _beneficiary;


    IERC20 private _token;


    uint256 private _start;
    uint256 private _duration;


    uint256 private _lastReleaseTime;

    bool private _revocable;

    uint256 private _released;
    bool private _revoked;










    constructor(IERC20 token, address beneficiary, uint256 start, uint256 duration, bool revocable) public {

        require(beneficiary != address(0), "beneficiary is zero address");
        require(duration > 0, "duration is 0");

        require(start.add(duration) > block.timestamp, "final time before current time");

        _token = token;

        _beneficiary = beneficiary;

        transferOwnership(beneficiary);

        _revocable = revocable;
        _duration = duration;
        _start = start;
    }




    function beneficiary() public view returns (address) {
        return _beneficiary;
    }




    function start() public view returns (uint256) {
        return _start;
    }




    function duration() public view returns (uint256) {
        return _duration;
    }




    function revocable() public view returns (bool) {
        return _revocable;
    }




    function released() public view returns (uint256) {
        return _released;
    }




    function revoked() public view returns (bool) {
        return _revoked;
    }




    function lastReleaseTime() public view returns (uint256) {
        return _lastReleaseTime;
    }




    function release() public {
        uint256 unreleased = _releasableAmount();

        require(unreleased > 0, "no tokens are due");
        require(block.timestamp > _lastReleaseTime + RELEASE_INTERVAL, "release interval is not passed");

        _released = _released.add(unreleased);

        _token.safeTransfer(_beneficiary, unreleased);
        _lastReleaseTime = block.timestamp;

        emit TokensReleased(address(_token), unreleased);
    }





    function revoke() public onlyOwner {
        require(_revocable, "cannot revoke");
        require(!_revoked, "vesting already revoked");

        uint256 balance = _token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount();
        uint256 refund = balance.sub(unreleased);

        _revoked = true;

        _token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(_token));
    }




    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released);
    }




    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released);

        if (block.timestamp < _start) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}













contract HolyKnight is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;













        uint256 stakedLPAmount;
    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardCalcBlock;
        uint256 accHolyPerShare;
        bool    stakeable;
        address stakeableContract;
        IERC20  stakedHoldableToken;
    }


    HolyToken public holytoken;

    address public devaddr;

    address public treasuryaddr;


    uint256 public startBlock;

    uint256 public targetEndBlock;


    uint256 public totalSupply;

    uint256 public reservedPercent;

    uint256 public holyPerBlock;


    PoolInfo[] public poolInfo;

    uint256 public totalAllocPoint = 0;


    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    mapping (address => uint256) public totalStaked;



    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Treasury(address indexed token, address treasury, uint256 amount);

    constructor(
        HolyToken _token,
        address _devaddr,
        address _treasuryaddr,
        uint256 _totalsupply,
        uint256 _reservedPercent,
        uint256 _startBlock,
        uint256 _targetEndBlock
    ) public {
        holytoken = _token;

        devaddr = _devaddr;
        treasuryaddr = _treasuryaddr;


        transferOwnership(_devaddr);

        totalSupply = _totalsupply;
        reservedPercent = _reservedPercent;

        startBlock = _startBlock;
        targetEndBlock = _targetEndBlock;


        updateHolyPerBlock();
    }



    function setReserve(uint256 _reservedPercent) public onlyOwner {
        reservedPercent = _reservedPercent;
        updateHolyPerBlock();
    }

    function updateHolyPerBlock() internal {

        holyPerBlock = totalSupply.sub(totalSupply.mul(reservedPercent).div(100)).div(targetEndBlock.sub(startBlock));
        massUpdatePools();
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }



    function add(uint256 _allocPoint, IERC20 _lpToken, bool _stakeable, address _stakeableContract, IERC20 _stakedHoldableToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardCalcBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardCalcBlock: lastRewardCalcBlock,
            accHolyPerShare: 0,
            stakeable: _stakeable,
            stakeableContract: _stakeableContract,
            stakedHoldableToken: IERC20(_stakedHoldableToken)
        }));
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);

        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function pendingHoly(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accHolyPerShare = pool.accHolyPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardCalcBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardCalcBlock);
            uint256 tokenReward = multiplier.mul(holyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accHolyPerShare = accHolyPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accHolyPerShare).div(1e12).sub(user.rewardDebt);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardCalcBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardCalcBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(pool.lastRewardCalcBlock);
        uint256 tokenReward = multiplier.mul(holyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accHolyPerShare = pool.accHolyPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardCalcBlock = block.number;
    }


    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accHolyPerShare).div(1e12).sub(user.rewardDebt);
            safeTokenTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);

        user.rewardDebt = user.amount.mul(pool.accHolyPerShare).div(1e12);
        totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].add(_amount);


        if (pool.stakeable) {
            uint256 prevbalance = pool.stakedHoldableToken.balanceOf(address(this));
            Stakeable(pool.stakeableContract).deposit(_amount);
            uint256 balancetoadd = pool.stakedHoldableToken.balanceOf(address(this)).sub(prevbalance);
            user.stakedLPAmount = user.stakedLPAmount.add(balancetoadd);

            totalStaked[address(pool.stakedHoldableToken)] = totalStaked[address(pool.stakedHoldableToken)].add(balancetoadd);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }


    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accHolyPerShare).div(1e12).sub(user.rewardDebt);
        safeTokenTransfer(msg.sender, pending);

        if (pool.stakeable) {

            Stakeable(pool.stakeableContract).withdraw(user.stakedLPAmount);
            totalStaked[address(pool.stakedHoldableToken)] = totalStaked[address(pool.stakedHoldableToken)].sub(user.stakedLPAmount);
            user.stakedLPAmount = 0;
            pool.lpToken.safeTransfer(address(msg.sender), user.amount);
            totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].sub(user.amount);
            user.amount = 0;
            user.rewardDebt = 0;
        } else {
            require(user.amount >= _amount, "withdraw: not good");
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].sub(_amount);
            user.amount = user.amount.sub(_amount);
            user.rewardDebt = user.amount.mul(pool.accHolyPerShare).div(1e12);
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (pool.stakeable) {

            Stakeable(pool.stakeableContract).withdraw(user.stakedLPAmount);
            totalStaked[address(pool.stakedHoldableToken)] = totalStaked[address(pool.stakedHoldableToken)].sub(user.stakedLPAmount);
            user.stakedLPAmount = 0;
        }

        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = holytoken.balanceOf(address(this));
        if (_amount > balance) {
            holytoken.transfer(_to, balance);
        } else {
            holytoken.transfer(_to, _amount);
        }
    }


    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "forbidden");
        devaddr = _devaddr;
    }


    function treasury(address _treasuryaddr) public {
        require(msg.sender == treasuryaddr, "forbidden");
        treasuryaddr = _treasuryaddr;
    }


    function putToTreasury(address token) public onlyOwner {
        uint256 availablebalance = IERC20(token).balanceOf(address(this)) - totalStaked[token];
        require(availablebalance > 0, "not enough tokens");
        putToTreasuryAmount(token, availablebalance);
    }


    function putToTreasuryAmount(address token, uint256 _amount) public onlyOwner {
        uint256 userbalances = totalStaked[token];
        uint256 lptokenbalance = IERC20(token).balanceOf(address(this));
        require(token != address(holytoken), "cannot transfer holy tokens");
        require(_amount <= lptokenbalance - userbalances, "not enough tokens");
        IERC20(token).safeTransfer(treasuryaddr, _amount);
        emit Treasury(token, treasuryaddr, _amount);
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




    function name() public view returns (string memory) {
        return _name;
    }





    function symbol() public view returns (string memory) {
        return _symbol;
    }














    function decimals() public view returns (uint8) {
        return _decimals;
    }




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}











contract HolyToken is ERC20("HolyToken", "HOLY") {



    address public founder;



    address public treasury;



    address public timeVestedSupply;



    address public growthVestedSupply;



    address public mainSupply;



    address public poolSupply;

    uint public constant AMOUNT_INITLIQUIDITY = 1000000 * 1e18;
    uint public constant AMOUNT_OPERATIONS = 9000000 * 1e18;
    uint public constant AMOUNT_TEAM = 10000000 * 1e18;
    uint public constant DISTRIBUTION_SUPPLY = 24000000 * 1e18;
    uint public constant DISTRIBUTION_RESERVE_PERCENT = 10;
    uint public constant MAIN_SUPPLY = 56000000 * 1e18;

    uint public constant MAIN_SUPPLY_VESTING_PERIOD = 127 days;
    uint public constant VESTING_START = 1600905600;


    uint public constant START_LP_BLOCK = 10879960;

    uint public constant END_LP_BLOCK = 11669960;



    constructor(address _founder, address _treasuryaddr) public {
        founder = _founder;
        treasury = _treasuryaddr;


	    mainSupply = address(new HolderTimelock(this, founder, block.timestamp + MAIN_SUPPLY_VESTING_PERIOD));


	    growthVestedSupply = address(new HolderTVLLock(this, founder, VESTING_START));


	    timeVestedSupply = address(new HolderVesting(this, founder, VESTING_START, 365 days, false));


	    poolSupply = address(new HolyKnight(this, founder, treasury, DISTRIBUTION_SUPPLY, DISTRIBUTION_RESERVE_PERCENT, START_LP_BLOCK, END_LP_BLOCK));


	    _mint(founder, AMOUNT_INITLIQUIDITY);
	    _mint(timeVestedSupply, AMOUNT_OPERATIONS);
	    _mint(growthVestedSupply, AMOUNT_TEAM);
	    _mint(poolSupply, DISTRIBUTION_SUPPLY);
	    _mint(mainSupply, MAIN_SUPPLY);
    }
}
