pragma solidity ^0.5.12;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";


interface AsyncArtwork_v1 {
    function getControlToken(uint256 controlTokenId) external view returns (int256[] memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}





contract AsyncArtwork_v2 is Initializable, ERC721, ERC721Enumerable, ERC721Metadata {

    event PlatformAddressUpdated(
        address platformAddress
    );

    event PermissionUpdated(
        uint256 tokenId,
        address tokenOwner,
        address permissioned
    );


    event CreatorWhitelisted(
        uint256 tokenId,
        uint256 layerCount,
        address creator
    );


    event PlatformSalePercentageUpdated (
        uint256 tokenId,
        uint256 platformFirstPercentage,
        uint256 platformSecondPercentage
    );


    event ArtistSecondSalePercentUpdated (
        uint256 artistSecondPercentage
    );


    event BidProposed(
        uint256 tokenId,
        uint256 bidAmount,
        address bidder
    );


    event BidWithdrawn(
        uint256 tokenId
    );


    event BuyPriceSet(
        uint256 tokenId,
        uint256 price
    );


    event TokenSale(

        uint256 tokenId,

        uint256 salePrice,

        address buyer
    );


    event ControlLeverUpdated(

        uint256 tokenId,

        uint256 priorityTip,

        int256 numRemainingUpdates,

        uint256[] leverIds,

        int256[] previousValues,

        int256[] updatedValues
    );


    struct ControlToken {

        uint256 numControlLevers;

        int256 numRemainingUpdates;

        bool exists;

        bool isSetup;

        mapping(uint256 => ControlLever) levers;
    }


    struct ControlLever {

        int256 minValue;

        int256 maxValue;

        int256 currentValue;

        bool exists;
    }


    struct PendingBid {

        address payable bidder;

        uint256 amount;

        bool exists;
    }

    struct WhitelistReservation {

        address creator;

        uint256 layerCount;
    }


    mapping(uint256 => bool) public tokenDidHaveFirstSale;

    mapping(uint256 => bool) public tokenURILocked;

    mapping(uint256 => uint256) public buyPrices;

    mapping(address => uint256) public failedTransferCredits;

    mapping(uint256 => uint256) public platformFirstSalePercentages;

    mapping(uint256 => uint256) public platformSecondSalePercentages;

    mapping(uint256 => WhitelistReservation) public creatorWhitelist;

    mapping(uint256 => address payable[]) public uniqueTokenCreators;

    mapping(uint256 => PendingBid) public pendingBids;


    mapping(uint256 => ControlToken) controlTokenMapping;

    mapping(address => mapping(uint256 => address)) public permissionedControllers;

    uint256 public artistSecondSalePercentage;

    uint256 public expectedTokenSupply;

    uint256 public minBidIncreasePercent;

    address payable public platformAddress;

    address public upgraderAddress;

    function initialize(string memory name, string memory symbol, uint256 initialExpectedTokenSupply, address _upgraderAddress) public initializer {
        ERC721.initialize();
        ERC721Enumerable.initialize();
        ERC721Metadata.initialize(name, symbol);


        artistSecondSalePercentage = 10;


        minBidIncreasePercent = 1;


        platformAddress = msg.sender;


        upgraderAddress = _upgraderAddress;


        expectedTokenSupply = initialExpectedTokenSupply;

        require(expectedTokenSupply > 0);
    }


    modifier onlyPlatform() {
        require(msg.sender == platformAddress);
        _;
    }

    modifier onlyWhitelistedCreator(uint256 masterTokenId, uint256 layerCount) {
        require(creatorWhitelist[masterTokenId].creator == msg.sender);
        require(creatorWhitelist[masterTokenId].layerCount == layerCount);
        _;
    }


    function whitelistTokenForCreator(address creator, uint256 masterTokenId, uint256 layerCount,
        uint256 platformFirstSalePercentage, uint256 platformSecondSalePercentage) external onlyPlatform {

        require(masterTokenId == expectedTokenSupply);

        require (layerCount > 0);

        creatorWhitelist[masterTokenId] = WhitelistReservation(creator, layerCount);

        expectedTokenSupply = masterTokenId.add(layerCount).add(1);

        platformFirstSalePercentages[masterTokenId] = platformFirstSalePercentage;
        platformSecondSalePercentages[masterTokenId] = platformSecondSalePercentage;

        emit CreatorWhitelisted(masterTokenId, layerCount, creator);
    }


    function updatePlatformAddress(address payable newPlatformAddress) external onlyPlatform {
        platformAddress = newPlatformAddress;

        emit PlatformAddressUpdated(newPlatformAddress);
    }


    function waiveFirstSaleRequirement(uint256 tokenId) external onlyPlatform {

        tokenDidHaveFirstSale[tokenId] = true;
    }


    function updatePlatformSalePercentage(uint256 tokenId, uint256 platformFirstSalePercentage,
        uint256 platformSecondSalePercentage) external onlyPlatform {

        platformFirstSalePercentages[tokenId] = platformFirstSalePercentage;
        platformSecondSalePercentages[tokenId] = platformSecondSalePercentage;

        emit PlatformSalePercentageUpdated(tokenId, platformFirstSalePercentage, platformSecondSalePercentage);
    }

    function updateMinimumBidIncreasePercent(uint256 _minBidIncreasePercent) external onlyPlatform {
        require((_minBidIncreasePercent > 0) && (_minBidIncreasePercent <= 50), "Bid increases must be within 0-50%");

        minBidIncreasePercent = _minBidIncreasePercent;
    }

    function updateTokenURI(uint256 tokenId, string calldata tokenURI) external onlyPlatform {

        require(_exists(tokenId));

        require(tokenURILocked[tokenId] == false);

        super._setTokenURI(tokenId, tokenURI);
    }


    function lockTokenURI(uint256 tokenId) external onlyPlatform {

        require(_exists(tokenId));

        tokenURILocked[tokenId] = true;
    }


    function updateArtistSecondSalePercentage(uint256 _artistSecondSalePercentage) external onlyPlatform {

        artistSecondSalePercentage = _artistSecondSalePercentage;

        emit ArtistSecondSalePercentUpdated(artistSecondSalePercentage);
    }

    function setupControlToken(uint256 controlTokenId, string calldata controlTokenURI,
        int256[] calldata leverMinValues,
        int256[] calldata leverMaxValues,
        int256[] calldata leverStartValues,
        int256 numAllowedUpdates,
        address payable[] calldata additionalCollaborators
    ) external {

        require (leverMinValues.length <= 500, "Too many control levers.");

        require (additionalCollaborators.length <= 50, "Too many collaborators.");

        require(controlTokenMapping[controlTokenId].exists, "No control token found");

        require(controlTokenMapping[controlTokenId].isSetup == false, "Already setup");

        require(uniqueTokenCreators[controlTokenId][0] == msg.sender, "Must be control token artist");

        require((leverMinValues.length == leverMaxValues.length) && (leverMaxValues.length == leverStartValues.length), "Values array mismatch");

        require((numAllowedUpdates == -1) || (numAllowedUpdates > 0), "Invalid allowed updates");

        super._safeMint(msg.sender, controlTokenId);

        super._setTokenURI(controlTokenId, controlTokenURI);

        controlTokenMapping[controlTokenId] = ControlToken(leverStartValues.length, numAllowedUpdates, true, true);

        for (uint256 k = 0; k < leverStartValues.length; k++) {

            require(leverMaxValues[k] >= leverMinValues[k], "Max val must >= min");

            require((leverStartValues[k] >= leverMinValues[k]) && (leverStartValues[k] <= leverMaxValues[k]), "Invalid start val");

            controlTokenMapping[controlTokenId].levers[k] = ControlLever(leverMinValues[k],
                leverMaxValues[k], leverStartValues[k], true);
        }

        for (uint256 i = 0; i < additionalCollaborators.length; i++) {

            require(additionalCollaborators[i] != address(0));

            uniqueTokenCreators[controlTokenId].push(additionalCollaborators[i]);
        }
    }


    function upgradeV1Token(uint256 tokenId, address v1Address, bool isControlToken, address to,
        uint256 platformFirstPercentageForToken, uint256 platformSecondPercentageForToken, bool hasTokenHadFirstSale,
        address payable[] calldata uniqueTokenCreatorsForToken) external {

        AsyncArtwork_v1 v1Token = AsyncArtwork_v1(v1Address);


        require(msg.sender == upgraderAddress, "Only upgrader can call.");


        uniqueTokenCreators[tokenId] = uniqueTokenCreatorsForToken;

        if (isControlToken) {

            int256[] memory controlToken = v1Token.getControlToken(tokenId);

            require(controlToken.length % 3 == 0, "Invalid control token.");

            require(controlToken.length > 0, "Control token must have levers");


            controlTokenMapping[tokenId] = ControlToken(controlToken.length / 3, -1, true, true);



            for (uint256 k = 0; k < controlToken.length; k+=3) {
                controlTokenMapping[tokenId].levers[k / 3] = ControlLever(controlToken[k],
                    controlToken[k + 1], controlToken[k + 2], true);
            }
        }


        platformFirstSalePercentages[tokenId] = platformFirstPercentageForToken;

        platformSecondSalePercentages[tokenId] = platformSecondPercentageForToken;


        tokenDidHaveFirstSale[tokenId] = hasTokenHadFirstSale;


        super._safeMint(to, tokenId);


        super._setTokenURI(tokenId, v1Token.tokenURI(tokenId));
    }

    function mintArtwork(uint256 masterTokenId, string calldata artworkTokenURI, address payable[] calldata controlTokenArtists)
        external onlyWhitelistedCreator(masterTokenId, controlTokenArtists.length) {

        require(masterTokenId > 0);

        super._safeMint(msg.sender, masterTokenId);

        super._setTokenURI(masterTokenId, artworkTokenURI);

        uniqueTokenCreators[masterTokenId].push(msg.sender);

        for (uint256 i = 0; i < controlTokenArtists.length; i++) {

            require(controlTokenArtists[i] != address(0));

            uint256 controlTokenId = masterTokenId + i + 1;

            uniqueTokenCreators[controlTokenId].push(controlTokenArtists[i]);

            controlTokenMapping[controlTokenId] = ControlToken(0, 0, true, false);


            platformFirstSalePercentages[controlTokenId] = platformFirstSalePercentages[masterTokenId];

            platformSecondSalePercentages[controlTokenId] = platformSecondSalePercentages[masterTokenId];

            if (controlTokenArtists[i] != msg.sender) {
                bool containsControlTokenArtist = false;

                for (uint256 k = 0; k < uniqueTokenCreators[masterTokenId].length; k++) {
                    if (uniqueTokenCreators[masterTokenId][k] == controlTokenArtists[i]) {
                        containsControlTokenArtist = true;
                        break;
                    }
                }
                if (containsControlTokenArtist == false) {
                    uniqueTokenCreators[masterTokenId].push(controlTokenArtists[i]);
                }
            }
        }
    }

    function bid(uint256 tokenId) external payable {

        require(msg.value > 0);

        require(_isApprovedOrOwner(msg.sender, tokenId) == false);

        if (pendingBids[tokenId].exists) {

            require(msg.value >= (pendingBids[tokenId].amount.mul(minBidIncreasePercent.add(100)).div(100)), "Bid must increase by min %");

            safeFundsTransfer(pendingBids[tokenId].bidder, pendingBids[tokenId].amount);
        }

        pendingBids[tokenId] = PendingBid(msg.sender, msg.value, true);

        emit BidProposed(tokenId, msg.value, msg.sender);
    }

    function withdrawBid(uint256 tokenId) external {

        require((pendingBids[tokenId].bidder == msg.sender) || (msg.sender == platformAddress));

        _withdrawBid(tokenId);
    }
    function _withdrawBid(uint256 tokenId) internal {
        require(pendingBids[tokenId].exists);

        safeFundsTransfer(pendingBids[tokenId].bidder, pendingBids[tokenId].amount);

        pendingBids[tokenId] = PendingBid(address(0), 0, false);

        emit BidWithdrawn(tokenId);
    }



    function takeBuyPrice(uint256 tokenId, int256 expectedRemainingUpdates) external payable {

        require(_isApprovedOrOwner(msg.sender, tokenId) == false);

        uint256 saleAmount = buyPrices[tokenId];

        require(saleAmount > 0);

        require(msg.value == saleAmount);

        if (controlTokenMapping[tokenId].exists) {

            require(controlTokenMapping[tokenId].numRemainingUpdates == expectedRemainingUpdates);
        }

        if (pendingBids[tokenId].exists) {

            safeFundsTransfer(pendingBids[tokenId].bidder, pendingBids[tokenId].amount);

            pendingBids[tokenId] = PendingBid(address(0), 0, false);
        }
        onTokenSold(tokenId, saleAmount, msg.sender);
    }


    function distributeFundsToCreators(uint256 amount, address payable[] memory creators) private {
        uint256 creatorShare = amount.div(creators.length);

        for (uint256 i = 0; i < creators.length; i++) {
            safeFundsTransfer(creators[i], creatorShare);
        }
    }



    function onTokenSold(uint256 tokenId, uint256 saleAmount, address to) private {

        if (tokenDidHaveFirstSale[tokenId]) {

            uint256 platformAmount = saleAmount.mul(platformSecondSalePercentages[tokenId]).div(100);
            safeFundsTransfer(platformAddress, platformAmount);

            uint256 creatorAmount = saleAmount.mul(artistSecondSalePercentage).div(100);
            distributeFundsToCreators(creatorAmount, uniqueTokenCreators[tokenId]);

            address payable payableOwner = address(uint160(ownerOf(tokenId)));

            safeFundsTransfer(payableOwner, saleAmount.sub(platformAmount).sub(creatorAmount));
        } else {
            tokenDidHaveFirstSale[tokenId] = true;

            uint256 platformAmount = saleAmount.mul(platformFirstSalePercentages[tokenId]).div(100);
            safeFundsTransfer(platformAddress, platformAmount);


            distributeFundsToCreators(saleAmount.sub(platformAmount), uniqueTokenCreators[tokenId]);
        }

        pendingBids[tokenId] = PendingBid(address(0), 0, false);

        _transferFrom(ownerOf(tokenId), to, tokenId);

        emit TokenSale(tokenId, saleAmount, to);
    }



    function acceptBid(uint256 tokenId, uint256 minAcceptedAmount) external {

        require(_isApprovedOrOwner(msg.sender, tokenId));

        require(pendingBids[tokenId].exists);

        require(pendingBids[tokenId].amount >= minAcceptedAmount);

        onTokenSold(tokenId, pendingBids[tokenId].amount, pendingBids[tokenId].bidder);
    }


    function makeBuyPrice(uint256 tokenId, uint256 amount) external {

        require(_isApprovedOrOwner(msg.sender, tokenId));

        buyPrices[tokenId] = amount;

        emit BuyPriceSet(tokenId, amount);
    }


    function getNumRemainingControlUpdates(uint256 controlTokenId) external view returns (int256) {
        require(controlTokenMapping[controlTokenId].exists, "Token does not exist.");

        return controlTokenMapping[controlTokenId].numRemainingUpdates;
    }


    function getControlToken(uint256 controlTokenId) external view returns(int256[] memory) {
        require(controlTokenMapping[controlTokenId].exists, "Token does not exist.");

        ControlToken storage controlToken = controlTokenMapping[controlTokenId];

        int256[] memory returnValues = new int256[](controlToken.numControlLevers.mul(3));
        uint256 returnValIndex = 0;


        for (uint256 i = 0; i < controlToken.numControlLevers; i++) {
            returnValues[returnValIndex] = controlToken.levers[i].minValue;
            returnValIndex = returnValIndex.add(1);

            returnValues[returnValIndex] = controlToken.levers[i].maxValue;
            returnValIndex = returnValIndex.add(1);

            returnValues[returnValIndex] = controlToken.levers[i].currentValue;
            returnValIndex = returnValIndex.add(1);
        }

        return returnValues;
    }


    function grantControlPermission(uint256 tokenId, address permissioned) external {
        permissionedControllers[msg.sender][tokenId] = permissioned;

        emit PermissionUpdated(tokenId, msg.sender, permissioned);
    }



    function useControlToken(uint256 controlTokenId, uint256[] calldata leverIds, int256[] calldata newValues) external payable {

        require(_isApprovedOrOwner(msg.sender, controlTokenId) || (permissionedControllers[ownerOf(controlTokenId)][controlTokenId] == msg.sender),
            "Owner or permissioned only");

        require(controlTokenMapping[controlTokenId].exists, "Token does not exist.");

        ControlToken storage controlToken = controlTokenMapping[controlTokenId];

        require((controlToken.numRemainingUpdates == -1) || (controlToken.numRemainingUpdates > 0), "No more updates allowed");

        int256[] memory previousValues = new int256[](newValues.length);

        for (uint256 i = 0; i < leverIds.length; i++) {

            ControlLever storage lever = controlTokenMapping[controlTokenId].levers[leverIds[i]];


            require((newValues[i] >= lever.minValue) && (newValues[i] <= lever.maxValue), "Invalid val");


            require(newValues[i] != lever.currentValue, "Must provide different val");



            int256 previousValue = lever.currentValue;


            lever.currentValue = newValues[i];


            previousValues[i] = previousValue;
        }


        if (msg.value > 0) {
            safeFundsTransfer(platformAddress, msg.value);
        }


        if (controlToken.numRemainingUpdates > 0) {

            controlToken.numRemainingUpdates = controlToken.numRemainingUpdates - 1;


            if (pendingBids[controlTokenId].exists) {
                _withdrawBid(controlTokenId);
            }
        }


        emit ControlLeverUpdated(controlTokenId, msg.value, controlToken.numRemainingUpdates, leverIds, previousValues, newValues);
    }


    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0);
        require(address(this).balance >= amount);

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call.value(amount)("");
        require(successfulWithdraw);
    }


    function safeFundsTransfer(address payable recipient, uint256 amount) internal {

        (bool success, ) = recipient.call.value(amount).gas(2300)("");

        if (success == false) {
            failedTransferCredits[recipient] = failedTransferCredits[recipient].add(amount);
        }
    }


    function _transferFrom(address from, address to, uint256 tokenId) internal {

        buyPrices[tokenId] = 0;

        super._transferFrom(from, to, tokenId);
    }
}
