
pragma solidity ^0.8.8;

































































import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./SutterTreasury.sol";
import "./ERC2981.sol";

struct PresaleConfig {
  uint32 startTime;
  uint32 endTime;
  uint32 supplyLimit;
  uint256 mintPrice;
}

struct DutchAuctionConfig {
  uint32 txLimit;
  uint32 supplyLimit;
  uint32 startTime;
  uint32 bottomTime;
  uint32 stepInterval;
  uint256 startPrice;
  uint256 bottomPrice;
  uint256 priceStep;
}

contract CryptoBatz is
  Ownable,
  ERC721,
  ERC2981,
  SutterTreasury
{
  using Address for address;
  using SafeCast for uint256;
  using ECDSA for bytes32;



  uint32 public constant MAX_OWNER_RESERVE = 101;
  uint32 public constant ANCIENT_BATZ_SUPPLY = 99;

  uint256 public totalSupply = 0;


  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;


  mapping(uint256 => uint256) private _ownedTokensIndex;

  PresaleConfig public presaleConfig;
  DutchAuctionConfig public dutchAuctionConfig;

  string public baseURI;
  address public whitelistSigner;
  address public ancientBatzMinter;

  uint256 public PROVENANCE_HASH;
  uint256 public randomizedStartIndex;

  mapping(address => uint256) private presaleMinted;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("presale(address buyer,uint256 limit)");

  address[] private mintPayees = [
    0xFa65B0e06BB42839aB0c37A26De4eE0c03B30211,
    0x09e339CEF02482f4C4127CC49C153303ad801EE0,
    0xE9E9206B598F6Fc95E006684Fe432f100E876110
  ];

  uint256[] private mintShares = [
    50,
    45,
    5
  ];

  SutterTreasury public royaltyRecipient;



  constructor(string memory initialBaseUri)
    ERC721("Crypto Batz by Ozzy Osbourne", "BATZ")
    SutterTreasury(mintPayees, mintShares)
  {
    baseURI = initialBaseUri;

    ancientBatzMinter = msg.sender;

    presaleConfig = PresaleConfig({
      startTime: 1642633200,
      endTime: 1642719600,
      supplyLimit: 7166,
      mintPrice: 0.088 ether
    });

    dutchAuctionConfig = DutchAuctionConfig({
      txLimit: 3,
      supplyLimit: 9666,
      startTime: 1642719600,
      bottomTime: 1642730400,
      stepInterval: 300,
      startPrice: 0.666 ether,
      bottomPrice: 0.1 ether,
      priceStep: 0.0157 ether
    });

    address[] memory royaltyPayees = new address[](2);
    royaltyPayees[0] = 0xFa65B0e06BB42839aB0c37A26De4eE0c03B30211;
    royaltyPayees[1] = 0x09e339CEF02482f4C4127CC49C153303ad801EE0;

    uint256[] memory royaltyShares = new uint256[](2);
    royaltyShares[0] = 70;
    royaltyShares[1] = 30;

    royaltyRecipient = new SutterTreasury(royaltyPayees, royaltyShares);

    _setRoyalties(address(royaltyRecipient), 750);

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("CryptoBatz")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }









  function buyPresale(
    bytes calldata signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable {
    PresaleConfig memory _config = presaleConfig;

    require(
      block.timestamp >= _config.startTime && block.timestamp < _config.endTime,
      "Presale is not active"
    );
    require(whitelistSigner != address(0), "Whitelist signer has not been set");
    require(
      msg.value == (_config.mintPrice * numberOfTokens),
      "Incorrect payment"
    );
    require(
      (presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit,
      "Mint limit exceeded"
    );
    require(
      (totalSupply + numberOfTokens) <= _config.supplyLimit,
      "Not enought BATZ remaining"
    );

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(TYPEHASH, msg.sender, approvedLimit))
      )
    );
    address signer = digest.recover(signature);
    require(
      signer != address(0) && signer == whitelistSigner,
      "Invalid signature"
    );

    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;

    mint(msg.sender, numberOfTokens);
  }




  function buyPublic(uint256 numberOfTokens) external payable {

    require(
      (!msg.sender.isContract() && msg.sender == tx.origin),
      "Contract buys not allowed"
    );

    DutchAuctionConfig memory _config = dutchAuctionConfig;

    require(
      (totalSupply + numberOfTokens) <= _config.supplyLimit,
      "Not enought BATZ remaining"
    );
    require(block.timestamp >= _config.startTime, "Sale is not active");
    require(numberOfTokens <= _config.txLimit, "Transaction limit exceeded");

    uint256 mintPrice = getCurrentAuctionPrice() * numberOfTokens;
    require(msg.value >= mintPrice, "Insufficient payment");


    if (msg.value > mintPrice) {
      Address.sendValue(payable(msg.sender), msg.value - mintPrice);
    }

    mint(msg.sender, numberOfTokens);
  }




  function getCurrentAuctionPrice() public view returns (uint256 currentPrice) {
    DutchAuctionConfig memory _config = dutchAuctionConfig;

    uint256 timestamp = block.timestamp;

    if (timestamp < _config.startTime) {
      currentPrice = _config.startPrice;
    } else if (timestamp >= _config.bottomTime) {
      currentPrice = _config.bottomPrice;
    } else {
      uint256 elapsedIntervals = (timestamp - _config.startTime) /
        _config.stepInterval;
      currentPrice =
        _config.startPrice -
        (elapsedIntervals * _config.priceStep);
    }

    return currentPrice;
  }




  function tokensOwnedBy(address wallet)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ownedTokenIds[i] = _ownedTokens[wallet][i];
    }

    return ownedTokenIds;
  }


  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }







  function reserve(address to, uint256 numberOfTokens) external onlyOwner {
    require(
      (totalSupply + numberOfTokens) <= MAX_OWNER_RESERVE,
      "Exceeds owner reserve limit"
    );

    mint(to, numberOfTokens);
  }





  function rollStartIndex() external onlyOwner {
    require(PROVENANCE_HASH != 0, "Provenance hash not set");
    require(randomizedStartIndex == 0, "Index already set");
    require(
      block.timestamp >= dutchAuctionConfig.startTime,
      "Too early to roll start index"
    );

    uint256 number = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          block.coinbase,
          block.difficulty
        )
      )
    );

    randomizedStartIndex = (number % dutchAuctionConfig.supplyLimit) + 1;
  }




  function mintAncientBatz(address to, uint256 ancientBatzId) external {
    require(ancientBatzMinter != address(0), "AncientBatz minter not set");
    require(
      msg.sender == ancientBatzMinter,
      "Must be authorized AncientBatz minter"
    );
    require(
      ancientBatzId > 0 && ancientBatzId <= ANCIENT_BATZ_SUPPLY,
      "Invalid AncientBatz Id"
    );

    uint256 tokenId = dutchAuctionConfig.supplyLimit + ancientBatzId;

    _safeMint(to, tokenId);

    totalSupply++;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(recipient != address(0), "zero address");
    _setRoyalties(recipient, value);
  }

  function setWhitelistSigner(address newWhitelistSigner) external onlyOwner {
    whitelistSigner = newWhitelistSigner;
  }

  function setAncientBatzMinter(address newMinter) external onlyOwner {
    ancientBatzMinter = newMinter;
  }

  function setProvenance(uint256 provenanceHash) external onlyOwner {
    require(randomizedStartIndex == 0, "Starting index already set");

    PROVENANCE_HASH = provenanceHash;
  }


  function configurePresale(
    uint256 startTime,
    uint256 endTime,
    uint256 supplyLimit,
    uint256 mintPrice
  ) external onlyOwner {
    uint32 _startTime = startTime.toUint32();
    uint32 _endTime = endTime.toUint32();
    uint32 _supplyLimit = supplyLimit.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_startTime < _endTime, "Invalid time");

    presaleConfig = PresaleConfig({
      startTime: _startTime,
      endTime: _endTime,
      supplyLimit: _supplyLimit,
      mintPrice: mintPrice
    });
  }


  function configureDutchAuction(
    uint256 txLimit,
    uint256 supplyLimit,
    uint256 startTime,
    uint256 bottomTime,
    uint256 stepInterval,
    uint256 startPrice,
    uint256 bottomPrice,
    uint256 priceStep
  ) external onlyOwner {
    uint32 _txLimit = txLimit.toUint32();
    uint32 _supplyLimit = supplyLimit.toUint32();
    uint32 _startTime = startTime.toUint32();
    uint32 _bottomTime = bottomTime.toUint32();
    uint32 _stepInterval = stepInterval.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_startTime < _bottomTime, "Invalid time");

    dutchAuctionConfig = DutchAuctionConfig({
      txLimit: _txLimit,
      supplyLimit: _supplyLimit,
      startTime: _startTime,
      bottomTime: _bottomTime,
      stepInterval: _stepInterval,
      startPrice: startPrice,
      bottomPrice: bottomPrice,
      priceStep: priceStep
    });
  }



  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function mint(address to, uint256 numberOfTokens) private {
    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }

    totalSupply = newId;
  }











  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }









  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {



    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];


    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId;
      _ownedTokensIndex[lastTokenId] = tokenIndex;
    }


    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }
















  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0)) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }
}
