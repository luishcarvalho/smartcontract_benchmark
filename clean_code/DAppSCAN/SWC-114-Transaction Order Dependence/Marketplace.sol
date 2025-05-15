pragma solidity ^0.4.24;

import "../../../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";









contract ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}


contract V00_Marketplace is Ownable {




    event MarketplaceData  (address indexed party, bytes32 ipfsHash);
    event AffiliateAdded   (address indexed party, bytes32 ipfsHash);
    event AffiliateRemoved (address indexed party, bytes32 ipfsHash);
    event ListingCreated   (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingUpdated   (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingWithdrawn (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingArbitrated(address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingData      (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event OfferCreated     (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferAccepted    (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferFinalized   (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferWithdrawn   (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferFundsAdded  (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferDisputed    (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferRuling      (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash, uint ruling);
    event OfferData        (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);

    struct Listing {
        address seller;
        uint deposit;
        address depositManager;
    }

    struct Offer {
        uint value;
        uint commission;
        uint refund;
        ERC20 currency;
        address buyer;
        address affiliate;
        address arbitrator;
        uint finalizes;
        uint8 status;
    }

    Listing[] public listings;
    mapping(uint => Offer[]) public offers;
    mapping(address => bool) public allowedAffiliates;

    ERC20 public tokenAddr;

    constructor(address _tokenAddr) public {
        owner = msg.sender;
        setTokenAddr(_tokenAddr);
        allowedAffiliates[0x0] = true;
    }


    function totalListings() public view returns (uint) {
        return listings.length;
    }


    function totalOffers(uint listingID) public view returns (uint) {
        return offers[listingID].length;
    }


    function createListing(bytes32 _ipfsHash, uint _deposit, address _depositManager)
        public
    {
        _createListing(msg.sender, _ipfsHash, _deposit, _depositManager);
    }


    function createListingWithSender(
        address _seller,
        bytes32 _ipfsHash,
        uint _deposit,
        address _depositManager
    )
        public returns (bool)
    {
        require(msg.sender == address(tokenAddr), "Token must call");
        _createListing(_seller, _ipfsHash, _deposit, _depositManager);
        return true;
    }


    function _createListing(
        address _seller,
        bytes32 _ipfsHash,
        uint _deposit,
        address _depositManager
    )
        private
    {





























































































































































































































































































































































