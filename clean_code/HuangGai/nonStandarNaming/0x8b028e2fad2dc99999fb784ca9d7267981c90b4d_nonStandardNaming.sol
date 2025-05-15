

pragma solidity 0.5.11;



contract DharmaTradeReserve {

  address private constant _upgrade_beacon642 = address(
    0x2Cf7C0333D9b7F94BbF55B9701227E359F92fD31
  );


  constructor(bytes memory initializationCalldata) public payable {

    (bool ok, ) = _IMPLEMENTATION344().delegatecall(initializationCalldata);


    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }


  function () external payable {

    _DELEGATE181(_IMPLEMENTATION344());
  }


  function _IMPLEMENTATION344() private view returns (address implementation) {

    (bool ok, bytes memory returnData) = _upgrade_beacon642.staticcall("");


    require(ok, string(returnData));


    implementation = abi.decode(returnData, (address));
  }


  function _DELEGATE181(address implementation) private {
    assembly {



      calldatacopy(0, 0, calldatasize)



      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)


      returndatacopy(0, 0, returndatasize)

      switch result

      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }
}
