



pragma solidity 0.5.15;
















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

contract Timelock {
    using SafeMath for uint256;


    event NewAdmin(address indexed newAdmin);

    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);

    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature,  bytes data, uint256 eta);

    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature,  bytes data, uint256 eta);

    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);


    uint256 public constant GRACE_PERIOD = 14 days;

    uint256 public constant MINIMUM_DELAY = 12 hours;

    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;
    bool public admin_initialized;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor()
        public
    {



        admin = msg.sender;
        delay = MINIMUM_DELAY;
        admin_initialized = false;
    }

    function () external payable { }






    function setDelay(uint256 delay_)
        public
    {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }



    function acceptAdmin()
        public
    {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }





    function setPendingAdmin(address pendingAdmin_)
        public
    {

        if (admin_initialized) {
          require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
          require(msg.sender == admin, "Timelock::setPendingAdmin: !init & !admin");
          admin_initialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }


    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    )
        public
        returns (bytes32)
    {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    )
        public
    {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    )
        public
        payable
        returns (bytes memory)
    {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");



        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        if (admin_initialized) {
          require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
          require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
          require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

          queuedTransactions[txHash] = false;
        }


        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }


        (bool success, bytes memory returnData) = (false, bytes(msg.data));
	 target.call.value(value)(callData);

        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {

        return block.timestamp;
    }
}
