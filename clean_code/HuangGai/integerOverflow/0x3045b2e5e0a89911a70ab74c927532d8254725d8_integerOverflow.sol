










pragma solidity ^0.6.6;

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount)
        external
        returns (bool);








    function allowance(address owner, address spender)
        external
        view
        returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address _to, uint256 _amount) external;







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}

library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {

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













    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );


        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }



















    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }







    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }








    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {




        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {


            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );




    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract McdonaldChef is Ownable {
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
        uint256 accMcdonaldPerShare;
    }


    IERC20 public mcdonald;

    address public devaddr;

    uint256 public bonusEndBlock;

    uint256 public mcdonaldPerBlock;


    IMigratorChef public migrator;


    PoolInfo[] public poolInfo;
    mapping(address => bool) public lpTokenExistsInPool;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    uint256 public blockInADay = 5760;
    uint256 public blockInAMonth = 172800;
    uint256 public halvePeriod = blockInAMonth;
    uint256 public minimumMcdonaldPerBlock = 125 ether;
    uint256 public lastHalveBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Halve(uint256 newMcdonaldPerBlock, uint256 nextHalveBlockNumber);

    constructor(
        IERC20 _mcdonald,
        address _devaddr,
        uint256 _startBlock
    ) public {
        mcdonald = _mcdonald;
        devaddr = _devaddr;
        mcdonaldPerBlock = 1000 ether;
        startBlock = _startBlock;
        lastHalveBlock = _startBlock;
    }

    function doHalvingCheck(bool _withUpdate) public {
        if (mcdonaldPerBlock <= minimumMcdonaldPerBlock) {
            return;
        }
        bool doHalve = block.number > lastHalveBlock + halvePeriod;
        if (!doHalve) {
            return;
        }
        uint256 newMcdonaldPerBlock = mcdonaldPerBlock.div(2);
        if (newMcdonaldPerBlock >= minimumMcdonaldPerBlock) {
            mcdonaldPerBlock = newMcdonaldPerBlock;
            lastHalveBlock = block.number;
            emit Halve(newMcdonaldPerBlock, block.number + halvePeriod);

            if (_withUpdate) {
                massUpdatePools();
            }
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }



    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        require(
            !lpTokenExistsInPool[address(_lpToken)],
            "McdonaldChef: LP Token Address already exists in pool"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accMcdonaldPerShare: 0
            })
        );
        lpTokenExistsInPool[address(_lpToken)] = true;
    }

    function updateLpTokenExists(address _lpTokenAddr, bool _isExists)
        external
        onlyOwner
    {
        lpTokenExistsInPool[_lpTokenAddr] = _isExists;
    }


    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function migrate(uint256 _pid) public onlyOwner {
        require(
            address(migrator) != address(0),
            "McdonaldChef: Address of migrator is null"
        );
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(
            !lpTokenExistsInPool[address(newLpToken)],
            "McdonaldChef: New LP Token Address already exists in pool"
        );
        require(
            bal == newLpToken.balanceOf(address(this)),
            "McdonaldChef: New LP Token balance incorrect"
        );
        pool.lpToken = newLpToken;
        lpTokenExistsInPool[address(newLpToken)] = true;
    }


    function pendingMcdonald(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMcdonaldPerShare = pool.accMcdonaldPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockPassed = block.number.sub(pool.lastRewardBlock);
            uint256 mcdonaldReward = blockPassed
                .mul(mcdonaldPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accMcdonaldPerShare = accMcdonaldPerShare.add(
                mcdonaldReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accMcdonaldPerShare).div(1e12).sub(user.rewardDebt);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        doHalvingCheck(false);
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockPassed = block.number.sub(pool.lastRewardBlock);
        uint256 mcdonaldReward = blockPassed
            .mul(mcdonaldPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        mcdonald.mint(devaddr, mcdonaldReward.div(16));
        mcdonald.mint(address(this), mcdonaldReward);
        pool.accMcdonaldPerShare = pool.accMcdonaldPerShare.add(
            mcdonaldReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }


    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accMcdonaldPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeMcdonaldTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);

        user.rewardDebt = user.amount.mul(pool.accMcdonaldPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }


    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amount >= _amount,
            "McdonaldChef: Insufficient Amount to withdraw"
        );
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMcdonaldPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeMcdonaldTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);

        user.rewardDebt = user.amount.mul(pool.accMcdonaldPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    function safeMcdonaldTransfer(address _to, uint256 _amount) internal {
        uint256 mcdonaldBal = mcdonald.balanceOf(address(this));
        if (_amount > mcdonaldBal) {
            mcdonald.transfer(_to, mcdonaldBal);
        } else {
            mcdonald.transfer(_to, _amount);
        }
    }


    function dev(address _devaddr) public {
        require(
            msg.sender == devaddr,
            "McdonaldChef: Sender is not the developer"
        );
        devaddr = _devaddr;
    }
}
