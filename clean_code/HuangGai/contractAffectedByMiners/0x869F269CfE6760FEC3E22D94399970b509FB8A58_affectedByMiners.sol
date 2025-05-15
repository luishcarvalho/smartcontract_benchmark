


























pragma solidity ^0.6.12;

library BasisPoints {
    using SafeMath for uint;

   uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
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






library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

            if (block.number > 0) {



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
        if (block.timestamp > 0) {

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



contract PubToken is ERC20("PUB.finance","PUBS"), Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public burnBP;
    uint public taxBP;
    Bartender private bartender;


    mapping(address => bool) public taxExempt;
    mapping(address => bool) public fromOnlyTaxExempt;
    mapping(address => bool) public toOnlyTaxExempt;


    constructor(uint _taxBP, uint _burnBP, address _bartender, address owner) public {
        bartender = Bartender(_bartender);
        taxBP = _taxBP;
        burnBP = _burnBP;
        setTaxExemptStatus(address(bartender), true);
        transferOwnership(owner);
    }
    modifier onlyBartender {
        require(msg.sender == address(bartender), "Can only be called by Bartender contract.");
        _;
    }


    function mint(address _to, uint256 _amount) public onlyBartender {
        _mint(_to, _amount);
    }


    function setFromOnlyTaxExemptStatus(address account, bool status) external onlyOwner {
        fromOnlyTaxExempt[account] = status;
    }

    function setToOnlyTaxExemptStatus(address account, bool status) external onlyOwner {
        fromOnlyTaxExempt[account] = status;
    }

    function setTaxExemptStatus(address account, bool status) public onlyOwner {
        taxExempt[account] = status;
    }


    function transfer(address recipient, uint amount) public override returns (bool) {
        (
        !taxExempt[msg.sender] && !taxExempt[recipient] &&
        !toOnlyTaxExempt[recipient] && !fromOnlyTaxExempt[msg.sender]
        ) ?
        _transferWithTax(msg.sender, recipient, amount) :
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        (
        !taxExempt[sender] && !taxExempt[recipient] &&
        !toOnlyTaxExempt[recipient] && !fromOnlyTaxExempt[sender]
        ) ?
        _transferWithTax(sender, recipient, amount) :
        _transfer(sender, recipient, amount);

        approve(
            msg.sender,
            allowance(
                sender,
                msg.sender
            ).sub(amount, "Transfer amount exceeds allowance")
        );
        return true;
    }

    function findTaxAmount(uint value) public view returns (uint tax, uint devTax) {
        tax = value.mulBP(taxBP);
        devTax = value.mulBP(burnBP);
    }

    function _transferWithTax(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        (uint tax, uint devTax) = findTaxAmount(amount);
        uint tokensToTransfer = amount.sub(tax).sub(devTax);

        _transfer(sender, address(bartender), tax);
        _transfer(sender, address(bartender), devTax);

        _transfer(sender, recipient, tokensToTransfer);
        bartender.handleTaxDistribution(tax, devTax);
    }

}

contract Bartender is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    enum LockType { None, ThreeDays, Week, Month, Forever}


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        LockType lockType;
        uint256 unlockDate;
        uint256 taxRewardDebt;
        uint256 lpTaxRewardDebt;












    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accPubPerShare;
        uint256 accTaxPubPerShare;
        uint256 accLPTaxPubPerShare;
        uint256 accTokensForTax;
        uint256 accTokensForLPTax;

    }


    PubToken public pub;

    uint256 public pubPerBlock;

    uint256 public constant OWNER_FEE_NUMERATOR = 50;

    uint256 public constant OWNER_FEE_DENOMINATOR = 10000;


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo[])) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;


    uint256 public accumulatedTax = 0;


    IERC20 oldPub;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        uint256 _startBlock,
        address _oldPub
    ) public {



        pub = new PubToken(250, 250, address(this), msg.sender);
        oldPub = IERC20(_oldPub);


        pub.mint(msg.sender, 5 * 10**18);

        pubPerBlock = 0;
        startBlock = _startBlock;
    }
    modifier onlyPubToken {
        require(msg.sender == address(pub), "Can only be called by PubToken contract.");
        _;
    }


    function pubBalance(address a) external view returns (uint256){
        return pub.balanceOf(a);
    }


    function pubToken() external view returns (address) {
        return address(pub);
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    function pubOwner() external view returns (address) {
        return pub.owner();
    }


    function myPubTokenBalance() external view returns (uint256) {
        return pub.balanceOf(msg.sender);
    }


    function getUserInfo(uint256 _pid, address _address) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][_address];

        uint256 length = userInfoArr.length;
        uint totalAmount = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            totalAmount = totalAmount.add(userInfoArr[userInfoIndex].amount);

        }
        return totalAmount;
    }

    function getUserInfoLocked(uint256 _pid, address _address) external view returns (uint256) {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][_address];


        uint256 length = userInfoArr.length;
        uint totalAmount = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user =userInfoArr[userInfoIndex];
            if (user.amount > 0 && user.unlockDate > now) {

                totalAmount = totalAmount.add(user.amount);
            }
        }
        return totalAmount;
    }



    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPubPerShare: 0,
            accTaxPubPerShare:0,
            accLPTaxPubPerShare:0,
            accTokensForTax:0,
            accTokensForLPTax:0
            }));
    }


    function getPubPerBlock() public view returns (uint256){
        return pubPerBlock;
    }


    function setPubPerBlock(uint256 _pubPerBlock) public onlyOwner {
        require(_pubPerBlock > 0, "_pubPerBlock must be non-zero");


        massUpdatePools();


        pubPerBlock = _pubPerBlock;
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function pendingPubs(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now) {
                uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                totalPubToTransfer = totalPubToTransfer.add(pending);


                if (user.lockType >= LockType.Week) {
                    uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }

                if (user.lockType >= LockType.Month) {
                    uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }
            }
        }
        return totalPubToTransfer;
    }


    function pendingLockedPubs(uint256 _pid, address _user) external view returns (uint256) {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];


        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate > now) {
                uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                totalPubToTransfer = totalPubToTransfer.add(pending);


                if (user.lockType >= LockType.Week) {
                    uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }

                if (user.lockType >= LockType.Month) {
                    uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                }
            }
        }
        return totalPubToTransfer;
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function massUpdateTaxAllocationForPools() public {
        uint callerBonus = accumulatedTax.mul(100).div(10000);
        pub.transfer(msg.sender, callerBonus);
        accumulatedTax = accumulatedTax.sub(callerBonus);
        if (block.timestamp == 0) {
            return;
        }
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 lpSupply = pool.accTokensForTax;


            uint256 taxPubReward = accumulatedTax.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accTaxPubPerShare = pool.accTaxPubPerShare.add(taxPubReward.mul(1e12).div(lpSupply));

        }
        accumulatedTax = 0;
    }

    function massUpdateLPTaxAllocationForPools(uint _amount) public {
        pub.transferFrom(msg.sender, address(this), _amount);

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 lpSupply = pool.accTokensForLPTax;


            uint256 lpTaxPubReward = _amount.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accLPTaxPubPerShare = pool.accLPTaxPubPerShare.add(lpTaxPubReward.mul(1e12).div(lpSupply));
        }
    }



    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 pubReward = pubPerBlock.mul(pool.allocPoint).div(totalAllocPoint);

        if(block.timestamp > 0){
            pub.mint(address(this), pubReward);
        }
        pool.accPubPerShare = pool.accPubPerShare.add(pubReward.mul(1e12).div(lpSupply));

        pool.lastRewardBlock = block.number;
    }


    function harvest(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now) {
                uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                totalPubToTransfer = totalPubToTransfer.add(pending);
                user.rewardDebt = user.amount.mul(pool.accPubPerShare).div(1e12);


                if (user.lockType >= LockType.Week) {
                    uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                    user.taxRewardDebt = user.amount.mul(pool.accTaxPubPerShare).div(1e12);
                }

                if (user.lockType >= LockType.Month) {
                    uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                    user.lpTaxRewardDebt = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12);
                }
            }
        }
        safePubTransfer(msg.sender, totalPubToTransfer);
    }


    function deposit(uint256 _pid, uint256 _amount, LockType lockType) public {
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        if (block.gaslimit > 0) {

            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

            UserInfo memory user = UserInfo(_amount,0,lockType,0,0,0);
            user.amount = _amount;
            user.rewardDebt = user.amount.mul(pool.accPubPerShare).div(1e12);
            user.lockType = lockType;
            user.taxRewardDebt = user.amount.mul(pool.accTaxPubPerShare).div(1e12);
            user.lpTaxRewardDebt = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12);

            if(lockType == LockType.ThreeDays){
                user.unlockDate = now + 3 days;
            }
            else if(lockType == LockType.Week){
                user.unlockDate = now + 1 weeks;
                pool.accTokensForTax = pool.accTokensForTax.add(_amount);

            }
            else if(lockType == LockType.Month){
                user.unlockDate = now + 30 days;
                pool.accTokensForLPTax = pool.accTokensForLPTax.add(_amount);
                pool.accTokensForTax = pool.accTokensForTax.add(_amount);
            }
            else if(lockType == LockType.Forever){
                user.unlockDate = now;
                pool.accTokensForLPTax = pool.accTokensForLPTax.add(_amount);
                pool.accTokensForTax = pool.accTokensForTax.add(_amount);
            }
            else {
                user.unlockDate = now;
            }
            userInfo[_pid][msg.sender].push(user);
            emit Deposit(msg.sender, _pid, _amount);
        }
    }


    function withdrawMax(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        uint totalLPToTransfer = 0;
        uint totalLPFee = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now && user.lockType != LockType.Forever) {
                    uint256 pending = user.amount.mul(pool.accPubPerShare).div(1e12).sub(user.rewardDebt);
                    totalPubToTransfer = totalPubToTransfer.add(pending);
                    uint256 amount  = user.amount;


                    if (user.lockType >= LockType.Week) {
                        uint256 pendingTax = user.amount.mul(pool.accTaxPubPerShare).div(1e12).sub(user.taxRewardDebt);
                        totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                        user.taxRewardDebt = user.amount.mul(pool.accTaxPubPerShare).div(1e12);
                    }


                    if (user.lockType >= LockType.Month) {
                        uint256 pendingTax = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12).sub(user.lpTaxRewardDebt);
                        totalPubToTransfer = totalPubToTransfer.add(pendingTax);
                        user.lpTaxRewardDebt = user.amount.mul(pool.accLPTaxPubPerShare).div(1e12);
                    }


                    uint256 fee = 0;
                    if(user.lockType == LockType.None){
                        fee = 100;
                    }
                    else if(user.lockType == LockType.ThreeDays){
                        fee = 50;
                    }
                    else if(user.lockType == LockType.Week){
                        fee = 25;
                        pool.accTokensForTax = pool.accTokensForTax.sub(amount);
                    }
                    else if(user.lockType == LockType.Month){
                        pool.accTokensForLPTax = pool.accTokensForLPTax.sub(amount);
                        pool.accTokensForTax = pool.accTokensForTax.sub(amount);
                    }

                    uint256 feeAmount = amount.mul(fee).div(OWNER_FEE_DENOMINATOR);
                    amount = amount.sub(feeAmount);
                    totalLPFee = totalLPFee.add(feeAmount);

                    totalLPToTransfer = totalLPToTransfer.add(amount);

                    user.rewardDebt = 0;
                    user.amount = 0;
                }

        }

        for (uint256 userInfoIndex = 0; userInfoIndex < length;) {
            UserInfo storage user = userInfoArr[userInfoIndex];
            if(block.number == 0){
                for (uint256 idx = userInfoIndex; idx < length-1; ++idx) {
                    userInfoArr[idx] = userInfoArr[idx+1];
                }
                length = length.sub(1);
                delete userInfoArr[length];
            }
            else{
                userInfoIndex++;
            }
        }


        safePubTransfer(msg.sender, totalPubToTransfer);


        pool.lpToken.safeTransfer(address(owner()), totalLPFee);


        pool.lpToken.safeTransfer(address(msg.sender), totalLPToTransfer);

        emit Withdraw(msg.sender, _pid, totalLPToTransfer);
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage userInfoArr = userInfo[_pid][msg.sender];

        uint256 length = userInfoArr.length;
        uint totalPubToTransfer = 0;
        uint totalLPToTransfer = 0;
        uint totalLPFee = 0;
        for (uint256 userInfoIndex = 0; userInfoIndex < length; ++userInfoIndex) {
            UserInfo storage user = userInfoArr[userInfoIndex];

            if (user.amount > 0 && user.unlockDate <= now && user.lockType != LockType.Forever) {
                uint256 amount  = user.amount;



                uint256 fee = 0;
                if(user.lockType == LockType.None){
                    fee = 100;
                }
                else if(user.lockType == LockType.ThreeDays){
                    fee = 50;
                }
                else if(user.lockType == LockType.Week){
                    fee = 25;
                    pool.accTokensForTax = pool.accTokensForTax.sub(amount);

                }
                else if(user.lockType == LockType.Month){
                    pool.accTokensForLPTax = pool.accTokensForLPTax.sub(amount);
                    pool.accTokensForTax = pool.accTokensForTax.sub(amount);

                }

                uint256 feeAmount = amount.mul(fee).div(OWNER_FEE_DENOMINATOR);
                amount = amount.sub(feeAmount);
                totalLPFee = totalLPFee.add(feeAmount);

                totalLPToTransfer = totalLPToTransfer.add(amount);
            }
        }


        pool.lpToken.safeTransfer(address(owner()), totalLPFee);


        pool.lpToken.safeTransfer(address(msg.sender), totalLPToTransfer);

        emit EmergencyWithdraw(msg.sender, _pid, totalLPToTransfer);
    }


    function safePubTransfer(address _to, uint256 _amount) internal {
        uint256 pubBal = pub.balanceOf(address(this));
        if (block.gaslimit > pubBal) {
            pub.transfer(_to, pubBal);
        } else {
            pub.transfer(_to, _amount);
        }
    }

    function handleTaxDistribution(uint _tax,uint _devTax) external onlyPubToken{
        accumulatedTax = accumulatedTax.add(_tax);

        pub.transfer(address(owner()), _devTax);
    }


    function swapPubForPub2(uint _amount) public{
        oldPub.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _amount);
        pub.mint(msg.sender, _amount);
    }

}
