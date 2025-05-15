



pragma solidity ^0.6.2;




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
        return functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }







    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");


        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }







    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");


        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


pragma solidity ^0.6.0;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

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


contract QubNQub is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 MAX_QUB_AMOUNT = 50000*10**18;
    uint256 MIN_STAKING_DAYS = 30 days;

    IERC20 public nqubWrapper = IERC20(0x892A74a8727Daf514cD3EFaBAaC03f415f3D20Af);
    IERC20 public qub = IERC20(0xB2D74b7a454EDa300c6E633f5b593d128C0C0Dcf);
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakeDates;
    mapping(address => uint256) public withdrawDates;
    mapping(address => uint256) public stakeDays;
    mapping(address => uint256) public stakeRequests;
    mapping(address => bool) public withdrawLocks;

    modifier checkBalance(uint256 amount) {
        require(balances[msg.sender].add(amount) <= MAX_QUB_AMOUNT);
        _;
    }

    modifier checkWithdrawDate {
        require(withdrawDates[msg.sender] > 0 && now >= withdrawDates[msg.sender]);
        require(now.sub(stakeRequests[msg.sender]) >= 24 hours);
        _;
    }

    modifier checkWithdrawLock {
        require(now.sub(stakeRequests[msg.sender]) >= 30 days || !withdrawLocks[msg.sender]);
        _;
    }

    function calculateWithdrawDate() internal {
        stakeDays[msg.sender] = MIN_STAKING_DAYS.mul(MAX_QUB_AMOUNT.div(balances[msg.sender]));
        uint256 newWithdrawDate = now.add(stakeDays[msg.sender]);
        if (stakeDates[msg.sender] > 0) {
            uint256 stakeDuration = withdrawDates[msg.sender].sub(stakeDates[msg.sender]);
            uint256 stakeDurationPercent = now.sub(stakeDates[msg.sender]).mul(100).div(stakeDuration);
            newWithdrawDate = newWithdrawDate.sub(stakeDays[msg.sender].mul(stakeDurationPercent).div(100));
        }
        withdrawDates[msg.sender] = newWithdrawDate;
        stakeDates[msg.sender] = now;
    }

    function stake(uint256 amount) public checkBalance(amount) {
        balances[msg.sender] = balances[msg.sender].add(amount);

        calculateWithdrawDate();
        stakeRequests[msg.sender] = now;
        withdrawLocks[msg.sender] = true;
        qub.safeTransferFrom(msg.sender, address(this), amount);
    }

    function getReward() public checkWithdrawDate {
        uint256 withdrawAmount = 1;
        uint256 overStakeDuration = now.sub(withdrawDates[msg.sender]);
        uint256 additionalAmount = overStakeDuration.div(stakeDays[msg.sender]);
        stakeDates[msg.sender] = 0;
        calculateWithdrawDate();
        withdrawDates[msg.sender] = withdrawDates[msg.sender].sub(overStakeDuration.mod(stakeDays[msg.sender]));
        withdrawAmount = withdrawAmount.add(additionalAmount);
        withdrawLocks[msg.sender] = false;
        nqubWrapper.safeTransfer(msg.sender, withdrawAmount);
    }

    function withdraw(uint256 amount) public checkWithdrawLock {
        balances[msg.sender] = balances[msg.sender].sub(amount);

        if (balances[msg.sender] > 0) {
            calculateWithdrawDate();
        } else {
            stakeDates[msg.sender] = 0;
            withdrawDates[msg.sender] = 0;
        }
        qub.safeTransfer(msg.sender, amount);
    }

    function getEtherFund(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }

    function getTokenFund(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 ierc20Token = IERC20(tokenAddress);
        ierc20Token.safeTransfer(msg.sender, amount);
    }
}
