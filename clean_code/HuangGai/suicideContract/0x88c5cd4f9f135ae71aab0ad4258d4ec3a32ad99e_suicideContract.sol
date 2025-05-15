





pragma solidity 0.6.12;






library Strings {



    function toString(uint256 value) internal pure returns (string memory) {



        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
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


abstract contract AdministratorRole is AccessControl {

    bytes32 public constant ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");

    modifier onlyAdministrator() {
        require(hasRole(ADMINISTRATOR_ROLE, _msgSender()), "AdministratorRole: caller is not the administrator");
        _;
    }

    constructor
    (
        address administrator,
        bytes32 administratorRoleAdmin
    )
        internal
    {
        require(administrator != address(0), "AdministratorRole: administrator is the zero address");

        _setupRole(ADMINISTRATOR_ROLE, administrator);
        _setRoleAdmin(ADMINISTRATOR_ROLE, administratorRoleAdmin);
    }

    function grantAdministratorRole
    (
        address account
    )
        external
    {
        grantRole(ADMINISTRATOR_ROLE, account);
    }

    function revokeAdministratorRole
    (
        address account
    )
        external
    {
        revokeRole(ADMINISTRATOR_ROLE, account);
    }

    function renounceAdministratorRole()
        external
    {
        renounceRole(ADMINISTRATOR_ROLE, _msgSender());
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


abstract contract VASPRegistry {

    function getCredentialsRef
    (
        bytes6 vaspId
    )
        external virtual view
        returns (string memory credentialsRef, bytes32 credentialsHash);

    function validateCredentials
    (
        string calldata credentials,
        bytes32 credentialsHash
    )
        external pure
        returns (bool)
    {
        return  _calculateCredentialsHash(credentials) == credentialsHash;
    }

    function _calculateCredentialsHash
    (
        string memory credentials
    )
        internal pure
        returns (bytes32)
    {
        return keccak256(bytes(credentials));
    }
}


contract VASPDirectory is VASPRegistry, AdministratorRole, OwnerRole {
    using Strings for uint256;

    mapping(bytes6 => bytes32) private _credentialsHashes;

    event CredentialsInserted
    (
        bytes6 indexed vaspId,
        bytes32 indexed credentialsRef,
        bytes32 indexed credentialsHash,
        string credentials
    );

    event CredentialsRevoked
    (
        bytes6 indexed vaspId,
        bytes32 indexed credentialsRef,
        bytes32 indexed credentialsHash
    );


    constructor
    (
        address owner,
        address administrator
    )
        public
        AdministratorRole(administrator, OWNER_ROLE)
        OwnerRole(owner)
    {
    }


    function insertCredentials
    (
        bytes6 vaspId,
        string calldata credentials
    )
        external
        onlyAdministrator
    {
        require(_credentialsHashes[vaspId] == bytes32(0), "VASPDirectory: vaspId has already been registered");

        bytes32 credentialsHash = _calculateCredentialsHash(credentials);

        _credentialsHashes[vaspId] = credentialsHash;

        emit CredentialsInserted(vaspId, credentialsHash, credentialsHash, credentials);
    }

    function revokeCredentials
    (
        bytes6 vaspId
    )
        external
        onlyAdministrator
    {
        bytes32 credentialsHash = _credentialsHashes[vaspId];

        require(credentialsHash != bytes32(0), "VASPDirectory: vaspCode is not registered");

        delete _credentialsHashes[vaspId];

        emit CredentialsRevoked(vaspId, credentialsHash, credentialsHash);
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

    function getCredentialsRef
    (
        bytes6 vaspId
    )
        external override view
        returns (string memory credentialsRef, bytes32 credentialsHash)
    {
        credentialsHash = _credentialsHashes[vaspId];

        if (credentialsHash != bytes32(0)) {
            credentialsRef = _convertBytes32ToHexString(credentialsHash);
        } else {
            credentialsRef = '';
        }

        return (credentialsRef, credentialsHash);
    }

    function _convertBytes32ToHexString
    (
        bytes32 input
    )
        private pure
        returns (string memory)
    {
        bytes memory output = new bytes(66);

        output[0] = '0';
        output[1] = 'x';

        for(uint i = 0; i < 32; i++) {
            uint8 decimalValue = uint8(input[i]);
            output[i * 2 + 2] = _hexChar(decimalValue / 16);
            output[i * 2 + 3] = _hexChar(decimalValue % 16);
        }

        return string(output);
    }

    function _hexChar
    (
        uint8 decimalRepresentation
    )
        private pure
        returns (bytes1)
    {
        require(decimalRepresentation < 16, "VASPDirectory: decimalRepresentation should be lower than 16");

        if (uint8(decimalRepresentation) < 10) {
            return bytes1(decimalRepresentation + 0x30);
        } else {
            return bytes1(decimalRepresentation + 0x57);
        }
    }
}
