

pragma solidity 0.6.12;
import "../math/SafeMathUint128.sol";
import "../interfaces/IHEZToken.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";









contract HermezAuctionProtocol is Initializable, ReentrancyGuardUpgradeSafe {
    using SafeMath128 for uint128;

    struct Coordinator {
        address forger;
        string coordinatorURL;
    }



    struct SlotState {
        address bidder;
        bool fulfilled;
        uint128 bidAmount;
        uint128 closedMinBid;
    }



    bytes4 private constant _PERMIT_SIGNATURE = 0xd505accf;


    uint8 public constant BLOCKS_PER_SLOT = 40;

    uint128 public constant INITIAL_MINIMAL_BIDDING = 10 * (1e18);


    IHEZToken public tokenHEZ;

    address public hermezRollup;

    address private _governanceAddress;

    address private _donationAddress;

    address private _bootCoordinator;

    uint128[6] private _defaultSlotSetBid;

    uint128 public genesisBlock;

    uint16 private _closedAuctionSlots;

    uint16 private _openAuctionSlots;

    uint16[3] private _allocationRatio;

    uint16 private _outbidding;


    uint8 private _slotDeadline;


    mapping(uint128 => SlotState) public slots;

    mapping(address => uint128) public pendingBalances;

    mapping(address => Coordinator) public coordinators;

    event NewBid(
        uint128 indexed slot,
        uint128 bidAmount,
        address indexed bidder
    );
    event NewSlotDeadline(uint8 newSlotDeadline);
    event NewClosedAuctionSlots(uint16 newClosedAuctionSlots);
    event NewOutbidding(uint16 newOutbidding);
    event NewDonationAddress(address indexed newDonationAddress);
    event NewBootCoordinator(address indexed newBootCoordinator);
    event NewOpenAuctionSlots(uint16 newOpenAuctionSlots);
    event NewAllocationRatio(uint16[3] newAllocationRatio);
    event SetCoordinator(
        address indexed bidder,
        address indexed forger,
        string coordinatorURL
    );
    event NewForgeAllocated(
        address indexed bidder,
        address indexed forger,
        uint128 indexed slotToForge,
        uint128 burnAmount,
        uint128 donationAmount,
        uint128 governanceAmount
    );
    event NewDefaultSlotSetBid(uint128 slotSet, uint128 newInitialMinBid);
    event NewForge(address indexed forger, uint128 indexed slotToForge);
    event HEZClaimed(address indexed owner, uint128 amount);

    modifier onlyGovernance() {
        require(
            _governanceAddress == msg.sender,
            "HermezAuctionProtocol::onlyGovernance: ONLY_GOVERNANCE"
        );
        _;
    }











    function hermezAuctionProtocolInitializer(
        address token,
        uint128 genesis,
        address hermezRollupAddress,
        address governanceAddress,
        address donationAddress,
        address bootCoordinatorAddress
    ) public initializer {
        __ReentrancyGuard_init_unchained();
        _outbidding = 1000;
        _slotDeadline = 20;
        _closedAuctionSlots = 2;
        _openAuctionSlots = 4320;
        _allocationRatio = [4000, 4000, 2000];
        _defaultSlotSetBid = [
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING
        ];

        tokenHEZ = IHEZToken(token);
        require(
            genesis >= block.number + (BLOCKS_PER_SLOT * _closedAuctionSlots),
            "HermezAuctionProtocol::hermezAuctionProtocolInitializer GENESIS_BELOW_MINIMAL"
        );
        genesisBlock = genesis;
        hermezRollup = hermezRollupAddress;
        _governanceAddress = governanceAddress;
        _donationAddress = donationAddress;
        _bootCoordinator = bootCoordinatorAddress;
    }





    function getSlotDeadline() external view returns (uint8) {
        return _slotDeadline;
    }






    function setSlotDeadline(uint8 newDeadline) external onlyGovernance {
        require(
            newDeadline <= BLOCKS_PER_SLOT,
            "HermezAuctionProtocol::setSlotDeadline: GREATER_THAN_BLOCKS_PER_SLOT"
        );
        _slotDeadline = newDeadline;
        emit NewSlotDeadline(_slotDeadline);
    }





    function getOpenAuctionSlots() external view returns (uint16) {
        return _openAuctionSlots;
    }









    function setOpenAuctionSlots(uint16 newOpenAuctionSlots)
        external
        onlyGovernance
    {
        require(
            newOpenAuctionSlots >= _closedAuctionSlots,
            "HermezAuctionProtocol::setOpenAuctionSlots: SMALLER_THAN_CLOSED_AUCTION_SLOTS"
        );
        _openAuctionSlots = newOpenAuctionSlots;
        emit NewOpenAuctionSlots(_openAuctionSlots);
    }





    function getClosedAuctionSlots() external view returns (uint16) {
        return _closedAuctionSlots;
    }









    function setClosedAuctionSlots(uint16 newClosedAuctionSlots)
        external
        onlyGovernance
    {
        require(
            newClosedAuctionSlots <= _openAuctionSlots,
            "HermezAuctionProtocol::setClosedAuctionSlots: GREATER_THAN_CLOSED_AUCTION_SLOTS"
        );
        _closedAuctionSlots = newClosedAuctionSlots;
        emit NewClosedAuctionSlots(_closedAuctionSlots);
    }





    function getOutbidding() external view returns (uint16) {
        return _outbidding;
    }







    function setOutbidding(uint16 newOutbidding) external onlyGovernance {
        _outbidding = newOutbidding;
        emit NewOutbidding(_outbidding);
    }





    function getAllocationRatio() external view returns (uint16[3] memory) {
        return _allocationRatio;
    }






    function setAllocationRatio(uint16[3] memory newAllocationRatio)
        external
        onlyGovernance
    {

        require(
            (newAllocationRatio[0] +
                newAllocationRatio[1] +
                newAllocationRatio[2]) == 10000,
            "HermezAuctionProtocol::setAllocationRatio: ALLOCATION_RATIO_NOT_VALID"
        );
        _allocationRatio = newAllocationRatio;
        emit NewAllocationRatio(_allocationRatio);
    }





    function getDonationAddress() external view returns (address) {
        return _donationAddress;
    }






    function setDonationAddress(address newDonationAddress)
        external
        onlyGovernance
    {
        require(
            newDonationAddress != address(0),
            "HermezAuctionProtocol::setDonationAddress: NOT_VALID_ADDRESS"
        );
        _donationAddress = newDonationAddress;
        emit NewDonationAddress(_donationAddress);
    }





    function getBootCoordinator() external view returns (address) {
        return _bootCoordinator;
    }






    function setBootCoordinator(address newBootCoordinator)
        external
        onlyGovernance
    {
        _bootCoordinator = newBootCoordinator;
        emit NewBootCoordinator(_bootCoordinator);
    }






    function getDefaultSlotSetBid(uint8 slotSet) public view returns (uint128) {
        return _defaultSlotSetBid[slotSet];
    }








    function changeDefaultSlotSetBid(uint128 slotSet, uint128 newInitialMinBid)
        external
        onlyGovernance
    {
        require(
            slotSet <= _defaultSlotSetBid.length,
            "HermezAuctionProtocol::changeDefaultSlotSetBid: NOT_VALID_SLOT_SET"
        );
        require(
            _defaultSlotSetBid[slotSet] != 0,
            "HermezAuctionProtocol::changeDefaultSlotSetBid: SLOT_DECENTRALIZED"
        );

        uint128 current = getCurrentSlotNumber();

        for (uint128 i = current; i <= current + _closedAuctionSlots; i++) {

            if (slots[i].closedMinBid == 0) {
                slots[i].closedMinBid = _defaultSlotSetBid[getSlotSet(i)];
            }
        }
        _defaultSlotSetBid[slotSet] = newInitialMinBid;
        emit NewDefaultSlotSetBid(slotSet, newInitialMinBid);
    }








    function setCoordinator(address forger, string memory coordinatorURL)
        external
    {
        require(
            keccak256(abi.encodePacked(coordinatorURL)) !=
                keccak256(abi.encodePacked("")),
            "HermezAuctionProtocol::setCoordinator: NOT_VALID_URL"
        );
        coordinators[msg.sender].forger = forger;
        coordinators[msg.sender].coordinatorURL = coordinatorURL;
        emit SetCoordinator(msg.sender, forger, coordinatorURL);
    }





    function getCurrentSlotNumber() public view returns (uint128) {
        return getSlotNumber(uint128(block.number));
    }






    function getSlotNumber(uint128 blockNumber) public view returns (uint128) {
        return
            (blockNumber >= genesisBlock)
                ? ((blockNumber - genesisBlock) / BLOCKS_PER_SLOT)
                : uint128(0);
    }






    function getSlotSet(uint128 slot) public view returns (uint128) {
        return slot.mod(uint128(_defaultSlotSetBid.length));
    }







    function getMinBidBySlot(uint128 slot) public view returns (uint128) {
        require(
            slot >= (getCurrentSlotNumber() + _closedAuctionSlots),
            "HermezAuctionProtocol::getMinBidBySlot: AUCTION_CLOSED"
        );
        uint128 slotSet = getSlotSet(slot);


        return
            (slots[slot].bidAmount == 0)
                ? _defaultSlotSetBid[slotSet].add(
                    _defaultSlotSetBid[slotSet].mul(_outbidding).div(
                        uint128(10000)
                    )
                )
                : slots[slot].bidAmount.add(
                    slots[slot].bidAmount.mul(_outbidding).div(uint128(10000))
                );
    }









    function processBid(
        uint128 amount,
        uint128 slot,
        uint128 bidAmount,
        bytes calldata permit
    ) external {

        require(
            coordinators[msg.sender].forger != address(0),
            "HermezAuctionProtocol::processBid: COORDINATOR_NOT_REGISTERED"
        );
        require(
            slot >= (getCurrentSlotNumber() + _closedAuctionSlots),
            "HermezAuctionProtocol::processBid: AUCTION_CLOSED"
        );
        require(
            bidAmount >= getMinBidBySlot(slot),
            "HermezAuctionProtocol::processBid: BELOW_MINIMUM"
        );

        require(
            slot <
                (getCurrentSlotNumber() +
                    _closedAuctionSlots +
                    _openAuctionSlots),
            "HermezAuctionProtocol::processBid: AUCTION_NOT_OPEN"
        );

        if (permit.length != 0) {
            _permit(amount, permit);
        }

        require(
            tokenHEZ.transferFrom(msg.sender, address(this), amount),
            "HermezAuctionProtocol::processBid: TOKEN_TRANSFER_FAILED"
        );
        pendingBalances[msg.sender] = pendingBalances[msg.sender].add(amount);

        require(
            pendingBalances[msg.sender] >= bidAmount,
            "HermezAuctionProtocol::processBid: NOT_ENOUGH_BALANCE"
        );
        _doBid(slot, bidAmount, msg.sender);
    }












    function processMultiBid(
        uint128 amount,
        uint128 startingSlot,
        uint128 endingSlot,
        bool[6] memory slotSets,
        uint128 maxBid,
        uint128 minBid,
        bytes calldata permit
    ) external {
        require(
            startingSlot >= (getCurrentSlotNumber() + _closedAuctionSlots),
            "HermezAuctionProtocol::processMultiBid AUCTION_CLOSED"
        );
        require(
            endingSlot <
                (getCurrentSlotNumber() +
                    _closedAuctionSlots +
                    _openAuctionSlots),
            "HermezAuctionProtocol::processMultiBid AUCTION_NOT_OPEN"
        );
        require(
            maxBid >= minBid,
            "HermezAuctionProtocol::processMultiBid MAXBID_GREATER_THAN_MINBID"
        );

        require(
            coordinators[msg.sender].forger != address(0),
            "HermezAuctionProtocol::processMultiBid COORDINATOR_NOT_REGISTERED"
        );

        if (permit.length != 0) {
            _permit(amount, permit);
        }

        require(
            tokenHEZ.transferFrom(msg.sender, address(this), amount),
            "HermezAuctionProtocol::processMultiBid: TOKEN_TRANSFER_FAILED"
        );
        pendingBalances[msg.sender] = pendingBalances[msg.sender].add(amount);

        uint128 bidAmount;
        for (uint128 slot = startingSlot; slot <= endingSlot; slot++) {
            uint128 minBidBySlot = getMinBidBySlot(slot);

            if (minBidBySlot <= minBid) {
                bidAmount = minBid;


            } else if (minBidBySlot > minBid && minBidBySlot <= maxBid) {
                bidAmount = minBidBySlot;

            } else {
                continue;
            }


            if (slotSets[getSlotSet(slot)]) {
                require(
                    pendingBalances[msg.sender] >= bidAmount,
                    "HermezAuctionProtocol::processMultiBid NOT_ENOUGH_BALANCE"
                );
                _doBid(slot, bidAmount, msg.sender);
            }
        }
    }






    function _permit(uint256 _amount, bytes calldata _permitData) internal {
        bytes4 sig = abi.decode(_permitData, (bytes4));

        require(
            sig == _PERMIT_SIGNATURE,
            "HermezAuctionProtocol::_permit: NOT_VALID_CALL"
        );
        (
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(
            _permitData[4:],
            (address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        require(
            owner == msg.sender,
            "HermezAuctionProtocol::_permit: OWNER_NOT_EQUAL_SENDER"
        );
        require(
            spender == address(this),
            "HermezAuctionProtocol::_permit: SPENDER_NOT_EQUAL_THIS"
        );
        require(
            value == _amount,
            "HermezAuctionProtocol::_permit: WRONG_AMOUNT"
        );



























    function _doBid(
        uint128 slot,
        uint128 bidAmount,
        address bidder
    ) private {
        address prevBidder = slots[slot].bidder;
        uint128 prevBidValue = slots[slot].bidAmount;

        pendingBalances[bidder] = pendingBalances[bidder].sub(bidAmount);

        slots[slot].bidder = bidder;
        slots[slot].bidAmount = bidAmount;


        if (prevBidder != address(0) && prevBidValue != 0) {
            pendingBalances[prevBidder] = pendingBalances[prevBidder].add(
                prevBidValue
            );
        }
        emit NewBid(slot, bidAmount, bidder);
    }







    function canForge(address forger, uint256 blockNumber)
        public
        view
        returns (bool)
    {
        require(
            blockNumber < 2**128,
            "HermezAuctionProtocol::canForge WRONG_BLOCKNUMBER"
        );
        require(
            blockNumber >= genesisBlock,
            "HermezAuctionProtocol::canForge AUCTION_NOT_STARTED"
        );

        uint128 slotToForge = getSlotNumber(uint128(blockNumber));

        uint128 relativeBlock = uint128(blockNumber).sub(
            (slotToForge.mul(BLOCKS_PER_SLOT)).add(genesisBlock)
        );


        uint128 minBid = (slots[slotToForge].closedMinBid == 0)
            ? _defaultSlotSetBid[getSlotSet(slotToForge)]
            : slots[slotToForge].closedMinBid;


        if (!slots[slotToForge].fulfilled && (relativeBlock >= _slotDeadline)) {
            return true;

        } else if (
            (coordinators[slots[slotToForge].bidder].forger == forger) &&
            (slots[slotToForge].bidAmount >= minBid)
        ) {
            return true;

        } else if (
            (_bootCoordinator == forger) &&
            ((slots[slotToForge].bidAmount < minBid) ||
                (slots[slotToForge].bidAmount == 0))
        ) {
            return true;

        } else {
            return false;
        }
    }






    function forge(address forger) external {
        require(
            msg.sender == hermezRollup,
            "HermezAuctionProtocol::forge: ONLY_HERMEZ_ROLLUP"
        );
        require(
            canForge(forger, block.number),
            "HermezAuctionProtocol::forge: CANNOT_FORGE"
        );
        uint128 slotToForge = getCurrentSlotNumber();

        bool prevFulfilled = slots[slotToForge].fulfilled;



        uint128 minBid = (slots[slotToForge].closedMinBid == 0)
            ? _defaultSlotSetBid[getSlotSet(slotToForge)]
            : slots[slotToForge].closedMinBid;



        if (!prevFulfilled) {
            slots[slotToForge].fulfilled = true;



            if (
                (_bootCoordinator == forger) &&
                (slots[slotToForge].bidAmount != 0) &&
                (slots[slotToForge].bidAmount < minBid)
            ) {

                slots[slotToForge].closedMinBid = minBid;
                pendingBalances[slots[slotToForge]
                    .bidder] = pendingBalances[slots[slotToForge].bidder].add(
                    slots[slotToForge].bidAmount
                );

            } else if (_bootCoordinator != forger) {

                slots[slotToForge].closedMinBid = slots[slotToForge].bidAmount;


                uint128 burnAmount = slots[slotToForge]
                    .bidAmount
                    .mul(_allocationRatio[0])
                    .div(uint128(10000));
                uint128 donationAmount = slots[slotToForge]
                    .bidAmount
                    .mul(_allocationRatio[1])
                    .div(uint128(10000));
                uint128 governanceAmount = slots[slotToForge]
                    .bidAmount
                    .mul(_allocationRatio[2])
                    .div(uint128(10000));

                tokenHEZ.burn(burnAmount);

                pendingBalances[_donationAddress] = pendingBalances[_donationAddress]
                    .add(donationAmount);

                pendingBalances[_governanceAddress] = pendingBalances[_governanceAddress]
                    .add(governanceAmount);

                emit NewForgeAllocated(
                    slots[slotToForge].bidder,
                    forger,
                    slotToForge,
                    burnAmount,
                    donationAmount,
                    governanceAmount
                );
            }
        }
        emit NewForge(forger, slotToForge);
    }







    function getClaimableHEZ(address bidder) public view returns (uint128) {
        return pendingBalances[bidder];
    }





    function claimHEZ() public nonReentrant {
        uint128 pending = getClaimableHEZ(msg.sender);
        require(
            pending > 0,
            "HermezAuctionProtocol::claimHEZ: NOT_ENOUGH_BALANCE"
        );
        pendingBalances[msg.sender] = 0;
        require(
            tokenHEZ.transfer(msg.sender, pending),
            "HermezAuctionProtocol::claimHEZ: TOKEN_TRANSFER_FAILED"
        );
        emit HEZClaimed(msg.sender, pending);
    }
}
