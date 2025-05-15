

pragma solidity 0.5.16;



contract Proxy {

  function () payable external {
    _FALLBACK743();
  }


  function _IMPLEMENTATION883() internal view returns (address);


  function _DELEGATE763(address implementation) internal {
    assembly {



      calldatacopy(0, 0, calldatasize)



      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)


      returndatacopy(0, 0, returndatasize)

      switch result

      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }


  function _WILLFALLBACK413() internal {
  }


  function _FALLBACK743() internal {
    _WILLFALLBACK413();
    _DELEGATE763(_IMPLEMENTATION883());
  }
}


library OpenZeppelinUpgradesAddress {

    function ISCONTRACT295(address account) internal view returns (bool) {
        uint256 size;







        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


contract BaseUpgradeabilityProxy is Proxy {

  event UPGRADED520(address indexed implementation);


  bytes32 internal constant implementation_slot134 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;


  function _IMPLEMENTATION883() internal view returns (address impl) {
    bytes32 slot = implementation_slot134;
    assembly {
      impl := sload(slot)
    }
  }


  function _UPGRADETO492(address newImplementation) internal {
    _SETIMPLEMENTATION972(newImplementation);
    emit UPGRADED520(newImplementation);
  }


  function _SETIMPLEMENTATION972(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.ISCONTRACT295(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = implementation_slot134;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}


contract UpgradeabilityProxy is BaseUpgradeabilityProxy {

  constructor(address _logic, bytes memory _data) public payable {
    assert(implementation_slot134 == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _SETIMPLEMENTATION972(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }
}


contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {

  event ADMINCHANGED457(address previousAdmin, address newAdmin);



  bytes32 internal constant admin_slot433 = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;


  modifier IFADMIN310() {
    if (msg.sender == _ADMIN931()) {
      _;
    } else {
      _FALLBACK743();
    }
  }


  function ADMIN692() external IFADMIN310 returns (address) {
    return _ADMIN931();
  }


  function IMPLEMENTATION885() external IFADMIN310 returns (address) {
    return _IMPLEMENTATION883();
  }


  function CHANGEADMIN627(address newAdmin) external IFADMIN310 {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit ADMINCHANGED457(_ADMIN931(), newAdmin);
    _SETADMIN928(newAdmin);
  }


  function UPGRADETO124(address newImplementation) external IFADMIN310 {
    _UPGRADETO492(newImplementation);
  }


  function UPGRADETOANDCALL516(address newImplementation, bytes calldata data) payable external IFADMIN310 {
    _UPGRADETO492(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }


  function _ADMIN931() internal view returns (address adm) {
    bytes32 slot = admin_slot433;
    assembly {
      adm := sload(slot)
    }
  }


  function _SETADMIN928(address newAdmin) internal {
    bytes32 slot = admin_slot433;

    assembly {
      sstore(slot, newAdmin)
    }
  }


  function _WILLFALLBACK413() internal {
    require(msg.sender != _ADMIN931(), "Cannot call fallback function from the proxy admin");
    super._WILLFALLBACK413();
  }
}


contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {

  function INITIALIZE172(address _logic, bytes memory _data) public payable {
    require(_IMPLEMENTATION883() == address(0));
    assert(implementation_slot134 == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _SETIMPLEMENTATION972(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {

  function INITIALIZE172(address _logic, address _admin, bytes memory _data) public payable {
    require(_IMPLEMENTATION883() == address(0));
    InitializableUpgradeabilityProxy.INITIALIZE172(_logic, _data);
    assert(admin_slot433 == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _SETADMIN928(_admin);
  }
}


contract MassetProxy is InitializableAdminUpgradeabilityProxy {
}
