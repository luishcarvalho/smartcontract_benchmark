pragma solidity 0.5.7;








contract Proxy {




  function () payable external {
    _fallback();
  }




  function _implementation() internal view returns (address);







  function _delegate(address implementation) internal {
    assembly {



      calldatacopy(0, 0, calldatasize)



      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)


      returndatacopy(0, 0, returndatasize)

      switch result

      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }






  function _willFallback() internal {
  }





  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}











library ZOSLibAddress {







    function isContract(address account) internal view returns (bool) {
        uint256 size;







        assembly { size := extcodesize(account) }
        return size > 0;
    }
}







contract BaseUpgradeabilityProxy is Proxy {




  event Upgraded(address indexed implementation);






  bytes32 internal constant IMPLEMENTATION_SLOT = 0x6373548c81aec7af8a152e649030793ecf1835415f396e2eafb522eedc3c06e9;





  function _implementation() internal view returns (address impl) {
    bytes32 slot ;

    assembly {
      impl := sload(slot)
    }
  }





  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }





  function _setImplementation(address newImplementation) internal {
    require(ZOSLibAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot ;


    assembly {
      sstore(slot, newImplementation)
    }
  }
}







contract UpgradeabilityProxy is BaseUpgradeabilityProxy {








  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == keccak256("org.loopring.proxy.implementation"));
    _setImplementation(_logic);




  }
}










contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {





  event AdminChanged(address previousAdmin, address newAdmin);






  bytes32 internal constant ADMIN_SLOT = 0x0cbe1756fc073c7e8f4075e2df79a804181fe791bbb6ceadc4d3e357017a748f;






  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }




  function admin() external ifAdmin returns (address) {
    return _admin();
  }




  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }






  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }






  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }










  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }




  function _admin() internal view returns (address adm) {
    bytes32 slot ;

    assembly {
      adm := sload(slot)
    }
  }





  function _setAdmin(address newAdmin) internal {
    bytes32 slot ;


    assembly {
      sstore(slot, newAdmin)
    }
  }




  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}







contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {









  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == keccak256("org.loopring.proxy.admin"));
    _setAdmin(_admin);
  }
}

contract LoopringAdminUpgradeabilityProxy is AdminUpgradeabilityProxy {
    constructor(address _implementation, address _admin) public
        AdminUpgradeabilityProxy(_implementation, _admin, bytes("")) {
    }
}
