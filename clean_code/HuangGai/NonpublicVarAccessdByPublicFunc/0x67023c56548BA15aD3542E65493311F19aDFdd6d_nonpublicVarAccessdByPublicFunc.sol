
































pragma solidity 0.5.11;








contract Governable {

    bytes32
        private constant governorPosition = 0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;


    bytes32
        private constant pendingGovernorPosition = 0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;


    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );




    constructor() internal {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }




    function governor() public view returns (address) {
        return _governor();
    }

    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }




    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }




    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }






    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }





    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }





    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
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
    bytes32 slot = IMPLEMENTATION_SLOT;
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

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}



pragma solidity 0.5.11;







contract InitializeGovernedUpgradeabilityProxy is
    Governable,
    BaseUpgradeabilityProxy
{









    function initialize(
        address _logic,
        address _initGovernor,
        bytes memory _data
    ) public payable onlyGovernor {
        require(_implementation() == address(0));
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
        _changeGovernor(_initGovernor);
    }




    function admin() external view returns (address) {
        return _governor();
    }




    function implementation() external view returns (address) {
        return _implementation();
    }






    function upgradeTo(address newImplementation) external onlyGovernor {
        _upgradeTo(newImplementation);
    }










    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlyGovernor
    {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }
}



pragma solidity 0.5.11;




contract OUSDProxy is InitializeGovernedUpgradeabilityProxy {

}




contract VaultProxy is InitializeGovernedUpgradeabilityProxy {

}




contract CompoundStrategyProxy is InitializeGovernedUpgradeabilityProxy {

}




contract ThreePoolStrategyProxy is InitializeGovernedUpgradeabilityProxy {

}
