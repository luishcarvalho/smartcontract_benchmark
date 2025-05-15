


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






interface IERC20Metadata is IERC20 {



    function name() external view returns (string memory);




    function symbol() external view returns (string memory);




    function decimals() external view returns (uint8);
}


























contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;










    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }




    function name() public view virtual override returns (string memory) {
        return _name;
    }





    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }














    function decimals() public view virtual override returns (uint8) {
        return 18;
    }




    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view virtual override returns (uint256) {
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














    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }















    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }














    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }















    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}















    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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










abstract contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    function paused() public view virtual returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

interface IThorusMaster {
    function deposit(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

    function withdraw(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

    function claim(uint256 _pid) external;

    function pendingThorus(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}

contract ThorusAutoStake is ERC20("sTHO", "sTHO"), Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 lastDepositedTime;
        uint256 thorusAtLastUserAction;
        uint256 lastUserActionTime;
    }

    IERC20 public immutable thorus;
    IThorusMaster public immutable thorusMaster;
    uint256 public immutable stakingPid;

    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public whitelistedProxies;

    uint256 public lastHarvestedTime;
    address public treasury;

    uint256 internal constant MAX_PERFORMANCE_FEE = 500;
    uint256 internal constant MAX_CALL_FEE = 100;
    uint256 internal constant MAX_WITHDRAW_FEE = 100;
    uint256 internal constant MAX_WITHDRAW_FEE_PERIOD = 72 hours;

    uint256 public performanceFee = 200;
    uint256 public callFee = 20;
    uint256 public withdrawFee = 50;
    uint256 public withdrawFeePeriod = 72 hours;

    bool public hadEmergencyWithdrawn = false;

    event Deposit(address indexed sender, uint256 amount, uint256 mintSupply, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 currentAmount, uint256 amount);
    event Harvest(address indexed sender, uint256 performanceFee, uint256 callFee);
    event WhitelistedProxy(address indexed proxy);
    event DewhitelistedProxy(address indexed proxy);
    event SetTreasury(address indexed treasury);
    event SetPerformanceFee(uint256 performanceFee);
    event SetCallFee(uint256 callFee);
    event SetWithdrawFee(uint256 withdrawFee);
    event SetWithdrawFeePeriod(uint256 withdrawFeePeriod);
    event EmergencyWithdraw();

    constructor(
        IERC20 _thorus,
        IThorusMaster _thorusMaster,
        uint256 _stakingPid,
        address _treasury
    ) {
        thorus = _thorus;
        thorusMaster = _thorusMaster;
        stakingPid = _stakingPid;
        treasury = _treasury;

        IERC20(_thorus).approve(address(_thorusMaster), type(uint256).max);
    }

    function whitelistProxy(address _proxy) external onlyOwner {
        require(_proxy != address(0), 'zero address');
        require(!whitelistedProxies[_proxy], 'proxy already whitelisted');
        whitelistedProxies[_proxy] = true;
        emit WhitelistedProxy(_proxy);
    }

    function dewhitelistProxy(address _proxy) external onlyOwner {
        require(_proxy != address(0), 'zero address');
        require(whitelistedProxies[_proxy], 'proxy not whitelisted');
        whitelistedProxies[_proxy] = false;
        emit DewhitelistedProxy(_proxy);
    }

    function deposit(address _user, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Nothing to deposit");
        require(_user == msg.sender || whitelistedProxies[msg.sender], 'msg.sender is not allowed proxy');

        uint256 pool = thorusBalanceOf();
        thorus.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 mintSupply = 0;
        if (totalSupply() != 0) {
            mintSupply = _amount * totalSupply() / pool;
        } else {
            mintSupply = _amount;
        }
        UserInfo storage user = userInfo[_user];

        _mint(_user, mintSupply);
        user.lastDepositedTime = block.timestamp;

        user.thorusAtLastUserAction = balanceOf(_user) * thorusBalanceOf() / totalSupply();
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(_user, _amount, mintSupply, block.timestamp);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function harvest() external whenNotPaused nonReentrant {
        IThorusMaster(thorusMaster).claim(stakingPid);

        uint256 bal = available();
        uint256 currentPerformanceFee = bal * performanceFee / 10000;
        thorus.safeTransfer(treasury, currentPerformanceFee);

        uint256 currentCallFee = bal * callFee / 10000;
        thorus.safeTransfer(msg.sender, currentCallFee);

        _earn();

        lastHarvestedTime = block.timestamp;

        emit Harvest(msg.sender, currentPerformanceFee, currentCallFee);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        performanceFee = _performanceFee;
        emit SetPerformanceFee(_performanceFee);
    }

    function setCallFee(uint256 _callFee) external onlyOwner {
        require(_callFee <= MAX_CALL_FEE, "callFee cannot be more than MAX_CALL_FEE");
        callFee = _callFee;
        emit SetCallFee(_callFee);
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "withdrawFee cannot be more than MAX_WITHDRAW_FEE");
        withdrawFee = _withdrawFee;
        emit SetWithdrawFee(_withdrawFee);
    }

    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyOwner {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
        );
        withdrawFeePeriod = _withdrawFeePeriod;
        emit SetWithdrawFeePeriod(_withdrawFeePeriod);
    }

    function emergencyWithdraw() external onlyOwner {
        IThorusMaster(thorusMaster).emergencyWithdraw(stakingPid);
        hadEmergencyWithdrawn = true;
        _pause();
        emit EmergencyWithdraw();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        require(!hadEmergencyWithdrawn, 'cannot unpause after emergency withdraw');
        _unpause();
    }

    function calculateHarvestThorusRewards() external view returns (uint256) {
        uint256 amount = IThorusMaster(thorusMaster).pendingThorus(stakingPid, address(this));
        amount = amount + available();
        uint256 currentCallFee = amount * callFee / 10000;

        return currentCallFee;
    }

    function calculateTotalPendingThorusRewards() external view returns (uint256) {
        uint256 amount = IThorusMaster(thorusMaster).pendingThorus(stakingPid, address(this));
        amount = amount + available();

        return amount;
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : thorusBalanceOf() * 1e18 / totalSupply();
    }

    function withdraw(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "Nothing to withdraw");
        require(_amount <= balanceOf(msg.sender), "Withdraw amount exceeds balance");

        uint256 currentAmount = thorusBalanceOf() * _amount / totalSupply();
        _burn(msg.sender, _amount);

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount - bal;
            IThorusMaster(thorusMaster).withdraw(stakingPid, balWithdraw, true);
            uint256 balAfter = available();
            uint256 diff = balAfter - bal;
            if (diff < balWithdraw) {
                currentAmount = balAfter;
            }
        }

        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            uint256 currentWithdrawFee = currentAmount * withdrawFee / 10000;
            thorus.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount - currentWithdrawFee;
        }

        if (balanceOf(msg.sender) > 0) {
            user.thorusAtLastUserAction = balanceOf(msg.sender) * thorusBalanceOf() / totalSupply();
        } else {
            user.thorusAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        thorus.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, _amount);
    }

    function available() public view returns (uint256) {
        return thorus.balanceOf(address(this));
    }

    function thorusBalanceOf() public view returns (uint256) {
        (uint256 amount, , ) = IThorusMaster(thorusMaster).userInfo(stakingPid, address(this));
        return thorus.balanceOf(address(this)) + amount;
    }

    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            IThorusMaster(thorusMaster).deposit(stakingPid, bal, true);
        }
    }
}
