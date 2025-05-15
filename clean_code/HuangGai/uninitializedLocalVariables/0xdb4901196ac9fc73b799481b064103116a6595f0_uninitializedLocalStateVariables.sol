





pragma solidity ^0.6.6;


pragma solidity ^0.6.0;


pragma solidity ^0.6.0;

























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

        uint256 valueIndex ;


        if (valueIndex != 0) {




            uint256 toDeleteIndex ;

            uint256 lastIndex ;





            bytes32 lastvalue ;



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
pragma solidity ^0.6.2;




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



































abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;









    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);







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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
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
pragma solidity ^0.6.6;

interface IAddressList {
    event AddressUpdated(address indexed a, address indexed sender);
    event AddressRemoved(address indexed a, address indexed sender);

    function add(address a) external returns (bool);
    function addValue(address a, uint256 v) external returns (bool);
    function remove(address a) external returns (bool);

    function get(address a) external view returns (uint256);
    function at(uint256 index) external view returns (address, uint256);
    function length() external view returns (uint256);
}
pragma solidity ^0.6.0;

























library EnumerableMap {









    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {

        MapEntry[] _entries;



        mapping (bytes32 => uint256) _indexes;
    }








    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {

        uint256 keyIndex ;


        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));


            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }






    function _remove(Map storage map, bytes32 key) private returns (bool) {

        uint256 keyIndex ;


        if (keyIndex != 0) {




            uint256 toDeleteIndex ;

            uint256 lastIndex ;





            MapEntry storage lastEntry = map._entries[lastIndex];


            map._entries[toDeleteIndex] = lastEntry;

            map._indexes[lastEntry._key] = toDeleteIndex + 1;


            map._entries.pop();


            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }




    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }











    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }








    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }




    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex ;

        require(keyIndex != 0, errorMessage);
        return map._entries[keyIndex - 1]._value;
    }



    struct AddressToUintMap {
        Map _inner;
    }








    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(key)), bytes32(value));
    }






    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(key)));
    }




    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(key)));
    }




    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }










    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint256(key)), uint256(value));
    }








    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(key))));
    }




    function get(AddressToUintMap storage map, address key, string memory errorMessage) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(key)), errorMessage));
    }
}
contract AddressList is AccessControl, IAddressList {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private theList;

    bytes32 public constant LIST_ADMIN = keccak256('LIST_ADMIN');

    modifier onlyListAdmin() {
        require(hasRole(LIST_ADMIN, msg.sender), 'Sender lacks LIST_ADMIN role');
        _;
    }


    constructor(address owner) public {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(LIST_ADMIN, owner);
    }




    function at(uint256 index) external view override returns (address, uint256) {
        return theList.at(index);
    }


    function length() external view override returns (uint256) {
        return theList.length();
    }


    function get(address a) external view override returns (uint256) {
        return theList.contains(a) ? theList.get(a) : 0;
    }




    function add(address a) external override onlyListAdmin returns (bool) {
        return _add(a, 1);
    }


    function addValue(address a, uint256 v) external override onlyListAdmin returns (bool) {
        return _add(a, v);
    }


    function remove(address a) external override onlyListAdmin returns (bool) {
        return _remove(a);
    }



    function _add(address a, uint256 v) private returns (bool) {
        require(v != 0, 'Metadata value v cannot be zero');
        if (!theList.contains(a) || theList.get(a) != v) {
            theList.set(a, v);
            emit AddressUpdated(a, msg.sender);
            return true;
        }

        return false;
    }

    function _remove(address a) private returns (bool) {
        bool removed ;

        if (removed) {
            emit AddressRemoved(a, msg.sender);
            return true;
        }

        return false;
    }
}
