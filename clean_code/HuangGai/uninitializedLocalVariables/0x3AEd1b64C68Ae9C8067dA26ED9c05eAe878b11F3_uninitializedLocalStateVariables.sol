












pragma solidity >= 0.6.12;

library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

contract SmartWolves {
    using SafeMath for uint;

    uint status;

    uint registrationFee;

    address payable public companyAccount;

    event Enrolled(
        uint8 indexed pool,
        address indexed payerAddress,
        bytes32 indexed username,
        uint amount
    );

    event PayoutSuccess(
        address indexed payee,
        bytes32 indexed username,
        uint amount
    );

    event NewDeposit(
        address indexed payer,
        uint amount
    );

    event CompanyAccountChanged(
        address indexed oldAccount,
        address indexed newAccount
    );

    struct User {
        uint8 pool;
        address paymentAddress;
        bytes32 userName;
    }

    mapping(uint8 => uint) public pools;

    mapping(bytes32 => User) public users;

    constructor(uint _registrationFee) public {
        registrationFee = _registrationFee;
        companyAccount = msg.sender;

        pools[1] = 50000000000000000;
        pools[2] = 200000000000000000;
        pools[3] = 500000000000000000;
        pools[4] = 1000000000000000000;
        pools[5] = 2000000000000000000;
        pools[6] = 5000000000000000000;
        pools[7] = 10000000000000000000;
        pools[8] = 20000000000000000000;
        pools[9] = 30000000000000000000;
        pools[10] = 50000000000000000000;
        pools[11] = 100000000000000000000;
    }

    modifier onlyOwner(){
        require(msg.sender == companyAccount, 'Sorry this can be only by the admin account!');
        _;
    }

    modifier noContract(address _address){
        require(!isContract(_address), 'Payment to a contract is not allowed!');
        _;
    }

    modifier notEnrolledAlready(bytes32 _username){
        require(users[_username].userName != _username, 'You seems have enrolled already!');
        _;
    }

    function enrol(bytes32 _username, uint8 _pool) external payable notEnrolledAlready(_username) {
        require(msg.value >= pools[_pool].add(registrationFee), 'Please send the correct amount!');

        depositAmount(companyAccount, msg.value);

        users[_username] = User(_pool, msg.sender, _username);

        emit Enrolled(_pool, msg.sender, _username, msg.value);
    }

    function withdrawToUserAccount(address _userAddress, bytes32 __userName, uint _amount) external payable onlyOwner noContract(_userAddress) {
        depositAmount(_userAddress, _amount);

        emit PayoutSuccess(_userAddress, __userName, _amount);
    }

    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function depositAmount(address _user, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Address: insufficient balance");


        (bool success,) = _user.call{value : _amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function changeCompanyAccount() external onlyOwner {
        address oldAccount ;

        companyAccount = msg.sender;
        emit CompanyAccountChanged(oldAccount, msg.sender);
    }

    receive() external payable {
        emit NewDeposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit NewDeposit(msg.sender, msg.value);
    }
}
