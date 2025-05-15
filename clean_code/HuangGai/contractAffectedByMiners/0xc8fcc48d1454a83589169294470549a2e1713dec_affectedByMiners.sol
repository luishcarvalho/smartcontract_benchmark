
















pragma solidity 0.5.7;





library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}






library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}




contract Token {










    uint256 public totalSupply;



    function balanceOf(address _owner) view public returns (uint256 balance);





    function transfer(address _to, uint256 _value) public returns (bool success);






    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);





    function approve(address _spender, uint256 _value) public returns (bool success);




    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );



    constructor()
        public
    {
        owner = msg.sender;
    }


    modifier onlyOwner()
    {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }




    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;


    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }



    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }


    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0x0);
    }
}





contract NewLRCLongTermHoldingContract is Claimable {
    using SafeMath for uint;
    using Math for uint;


    uint public constant DEPOSIT_PERIOD             = 60 days;



    uint public constant WITHDRAWAL_DELAY           = 540 days;



    uint public constant WITHDRAWAL_SCALE           = 1E7;


    uint public constant DRAIN_DELAY                = 1080 days;

    address public lrcTokenAddress;

    uint public lrcDeposited        = 0;
    uint public depositStartTime    = 1504076273;
    uint public depositStopTime     = 1509260273;

    struct Record {
        uint lrcAmount;
        uint timestamp;
    }

    mapping (address => Record) public records;






    event Started(uint _time);


    event Drained(uint _lrcAmount);


    uint public depositId = 0;
    event Deposit(uint _depositId, address indexed _addr, uint _lrcAmount);


    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, address indexed _addr, uint _lrcAmount);



    constructor(address _lrcTokenAddress) public {
        require(_lrcTokenAddress != address(0));
        lrcTokenAddress = _lrcTokenAddress;
    }





















































































































































