





pragma solidity ^0.7.0;


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

    constructor () {
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






contract Lock is Ownable {
    using SafeMath for uint;
    enum period {
        second,
        minute,
        hour,
        day,
        week,
        month,
        year,
        quarter,
        biannual
    }


    uint epochLength;

    IERC20 private _token;


    address private _beneficiary;

    uint periods;


    uint paymentSize;
    uint paymentsRemaining =0;
    uint startTime =0;
    uint beneficiaryBalance = 0;

    function initialize(address tokenAddress, address beneficiary, uint duration,uint durationMultiple,uint p)  public onlyOwner{
        release();
        require(paymentsRemaining == 0, 'cannot initialize during active vesting schedule');
        require(duration>0 && p>0, 'epoch parameters must be positive');
        _token = IERC20(tokenAddress);
        _beneficiary = beneficiary;
        if(duration<=uint(period.biannual)){

            if(duration == uint(period.second)){
                epochLength = durationMultiple * 1 seconds;
            }else if(duration == uint(period.minute)){
                epochLength = durationMultiple * 1 minutes;
            }
            else if(duration == uint(period.hour)){
                epochLength =  durationMultiple *1 hours;
            }else if(duration == uint(period.day)){
                epochLength =  durationMultiple *1 days;
            }
            else if(duration == uint(period.week)){
                epochLength =  durationMultiple *1 weeks;
            }else if(duration == uint(period.month)){
                epochLength =  durationMultiple *30 days;
            }else if(duration == uint(period.year)){
                epochLength =  durationMultiple *52 weeks;
            }else if(duration == uint(period.quarter)){
                epochLength =  durationMultiple *13 weeks;
            }
            else if(duration == uint(period.biannual)){
                epochLength = 26 weeks;
            }
        }
        else{
                epochLength = duration;
            }
            periods = p;

        emit Initialized(tokenAddress,beneficiary,epochLength,p);
    }

    function deposit (uint amount) public {
         require (_token.transferFrom(msg.sender,address(this),amount),'transfer failed');
         uint balance = _token.balanceOf(address(this));
         if(paymentsRemaining==0)
         {
             paymentsRemaining = periods;
             startTime = block.timestamp;
         }
         paymentSize = balance/paymentsRemaining;
         emit PaymentsUpdatedOnDeposit(paymentSize,startTime,paymentsRemaining);
    }

    function getElapsedReward() public view returns (uint,uint,uint){
         if(epochLength == 0)
            return (0, startTime,paymentsRemaining);
        uint elapsedEpochs = (block.timestamp - startTime)/epochLength;
        if(elapsedEpochs==0)
            return (0, startTime,paymentsRemaining);
        elapsedEpochs = elapsedEpochs>paymentsRemaining?paymentsRemaining:elapsedEpochs;
        uint newStartTime = block.timestamp;
        uint newPaymentsRemaining = paymentsRemaining.sub(elapsedEpochs);
        uint balance  =_token.balanceOf(address(this));
        uint accumulatedFunds = paymentSize.mul(elapsedEpochs);
         return (beneficiaryBalance.add(accumulatedFunds>balance?balance:accumulatedFunds),newStartTime,newPaymentsRemaining);
    }

    function updateBeneficiaryBalance() private {
        (beneficiaryBalance,startTime, paymentsRemaining) = getElapsedReward();
    }

    function changeBeneficiary (address beneficiary) public onlyOwner{
        require (paymentsRemaining == 0, 'TokenTimelock: cannot change beneficiary while token balance positive');
        _beneficiary = beneficiary;
    }



    function beneficiary() public view returns (address) {
        return _beneficiary;
    }




    function release() public {

        require(block.timestamp >= startTime, "TokenTimelock: current time is before release time");
        updateBeneficiaryBalance();
        uint amountToSend = beneficiaryBalance;
        beneficiaryBalance = 0;
        if(amountToSend>0)
            require(_token.transfer(_beneficiary,amountToSend),'release funds failed');
        emit FundsReleasedToBeneficiary(_beneficiary,amountToSend,block.timestamp);
    }

    event PaymentsUpdatedOnDeposit(uint paymentSize,uint startTime, uint paymentsRemaining);
    event Initialized (address tokenAddress, address beneficiary, uint duration,uint periods);
    event FundsReleasedToBeneficiary(address beneficiary, uint value, uint timeStamp);
}
