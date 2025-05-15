

pragma solidity ^0.5.16;

interface IERC20 {
    function TOTALSUPPLY53() external view returns (uint256);
    function BALANCEOF768(address account) external view returns (uint256);
    function TRANSFER471(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE884(address owner, address spender) external view returns (uint256);
    function APPROVE804(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM437(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER776(address indexed from, address indexed to, uint256 value);
    event APPROVAL649(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }


    function _MSGSENDER485() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA48() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    function TOTALSUPPLY53() public view returns (uint256) {
        return _totalSupply;
    }
    function BALANCEOF768(address account) public view returns (uint256) {
        return _balances[account];
    }
    function TRANSFER471(address recipient, uint256 amount) public returns (bool) {
        _TRANSFER526(_MSGSENDER485(), recipient, amount);
        return true;
    }
    function ALLOWANCE884(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function APPROVE804(address spender, uint256 amount) public returns (bool) {
        _APPROVE393(_MSGSENDER485(), spender, amount);
        return true;
    }
    function TRANSFERFROM437(address sender, address recipient, uint256 amount) public returns (bool) {
        _TRANSFER526(sender, recipient, amount);
        _APPROVE393(sender, _MSGSENDER485(), _allowances[sender][_MSGSENDER485()].SUB142(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function INCREASEALLOWANCE734(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE393(_MSGSENDER485(), spender, _allowances[_MSGSENDER485()][spender].ADD675(addedValue));
        return true;
    }
    function DECREASEALLOWANCE300(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE393(_MSGSENDER485(), spender, _allowances[_MSGSENDER485()][spender].SUB142(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _TRANSFER526(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB142(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD675(amount);
        emit TRANSFER776(sender, recipient, amount);
    }
    function _MINT24(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD675(amount);
        _balances[account] = _balances[account].ADD675(amount);
        emit TRANSFER776(address(0), account, amount);
    }
    function _BURN451(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].SUB142(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB142(amount);
        emit TRANSFER776(account, address(0), amount);
    }
    function _APPROVE393(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL649(owner, spender, amount);
    }
    function _BURNFROM611(address account, uint256 amount) internal {
        _BURN451(account, amount);
        _APPROVE393(account, _MSGSENDER485(), _allowances[account][_MSGSENDER485()].SUB142(amount, "ERC20: burn amount exceeds allowance"));
    }
}

library SafeMath {
    function ADD675(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function SUB142(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB142(a, b, "SafeMath: subtraction overflow");
    }
    function SUB142(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function MUL208(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function DIV371(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV371(a, b, "SafeMath: division by zero");
    }
    function DIV371(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function MOD580(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD580(a, b, "SafeMath: modulo by zero");
    }
    function MOD580(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function ISCONTRACT463(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function TOPAYABLE85(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function SENDVALUE508(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER278(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN936(token, abi.encodeWithSelector(token.TRANSFER471.selector, to, value));
    }

    function SAFETRANSFERFROM994(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN936(token, abi.encodeWithSelector(token.TRANSFERFROM437.selector, from, to, value));
    }

    function SAFEAPPROVE667(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.ALLOWANCE884(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN936(token, abi.encodeWithSelector(token.APPROVE804.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE13(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE884(address(this), spender).ADD675(value);
        CALLOPTIONALRETURN936(token, abi.encodeWithSelector(token.APPROVE804.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE169(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE884(address(this), spender).SUB142(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN936(token, abi.encodeWithSelector(token.APPROVE804.selector, spender, newAllowance));
    }
    function CALLOPTIONALRETURN936(IERC20 token, bytes memory data) private {
        require(address(token).ISCONTRACT463(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract pCOMPVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    struct RewardDivide {
        mapping (address => uint256) amount;
        uint256 time;
    }

    IERC20 public token = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    address public governance;
    uint256 public totalDeposit;
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public rewardBalances;
    address[] public addressIndices;

    mapping(uint256 => RewardDivide) public _rewards;
    uint256 public _rewardCount = 0;

    event WITHDRAWN745(address indexed user, uint256 amount);

    constructor () public {
        governance = msg.sender;
    }

    function BALANCE329() public view returns (uint) {
        return token.BALANCEOF768(address(this));
    }

    function SETGOVERNANCE765(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function DEPOSITALL1000() external {
        DEPOSIT234(token.BALANCEOF768(msg.sender));
    }

    function DEPOSIT234(uint256 _amount) public {
        require(_amount > 0, "can't deposit 0");

        uint arrayLength = addressIndices.length;

        bool found = false;
        for (uint i = 0; i < arrayLength; i++) {
            if(addressIndices[i]==msg.sender){
                found=true;
                break;
            }
        }

        if(!found){
            addressIndices.push(msg.sender);
        }

        uint256 realAmount = _amount.MUL208(995).DIV371(1000);
        uint256 feeAmount = _amount.MUL208(5).DIV371(1000);

        address feeAddress = 0xD319d5a9D039f06858263E95235575Bb0Bd630BC;
        address vaultAddress = 0x071E6194403942E8b38fd057B7Cf8871Bd525090;

        token.SAFETRANSFERFROM994(msg.sender, feeAddress, feeAmount);
        token.SAFETRANSFERFROM994(msg.sender, vaultAddress, realAmount);

        totalDeposit = totalDeposit.ADD675(realAmount);
        depositBalances[msg.sender] = depositBalances[msg.sender].ADD675(realAmount);
    }

    function REWARD945(uint256 _amount) external {
        require(_amount > 0, "can't reward 0");
        require(totalDeposit > 0, "totalDeposit must bigger than 0");

        token.SAFETRANSFERFROM994(msg.sender, address(this), _amount);

        uint arrayLength = addressIndices.length;
        for (uint i = 0; i < arrayLength; i++) {
            rewardBalances[addressIndices[i]] = rewardBalances[addressIndices[i]].ADD675(_amount.MUL208(depositBalances[addressIndices[i]]).DIV371(totalDeposit));
            _rewards[_rewardCount].amount[addressIndices[i]] = _amount.MUL208(depositBalances[addressIndices[i]]).DIV371(totalDeposit);
        }

        _rewards[_rewardCount].time = block.timestamp;
        _rewardCount++;
    }

    function WITHDRAWALL110() external {
        WITHDRAW746(rewardBalances[msg.sender]);
    }

    function WITHDRAW746(uint256 _amount) public {
        require(_rewardCount > 0, "no reward amount");
        require(_amount > 0, "can't withdraw 0");

        uint256 availableWithdrawAmount = AVAILABLEWITHDRAW478(msg.sender);

        if (_amount > availableWithdrawAmount) {
            _amount = availableWithdrawAmount;
        }

        token.SAFETRANSFER278(msg.sender, _amount);

        rewardBalances[msg.sender] = rewardBalances[msg.sender].SUB142(_amount);
        emit WITHDRAWN745(msg.sender, _amount);
    }

    function AVAILABLEWITHDRAW478(address owner) public view returns(uint256){
        uint256 availableWithdrawAmount = rewardBalances[owner];
        for (uint256 i = _rewardCount - 1; block.timestamp < _rewards[i].time.ADD675(7 days); --i) {
            availableWithdrawAmount = availableWithdrawAmount.SUB142(_rewards[i].amount[owner].MUL208(_rewards[i].time.ADD675(7 days).SUB142(block.timestamp)).DIV371(7 days));
            if (i == 0) break;
        }
        return availableWithdrawAmount;
    }
}
