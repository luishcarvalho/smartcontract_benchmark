





pragma solidity 0.5.16;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}



pragma solidity ^0.5.0;








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



pragma solidity ^0.5.0;









library OpenZeppelinUpgradesAddress {







    function isContract(address account) internal view returns (bool) {
        uint256 size;







        assembly { size := extcodesize(account) }
        return size > 0;
    }
}



pragma solidity ^0.5.0;









contract BaseUpgradeabilityProxy is Proxy {




  event Upgraded(address indexed implementation);






  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;





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
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot ;


    assembly {
      sstore(slot, newImplementation)
    }
  }
}



pragma solidity 0.5.16;



contract VaultProxy is BaseUpgradeabilityProxy {

  constructor(address _implementation) public {
    _setImplementation(_implementation);
  }





  function upgrade() external {
    (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
    require(should, "Upgrade not scheduled");
    _upgradeTo(newImplementation);



    (bool success, bytes memory result) = address(this).delegatecall(
      abi.encodeWithSignature("finalizeUpgrade()")
    );

    require(success, "Issue when finalizing the upgrade");
  }

  function implementation() external view returns (address) {
    return _implementation();
  }
}
