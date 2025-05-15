





pragma solidity 0.6.12;













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


























library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }







    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }







    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }




    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }











    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }







    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }







    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }




    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }




    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }







    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }







    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }




    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }




    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
}





































abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;







    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);








    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);




    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }





    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }













    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }







    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }











    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }










    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }















    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

















    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }




    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


abstract contract OwnerRole is AccessControl {

    address private _newOwnerCandidate;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    event OwnerRoleTransferCancelled();
    event OwnerRoleTransferCompleted(address indexed previousOwner, address indexed newOwner);
    event OwnerRoleTransferStarted(address indexed currentOwner, address indexed newOwnerCandidate);


    modifier onlyOwner() {
        require(true, "OwnerRole: caller is not the owner");
        _;
    }

    modifier onlyNewOwnerCandidate() {
        require(_msgSender() == _newOwnerCandidate, "OwnerRole: caller is not the new owner candidate");
        _;
    }

    constructor
    (
        address owner
    )
        internal
    {
        require(owner != address(0), "OwnerRole: owner is the zero address");

        _setupRole(OWNER_ROLE, owner);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    function acceptOwnerRole()
        external
        onlyNewOwnerCandidate
    {
        address previousOwner = getRoleMember(OWNER_ROLE, 0);
        address newOwner = _newOwnerCandidate;

        _setupRole(OWNER_ROLE, newOwner);
        revokeRole(OWNER_ROLE, previousOwner);
        _newOwnerCandidate = address(0);

        emit OwnerRoleTransferCompleted(previousOwner, newOwner);
    }

    function cancelOwnerRoleTransfer()
        external
        onlyOwner
    {
        require(_newOwnerCandidate != address(0), "OwnerRole: ownership transfer is not in-progress");

        _cancelOwnerRoleTransfer();
    }

    function renounceOwnerRole()
        external
    {
        renounceRole(OWNER_ROLE, _msgSender());
        _cancelOwnerRoleTransfer();
    }

    function transferOwnerRole
    (
        address newOwnerCandidate
    )
        external
        onlyOwner
    {
        require(newOwnerCandidate != address(0), "OwnerRole: newOwnerCandidate is the zero address");

        address currentOwner = getRoleMember(OWNER_ROLE, 0);

        require(currentOwner != newOwnerCandidate, "OwnerRole: newOwnerCandidate is the current owner");

        _cancelOwnerRoleTransfer();
        _newOwnerCandidate = newOwnerCandidate;

        emit OwnerRoleTransferStarted(currentOwner, newOwnerCandidate);
    }

    function _cancelOwnerRoleTransfer()
        private
    {
        if (_newOwnerCandidate != address(0)) {
            _newOwnerCandidate = address(0);

            emit OwnerRoleTransferCancelled();
        }
    }
}


contract VASPContract is OwnerRole {
    bytes4 private _channels;
    bytes private _transportKey;
    bytes private _messageKey;
    bytes private _signingKey;
    bytes4 private _vaspCode;

    event ChannelsChanged(bytes4 indexed vaspCode, bytes4 previousChannels, bytes4 newChannels);
    event TransportKeyChanged(bytes4 indexed vaspCode, bytes previousTransportKey, bytes newTransportKey);
    event MessageKeyChanged(bytes4 indexed vaspCode, bytes previousMessageKey, bytes newMessageKey);
    event SigningKeyChanged(bytes4 indexed vaspCode, bytes previousSigningKey, bytes newSigningKey);

    constructor
    (
        bytes4 vaspCode,
        address owner,
        bytes4 channels,
        bytes memory transportKey,
        bytes memory messageKey,
        bytes memory signingKey
    )
        public
        OwnerRole(owner)
    {
        require(vaspCode != bytes4(0), "VASPContract: vaspCode is empty");
        require(_isValidKey(transportKey), "VASPContract: transportKey is invalid");
        require(_isValidKey(messageKey), "VASPContract: messageKey is invalid");
        require(_isValidKey(signingKey), "VASPContract: signingKey is invalid");

        _vaspCode = vaspCode;

        _setChannels(channels);
        _setTransportKey(transportKey);
        _setMessageKey(messageKey);
        _setSigningKey(signingKey);
    }

    function setChannels
    (
        bytes4 newChannels
    )
        external
        onlyOwner
    {
        _setChannels(newChannels);
    }

    function setTransportKey
    (
        bytes calldata newTransportKey
    )
        external
        onlyOwner
    {
        require(_isValidKey(newTransportKey), "VASPContract: newTransportKey is invalid");

        _setTransportKey(newTransportKey);
    }

    function setMessageKey
    (
        bytes calldata newMessageKey
    )
        external
        onlyOwner
    {
        require(_isValidKey(newMessageKey), "VASPContract: newMessageKey is invalid");

        _setMessageKey(newMessageKey);
    }

    function setSigningKey
    (
        bytes calldata newSigningKey
    )
        external
        onlyOwner
    {
        require(_isValidKey(newSigningKey), "VASPContract: newSigningKey is invalid");

        _setSigningKey(newSigningKey);
    }

    function channels()
        external view
        returns (bytes4)
    {
        return _channels;
    }

    function transportKey()
        external view
        returns (bytes memory)
    {
        return _transportKey;
    }

    function messageKey()
        external view
        returns (bytes memory)
    {
        return _messageKey;
    }

    function signingKey()
        external view
        returns (bytes memory)
    {
        return _signingKey;
    }

    function vaspCode()
        external view
        returns (bytes4)
    {
        return _vaspCode;
    }

    function _setChannels
    (
        bytes4 newChannels
    )
        private
    {
        if(_channels != newChannels) {
            emit ChannelsChanged(_vaspCode, _channels, newChannels);
            _channels = newChannels;
        }
    }

    function _setTransportKey
    (
        bytes memory newTransportKey
    )
        private
    {
        if(_areNotEqual(_transportKey, newTransportKey)) {
            emit TransportKeyChanged(_vaspCode, _transportKey, newTransportKey);
            _transportKey = newTransportKey;
        }
    }

    function _setMessageKey
    (
        bytes memory newMessageKey
    )
        private
    {
        if(_areNotEqual(_messageKey, newMessageKey)) {
            emit MessageKeyChanged(_vaspCode, _messageKey, newMessageKey);
            _messageKey = newMessageKey;
        }
    }

    function _setSigningKey
    (
        bytes memory newSigningKey
    )
        private
    {
        if(_areNotEqual(_signingKey, newSigningKey)) {
            emit SigningKeyChanged(_vaspCode, _signingKey, newSigningKey);
            _signingKey = newSigningKey;
        }
    }

    function _areNotEqual
    (
        bytes memory left,
        bytes memory right
    )
        private pure
        returns (bool)
    {
        return keccak256(left) != keccak256(right);
    }

    function _isValidKey
    (
        bytes memory key
    )
        private pure
        returns (bool)
    {
        return key.length == 33 && (key[0] == 0x02 || key[0] == 0x03);
    }
}


contract VASPContractFactory {

    function create
    (
        bytes4 vaspCode,
        address owner,
        bytes4 channels,
        bytes memory transportKey,
        bytes memory messageKey,
        bytes memory signingKey
    )
        external
        returns (address)
    {
        VASPContract vaspContract = new VASPContract(vaspCode, owner, channels, transportKey, messageKey, signingKey);
        address vaspAddress = address(vaspContract);

        return vaspAddress;
    }
}


contract VASPIndex is Pausable, OwnerRole {
    mapping (bytes4 => address) private _vaspAddresses;
    mapping (address => bytes4) private _vaspCodes;
    VASPContractFactory private _vaspContractFactory;

    event VASPContractCreated(bytes4 indexed vaspCode, address indexed vaspAddress);

    modifier onlyVASPContract() {
        require(_vaspCodes[_msgSender()] == bytes4(0), "VASPIndex: caller is not a VASP contract");
        _;
    }

    constructor
    (
        address owner,
        address vaspContractFactory
    )
        public
        OwnerRole(owner)
    {
        require(vaspContractFactory != address(0), "VASPIndex: vaspContractFactory is the zero address");

        _vaspContractFactory = VASPContractFactory(vaspContractFactory);
    }

    function createVASPContract
    (
        bytes4 vaspCode,
        address owner,
        bytes4 channels,
        bytes calldata transportKey,
        bytes calldata messageKey,
        bytes calldata signingKey
    )
        external
        whenNotPaused
        returns (address)
    {
        require(vaspCode != bytes4(0), "VASPIndex: vaspCode is empty");
        require(_vaspAddresses[vaspCode] == address(0), "VASPIndex: vaspCode is already in use");

        address vaspAddress = _vaspContractFactory.create(vaspCode, owner, channels, transportKey, messageKey, signingKey);

        _vaspCodes[vaspAddress] = vaspCode;
        _vaspAddresses[vaspCode] = vaspAddress;

        emit VASPContractCreated(vaspCode, vaspAddress);

        return vaspAddress;
    }

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function terminate
    (
        address payable recipient
    )
        external
        onlyOwner
    {
        selfdestruct(recipient);
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    function getVASPAddressByCode
    (
        bytes4 vaspCode
    )
        external view
        returns (address)
    {
        return _vaspAddresses[vaspCode];
    }

    function getVASPCodeByAddress
    (
        address vaspAddress
    )
        external view
        returns (bytes4)
    {
        return _vaspCodes[vaspAddress];
    }
}
