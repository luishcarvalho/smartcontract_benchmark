

pragma solidity 0.8.4;

import { IERC20 } from "../ERC20/IERC20.sol";
import "../security/ReentrancyGuard.sol";
import "../utils/Counters.sol";
import "../utils/NonZeroAddressGuard.sol";
import "../security/Ownable.sol";




contract Vesting is ReentrancyGuard, Ownable, NonZeroAddressGuard {
    using Counters for Counters.Counter;


    Counters.Counter private _entryIds;


    IERC20 public token;

    struct Entry {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 cliff;
        uint256 lastUpdated;
        uint256 claimed;
        address recipient;
        bool isFireable;
        bool isFired;
    }


    mapping(uint256 => Entry) public entries;


    mapping(address => uint256[]) public entryIdsByRecipient;


    bool private _initialized;

    event EntryCreated(uint256 indexed entryId, address recipient, uint256 amount, uint256 start, uint256 end, uint256 cliff);
    event EntryFired(uint256 indexed entryId);
    event Claimed(address indexed recipient, uint256 amount);






    function initialize(address owner_, IERC20 token_) external nonZeroAddress(owner_) nonZeroAddress(address(token_)) {
        require(!_initialized, "Already initialized");
        owner = owner_;
        token = token_;

        _initialized = true;
    }

    struct EntryVars {
        address recipient;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 cliff;
        uint256 unlocked;
        bool isFireable;
    }







    function createEntry(EntryVars calldata entry) external onlyOwner nonReentrant returns (bool){
        return _createEntry(entry);
    }






    function fireEntry(uint256 entryId) external onlyOwner returns (bool){
        return _fireEntry(entryId);
    }






    function createEntries(EntryVars[] calldata _entries) external onlyOwner nonReentrant returns (bool){
        require(_entries.length  > 0, "empty data");
        require(_entries.length  <= 80, "exceed max length");

        for(uint8 i=0; i < _entries.length; i++) {
            _createEntry(_entries[i]);
        }
        return true;
    }





    function claim() external nonReentrant  {
        uint256 totalAmount;
        for(uint8 i=0; i < entryIdsByRecipient[msg.sender].length; i++) {
            totalAmount += _claim(entryIdsByRecipient[msg.sender][i]);
        }
        if (totalAmount > 0) {
            emit Claimed(msg.sender, totalAmount);
            assert(token.transfer(msg.sender, totalAmount));
        }
    }





    function withdraw(address destination) external onlyOwner nonZeroAddress(destination) returns (bool) {
        require(token.transfer(destination, this.balanceOf()), "transfer failed");
        return true;
    }






    function balanceOf() external view returns (uint256) {
        return token.balanceOf(address(this));
    }






    function balanceOf(uint256 entryId) external view returns (uint256 amount) {
        return _balanceOf(entryId);
    }






    function balanceOf(address account) external view returns (uint256 amount) {
        for(uint8 i=0; i < entryIdsByRecipient[account].length; i++) {
            amount += _balanceOf(entryIdsByRecipient[account][i]);
        }
        return amount;
    }



    struct Snapshot {
        uint256 entryId;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 cliff;
        uint256 claimed;
        uint256 available;
        bool isFired;
    }






    function getSnapshot(address account) external nonZeroAddress(account) view returns(Snapshot[] memory) {
        Snapshot[] memory snapshot = new Snapshot[](entryIdsByRecipient[account].length);

        for(uint8 i=0; i < entryIdsByRecipient[account].length; i++) {
            Entry memory entry = entries[entryIdsByRecipient[account][i]];
            snapshot[i] = Snapshot({
                entryId: entryIdsByRecipient[account][i],
                amount: entry.amount,
                start: entry.start,
                end: entry.end,
                cliff: entry.cliff,
                claimed: entry.claimed,
                available: _balanceOf(entryIdsByRecipient[account][i]),
                isFired: entry.isFired
            });
        }
        return snapshot;
    }






    function lockedOf(uint256 entryId) external view returns (uint256 amount) {
        return _lockedOf(entryId);
    }






    function lockedOf(address account) external view returns (uint256 amount) {
        for(uint8 i=0; i < entryIdsByRecipient[account].length; i++) {
            amount += _lockedOf(entryIdsByRecipient[account][i]);
        }
        return amount;
    }

    function getBlockTimestamp() public virtual view returns (uint256) {
        return block.timestamp;
    }

    function _balanceOf(uint256 _entryId) internal view returns (uint256) {
        Entry storage entry = entries[_entryId];

        if (entry.amount == 0) {
            return 0;
        }

        uint256 currentTimestamp = getBlockTimestamp();
        if (currentTimestamp <= entry.start + entry.cliff) {
            return 0;
        }

        if (currentTimestamp > entry.end || entry.isFired) {
            return entry.amount - entry.claimed;
        }

        uint256 vested = entry.amount * (currentTimestamp - entry.lastUpdated) / (entry.end - entry.start);
        return vested;
    }

    function _lockedOf(uint256 _entryId) internal view returns (uint256) {
        Entry storage entry = entries[_entryId];
        if (entry.amount == 0) {
            return 0;
        }
        return entry.amount - entry.claimed;
    }

    function _createEntry(EntryVars memory entry) internal returns (bool success) {
        address recipient = entry.recipient;
        require(recipient != address(0), "recipient cannot be the zero address");


        require(entry.amount > 0, "amount must be greater than zero");
        require(entry.unlocked <= entry.amount, "unlocked cannot be greater than amount");
        require(entry.end >= entry.start, "End time must be after start time");
        require(entry.end > entry.start + entry.cliff, "cliff must be less than end");

        uint256 currentTimestamp = getBlockTimestamp();
        require(entry.start >= currentTimestamp, "Start time must be in the future");

        if (entry.unlocked > 0) {
            assert(token.transfer(recipient, entry.unlocked));
        }

        uint256 currentEntryId = _entryIds.current();
        if (entry.unlocked < entry.amount) {
            entries[currentEntryId] = Entry({
                recipient: recipient,
                amount: entry.amount - entry.unlocked,
                start: entry.start,
                lastUpdated: entry.start,
                end: entry.end,
                cliff: entry.cliff,
                claimed: 0,
                isFireable: entry.isFireable,
                isFired: false
            });
            entryIdsByRecipient[recipient].push(currentEntryId);

            emit EntryCreated(currentEntryId, recipient, entry.amount - entry.unlocked, entry.start, entry.end, entry.cliff);
            _entryIds.increment();
        }

        return true;
    }

    function _fireEntry(uint256 _entryId) internal returns (bool success) {
        Entry storage entry = entries[_entryId];
        require(entry.amount > 0, "entry not exists");
        require(entry.isFireable, "entry not fireable");

        entry.amount = _balanceOf(_entryId);
        entry.isFired = true;

        emit EntryFired(_entryId);
        return true;
    }

    function _claim(uint256 _entryId) internal returns (uint256 amount) {
        Entry storage entry = entries[_entryId];

        uint256 amountToClaim = _balanceOf(_entryId);
        if (amountToClaim > 0) {
            uint256 currentTimestamp = getBlockTimestamp();

            entry.lastUpdated = currentTimestamp;
            entry.claimed += amountToClaim;


            require(entry.amount >= entry.claimed, "claim exceed vested amount");
        }

        return amountToClaim;
    }
}
