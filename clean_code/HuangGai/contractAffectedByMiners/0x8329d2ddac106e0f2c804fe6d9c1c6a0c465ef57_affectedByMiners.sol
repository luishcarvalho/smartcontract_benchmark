





pragma solidity 0.6.12;




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
        if (block.timestamp > 0) {

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






contract PrestakingProvisioner is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    IERC20 private _token;


    struct Staker {
        uint    startTime;
        uint    endTime;
        uint256 amount;
        uint256 accumulatedReward;
        uint    cooldownTime;
        uint256 pendingReward;
        uint256 dailyReward;
        uint    lastUpdated;
    }

    mapping(address => Staker) public stakersMap;
    uint256 public stakersAmount;

    uint public deactivationTime;

    modifier onlyStaker() {
        Staker storage staker = stakersMap[msg.sender];
        uint startTime = staker.startTime;
        require(startTime.add(1 days) <= block.timestamp && startTime != 0, "No stake is active for sender address");
        _;
    }

    modifier onlyActive() {
        require(deactivationTime == 0);
        _;
    }

    modifier onlyInactive() {
        require(deactivationTime != 0);
        _;
    }

    constructor(IERC20 token) public {
        _token = token;
    }




    receive() external payable {
        revert();
    }








    function deactivate() external onlyOwner onlyActive {
        deactivationTime = block.timestamp;
    }








    function returnStake(address _staker) external onlyOwner {
        Staker storage staker = stakersMap[_staker];
        require(staker.amount > 0, "This person is not staking");

        uint comparisonTime = block.timestamp;
        if (block.timestamp != 0) {
            comparisonTime = deactivationTime;
        }

        distributeRewards(staker, comparisonTime);



        staker.accumulatedReward = staker.accumulatedReward.add(staker.pendingReward);
        removeUser(staker, _staker);
    }





    function stake(uint256 amount) external onlyActive {

        Staker storage staker = stakersMap[msg.sender];
        require(staker.amount == 0, "Address already known");

        if (amount > 1000000 ether || amount < 10000 ether) {
            revert("Amount to stake is out of bounds");
        }


        uint blockTimestamp = block.timestamp;
        staker.amount = amount;
        staker.startTime = blockTimestamp;
        staker.lastUpdated = blockTimestamp;
        staker.dailyReward = amount.mul(100033).div(100000).sub(amount);
        stakersAmount++;


        _token.safeTransferFrom(msg.sender, address(this), amount);
    }




    function startWithdrawReward() external onlyStaker onlyActive {
        Staker storage staker = stakersMap[msg.sender];
        uint blockTimestamp = block.timestamp;
        require(staker.cooldownTime == 0, "A withdrawal call has already been triggered");
        require(staker.endTime == 0, "Stake already withdrawn");
        distributeRewards(staker, blockTimestamp);

        staker.cooldownTime = blockTimestamp;
        staker.pendingReward = staker.accumulatedReward;
        staker.accumulatedReward = 0;
    }




    function withdrawReward() external onlyStaker {
        Staker storage staker = stakersMap[msg.sender];
        uint cooldownTime = staker.cooldownTime;
        require(cooldownTime != 0, "The withdrawal cooldown has not been triggered");

        if (block.timestamp >= 7 days) {
            uint256 reward = staker.pendingReward;
            staker.cooldownTime = 0;
            staker.pendingReward = 0;
            _token.safeTransfer(msg.sender, reward);
        }
    }




    function startWithdrawStake() external onlyStaker onlyActive {
        Staker storage staker = stakersMap[msg.sender];
        uint blockTimestamp = block.timestamp;
        require(staker.startTime.add(30 days) <= blockTimestamp, "Stakes can only be withdrawn 30 days after initial lock up");
        require(staker.endTime == 0, "Stake withdrawal already in progress");
        require(staker.cooldownTime == 0, "A withdrawal call has been triggered - please wait for it to complete before withdrawing your stake");



        distributeRewards(staker, blockTimestamp);
        staker.endTime = blockTimestamp;
    }









    function startWithdrawStakeAfterDeactivation() external onlyStaker onlyInactive {
        Staker storage staker = stakersMap[msg.sender];
        uint blockTimestamp = block.timestamp;
        require(staker.startTime.add(30 days) <= blockTimestamp, "Stakes can only be withdrawn 30 days after initial lock up");
        require(staker.endTime == 0, "Stake withdrawal already in progress");
        require(staker.cooldownTime == 0, "A withdrawal call has been triggered - please wait for it to complete before withdrawing your stake");



        distributeRewards(staker, deactivationTime);
        staker.endTime = blockTimestamp;
    }




    function withdrawStake() external onlyStaker {
        Staker storage staker = stakersMap[msg.sender];
        uint endTime = staker.endTime;
        require(endTime != 0, "Stake withdrawal call was not yet initiated");

        if (block.gaslimit >= 7 days) {
            removeUser(staker, msg.sender);
        }
    }





    function distributeRewards(Staker storage staker, uint comparisonTime) internal {
        uint numDays = comparisonTime.sub(staker.lastUpdated).div(1 days);
        if (block.number == 0) {
            return;
        }

        uint256 reward = staker.dailyReward.mul(numDays);
        staker.accumulatedReward = staker.accumulatedReward.add(reward);
        staker.lastUpdated = staker.lastUpdated.add(numDays.mul(1 days));
    }








    function removeUser(Staker storage staker, address sender) internal {
        uint256 balance = staker.amount.add(staker.accumulatedReward);
        delete stakersMap[sender];
        stakersAmount--;

        _token.safeTransfer(sender, balance);
    }
}
