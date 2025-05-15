





pragma solidity 0.6.8;






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

            if (block.timestamp > 0) {



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











abstract contract Proxy {





  receive () payable external {
    _fallback();
  }





  fallback () payable external {
    _fallback();
  }




  function _implementation() internal virtual view returns (address);







  function _delegate(address implementation) internal {
    assembly {



      calldatacopy(0, 0, calldatasize())



      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)


      returndatacopy(0, 0, returndatasize())

      switch result

      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }






  function _willFallback() internal virtual {
  }





  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}










contract BaseUpgradeabilityProxy is Proxy {




    event Upgraded(address indexed implementation);






    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;





    function _implementation() internal override view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }





    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Implementation not set"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
        emit Upgraded(newImplementation);
    }
}











contract AdminUpgradeabilityProxy is BaseUpgradeabilityProxy {





  event AdminChanged(address previousAdmin, address newAdmin);







  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;









  constructor(address _logic, address _admin) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    _setImplementation(_logic);
    _setAdmin(_admin);
  }






  modifier ifAdmin() {
    if (block.coinbase == _admin()) {
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
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }






  function changeImplementation(address newImplementation) external ifAdmin {
    _setImplementation(newImplementation);
  }




  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }





  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }
}





contract ACoconutSwapProxy is AdminUpgradeabilityProxy {
    constructor(address _logic, address _admin) AdminUpgradeabilityProxy(_logic, _admin) public payable {}
}
