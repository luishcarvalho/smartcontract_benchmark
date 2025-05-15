
pragma solidity ^0.5.16;


import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";


import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";


contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}





















































