pragma solidity 0.5.11;

import "../../proxies/smart-wallet/UpgradeBeaconProxyV1.sol";
import "../../../interfaces/DharmaSmartWalletFactoryV1Interface.sol";
import "../../../interfaces/DharmaSmartWalletInitializer.sol";









contract DharmaSmartWalletFactoryV1 is DharmaSmartWalletFactoryV1Interface {

  DharmaSmartWalletInitializer private _INITIALIZER;








  function newSmartWallet(
    address userSigningKey
  ) external returns (address wallet) {

    bytes memory initializationCalldata = abi.encodeWithSelector(
      _INITIALIZER.initialize.selector,
      userSigningKey
    );


    wallet = _deployUpgradeBeaconProxyInstance(initializationCalldata);


    emit SmartWalletDeployed(wallet, userSigningKey);
  }









  function getNextSmartWallet(
    address userSigningKey
  ) external view returns (address wallet) {

    bytes memory initializationCalldata = abi.encodeWithSelector(
      _INITIALIZER.initialize.selector,
      userSigningKey
    );


    wallet = _computeNextAddress(initializationCalldata);
  }








  function _deployUpgradeBeaconProxyInstance(
    bytes memory initializationCalldata
  ) private returns (address upgradeBeaconProxyInstance) {

    bytes memory initCode = abi.encodePacked(
      type(UpgradeBeaconProxyV1).creationCode,
      abi.encode(initializationCalldata)
    );


    (uint256 salt, ) = _getSaltAndTarget(initCode);


    assembly {
      let encoded_data := add(0x20, initCode)
      let encoded_size := mload(initCode)
      upgradeBeaconProxyInstance := create2(
        callvalue,
        encoded_data,
        encoded_size,
        salt
      )


      if iszero(upgradeBeaconProxyInstance) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }











  function _computeNextAddress(
    bytes memory initializationCalldata
  ) private view returns (address target) {

    bytes memory initCode = abi.encodePacked(
      type(UpgradeBeaconProxyV1).creationCode,
      abi.encode(initializationCalldata)
    );


    (, target) = _getSaltAndTarget(initCode);
  }







  function _getSaltAndTarget(
    bytes memory initCode
  ) private view returns (uint256 nonce, address target) {

    bytes32 initCodeHash = keccak256(initCode);


    nonce = 0;


    uint256 codeSize;


    while (true) {
      target = address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                address(this),
                nonce,
                initCodeHash
              )
            )
          )
        )
      );


      assembly { codeSize := extcodesize(target) }


      if (codeSize == 0) {
        break;
      }


      nonce++;
    }
  }
}
