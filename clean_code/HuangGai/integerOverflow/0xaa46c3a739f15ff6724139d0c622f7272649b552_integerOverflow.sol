





pragma solidity ^0.7.1;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


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

contract YMISSILEStake is Ownable {
    using SafeMath for uint256;

    IERC20 public YMISSILE;
    uint256 public pool;
    uint256 public minimum;
    uint256 public maximum;
    uint256 public totalStaked;
    uint256 public totalStakers;
    uint256 public totalPaid;
    uint256 public withdrawable;

    uint256 private _roi = 1e2;
    uint256 private _tax = 2e3;
    uint256 private _divisor = 1e4;
    uint256 private _decimals = 1e8;
    uint256 private _uDuration = 864e2;
    uint256 private _duration = _uDuration.mul(_roi);
    uint256 private _minDuration = _uDuration.mul(25);

    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 amount;
        uint256 withdrawn;
    }

    mapping(address => Stake) stakes;

    constructor() {
        pool = _decimals.mul(2e3);
        withdrawable = pool;
        minimum = _decimals.mul(20);
        maximum = _decimals.mul(200);
        YMISSILE = IERC20(0x447c76582DdF1d33BAF37FdEC5c74CdD7fe9d2da);
    }

    function stakeExists(address _stake) public view returns(bool) {
        return stakes[_stake].exists;
    }

    function createdDate(address _stake) external view returns(uint256) {
        return stakes[_stake].createdOn;
    }

    function withdrawn(address _stake) external view returns(uint256) {
        return stakes[_stake].withdrawn;
    }

    function stakedAmount(address _stake) external view returns(uint256) {
        return stakes[_stake].amount;
    }

    function newStake(uint256 _amount) public {
        require(!stakeExists(_msgSender()), "Sender is already staking");
        require(!poolFilled(_amount), "Staking pool filled");
        require(_amount >= minimum, "Amount is lower than minimum");
        require(_amount <= maximum, "Amount is higher than maximum");
        require(YMISSILE.transferFrom(_msgSender(), address(this), _amount), "Could not transfer token");

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
        uint256 duration = block.timestamp.sub(stake.createdOn);
        uint256 roi = _ROI(stake);
        uint256 offset = estimateRoi(amount).sub(roi);
        uint256 balance = roi.sub(stake.withdrawn);

        if (duration < _minDuration) {
            uint256 tax = amount.mul(_tax).div(_divisor);
            amount = amount.sub(tax);
            offset = offset.add(tax);
        }

        withdrawable = withdrawable.add(offset);
        uint256 total = amount.add(balance);
        totalPaid = totalPaid.add(balance);
        require(YMISSILE.transfer(_msgSender(), total), "Could not transfer token");

        totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(stake.amount);
        delete stakes[_msgSender()];
        emit Unstake(_msgSender(), total);
    }

    function withdrawReward() public {
        require(stakeExists(_msgSender()), "Sender is not staking");
        Stake storage stake = stakes[_msgSender()];
        uint256 roi = _ROI(stake).sub(stake.withdrawn);
        totalPaid = totalPaid.add(roi);
        stake.withdrawn = stake.withdrawn.add(roi);
        require(YMISSILE.transfer(_msgSender(), roi), "Could not transfer token");
        emit Withdrawal(_msgSender(), roi);
    }

    function ownerWithraw(uint256 _amount) public onlyOwner {
        require(_amount <= withdrawable, "Not enough balance");
        require(YMISSILE.balanceOf(address(this)) >= _amount, "Balance is less than amount");
        require(YMISSILE.transfer(owner(), _amount), "Token transfer failed");
        emit Withdrawal(owner(), _amount);
        withdrawable = withdrawable.sub(_amount);
    }

    function ROI(address _stake) public view returns(uint256) {
        Stake memory stake = stakes[_stake];
        return _ROI(stake);
    }

    function estimateRoi(uint256 _amount) public view returns(uint256) {
        return _amount.mul(_roi).mul(_duration).div(_uDuration).div(_divisor);
    }

    function poolFilled(uint256 _amount) public view returns(bool) {
        uint256 (totalStaked.add(_amount)) > pool;
    }

    function _ROI(Stake memory _stake) internal view returns(uint256) {
        uint256 duration = block.timestamp.sub(_stake.createdOn);
        if (duration > _duration) {
            duration = _duration;
        }
        uint256 uDuration = duration.div(_uDuration);
        uint256 roi = uDuration.mul(_roi).mul(_stake.amount);
        return roi.div(_divisor);
    }

    event NewStake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);
    event Withdrawal(address indexed staker, uint256 amount);
}
