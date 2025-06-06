/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       EternalStorage.sol
version:    1.0
author:     Clinton Ennise
            Jackson Chan

date:       2019-02-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract is used with external state storage contracts for
decoupled data storage.

Implements support for storing a keccak256 key and value pairs. It is
the more flexible and extensible option. This ensures data schema
changes can be implemented without requiring upgrades to the
storage contract

The first deployed storage contract would create this eternal storage.
Favour use of keccak256 key over sha3 as future version of solidity
> 0.5.0 will be deprecated.

-----------------------------------------------------------------
*/

pragma solidity 0.4.25;
import "./State.sol";

/**
 * @notice  This contract is based on the code available from this blog
 * https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/
 * Implements support for storing a keccak256 key and value pairs. It is the more flexible
 * and extensible option. This ensures data schema changes can be implemented without
 * requiring upgrades to the storage contract.
 */
contract EternalStorage is State {

    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        public
    {
    }
//SWC-108-State Variable Default Visibility:L51-57
    /* ========== DATA TYPES ========== */
    mapping(bytes32 => uint) UIntStorage;
    mapping(bytes32 => string) StringStorage;
    mapping(bytes32 => address) AddressStorage;
    mapping(bytes32 => bytes) BytesStorage;
    mapping(bytes32 => bytes32) Bytes32Storage;
    mapping(bytes32 => bool) BooleanStorage;
    mapping(bytes32 => int) IntStorage;

    // UIntStorage;
    function getUIntValue(bytes32 record) external view returns (uint){
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external
        onlyAssociatedContract
    {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete UIntStorage[record];
    }

    // StringStorage
    function getStringValue(bytes32 record) external view returns (string memory){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string value) external
        onlyAssociatedContract
    {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete StringStorage[record];
    }

    // AddressStorage
    function getAddressValue(bytes32 record) external view returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external
        onlyAssociatedContract
    {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete AddressStorage[record];
    }


    // BytesStorage
    function getBytesValue(bytes32 record) external view returns
    (bytes memory){
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes value) external
        onlyAssociatedContract
    {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BytesStorage[record];
    }

    // Bytes32Storage
    function getBytes32Value(bytes32 record) external view returns (bytes32)
    {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external
        onlyAssociatedContract
    {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external
        onlyAssociatedContract
    {
        delete Bytes32Storage[record];
    }

    // BooleanStorage
    function getBooleanValue(bytes32 record) external view returns (bool)
    {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external
        onlyAssociatedContract
    {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BooleanStorage[record];
    }

    // IntStorage
    function getIntValue(bytes32 record) external view returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external
        onlyAssociatedContract
    {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete IntStorage[record];
    }
}