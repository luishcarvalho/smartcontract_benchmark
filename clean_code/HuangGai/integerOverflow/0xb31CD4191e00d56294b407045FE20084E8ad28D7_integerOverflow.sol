



pragma solidity ^0.6.2;

interface IDotTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

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

contract Context {


    constructor () internal { }

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






contract DotxVesting is Ownable {

    using SafeMath for uint256;

    event TokensReleased(address token, uint256 amount);


    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    mapping (address => uint256) private _released;

    IDotTokenContract private dotxToken;
    address private tokenAddress;










    constructor(address dotxTokenAddress, uint256 start, uint256 cliffDuration, uint256 duration) public {
        dotxToken = IDotTokenContract(dotxTokenAddress);
        tokenAddress = dotxTokenAddress;

        start = start == 0 ? now : start;


        require(cliffDuration <= duration, "TokenVesting: cliff is longer than duration");
        require(duration > 0, "TokenVesting: duration is 0");

        require(start.add(duration) > block.timestamp, "TokenVesting: final time is before current time");

        _duration = duration;
        _cliff = start.add(cliffDuration);

        _start = start;
    }





    function beneficiary() public view returns (address) {
        return owner();
    }




    function cliff() public view returns (uint256) {
        return _cliff;
    }




    function start() public view returns (uint256) {
        return _start;
    }




    function duration() public view returns (uint256) {
        return _duration;
    }




    function released() public view returns (uint256) {
        return _released[tokenAddress];
    }




    function release() public onlyOwner {
        uint256 unreleased = releasableAmount();

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[address(tokenAddress)] = _released[address(tokenAddress)].add(unreleased);

        dotxToken.transfer(owner(), unreleased);

        emit TokensReleased(address(tokenAddress), unreleased);
    }




    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(_released[address(tokenAddress)]);
    }




    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = dotxToken.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(tokenAddress)]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }

    function getRemainingSeconds() public view returns(uint256){
        return _start.add(_duration).sub(block.timestamp);
    }

    function getRemainingDays() public view returns(uint256){
        return _start.add(_duration).sub(block.timestamp).div(86400);
    }

    function getCurrentBalance() public view returns(uint256){
        return dotxToken.balanceOf(address(this));
    }
}
