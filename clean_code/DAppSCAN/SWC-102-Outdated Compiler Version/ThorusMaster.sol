


pragma solidity 0.8.10;











abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}















abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor() {
        _setOwner(_msgSender());
    }




    function owner() public view virtual returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }







    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }







    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    using Address for address;

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

















abstract contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}

interface IThorusToken is IERC20 {
    function mint(address account, uint256 amount) external;
}

contract ThorusMaster is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardSecond;
        uint256 accThorusPerShare;
        uint256 lpSupply;
    }

    IThorusToken public immutable thorus;
    uint256 public thorusPerSecond;
    uint256 internal constant MAX_EMISSION_RATE = 100 ether;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public immutable startSecond;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Add(uint256 allocPoint, IERC20 lpToken);
    event Set(uint256 pid, uint256 oldAllocPoint, uint256 newAllocPoint);
    event SetThorusPerSecond(uint256 oldThorusPerSecond, uint256 newThorusPerSecond);

    constructor(
        IThorusToken _thorus,
        uint256 _thorusPerSecond,
        uint256 _startSecond
    ) {
        thorus = _thorus;
        thorusPerSecond = _thorusPerSecond;
        startSecond = _startSecond;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
            return _to - _from;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken) external onlyOwner {
        massUpdatePools();
        uint256 lastRewardSecond = block.timestamp > startSecond
            ? block.timestamp
            : startSecond;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardSecond: lastRewardSecond,
                accThorusPerShare: 0,
                lpSupply: 0
            })
        );
        emit Add(_allocPoint, _lpToken);
    }

    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        emit Set(_pid, poolInfo[_pid].allocPoint, _allocPoint);
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function pendingThorus(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accThorusPerShare = pool.accThorusPerShare;
        if (block.timestamp > pool.lastRewardSecond && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardSecond, block.timestamp);
            uint256 thorusReward = multiplier * thorusPerSecond * pool.allocPoint / totalAllocPoint;
            accThorusPerShare = accThorusPerShare + (thorusReward * 1e18 / pool.lpSupply);
        }
        return (user.amount * accThorusPerShare / 1e18) - user.rewardDebt + user.pendingRewards;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardSecond) {
            return;
        }
        if (pool.lpSupply == 0) {
            pool.lastRewardSecond = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardSecond, block.timestamp);
        uint256 thorusReward = multiplier * thorusPerSecond * pool.allocPoint / totalAllocPoint;
        thorus.mint(address(this), thorusReward);
        pool.accThorusPerShare = pool.accThorusPerShare + (thorusReward * 1e18 / pool.lpSupply);
        pool.lastRewardSecond = block.timestamp;
    }

    function deposit(uint256 _pid, uint256 _amount, bool _withdrawRewards) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accThorusPerShare / 1e18) - user.rewardDebt;
            uint256 totalPending = user.pendingRewards + pending;
            if (_withdrawRewards) {
                user.pendingRewards = 0;
                safeThorusTransfer(msg.sender, totalPending);
                emit Claim(msg.sender, _pid, totalPending);
            } else {
                user.pendingRewards = totalPending;
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            user.amount = user.amount + _amount;
            pool.lpSupply = pool.lpSupply + _amount;
        }
        user.rewardDebt = user.amount * pool.accThorusPerShare / 1e18;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount, bool _withdrawRewards) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accThorusPerShare / 1e18) - user.rewardDebt;
        uint256 totalPending = user.pendingRewards + pending;
        if (_withdrawRewards) {
            user.pendingRewards = 0;
            safeThorusTransfer(msg.sender, totalPending);
            emit Claim(msg.sender, _pid, totalPending);
        } else {
            user.pendingRewards = totalPending;
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpSupply = pool.lpSupply - _amount;
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = user.amount * pool.accThorusPerShare / 1e18;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(msg.sender, user.amount);
        pool.lpSupply = pool.lpSupply - user.amount;
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.pendingRewards = 0;
    }

    function claim(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accThorusPerShare / 1e18) - user.rewardDebt;
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards + pending;
            safeThorusTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, _pid, user.pendingRewards);
            user.pendingRewards = 0;
        }
        user.rewardDebt = user.amount * pool.accThorusPerShare / 1e18;
    }

    function safeThorusTransfer(address _to, uint256 _amount) internal {
        uint256 thorusBal = thorus.balanceOf(address(this));
        if (_amount > thorusBal) {
            thorus.transfer(_to, thorusBal);
        } else {
            thorus.transfer(_to, _amount);
        }
    }

    function setThorusPerSecond(uint256 _thorusPerSecond) external onlyOwner {
        require(_thorusPerSecond > 0, "!thorusPerSecond-0");
        require(_thorusPerSecond <= MAX_EMISSION_RATE, "!thorusPerSecond-MAX");
        massUpdatePools();
        emit SetThorusPerSecond(thorusPerSecond, _thorusPerSecond);
        thorusPerSecond = _thorusPerSecond;
    }
}
