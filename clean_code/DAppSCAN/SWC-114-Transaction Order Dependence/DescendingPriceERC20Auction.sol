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



contract Whitelistable is Ownable {
  mapping(address => bool) public whitelist;

  event AddToWhitelist(address _address);
  event RemoveFromWhitelist(address _address);

  modifier isWhitelisted(address _addr) {
    require(inWhitelist(_addr));
    _;
  }







  function inWhitelist(address _address) public view returns (bool) {
    return whitelist[_address];
  }







  function addToWhitelist(address _address) public onlyOwner returns (bool) {
    if (whitelist[_address]) {

      return false;
    }

    whitelist[_address] = true;
    emit AddToWhitelist(_address);
    return true;
  }







  function removeFromWhitelist(address _address) public onlyOwner returns (bool) {
    if (!whitelist[_address]) {

      return false;
    }

    whitelist[_address] = false;
    emit RemoveFromWhitelist(_address);
    return true;
  }
}








contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}







contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}











contract ERC20Auction is AuctionBase, Whitelistable {
  mapping(uint256 => address) public auctionIdToERC20Address;
  mapping(uint256 => uint256) public auctionIdToAmount;




  function setAuctionAsset(address tokenAddress, uint256 tokenAmount, uint256 auctionId) isWhitelisted(tokenAddress) internal {

    require(tokenAmount > 0 && auctionId != 0);
    auctionIdToERC20Address[auctionId] = tokenAddress;
    auctionIdToAmount[auctionId] = tokenAmount;
    escrowERC20Tokens(msg.sender, tokenAddress, tokenAmount);
  }

  function transferWinnings(address recipient, uint256 auctionId) internal {
    require(auctionId != 0);
    require(auctionHasAssets(auctionId));
    ERC20 erc20Contract = ERC20(auctionIdToERC20Address[auctionId]);


    uint256 tokenAmount = auctionIdToAmount[auctionId];
    auctionIdToAmount[auctionId] = 0;
    erc20Contract.transfer(recipient, tokenAmount);
  }




  function escrowERC20Tokens(address auctionSeller, address tokenAddress, uint256 tokenAmount) private {
    ERC20 erc20Contract = ERC20(tokenAddress);


    erc20Contract.transferFrom(auctionSeller, this, tokenAmount);
  }

  function auctionHasAssets(uint256 auctionId) private view returns (bool) {
    return (auctionIdToAmount[auctionId] != 0);
  }
}











contract DescendingPriceERC20Auction is DescendingPriceAuction, ERC20Auction {














  function createAuction(
    uint256 startPrice,
    uint256 priceFloor,
    uint256 duration,
    address tokenAddress,
    uint256 tokenAmount) whenNotPaused public payable returns (uint256)
  {
    uint256 auctionId = createEmptyAuction();
    setAuctionPricing(startPrice, priceFloor, duration, auctionId);
    setAuctionAsset(tokenAddress, tokenAmount, auctionId);
    return auctionId;
  }
}
