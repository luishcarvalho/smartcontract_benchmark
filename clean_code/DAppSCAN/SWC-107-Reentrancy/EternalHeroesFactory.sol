pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../utils/Ownable.sol";
import "../interfaces/ISWSupplyManager.sol";
import "multi-token-standard/contracts/interfaces/IERC1155.sol";
import "multi-token-standard/contracts/utils/SafeMath.sol";





contract EternalHeroesFactory is Ownable {
  using SafeMath for uint256;












  uint256 constant internal decimals = 2;


  ISWSupplyManager internal factoryManager;
  IERC1155 internal arcadeumCoin;
  uint256 internal arcadeumCoinID;


  struct Order {
    address recipient;
    uint256[] tokensBoughtIDs;
    uint256[] tokensBoughtAmounts;
    uint256[] expectedTiers;
  }


  mapping(uint256 => bool) internal isPurchasable;


  uint256 internal floorPrice;
  uint256 internal tierSize;
  uint256 internal priceIncrement;





  event AssetsPurchased(address indexed recipient, uint256[] tokensBoughtIds, uint256[] tokensBoughtAmounts, uint256 totalCost);
  event IDsRegistration(uint256[] ids);
  event IDsDeregistration(uint256[] ids);














  constructor(
    address _factoryManagerAddr,
    address _arcadeumCoinAddr,
    uint256 _arcadeumCoinID,
    uint256 _floorPrice,
    uint256 _tierSize,
    uint256 _priceIncrement
  ) public {


    require(
      _factoryManagerAddr != address(0) &&
      _arcadeumCoinAddr != address(0) &&
      _floorPrice > 100000000 &&
      _tierSize > 0 &&
      _priceIncrement > 0,
      "EternalHeroesFactory#constructor: INVALID_INPUT"
    );


    factoryManager = ISWSupplyManager(_factoryManagerAddr);
    arcadeumCoin = IERC1155(_arcadeumCoinAddr);
    arcadeumCoinID = _arcadeumCoinID;
    floorPrice = _floorPrice;
    tierSize = _tierSize;
    priceIncrement = _priceIncrement;
  }












  function registerIDs(uint256[] calldata _ids) external onlyOwner() {
    uint256[] memory maxSupplies = factoryManager.getMaxSupplies(_ids);
    for (uint256 i = 0; i < _ids.length; i++) {
      require(maxSupplies[i] > 0, "EternalHeroesFactory#registerIDs: UNCAPPED_SUPPLY");
      isPurchasable[_ids[i]] = true;
    }
    emit IDsRegistration(_ids);
  }





  function deregisterIDs(uint256[] calldata _ids) external onlyOwner() {
    for (uint256 i = 0; i < _ids.length; i++) {
      isPurchasable[_ids[i]] = false;
    }
    emit IDsDeregistration(_ids);
  }





  function withdraw(address _recipient) external onlyOwner() {
    require(_recipient != address(0x0), "EternalHeroesFactory#withdraw: INVALID_RECIPIENT");
    uint256 thisBalance = arcadeumCoin.balanceOf(address(this), arcadeumCoinID);
    arcadeumCoin.safeTransferFrom(address(this), _recipient, arcadeumCoinID, thisBalance, "");
  }







  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;




  function () external {
    revert("UNSUPPORTED_METHOD");
  }










  function onERC1155Received(address, address _from, uint256 _id, uint256 _amount, bytes memory _data)
    public returns(bytes4)
  {

    require(msg.sender == address(arcadeumCoin), "EternalHeroesFactory#onERC1155Received: INVALID_ARC_ADDRESS");
    require(_id == arcadeumCoinID, "EternalHeroesFactory#onERC1155Received: INVALID_ARC_ID");


    Order memory order = abi.decode(_data, (Order));
    address recipient = order.recipient == address(0x0) ? _from : order.recipient;
    _buy(order.tokensBoughtIDs, order.tokensBoughtAmounts, order.expectedTiers, _amount, recipient);

    return ERC1155_RECEIVED_VALUE;
  }




  function onERC1155BatchReceived(
    address _operator,
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data)
    public returns(bytes4)
  {
    require(_ids.length == 1, "EternalHeroesFactory#onERC1155BatchReceived: INVALID_BATCH_TRANSFER");
    require(
      ERC1155_RECEIVED_VALUE == onERC1155Received(_operator, _from, _ids[0], _amounts[0], _data),
      "EternalHeroesFactory#onERC1155BatchReceived: INVALID_ONRECEIVED_MESSAGE"
    );

    return ERC1155_BATCH_RECEIVED_VALUE;
  }















  function _buy(
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256[] memory _expectedTiers,
    uint256 _arcAmount,
    address _recipient)
    internal
  {

    uint256 nTokens = _ids.length;
    uint256 tier_size = tierSize;


    uint256[] memory current_supplies = factoryManager.getCurrentSupplies(_ids);


    uint256 total_cost = 0;




    uint256[] memory amounts_to_mint = new uint256[](nTokens);


    for (uint256 i = 0; i < nTokens; i++) {
      uint256 id = _ids[i];
      uint256 supply = current_supplies[i];
      uint256 to_mint = 0;
      uint256 amount = _amounts[i];


      require(isPurchasable[id], "EternalHeroesFactory#_buy: ID_NOT_PURCHASABLE");



      if (i > 0) {
        require(_ids[i-1] < id, "EternalHeroesFactory#_buy: UNSORTED_OR_DUPLICATE_TOKEN_IDS");
      }


      uint256 current_tier = supply.div(tier_size);


      if (_expectedTiers[i] != current_tier) {
        amounts_to_mint[i] = 0;
        continue;
      }


      uint256 current_price = floorPrice.add(current_tier.mul(priceIncrement));


      uint256 amount_left = tier_size.sub(supply.mod(tier_size));


      to_mint = amount < amount_left ? amount : amount_left;


      total_cost = total_cost.add(to_mint.mul(current_price));
      amounts_to_mint[i] = to_mint;
    }




    uint256 refundAmount = _arcAmount.sub(total_cost);
    if (refundAmount > 0) {
      arcadeumCoin.safeTransferFrom(address(this), _recipient, arcadeumCoinID, refundAmount, "");
    }


    factoryManager.batchMint(_recipient, _ids, amounts_to_mint, "");


    emit AssetsPurchased(_recipient, _ids, amounts_to_mint, total_cost);
  }











  function getPurchasableStatus(uint256[] calldata _ids) external view returns (bool[] memory) {
    uint256 nIds = _ids.length;
    bool[] memory purchasableStatus = new bool[](nIds);


    for (uint256 i = 0; i < nIds; i++) {
      purchasableStatus[i] = isPurchasable[_ids[i]];
    }

    return purchasableStatus;
  }




  function getFactoryManager() external view returns (address) {
    return address(factoryManager);
  }




  function getArcadeumCoin() external view returns (address) {
    return address(arcadeumCoin);
  }




  function getArcadeumCoinID() external view returns (uint256) {
    return arcadeumCoinID;
  }





  function getPrices(uint256[] calldata _ids) external view returns (uint256[] memory) {
    uint256[] memory current_prices = new uint256[](_ids.length);
    uint256[] memory current_supplies = factoryManager.getCurrentSupplies(_ids);
    for (uint256 i = 0;  i < _ids.length; i++) {
      uint256 current_tier = current_supplies[i].div(tierSize);
      current_prices[i] = floorPrice.add(current_tier.mul(priceIncrement));
    }
    return current_prices;
  }





  function getPriceTiers(uint256[] calldata _ids) external view returns (uint256[] memory) {
    uint256[] memory current_tiers = new uint256[](_ids.length);
    uint256[] memory current_supplies = factoryManager.getCurrentSupplies(_ids);
    for (uint256 i = 0;  i < _ids.length; i++) {
      current_tiers[i] = current_supplies[i].div(tierSize);
    }
    return current_tiers;
  }






  function getSuppliesCurrentTier(uint256[] calldata _ids) external view returns (uint256[] memory tiers, uint256[] memory supplies) {
    tiers = new uint256[](_ids.length);
    supplies = new uint256[](_ids.length);


    uint256[] memory current_supplies = factoryManager.getCurrentSupplies(_ids);
    uint256 tier_size = tierSize;


    for (uint256 i = 0;  i < _ids.length; i++) {
      tiers[i] = current_supplies[i].div(tier_size);
      supplies[i] = tier_size.sub(current_supplies[i].mod(tier_size));
    }
    return (tiers, supplies);
  }




  function getFloorPrice() external view returns (uint256) {
    return floorPrice;
  }




  function getTierSize() external view returns (uint256) {
    return tierSize;
  }




  function getPriceIncrement() external view returns (uint256) {
    return priceIncrement;
  }













  function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    return  interfaceID == 0x01ffc9a7 ||
      interfaceID == 0x4e2312e0;
  }

}
