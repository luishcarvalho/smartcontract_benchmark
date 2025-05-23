



pragma solidity 0.5.11;













contract DharmaAccountRecoveryOperatorMultisigStaging {

  mapping(bytes32 => bool) private _usedHashes;


  mapping(address => bool) private _isOwner;
  address[] private _owners;


  address private constant _DESTINATION = address(
    0x2a7E7718b755F9868E6B64DD18C6886707DD9c10
  );


  uint256 private constant _THRESHOLD = 2;


  constructor(address[] memory owners) public {
    require(owners.length <= 10, "Cannot have more than 10 owners.");
    require(_THRESHOLD <= owners.length, "Threshold cannot exceed total owners.");

    address lastAddress = address(0);
    for (uint256 i = 0; i < owners.length; i++) {
      require(
        owners[i] > lastAddress, "Owner addresses must be strictly increasing."
      );
      _isOwner[owners[i]] = true;
      lastAddress = owners[i];
    }
    _owners = owners;
  }

  function getHash(
    bytes calldata data,
    address executor,
    uint256 gasLimit,
    bytes32 salt
  ) external view returns (bytes32 hash, bool usable) {
    (hash, usable) = _getHash(data, executor, gasLimit, salt);
  }

  function getOwners() public view returns (address[] memory owners) {
    owners = _owners;
  }

  function isOwner(address account) public view returns (bool owner) {
    owner = _isOwner[account];
  }

  function getThreshold() public pure returns (uint256 threshold) {
    threshold = _THRESHOLD;
  }

  function getDestination() public pure returns (address destination) {
    destination = _DESTINATION;
  }


  function execute(
    bytes calldata data,
    address executor,
    uint256 gasLimit,
    bytes32 salt,
    bytes calldata signatures
  ) external returns (bool success, bytes memory returnData) {
    require(
      executor == msg.sender || executor == address(0),
      "Must call from the executor account if one is specified."
    );


    (bytes32 rawHash, bool usable) = _getHash(data, executor, gasLimit, salt);
    require(usable, "Hash in question has already been used previously.");


    bytes32 hash = _toEthSignedMessageHash(rawHash);


    address[] memory signers = _recoverGroup(hash, signatures);

    require(signers.length == _THRESHOLD, "Total signers must equal threshold.");


    address lastAddress = address(0);
    for (uint256 i = 0; i < signers.length; i++) {
      require(
        _isOwner[signers[i]], "Signature does not correspond to an owner."
      );
      require(
        signers[i] > lastAddress, "Signer addresses must be strictly increasing."
      );
      lastAddress = signers[i];
    }


    _usedHashes[rawHash] = true;
    (success, returnData) = _DESTINATION.call.gas(gasLimit)(data);
  }

  function _getHash(
    bytes memory data,
    address executor,
    uint256 gasLimit,
    bytes32 salt
  ) internal view returns (bytes32 hash, bool usable) {

    hash = keccak256(
      abi.encodePacked(address(this), salt, executor, gasLimit, data)
    );

    usable = !_usedHashes[hash];
  }

















  function _recoverGroup(
    bytes32 hash,
    bytes memory signatures
  ) internal pure returns (address[] memory signers) {

    if (signatures.length % 65 != 0) {
      return new address[](0);
    }


    signers = new address[](signatures.length / 65);


    bytes32 signatureLocation;
    bytes32 r;
    bytes32 s;
    uint8 v;

    for (uint256 i = 0; i < signers.length; i++) {
      assembly {
        signatureLocation := add(signatures, mul(i, 65))
        r := mload(add(signatureLocation, 32))
        s := mload(add(signatureLocation, 64))
        v := byte(0, mload(add(signatureLocation, 96)))
      }



      if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
        continue;
      }

      if (v != 27 && v != 28) {
        continue;
      }


      signers[i] = ecrecover(hash, v, r, s);
    }
  }

  function _toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}
