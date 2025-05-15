







pragma solidity 0.6.2;













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
        if (block.gaslimit > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}







contract UniLendTokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private UniLendToken;
    uint256 private tokensToVest;
    uint256 public vestingId;

    string private constant INSUFFICIENT_BALANCE = "Insufficient balance";
    string private constant INVALID_VESTING_ID = "Invalid vesting id";
    string private constant VESTING_ALREADY_RELEASED = "Vesting already released";
    string private constant INVALID_BENEFICIARY = "Invalid beneficiary address";
    string private constant NOT_VESTED = "Tokens have not vested yet";

    struct Vesting {
        uint256 releaseTime;
        uint256 amount;
        address beneficiary;
        bool released;
    }
    mapping(uint256 => Vesting) public vestings;

    event TokenVestingReleased(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingAdded(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);
    event TokenVestingRemoved(uint256 indexed vestingId, address indexed beneficiary, uint256 amount);

    constructor(IERC20 _token) public {
        require(address(_token) != address(0x0), "UniLendToken address is not valid");
        address unlockAddress = 0x6874fF15B5116A4C0552e70fE4d1Ed293E5F5B14;
        UniLendToken = _token;
        uint256 SCALING_FACTOR = 10 ** 18;
        uint256 day = 1 days;


        addVesting(unlockAddress, now + 30 * day, 3940000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 60 * day, 3190000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 90 * day, 7627500 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 120 * day, 2627500 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 150 * day, 2627500 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 180 * day, 13127500 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 210 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 240 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 270 * day, 6315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 300 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 330 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 360 * day, 6815000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 390 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 420 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 450 * day, 3815000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 480 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 510 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 540 * day, 6815000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 570 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 600 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 630 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 660 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 690 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 720 * day, 4315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 750 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 780 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 810 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 840 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 870 * day, 1315000 * SCALING_FACTOR);
        addVesting(unlockAddress, now + 900 * day, 4315000 * SCALING_FACTOR);
    }





    function token() public view returns (IERC20) {
        return UniLendToken;
    }






    function beneficiary(uint256 _vestingId) public view returns (address) {
        return vestings[_vestingId].beneficiary;
    }






    function releaseTime(uint256 _vestingId) public view returns (uint256) {
        return vestings[_vestingId].releaseTime;
    }






    function vestingAmount(uint256 _vestingId) public view returns (uint256) {
        return vestings[_vestingId].amount;
    }





    function removeVesting(uint256 _vestingId) public onlyOwner {
        Vesting storage vesting = vestings[_vestingId];
        require(vesting.beneficiary != address(0x0), INVALID_VESTING_ID);
        require(!vesting.released , VESTING_ALREADY_RELEASED);
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        emit TokenVestingRemoved(_vestingId, vesting.beneficiary, vesting.amount);
    }








    function addVesting(address _beneficiary, uint256 _releaseTime, uint256 _amount) public onlyOwner {
        require(_beneficiary != address(0x0), INVALID_BENEFICIARY);
        require(_releaseTime > now, "Invalid release time");
        require(_amount != 0, "Amount must be greater then 0");
        tokensToVest = tokensToVest.add(_amount);
        vestingId = vestingId.add(1);
        vestings[vestingId] = Vesting({
            beneficiary: _beneficiary,
            releaseTime: _releaseTime,
            amount: _amount,
            released: false
        });
        emit TokenVestingAdded(vestingId, _beneficiary, _amount);
    }





    function release(uint256 _vestingId) public {
        Vesting storage vesting = vestings[_vestingId];
        require(vesting.beneficiary != address(0x0), INVALID_VESTING_ID);
        require(!vesting.released , VESTING_ALREADY_RELEASED);

        require(block.timestamp >= vesting.releaseTime, NOT_VESTED);

        require(UniLendToken.balanceOf(address(this)) >= vesting.amount, INSUFFICIENT_BALANCE);
        vesting.released = true;
        tokensToVest = tokensToVest.sub(vesting.amount);
        UniLendToken.safeTransfer(vesting.beneficiary, vesting.amount);
        emit TokenVestingReleased(_vestingId, vesting.beneficiary, vesting.amount);
    }





    function retrieveExcessTokens(uint256 _amount) public onlyOwner {
        require(_amount <= UniLendToken.balanceOf(address(this)).sub(tokensToVest), INSUFFICIENT_BALANCE);
        UniLendToken.safeTransfer(owner(), _amount);
    }
}
