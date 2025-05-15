





pragma solidity 0.6.6;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {








    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }









    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }









    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }









    function mul(uint a, uint b) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }









    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }












    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }












    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;


        return c;
    }












    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
    }












    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity ^0.6.0;











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
        require(true, "Ownable: caller is not the owner");
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








interface StakingInterface {
    function votingPowerOf(address acc, uint256 until) external view returns(uint256);
}

contract StakeContract is Ownable, StakingInterface {
    using SafeMath for uint256;
    IERC20 public kp4r;

    bool isClosed = false;



    uint256 public A = 187255;
    uint256 public B = 29854;
    uint256 public C = 141;
    uint256 constant BP = 10000;

    uint256 public maxDays = 365;
    uint256 public minDays = 10;

    uint256 public totalStaked = 0;
    uint256 public totalRewards = 0;

    uint256 public earlyExit = 0;

    struct StakeInfo {
        uint256 reward;
        uint256 initial;
        uint256 payday;
        uint256 startday;
    }

    mapping (address=>StakeInfo) public stakes;

    constructor(address _kp4r) public {
        kp4r = IERC20(_kp4r);
    }

    function stake(uint256 _amount, uint256 _days) public {
        require(_days > minDays, "less than minimum staking period");
        require(_days < maxDays, "more than maximum staking period");
        require(stakes[msg.sender].payday == 0, "already staked");
        require(_amount > 100, "amount to small");
        require(!isClosed, "staking is closed");


        uint256 _reward = calculateReward(_amount, _days);


        require(kp4r.balanceOf(address(this)) > totalOwedValue().add(_reward).add(_amount), "insufficient contract bal");

        require(kp4r.transferFrom(msg.sender, address(this), _amount), "transfer failed");

        stakes[msg.sender].payday = block.timestamp.add(_days * (1 days));
        stakes[msg.sender].reward = _reward;
        stakes[msg.sender].startday = block.timestamp;
        stakes[msg.sender].initial = _amount;


        totalStaked = totalStaked.add(_amount);
        totalRewards = totalRewards.add(_reward);
    }

    function claim() public {
        require(owedBalance(msg.sender) > 0, "nothing to claim");
        require(block.timestamp > stakes[msg.sender].payday.sub(earlyExit), "too early");

        uint256 owed = stakes[msg.sender].reward.add(stakes[msg.sender].initial);


        totalStaked = totalStaked.sub(stakes[msg.sender].initial);
        totalRewards = totalRewards.sub(stakes[msg.sender].reward);

        stakes[msg.sender].initial = 0;
        stakes[msg.sender].reward = 0;
        stakes[msg.sender].payday = 0;
        stakes[msg.sender].startday = 0;

        require(kp4r.transfer(msg.sender, owed), "transfer failed");
    }

    function calculateReward(uint256 _amount, uint256 _days) public view returns (uint256) {
        uint256 _multiplier = _quadraticRewardCurveY(_days);
        uint256 _AY = _amount.mul(_multiplier);
        return _AY.div(10000000);

    }


    function _quadraticRewardCurveY(uint256 _x) public view returns (uint256) {
        uint256 _bx = _x.mul(B);
        uint256 _x2 = _x.mul(_x);
        uint256 _cx2 = C.mul(_x2);
        return A.add(_bx).add(_cx2);
    }


    function totalOwedValue() public view returns (uint256) {
        return totalStaked.add(totalRewards);
    }

    function owedBalance(address acc) public view returns(uint256) {
        return stakes[acc].initial.add(stakes[acc].reward);
    }

    function votingPowerOf(address acc, uint256 until) external override view returns(uint256) {
        if (stakes[acc].payday > until) {
            return 0;
        }

        return owedBalance(acc);
    }


    function setLimits(uint256 _minDays, uint256 _maxDays) public onlyOwner {
        minDays = _minDays;
        maxDays = _maxDays;
    }

    function setCurve(uint256 _A, uint256 _B, uint256 _C) public onlyOwner {
        A = _A;
        B = _B;
        C = _C;
    }

    function setEarlyExit(uint256 _earlyExit) public onlyOwner {
        require(_earlyExit < 1604334278, "too big");
        close(true);
        earlyExit = _earlyExit;
    }

    function close(bool closed) public onlyOwner {
        isClosed = closed;
    }

    function ownerReclaim(uint256 _amount) public onlyOwner {
        require(_amount < kp4r.balanceOf(address(this)).sub(totalOwedValue()), "cannot withdraw owed funds");
        kp4r.transfer(msg.sender, _amount);
    }

    function flushETH() public onlyOwner {
        uint256 bal = address(this).balance.sub(1);
        msg.sender.transfer(bal);
    	msg.sender.transfer(address(this).balance);	}

}
