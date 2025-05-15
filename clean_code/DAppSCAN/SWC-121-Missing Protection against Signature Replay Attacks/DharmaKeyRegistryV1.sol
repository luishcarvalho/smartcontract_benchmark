pragma solidity 0.5.11;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";















contract DharmaKeyRegistryV1 is Ownable {
  using ECDSA for bytes32;


  address private _globalKey;


  mapping (address => address) private _specificKeys;





  constructor() public {

    _globalKey = tx.origin;


    _transferOwnership(tx.origin);
  }












  function setGlobalKey(
    address globalKey,
    bytes calldata signature
  ) external onlyOwner {

    require(globalKey != address(0), "A global key must be supplied.");


    bytes32 messageHash = keccak256(
      abi.encodePacked(
        address(this),
        globalKey,
        "This signature demonstrates that the supplied signing key is valid."
      )
    );


    address signer = messageHash.toEthSignedMessageHash().recover(signature);


    require(globalKey == signer, "Invalid signature for supplied global key.");


    _globalKey = globalKey;
  }









  function setSpecificKey(
    address account,
    address specificKey
  ) external onlyOwner {

    _specificKeys[account] = specificKey;
  }







  function getKey() external view returns (address key) {

    key = _specificKeys[msg.sender];


    if (key == address(0)) {
      key = _globalKey;
    }
  }








  function getKeyForUser(address account) external view returns (address key) {

    key = _specificKeys[account];


    if (key == address(0)) {
      key = _globalKey;
    }
  }





  function getGlobalKey() external view returns (address globalKey) {

    globalKey = _globalKey;
  }







  function getSpecificKey(
    address account
  ) external view returns (address specificKey) {

    specificKey = _specificKeys[account];


    require(
      specificKey != address(0),
      "No specific key set for the provided account."
    );
  }
}
