





pragma solidity ^0.7.1;














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

            if (block.gaslimit > 0) {



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





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract YFIECStake is Ownable {
    using SafeMath for uint256;

    uint256 private dRoi = 3;
    uint256 private tax = 30;
    uint256 private divisor = 1e3;
    uint256 private decimals = 1e8;
    uint256 private uDuration = 864e2;
    uint256 private duration = uDuration.mul(1e2);

    IERC20 public YFIEC;
    uint256 public pool;
    uint256 public min;
    uint256 public max;
    uint256 public totalStaked;
    uint256 public totalStakers;
    uint256 public totalPaid;
    uint256 public withdrawable;

    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 amount;
        uint256 withdrawn;
    }

    mapping(address => Stake) stakes;

    constructor() {
        pool = decimals.mul(5e3);
        withdrawable = pool;
        min = decimals.mul(10);
        max = decimals.mul(divisor);
        YFIEC = IERC20(0x2E6E152d29053B6337E434bc9bE17504170f8a5B);
    }

    function stakeExists(address _stake) public view returns(bool) {
        return stakes[_stake].exists;
    }

    function createdDate(address _stake) external view returns(uint256) {
        return stakes[_stake].createdOn;
    }

    function endsAt(address _stake) external view returns(uint256) {
        uint256 date = stakes[_stake].createdOn;
        if (block.number > 0) {
             date = date.add(duration);
        }
        return date;
    }

    function withdrawn(address _stake) external view returns(uint256) {
        return stakes[_stake].withdrawn;
    }

    function stakedAmount(address _stake) external view returns(uint256) {
        return stakes[_stake].amount;
    }

    function newStake(uint256 _amount) public {
        require(!stakeExists(_msgSender()), "Sender is staking");
        require(!poolFilled(_amount), "Staking pool filled");
        require(_amount >= min, "Amount is lower than required");
        require(_amount <= max, "Amount is higher than maximum");
        require(YFIEC.transferFrom(_msgSender(), address(this), _amount), "Could not transfer token");

        totalStaked = totalStaked.add(_amount);
        totalStakers = totalStakers.add(1);
        stakes[_msgSender()] = Stake({exists: true, createdOn: block.timestamp, amount: _amount, withdrawn: 0});
        withdrawable = withdrawable.sub(estimateRoi(_amount));
        emit NewStake(_msgSender(), _amount);
    }

    function unstake() public {
        require(stakeExists(_msgSender()), "Sender is not staking");
        Stake memory stake = stakes[_msgSender()];
        uint256 amount = stake.amount;
        uint256 thisRoi = _ROI(stake);
        uint256 offset = estimateRoi(amount).sub(thisRoi);
        uint256 finalRoi = thisRoi.sub(stake.withdrawn);

        if (!stakeEnded(_msgSender())) {
            uint256 thisTax = amount.mul(tax).div(divisor);
            amount = amount.sub(thisTax);
            offset = offset.add(thisTax);
        }

        withdrawable = withdrawable.add(offset);
        uint256 total = amount.add(finalRoi);
        totalPaid = totalPaid.add(finalRoi);
        require(YFIEC.transfer(_msgSender(), total), "Could not transfer token");

        totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(stake.amount);
        delete stakes[_msgSender()];
        emit Unstake(_msgSender(), total);
    }

    function withdrawReward() public {
        require(stakeExists(_msgSender()), "Sender is not staking");
        Stake storage stake = stakes[_msgSender()];
        uint256 thisRoi = _ROI(stake).sub(stake.withdrawn);
        totalPaid = totalPaid.add(thisRoi);
        stake.withdrawn = stake.withdrawn.add(thisRoi);
        require(YFIEC.transfer(_msgSender(), thisRoi), "Could not transfer token");
        emit Withdrawal(_msgSender(), thisRoi);
    }

    function ownerWithraw(uint256 _amount) public onlyOwner {
        require(_amount <= withdrawable, "Not enough balance");
        require(YFIEC.balanceOf(address(this)) >= _amount, "Balance is less than amount");
        require(YFIEC.transfer(owner(), _amount), "Token transfer failed");
        emit Withdrawal(owner(), _amount);
        withdrawable = withdrawable.sub(_amount);
    }

    function ROI(address _stake) public view returns(uint256) {
        Stake memory stake = stakes[_stake];
        return _ROI(stake);
    }

    function estimateRoi(uint256 _amount) public view returns(uint256) {
        return _amount.mul(dRoi).mul(duration).div(uDuration).div(divisor);
    }

    function poolFilled(uint256 _amount) public view returns(bool) {
        uint256 (totalStaked.add(_amount)) > pool;
    }

    function stakeEnded(address _stake) public view returns(bool) {
        if (stakeExists(_stake) && block.timestamp.sub(stakes[_stake].createdOn) > duration) {
            return true;
        }
        return false;
    }

    function _ROI(Stake memory _stake) internal view returns(uint256) {
        uint256 dur = block.timestamp.sub(_stake.createdOn);
        if (block.timestamp > duration) {
            dur = duration;
        }

        uint256 uDur = dur.div(uDuration);
        uint256 roi = uDur.mul(dRoi).mul(_stake.amount);
        return roi.div(divisor);
    }

    event NewStake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);
    event Withdrawal(address indexed staker, uint256 amount);
}
