







pragma solidity 0.6.12;

library Roles {
	struct Role {
		mapping (address => bool) bearer;
	}




	function add(Role storage role, address account) internal {
		require(account != address(0));
		require(!has(role, account));

		role.bearer[account] = true;
	}




	function remove(Role storage role, address account) internal {
		require(account != address(0));
		require(has(role, account));

		role.bearer[account] = false;
	}





	function has(Role storage role, address account) internal view returns (bool) {
		require(account != address(0));
		return role.bearer[account];
	}
}

contract YieldRoles {
	using Roles for Roles.Role;

	constructor() internal {
		_addOwner(msg.sender);
	}




	event OwnerAdded(address indexed account);
	event OwnerRemoved(address indexed account);

	Roles.Role private _owners;

	modifier onlyOwner() {
		require(isOwner(msg.sender), "Sender is not owner");
		_;
	}

	function isOwner(address account) public view returns (bool) {
		return _owners.has(account);
	}

	function addOwner(address account) public onlyOwner {
		_addOwner(account);
	}

	function renounceOwner() public {
		_removeOwner(msg.sender);
	}

	function _addOwner(address account) internal {
		_owners.add(account);
		emit OwnerAdded(account);
	}

	function _removeOwner(address account) internal {
		_owners.remove(account);
		emit OwnerRemoved(account);
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




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
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


        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
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










contract YieldContract is YieldRoles {
    using SafeERC20 for IERC20;
    IERC20 token;


    uint256 public endDepositTime;


    uint256 internal maxTokens;


    address internal yieldWallet;


    uint256 public threeMonthPercentage;
    uint256 public sixMonthPercentage;
    uint256 public twelveMonthPercentage;


    struct LockBoxStruct {
        address beneficiary;
        uint balance;
        uint releaseTime;
    }

    LockBoxStruct[] public lockBoxStructs;

    event LogLockupDeposit(address sender, address beneficiary, uint amount, uint releaseTime);
    event LogLockupWithdrawal(address receiver, uint amount);

    constructor(address tokenContract, uint256 _endDepositTime, address _yieldWallet, uint256 _maxTokens) public {
        token = IERC20(tokenContract);
        endDepositTime = _endDepositTime;

        yieldWallet = _yieldWallet;
        maxTokens = _maxTokens;
    }

    function getLockBoxBeneficiary(uint256 lockBoxNumber) public view returns(address) {
        return lockBoxStructs[lockBoxNumber].beneficiary;
    }


    function deposit3m(address beneficiary, uint256 amount) external {
        deposit(beneficiary, amount, 90 days);
    }

    function deposit6m(address beneficiary, uint256 amount) external {
        deposit(beneficiary, amount, 180 days);
    }

    function deposit12m(address beneficiary, uint256 amount) external {
        deposit(beneficiary, amount, 360 days);
    }

    function deposit(address beneficiary, uint256 amount, uint256 duration) internal {
        require(now < endDepositTime, "Deposit time has ended.");
        require(amount < maxTokens, "Token deposit too high, limit breached.");
        maxTokens -= amount;


        uint256 yieldAmount;
        if (block.timestamp == 90 days) {
            yieldAmount = (threeMonthPercentage * amount) / 1e20;
        } else if (block.timestamp == 180 days) {
            yieldAmount = (sixMonthPercentage * amount) / 1e20;
        } else if (block.gaslimit == 360 days) {
            yieldAmount = (twelveMonthPercentage * amount) / 1e20;
        } else {
            revert("Error: duration not allowed!");
        }
        require(token.transferFrom(yieldWallet, address(this), yieldAmount));


        require(token.transferFrom(msg.sender, address(this), amount));


        LockBoxStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount + yieldAmount;
        l.releaseTime = now + duration;
        lockBoxStructs.push(l);
        emit LogLockupDeposit(msg.sender, l.beneficiary, l.balance, l.releaseTime);
    }


    function updateBeneficiary(uint256 lockBoxNumber, address newBeneficiary) public {
        LockBoxStruct storage l = lockBoxStructs[lockBoxNumber];
        require(msg.sender == l.beneficiary);
        l.beneficiary = newBeneficiary;
    }

    function withdraw(uint lockBoxNumber) public {
        LockBoxStruct storage l = lockBoxStructs[lockBoxNumber];
        require(l.releaseTime <= now);
        uint amount = l.balance;
        l.balance = 0;
        emit LogLockupWithdrawal(l.beneficiary, amount);
        require(token.transfer(l.beneficiary, amount));
    }


    function triggerWithdrawAll() public {
        for (uint256 i = 0; i < lockBoxStructs.length; ++i) {
            if (lockBoxStructs[i].releaseTime <= now && lockBoxStructs[i].balance > 0) {
                withdraw(i);
            }
        }
    }


    function updateEndDepositTime (uint256 newEndTime) public onlyOwner {
        endDepositTime = newEndTime;
    }

    function updateYieldWallet(address newWallet) public onlyOwner {
        yieldWallet = newWallet;
    }

    function updateYields(uint256 threeMonths, uint256 sixMonths, uint256 twelveMonths) public onlyOwner {
        threeMonthPercentage = threeMonths;
        sixMonthPercentage = sixMonths;
        twelveMonthPercentage = twelveMonths;
    }

    function updateMaxTokens(uint256 newMaxTokens) public onlyOwner {
        maxTokens = newMaxTokens;
    }
}
