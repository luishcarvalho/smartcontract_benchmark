pragma solidity 0.7.6;



import "../interface/RocketStorageInterface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";




contract RocketStorage is RocketStorageInterface {


    event NodeWithdrawalAddressSet(address indexed node, address indexed withdrawalAddress, uint256 time);
    event GuardianChanged(address oldGuardian, address newGuardian);


    using SafeMath for uint256;


    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => bytes)      private bytesStorage;


    mapping(address => address)    private withdrawalAddresses;
    mapping(address => address)    private pendingWithdrawalAddresses;


    address guardian;
    address newGuardian;


    bool storageInit = false;


    modifier onlyLatestRocketNetworkContract() {
        if (storageInit == true) {

            require(_getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        } else {



            require((
                _getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))) || tx.origin == guardian
            ), "Invalid or outdated network contract attempting access during deployment");
        }
        _;
    }



    constructor() {

        guardian = msg.sender;
    }


    function getGuardian() external override view returns (address) {
        return guardian;
    }


    function setGuardian(address _newAddress) external override {

        require(msg.sender == guardian, "Is not guardian account");

        newGuardian = _newAddress;
    }


    function confirmGuardian() external override {

        require(msg.sender == newGuardian, "Confirmation must come from new guardian address");

        address oldGuardian = guardian;

        guardian = newGuardian;
        delete newGuardian;

        emit GuardianChanged(oldGuardian, guardian);
    }


    function getDeployedStatus() external view returns (bool) {
        return storageInit;
    }


    function setDeployedStatus() external {

        require(msg.sender == guardian, "Is not guardian account");

        storageInit = true;
    }




    function getNodeWithdrawalAddress(address _nodeAddress) public override view returns (address) {

        if (!_getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress)))) {
            return address(0);
        }

        address withdrawalAddress = withdrawalAddresses[_nodeAddress];
        if (withdrawalAddress == address(0)) {
            return _nodeAddress;
        }
        return withdrawalAddress;
    }


    function getNodePendingWithdrawalAddress(address _nodeAddress) external override view returns (address) {
        return pendingWithdrawalAddresses[_nodeAddress];
    }


    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external override {

        require(_newWithdrawalAddress != address(0x0), "Invalid withdrawal address");

        address withdrawalAddress = getNodeWithdrawalAddress(_nodeAddress);
        require(withdrawalAddress == msg.sender, "Only a tx from a node's withdrawal address can update it");

        if (_confirm) {
            updateWithdrawalAddress(_nodeAddress, _newWithdrawalAddress);
        }

        else {
            pendingWithdrawalAddresses[_nodeAddress] = _newWithdrawalAddress;
        }
    }


    function confirmWithdrawalAddress(address _nodeAddress) external override {

        require(pendingWithdrawalAddresses[_nodeAddress] == msg.sender, "Confirmation must come from the pending withdrawal address");
        delete pendingWithdrawalAddresses[_nodeAddress];

        updateWithdrawalAddress(_nodeAddress, msg.sender);
    }


    function updateWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress) private {

        withdrawalAddresses[_nodeAddress] = _newWithdrawalAddress;

        emit NodeWithdrawalAddressSet(_nodeAddress, _newWithdrawalAddress, block.timestamp);
    }


    function getAddress(bytes32 _key) override external view returns (address r) {
        assembly {
            r := sload (_key)
        }
    }


    function getUint(bytes32 _key) override external view returns (uint256 r) {
        assembly {
            r := sload (_key)
        }
    }


    function getString(bytes32 _key) override external view returns (string memory) {
        return stringStorage[_key];
    }


    function getBytes(bytes32 _key) override external view returns (bytes memory) {
        return bytesStorage[_key];
    }


    function getBool(bytes32 _key) override external view returns (bool r) {
        assembly {
            r := sload (_key)
        }
    }


    function getInt(bytes32 _key) override external view returns (int r) {
        assembly {
            r := sload (_key)
        }
    }


    function getBytes32(bytes32 _key) override external view returns (bytes32 r) {
        assembly {
            r := sload (_key)
        }
    }



    function setAddress(bytes32 _key, address _value) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, _value)
        }
    }



    function setUint(bytes32 _key, uint _value) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, _value)
        }
    }


    function setString(bytes32 _key, string calldata _value) onlyLatestRocketNetworkContract override external {
        stringStorage[_key] = _value;
    }


    function setBytes(bytes32 _key, bytes calldata _value) onlyLatestRocketNetworkContract override external {
        bytesStorage[_key] = _value;
    }


    function setBool(bytes32 _key, bool _value) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, _value)
        }
    }



    function setInt(bytes32 _key, int _value) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, _value)
        }
    }


    function setBytes32(bytes32 _key, bytes32 _value) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, _value)
        }
    }



    function deleteAddress(bytes32 _key) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, 0)
        }
    }


    function deleteUint(bytes32 _key) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, 0)
        }
    }


    function deleteString(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete stringStorage[_key];
    }


    function deleteBytes(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete bytesStorage[_key];
    }


    function deleteBool(bytes32 _key) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, 0)
        }
    }


    function deleteInt(bytes32 _key) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, 0)
        }
    }


    function deleteBytes32(bytes32 _key) onlyLatestRocketNetworkContract override external {
        assembly {
            sstore (_key, 0)
        }
    }




    function addUint(bytes32 _key, uint256 _amount) onlyLatestRocketNetworkContract override external {
        uint256 a;
        uint256 b;
        assembly {
            a := sload (_key)
            b := add(a, _amount)
            sstore (_key, b)
        }
        require(b >= a, "SafeMath: addition overflow");
    }



    function subUint(bytes32 _key, uint256 _amount) onlyLatestRocketNetworkContract override external {
        uint256 a;
        assembly {
            a := sload (_key)
        }
        require(_amount <= a, "SafeMath: subtraction overflow");
        assembly {
            a := sub(a, _amount)
            sstore (_key, a)
        }
    }



    function _getBool(bytes32 _key) private view returns (bool r) {
        assembly {
            r := sload (_key)
        }
    }

    function _setBool(bytes32 _key, bool _value) private {
        assembly {
            sstore (_key, _value)
        }
    }
}
