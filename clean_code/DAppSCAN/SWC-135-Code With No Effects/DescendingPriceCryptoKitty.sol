pragma solidity ^0.4.23;








































contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






  function Ownable() public {
    owner = msg.sender;
  }




  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }





  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}







contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;





  modifier whenNotPaused() {
    require(!paused);
    _;
  }




  modifier whenPaused() {
    require(paused);
    _;
  }




  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }




  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}







library SafeMath {




  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }




  function div(uint256 a, uint256 b) internal pure returns (uint256) {



    return a / b;
  }




  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }




  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}












contract AuctionBase is Pausable {
  using SafeMath for uint256;

  mapping(uint256 => address) public auctionIdToSeller;


  uint256 public nextAuctionId = 1;




  modifier onlySeller(uint256 auctionId) {
    require(msg.sender == auctionIdToSeller[auctionId]);
    _;
  }

  event AuctionCreated(address indexed createdBy, uint256 indexed auctionId);




  function createEmptyAuction() internal returns (uint256) {
    uint256 thisAuctionId = nextAuctionId;
    nextAuctionId = nextAuctionId.add(1);

    auctionIdToSeller[thisAuctionId] = msg.sender;

    emit AuctionCreated(msg.sender, thisAuctionId);
    return thisAuctionId;
  }

  function transferWinnings(address recipient, uint256 auctionId) internal;
}











contract CryptoKittyAuction is AuctionBase {
  using SafeMath for uint256;


  mapping(uint256 => uint256) public kittyIdToAuctionId;

  mapping(uint256 => uint256) public auctionIdToKittyId;

  address public cryptoKittyAddress;

  constructor(address _cryptoKittyAddress) public {
    cryptoKittyAddress = _cryptoKittyAddress;
  }

  function setAuctionAsset(uint256 kittyId, uint256 auctionId) internal {
    require(auctionId != 0);

    require(kittyIdToAuctionId[kittyId] == 0);

    auctionIdToKittyId[auctionId] = kittyId;

    kittyIdToAuctionId[kittyId] = auctionId;

    escrowKitty(msg.sender, kittyId);
  }

  function transferWinnings(address recipient, uint256 auctionId) internal {
    require(auctionId != 0);
    require(auctionHasKitty(auctionId));
    CKERC721 catContract = CKERC721(cryptoKittyAddress);


    uint256 kittyId = auctionIdToKittyId[auctionId];
    kittyIdToAuctionId[kittyId] = 0;
    catContract.transfer(recipient, kittyId);
  }




  function escrowKitty(address seller, uint256 kittyId) private {
    CKERC721 catContract = CKERC721(cryptoKittyAddress);


    catContract.transferFrom(seller, this, kittyId);
  }

  function auctionHasKitty(uint256 auctionId) private view returns (bool) {
    uint256 kittyId = auctionIdToKittyId[auctionId];


    uint256 auctionThatCurrentlyOwnsKitty = kittyIdToAuctionId[kittyId];

    return(auctionThatCurrentlyOwnsKitty == auctionId);
  }
}












contract FeeCollector is Ownable {
  using SafeMath for uint256;
  uint256 feeBalance = 0;



  modifier requiresFee(uint256 feeAmount) {
    require(msg.value >= feeAmount);
    feeBalance = feeBalance.add(feeAmount);
    msg.sender.transfer(msg.value.sub(feeAmount));
    _;
  }

  event FeesWithdrawn(address indexed owner, uint256 indexed withdrawalAmount);

  function withdrawFees() external onlyOwner {
    uint256 feeAmountWithdrawn = feeBalance;
    feeBalance = 0;
    owner.transfer(feeAmountWithdrawn);
    emit FeesWithdrawn(owner, feeAmountWithdrawn);
  }
}











contract DescendingPriceAuction is AuctionBase, FeeCollector {
  using SafeMath for uint256;

  mapping(uint256 => uint256) public auctionIdToStartPrice;
  mapping(uint256 => uint256) public auctionIdToPriceFloor;
  mapping(uint256 => uint256) public auctionIdToStartBlock;
  mapping(uint256 => uint256) public auctionIdToPriceFloorBlock;
  mapping(uint256 => bool) public auctionIdToAcceptingBids;

  modifier onlyAcceptingBids(uint256 auctionId) {
    require(auctionIdToAcceptingBids[auctionId]);
    _;
  }




  function bid(uint256 auctionId) whenNotPaused onlyAcceptingBids(auctionId) whenNotPaused external payable {

    require(msg.sender != 0x0);

    uint256 currentPrice = getCurrentPrice(auctionId);

    require(msg.value >= currentPrice);

    auctionIdToAcceptingBids[auctionId] = false;
    transferWinnings(msg.sender, auctionId);


    uint256 overbidAmount = msg.value.sub(currentPrice);
    if (overbidAmount > 0) {

      msg.sender.transfer(overbidAmount);
    }
    auctionIdToSeller[auctionId].transfer(currentPrice);
  }

  function cancel(uint256 auctionId) whenNotPaused public onlySeller(auctionId) {
    transferWinnings(auctionIdToSeller[auctionId], auctionId);
    auctionIdToAcceptingBids[auctionId] = false;
  }

  function getCurrentPrice(uint256 auctionId) public view returns (uint256) {

    uint256 priceFloorBlock = auctionIdToPriceFloorBlock[auctionId];
    uint256 priceFloor = auctionIdToPriceFloor[auctionId];

    if (block.number >= priceFloorBlock) {
      return priceFloor;
    }

    uint256 startBlock = auctionIdToStartBlock[auctionId];
    uint256 startPrice = auctionIdToStartPrice[auctionId];

    uint256 priceDifference = startPrice.sub(priceFloor);
    uint256 blockDifference = priceFloorBlock.sub(startBlock);

    uint256 numberOfBlocksElapsed = block.number.sub(startBlock);

    uint256 priceDecrease = numberOfBlocksElapsed.mul(priceDifference.div(blockDifference));

    return startPrice.sub(priceDecrease);
  }





  function setAuctionPricing(uint256 startPrice, uint256 priceFloor, uint256 duration, uint256 auctionId) requiresFee(startPrice.div(50)) internal {
    require(startPrice > 0 && priceFloor < startPrice && priceFloor >= 0 && duration > 0);



    auctionIdToStartBlock[auctionId] = block.number;
    auctionIdToStartPrice[auctionId] = startPrice;
    auctionIdToPriceFloor[auctionId] = priceFloor;
    auctionIdToPriceFloorBlock[auctionId] = block.number.add(duration);
    auctionIdToAcceptingBids[auctionId] = true;
  }
}











contract DescendingPriceCryptoKittyAuction is DescendingPriceAuction, CryptoKittyAuction {
  constructor(address _cryptoKittyAddress) CryptoKittyAuction(_cryptoKittyAddress) public { }





  function createAuction(uint256 startPrice, uint256 priceFloor, uint256 duration, uint256 kittyId) whenNotPaused public payable returns (uint256) {
    uint256 auctionId = createEmptyAuction();
    setAuctionPricing(startPrice, priceFloor, duration, auctionId);
    setAuctionAsset(kittyId, auctionId);
    return auctionId;
  }
}
