
pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";

import "./interfaces/IRegistrar.sol";

contract StakingController is
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  ERC721HolderUpgradeable
{
  using ECDSAUpgradeable for bytes32;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IERC20Upgradeable private infinity;
  IRegistrar private registrar;
  address private controller;

  mapping(bytes32 => bool) private approvedBids;

  event DomainBidPlaced(
    bytes32 indexed unsignedRequestHash,
    string indexed bidIPFSHash,
    bytes indexed signature
  );

  event DomainBidApproved(string indexed bidIdentifier);

  event DomainBidFulfilled(
    string indexed bidIdentifier,
    string name,
    address recoveredbidder,
    uint256 indexed id,
    uint256 indexed parentID
  );

  modifier authorizedOwner(uint256 domain) {
    require(registrar.domainExists(domain), "ZNS: Invalid Domain");
    require(
      registrar.ownerOf(domain) == _msgSender(),
      "ZNS: Not Authorized Owner"
    );
    _;
  }

  function initialize(IRegistrar _registrar, IERC20Upgradeable _infinity)
    public
    initializer
  {
    __ERC165_init();
    __Context_init();

    infinity = _infinity;
    registrar = _registrar;
    controller = address(this);
  }











  function placeDomainBid(
    uint256 parentId,
    bytes32 unsignedRequestHash,
    bytes memory signature,
    string memory bidIPFSHash
  ) external {
    require(registrar.domainExists(parentId), "ZNS: Invalid Domain");
    emit DomainBidPlaced(unsignedRequestHash, bidIPFSHash, signature);
  }








  function approveDomainBid(
    uint256 parentId,
    string memory bidIPFSHash,
    bytes memory signature
  ) external authorizedOwner(parentId) {
    bytes32 hashOfSig = keccak256(abi.encode(signature));
    approvedBids[hashOfSig] = true;
    emit DomainBidApproved(bidIPFSHash);
  }
















  function fulfillDomainBid(
    uint256 parentId,
    uint256 bidAmount,
    uint256 royaltyAmount,
    string memory bidIPFSHash,
    string memory name,
    string memory metadata,
    bytes memory signature,
    bool lockOnCreation,
    address recipient
  ) external {
    bytes32 recoveredBidHash = createBid(
      parentId,
      bidAmount,
      bidIPFSHash,
      name
    );

    address recoveredBidder = recover(recoveredBidHash, signature);
    require(recipient == recoveredBidder, "ZNS: bid info doesnt match/exist");
    bytes32 hashOfSig = keccak256(abi.encode(signature));
    require(approvedBids[hashOfSig] == true, "ZNS: has been fullfilled");
    infinity.safeTransferFrom(recoveredBidder, controller, bidAmount);
    uint256 id = registrar.registerDomain(
      parentId,
      name,
      controller,
      recoveredBidder
    );
    registrar.setDomainMetadataUri(id, metadata);
    registrar.setDomainRoyaltyAmount(id, royaltyAmount);
    registrar.transferFrom(controller, recoveredBidder, id);
    if (lockOnCreation) {
      registrar.lockDomainMetadataForOwner(id);
    }
    approvedBids[hashOfSig] = false;
    emit DomainBidFulfilled(metadata, name, recoveredBidder, id, parentId);
  }






  function recover(bytes32 unsignedRequestHash, bytes memory signature)
    public
    pure
    returns (address)
  {
    return unsignedRequestHash.toEthSignedMessageHash().recover(signature);
  }








  function createBid(
    uint256 parentId,
    uint256 bidAmount,
    string memory bidIPFSHash,
    string memory name
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(parentId, bidAmount, bidIPFSHash, name));
  }
}
