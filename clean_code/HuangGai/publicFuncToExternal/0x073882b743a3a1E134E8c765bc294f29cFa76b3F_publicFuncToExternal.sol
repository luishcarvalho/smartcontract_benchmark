




pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


contract LnAdmin {
    address public admin;
    address public candidate;

    constructor(address _admin) public {
        require(_admin != address(0), "admin address cannot be 0");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) public onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit candidateChanged( old, candidate);
    }

    function becomeAdmin( ) public {
        require( msg.sender == candidate, "Only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged( old, admin );
    }

    modifier onlyAdmin {
        require( (msg.sender == admin), "Only the contract admin can perform this action");
        _;
    }

    event candidateChanged(address oldCandidate, address newCandidate );
    event AdminChanged(address oldAdmin, address newAdmin);
}




contract LnTokenLocker is LnAdmin, Pausable {
    using SafeMath for uint;

    IERC20 private token;
    struct LockInfo {
        uint256 amount;
        uint256 lockTimestamp;
        uint256 lockDays;
        uint256 claimedAmount;
    }
    mapping (address => LockInfo) public lockData;

    constructor(address _token, address _admin) public LnAdmin(_admin) {
        token = IERC20(_token);
    }

    function sendLockTokenMany(address[] calldata _users, uint256[] calldata _amounts, uint256[] calldata _lockdays) external onlyAdmin {
        require(_users.length == _amounts.length, "array length not eq");
        require(_users.length == _lockdays.length, "array length not eq");
        for (uint256 i=0; i < _users.length; i++) {
            sendLockToken(_users[i], _amounts[i], _lockdays[i]);
        }
    }


    function sendLockToken(address _user, uint256 _amount, uint256 _lockdays) public onlyAdmin returns (bool) {
        require(_amount > 0, "amount can not zero");
        require(lockData[_user].amount == 0, "this address has locked");
        require(_lockdays > 0, "lock days need more than zero");

        LockInfo memory lockinfo = LockInfo({
            amount:_amount,
            lockTimestamp:block.timestamp,
            lockDays:_lockdays,
            claimedAmount:0
        });

        lockData[_user] = lockinfo;
        return true;
    }

    function claimToken(uint256 _amount) public returns (uint256) {
        require(_amount > 0, "Invalid parameter amount");
        address _user = msg.sender;
        require(lockData[_user].amount > 0, "No lock token to claim");

        uint256 passdays = block.timestamp.sub(lockData[_user].lockTimestamp).div(1 days);
        require(passdays > 0, "need wait for one day at least");

        uint256 available = 0;
        if (passdays >= lockData[_user].lockDays) {
            available = lockData[_user].amount;
        } else {
            available = lockData[_user].amount.div(lockData[_user].lockDays).mul(passdays);
        }
        available = available.sub(lockData[_user].claimedAmount);
        require(available > 0, "not available claim");

        uint256 claim = _amount;
        if (_amount > available) {
            claim = available;
        }

        lockData[_user].claimedAmount = lockData[_user].claimedAmount.add(claim);

        token.transfer(_user, claim);

        return claim;
    }
}



contract LnTokenCliffLocker is LnAdmin, Pausable {
    using SafeMath for uint;

    IERC20 private token;
    struct LockInfo {
        uint256 amount;
        uint256 lockTimestamp;
        uint256 claimedAmount;
    }
    mapping (address => LockInfo) public lockData;

    constructor(address _token, address _admin) public LnAdmin(_admin) {
        token = IERC20(_token);
    }

    function sendLockTokenMany(address[] calldata _users, uint256[] calldata _amounts, uint256[] calldata _locktimes) external onlyAdmin {
        require(_users.length == _amounts.length, "array length not eq");
        require(_users.length == _locktimes.length, "array length not eq");
        for (uint256 i=0; i < _users.length; i++) {
            sendLockToken(_users[i], _amounts[i], _locktimes[i]);
        }
    }

    function avaible(address _user ) public view returns( uint256 ){
        require(lockData[_user].amount > 0, "No lock token to claim");
        if( now < lockData[_user].lockTimestamp ){
            return 0;
        }

        uint256 available = 0;
        available = lockData[_user].amount;
        available = available.sub(lockData[_user].claimedAmount);
        return available;
    }


    function sendLockToken(address _user, uint256 _amount, uint256 _locktimes ) public onlyAdmin returns (bool) {
        require(_amount > 0, "amount can not zero");
        require(lockData[_user].amount == 0, "this address has locked");
        require(_locktimes > 0, "lock days need more than zero");

        LockInfo memory lockinfo = LockInfo({
            amount:_amount,
            lockTimestamp:_locktimes,
            claimedAmount:0
        });

        lockData[_user] = lockinfo;
        return true;
    }

    function claimToken(uint256 _amount) public returns (uint256) {
        require(_amount > 0, "Invalid parameter amount");
        address _user = msg.sender;
        require(lockData[_user].amount > 0, "No lock token to claim");
        require( now >= lockData[_user].lockTimestamp, "Not time to claim" );

        uint256 available = 0;
        available = lockData[_user].amount;
        available = available.sub(lockData[_user].claimedAmount);
        require(available > 0, "not available claim");

        uint256 claim = _amount;
        if (_amount > available) {
            claim = available;
        }

        lockData[_user].claimedAmount = lockData[_user].claimedAmount.add(claim);

        token.transfer(_user, claim);

        return claim;
    }
}
