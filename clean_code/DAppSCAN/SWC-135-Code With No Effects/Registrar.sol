
pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721PausableUpgradeable.sol";
import "./interfaces/IRegistrar.sol";


contract Registrar is
  IRegistrar,
  OwnableUpgradeable,
  ERC721PausableUpgradeable
{

  struct DomainRecord {
    address minter;
    bool metadataLocked;
    address metadataLockedBy;
    address controller;
    uint256 royaltyAmount;
  }


  mapping(address => bool) public controllers;



  mapping(uint256 => DomainRecord) public records;

  modifier onlyController() {
    require(controllers[msg.sender], "Zer0 Registrar: Not controller");
    _;
  }

  modifier onlyOwnerOf(uint256 id) {
    require(ownerOf(id) == msg.sender, "Zer0 Registrar: Not owner");
    _;
  }

  function initialize() public initializer {
    __Ownable_init();
    __ERC721_init("Zer0 Name Service", "ZNS");


    _createDomain(0, msg.sender, msg.sender, address(0));
  }









  function addController(address controller) external override onlyOwner {
    controllers[controller] = true;
    emit ControllerAdded(controller);
  }





  function removeController(address controller) external override onlyOwner {
    controllers[controller] = false;
    emit ControllerRemoved(controller);
  }








  function registerDomain(
    uint256 parentId,
    string memory name,
    address domainOwner,
    address minter
  ) external override onlyController returns (uint256) {

    uint256 labelHash = uint256(keccak256(bytes(name)));
    address controller = msg.sender;


    require(_exists(parentId), "Zer0 Registrar: No parent");


    uint256 domainId = uint256(
      keccak256(abi.encodePacked(parentId, labelHash))
    );
    _createDomain(domainId, domainOwner, minter, controller);

    emit DomainCreated(domainId, name, labelHash, parentId, minter, controller);

    return domainId;
  }






  function setDomainRoyaltyAmount(uint256 id, uint256 amount)
    external
    override
    onlyOwnerOf(id)
  {
    require(!isDomainMetadataLocked(id), "Zer0 Registrar: Metadata locked");

    records[id].royaltyAmount = amount;
    emit RoyaltiesAmountChanged(id, amount);
  }






  function setDomainMetadataUri(uint256 id, string memory uri)
    external
    override
    onlyOwnerOf(id)
  {
    require(!isDomainMetadataLocked(id), "Zer0 Registrar: Metadata locked");

    _setTokenURI(id, uri);
    emit MetadataChanged(id, uri);
  }





  function lockDomainMetadata(uint256 id) external override onlyOwnerOf(id) {
    require(!isDomainMetadataLocked(id), "Zer0 Registrar: Metadata locked");

    _lockMetadata(id, msg.sender);
  }





  function lockDomainMetadataForOwner(uint256 id)
    external
    override
    onlyController
  {
    require(!isDomainMetadataLocked(id), "Zer0 Registrar: Metadata locked");

    address domainOwner = ownerOf(id);
    _lockMetadata(id, domainOwner);
  }





  function unlockDomainMetadata(uint256 id) external override {
    require(isDomainMetadataLocked(id), "Zer0 Registrar: Not locked");
    require(
      domainMetadataLockedBy(id) == msg.sender,
      "Zer0 Registrar: Not locker"
    );

    _unlockMetadata(id);
  }









  function isAvailable(uint256 id) public view override returns (bool) {
    bool notRegistered = !_exists(id);
    return notRegistered;
  }





  function domainExists(uint256 id) public view override returns (bool) {
    bool domainNftExists = _exists(id);
    return domainNftExists;
  }





  function minterOf(uint256 id) public view override returns (address) {
    address minter = records[id].minter;
    return minter;
  }





  function isDomainMetadataLocked(uint256 id)
    public
    view
    override
    returns (bool)
  {
    bool isLocked = records[id].metadataLocked;
    return isLocked;
  }





  function domainMetadataLockedBy(uint256 id)
    public
    view
    override
    returns (address)
  {
    address lockedBy = records[id].metadataLockedBy;
    return lockedBy;
  }





  function domainController(uint256 id) public view override returns (address) {
    address controller = records[id].controller;
    return controller;
  }





  function domainRoyaltyAmount(uint256 id)
    public
    view
    override
    returns (uint256)
  {
    uint256 amount = records[id].royaltyAmount;
    return amount;
  }






  function _createDomain(
    uint256 domainId,
    address domainOwner,
    address minter,
    address controller
  ) internal {

    _safeMint(domainOwner, domainId);
    records[domainId] = DomainRecord({
      minter: minter,
      metadataLocked: false,
      metadataLockedBy: address(0),
      controller: controller,
      royaltyAmount: 0
    });
  }


  function _lockMetadata(uint256 id, address locker) internal {
    records[id].metadataLocked = true;
    records[id].metadataLockedBy = locker;

    emit MetadataLocked(id, locker);
  }


  function _unlockMetadata(uint256 id) internal {
    records[id].metadataLocked = false;
    records[id].metadataLockedBy = address(0);

    emit MetadataUnlocked(id);
  }
}
