












pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;








contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;



    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }



    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}
















library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
















library DecimalMath {
    using SafeMath for uint256;

    uint256 constant ONE = 10**18;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / ONE;
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).divCeil(d);
    }
}









interface IERC20 {



    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}




















library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {










        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.gaslimit > 0) {


            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}










contract DODOMine is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;











    }


    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accDODOPerShare;
    }

    address public dodoToken;
    uint256 public dodoPerBlock;


    PoolInfo[] public poolInfos;
    mapping(address => uint256) public lpTokenRegistry;


    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public realizedReward;


    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    constructor(address _dodoToken, uint256 _startBlock) public {
        dodoToken = _dodoToken;
        startBlock = _startBlock;
    }



    modifier lpTokenExist(address lpToken) {
        require(lpTokenRegistry[lpToken] > 0, "LP Token Not Exist");
        _;
    }

    modifier lpTokenNotExist(address lpToken) {
        require(lpTokenRegistry[lpToken] == 0, "LP Token Already Exist");
        _;
    }



    function poolLength() external view returns (uint256) {
        return poolInfos.length;
    }

    function getPid(address _lpToken) public view lpTokenExist(_lpToken) returns (uint256) {
        return lpTokenRegistry[_lpToken] - 1;
    }

    function getUserLpBalance(address _lpToken, address _user) public view returns (uint256) {
        uint256 pid = getPid(_lpToken);
        return userInfo[pid][_user].amount;
    }



    function addLpToken(
        address _lpToken,
        uint256 _allocPoint,
        bool _withUpdate
    ) public lpTokenNotExist(_lpToken) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfos.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accDODOPerShare: 0
            })
        );
        lpTokenRegistry[_lpToken] = poolInfos.length;
    }

    function setLpToken(
        address _lpToken,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 pid = getPid(_lpToken);
        totalAllocPoint = totalAllocPoint.sub(poolInfos[pid].allocPoint).add(_allocPoint);
        poolInfos[pid].allocPoint = _allocPoint;
    }

    function setReward(uint256 _dodoPerBlock) external onlyOwner {
        dodoPerBlock = _dodoPerBlock;
    }



    function getPendingReward(address _lpToken, address _user) external view returns (uint256) {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][_user];
        uint256 accDODOPerShare = pool.accDODOPerShare;
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 DODOReward = block
                .number
                .sub(pool.lastRewardBlock)
                .mul(dodoPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accDODOPerShare = accDODOPerShare.add(DecimalMath.divFloor(DODOReward, lpSupply));
        }
        return DecimalMath.mul(user.amount, accDODOPerShare).sub(user.rewardDebt);
    }

    function getAllPendingReward(address _user) external view returns (uint256) {
        uint256 length = poolInfos.length;
        uint256 totalReward = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (userInfo[pid][_user].amount == 0 || poolInfos[pid].allocPoint == 0) {
                continue;
            }
            PoolInfo storage pool = poolInfos[pid];
            UserInfo storage user = userInfo[pid][_user];
            uint256 accDODOPerShare = pool.accDODOPerShare;
            uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
            if (block.number > pool.lastRewardBlock && lpSupply != 0) {
                uint256 DODOReward = block
                    .number
                    .sub(pool.lastRewardBlock)
                    .mul(dodoPerBlock)
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);
                accDODOPerShare = accDODOPerShare.add(DecimalMath.divFloor(DODOReward, lpSupply));
            }
            totalReward = totalReward.add(
                DecimalMath.mul(user.amount, accDODOPerShare).sub(user.rewardDebt)
            );
        }
        return totalReward;
    }

    function getRealizedReward(address _user) external view returns (uint256) {
        return realizedReward[_user];
    }

    function getDlpMiningSpeed(address _lpToken) external view returns (uint256) {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        return dodoPerBlock.mul(pool.allocPoint).div(totalAllocPoint);
    }




    function massUpdatePools() public {
        uint256 length = poolInfos.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfos[_pid];
        if (block.gaslimit <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (block.timestamp == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 DODOReward = block
            .number
            .sub(pool.lastRewardBlock)
            .mul(dodoPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accDODOPerShare = pool.accDODOPerShare.add(DecimalMath.divFloor(DODOReward, lpSupply));
        pool.lastRewardBlock = block.number;
    }




    function deposit(address _lpToken, uint256 _amount) public {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        if (block.timestamp > 0) {
            uint256 pending = DecimalMath.mul(user.amount, pool.accDODOPerShare).sub(
                user.rewardDebt
            );
            safeDODOTransfer(msg.sender, pending);
        }
        IERC20(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = DecimalMath.mul(user.amount, pool.accDODOPerShare);
        emit Deposit(msg.sender, pid, _amount);
    }

    function withdraw(address _lpToken, uint256 _amount) public {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= _amount, "withdraw too much");
        updatePool(pid);
        uint256 pending = DecimalMath.mul(user.amount, pool.accDODOPerShare).sub(user.rewardDebt);
        safeDODOTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = DecimalMath.mul(user.amount, pool.accDODOPerShare);
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, pid, _amount);
    }

    function withdrawAll(address _lpToken) public {
        uint256 balance = getUserLpBalance(_lpToken, msg.sender);
        withdraw(_lpToken, balance);
    }


    function emergencyWithdraw(address _lpToken) public {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function claim(address _lpToken) public {
        uint256 pid = getPid(_lpToken);
        if (userInfo[pid][msg.sender].amount == 0 || poolInfos[pid].allocPoint == 0) {
            return;
        }
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        uint256 pending = DecimalMath.mul(user.amount, pool.accDODOPerShare).sub(user.rewardDebt);
        user.rewardDebt = DecimalMath.mul(user.amount, pool.accDODOPerShare);
        safeDODOTransfer(msg.sender, pending);
    }

    function claimAll() public {
        uint256 length = poolInfos.length;
        uint256 pending = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (userInfo[pid][msg.sender].amount == 0 || poolInfos[pid].allocPoint == 0) {
                continue;
            }
            PoolInfo storage pool = poolInfos[pid];
            UserInfo storage user = userInfo[pid][msg.sender];
            updatePool(pid);
            pending = pending.add(
                DecimalMath.mul(user.amount, pool.accDODOPerShare).sub(user.rewardDebt)
            );
            user.rewardDebt = DecimalMath.mul(user.amount, pool.accDODOPerShare);
        }
        safeDODOTransfer(msg.sender, pending);
    }


    function safeDODOTransfer(address _to, uint256 _amount) internal {
        IERC20(dodoToken).safeTransfer(_to, _amount);
        realizedReward[_to] = realizedReward[_to].add(_amount);
        emit Claim(_to, _amount);
    }
}
