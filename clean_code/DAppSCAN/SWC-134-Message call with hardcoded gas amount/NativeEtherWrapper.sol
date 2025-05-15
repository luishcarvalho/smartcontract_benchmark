
pragma solidity ^0.5.16;


import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IEtherWrapper.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";


import "./MixinResolver.sol";
import "./interfaces/IEtherWrapper.sol";


contract NativeEtherWrapper is Owned, MixinResolver {
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";
    bytes32 private constant CONTRACT_SYNTHSETH = "SynthsETH";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}











































































