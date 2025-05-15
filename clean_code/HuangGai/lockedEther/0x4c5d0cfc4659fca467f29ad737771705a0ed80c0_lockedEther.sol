







pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

contract SellersAuthorization {
  mapping(address => bool) internal sellers;




  function isSeller(address _seller) public view returns (bool) {
    return sellers[_seller];
  }





  function _addSeller(address _newSeller) internal returns (bool) {
    require(_newSeller != address(0), 'Address 0x0 not valid');
    sellers[_newSeller] = true;
    return sellers[_newSeller];
  }






  function _removeSeller(address _seller) internal returns (bool) {
    sellers[_seller] = false;
    return sellers[_seller];
  }




  function _pushPayment(address payable _seller, uint256 _amount) internal {
    require(_seller != address(0));
    _seller.transfer(0);
  }
}



pragma solidity ^0.6.0;










interface IERC165 {








  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



pragma solidity ^0.6.2;







interface IERC1155 is IERC165 {



  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );





  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );





  event ApprovalForAll(
    address indexed account,
    address indexed operator,
    bool approved
  );








  event URI(string value, uint256 indexed id);








  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);








  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);










  function setApprovalForAll(address operator, bool approved) external;






  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);














  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;












  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}



pragma solidity ^0.6.0;














library SafeMath {










  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }











  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }











  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }











  function mul(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }













  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }













  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;


    return c;
  }













  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }













  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}



pragma solidity ^0.6.0;











abstract contract Context {
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this;
    return msg.data;
  }
}



pragma solidity ^0.6.0;













contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );




  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }




  function owner() public view returns (address) {
    return _owner;
  }




  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }








  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }





  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



pragma solidity 0.6.10;

contract Marketplace is Ownable, SellersAuthorization {
  using SafeMath for uint256;

  uint256 public offerIdCounter = 0;
  bool public paused = false;

  event OfferCreated(
    address indexed _tokenAddress,
    address indexed _seller,
    uint256 _tokenId,
    uint256 _tokenAmount,
    uint256 _price,
    uint256 _offerIdCounter
  );
  event OfferCancelled(
    address indexed _tokenAddress,
    uint256 _tokenId,
    uint256 _offerId
  );
  event OfferSuccess(
    address indexed _tokenAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _offerIdCounter,
    address _newOwner
  );

  modifier isNotPaused() {
    require(!paused, 'Contract paused');
    _;
  }




  modifier hasTokens(
    address _token,
    address _seller,
    uint256 _tokenId,
    uint256 _tokenAmount
  ) {
    require(
      IERC1155(_token).balanceOf(_seller, _tokenId) >= _tokenAmount,
      'Seller does not own enough tokens'
    );
    _;
  }

  struct Offer {
    address tokenAddress;
    address payable seller;
    uint256 tokenId;
    uint256 tokenAmount;
    uint256 price;
  }

  mapping(uint256 => Offer) private offers;









  function createOffer(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _tokenAmount,
    uint256 _price
  )
    public
    hasTokens(_tokenAddress, msg.sender, _tokenId, _tokenAmount)
    isNotPaused
  {
    require(isSeller(msg.sender));
    require(
      IERC1155(_tokenAddress).isApprovedForAll(msg.sender, address(this)),
      'Missing approval'
    );
    require(_price > 0);

    offers[offerIdCounter].tokenAddress = _tokenAddress;
    offers[offerIdCounter].tokenId = _tokenId;
    offers[offerIdCounter].seller = msg.sender;
    offers[offerIdCounter].tokenAmount = _tokenAmount;
    offers[offerIdCounter].price = _price;

    emit OfferCreated(
      _tokenAddress,
      msg.sender,
      _tokenId,
      _tokenAmount,
      _price,
      offerIdCounter
    );

    offerIdCounter = offerIdCounter.add(1);
  }






  function deleteOffer(uint256 _offerId) public isNotPaused {
    require(
      offers[_offerId].seller == msg.sender,
      'Msg.sender is not the seller'
    );
    emit OfferCancelled(
      offers[_offerId].tokenAddress,
      offers[_offerId].tokenId,
      _offerId
    );
    delete (offers[_offerId]);
  }







  function buyToken(uint256 _offerId, uint256 _tokenAmount)
    public
    payable
    isNotPaused
    hasTokens(
      offers[_offerId].tokenAddress,
      offers[_offerId].seller,
      offers[_offerId].tokenId,
      _tokenAmount
    )
  {
    require(_tokenAmount > 0, 'Token amount cannot be 0');
    require(
      msg.value == offers[_offerId].price.mul(_tokenAmount),
      'Invalid amount'
    );
    require(
      IERC1155(offers[_offerId].tokenAddress).isApprovedForAll(
        offers[_offerId].seller,
        address(this)
      ),
      'Missing approval'
    );

    offers[_offerId].tokenAmount = offers[_offerId].tokenAmount.sub(
      _tokenAmount
    );

    IERC1155(offers[_offerId].tokenAddress).safeTransferFrom(
      offers[_offerId].seller,
      msg.sender,
      offers[_offerId].tokenId,
      _tokenAmount,
      '0x0'
    );

    _pushPayment(offers[_offerId].seller, msg.value);

    emit OfferSuccess(
      offers[_offerId].tokenAddress,
      offers[_offerId].tokenId,
      msg.value,
      _offerId,
      msg.sender
    );
  }






  function addSeller(address _newSeller) public onlyOwner {
    require(_addSeller(_newSeller));
  }






  function removeSeller(address _seller) public onlyOwner {
    require(!_removeSeller(_seller));
  }







  function getOffer(uint256 _offerId) public view returns (Offer memory) {
    Offer memory _offer = offers[_offerId];
    uint256 balanceOf = IERC1155(_offer.tokenAddress).balanceOf(
      _offer.seller,
      _offer.tokenId
    );
    if (_offer.tokenAmount > balanceOf) {
      _offer.tokenAmount = balanceOf;
    }
    return _offer;
  }





  function pauseContract(bool _paused) public onlyOwner {
    paused = _paused;
  }




  function withdrawAll() public onlyOwner {
    msg.sender.transfer(0);
  }
}
