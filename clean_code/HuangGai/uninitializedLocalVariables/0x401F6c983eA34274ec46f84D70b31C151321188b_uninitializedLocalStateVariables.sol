





pragma solidity ^0.5.2;

interface IGovernance {
    function update(address target, bytes calldata data) external;
}



pragma solidity ^0.5.2;


contract Governable {
    IGovernance public governance;

    constructor(address _governance) public {
        governance = IGovernance(_governance);
    }

    modifier onlyGovernance() {
        require(
            msg.sender == address(governance),
            "Only governance contract is authorized"
        );
        _;
    }
}



pragma solidity ^0.5.2;

contract IWithdrawManager {
    function createExitQueue(address token) external;

    function verifyInclusion(
        bytes calldata data,
        uint8 offset,
        bool verifyTxInclusion
    ) external view returns (uint256 age);

    function addExitToQueue(
        address exitor,
        address childToken,
        address rootToken,
        uint256 exitAmountOrTokenId,
        bytes32 txHash,
        bool isRegularExit,
        uint256 priority
    ) external;

    function addInput(
        uint256 exitId,
        uint256 age,
        address utxoOwner,
        address token
    ) external;

    function challengeExit(
        uint256 exitId,
        uint256 inputId,
        bytes calldata challengeData,
        address adjudicatorPredicate
    ) external;
}



pragma solidity ^0.5.2;




contract Registry is Governable {

    bytes32 private constant WETH_TOKEN = keccak256("wethToken");
    bytes32 private constant DEPOSIT_MANAGER = keccak256("depositManager");
    bytes32 private constant STAKE_MANAGER = keccak256("stakeManager");
    bytes32 private constant VALIDATOR_SHARE = keccak256("validatorShare");
    bytes32 private constant WITHDRAW_MANAGER = keccak256("withdrawManager");
    bytes32 private constant CHILD_CHAIN = keccak256("childChain");
    bytes32 private constant STATE_SENDER = keccak256("stateSender");
    bytes32 private constant SLASHING_MANAGER = keccak256("slashingManager");

    address public erc20Predicate;
    address public erc721Predicate;

    mapping(bytes32 => address) public contractMap;
    mapping(address => address) public rootToChildToken;
    mapping(address => address) public childToRootToken;
    mapping(address => bool) public proofValidatorContracts;
    mapping(address => bool) public isERC721;

    enum Type {Invalid, ERC20, ERC721, Custom}
    struct Predicate {
        Type _type;
    }
    mapping(address => Predicate) public predicates;

    event TokenMapped(address indexed rootToken, address indexed childToken);
    event ProofValidatorAdded(address indexed validator, address indexed from);
    event ProofValidatorRemoved(address indexed validator, address indexed from);
    event PredicateAdded(address indexed predicate, address indexed from);
    event PredicateRemoved(address indexed predicate, address indexed from);
    event ContractMapUpdated(bytes32 indexed key, address indexed previousContract, address indexed newContract);

    constructor(address _governance) public Governable(_governance) {}

    function updateContractMap(bytes32 _key, address _address) external onlyGovernance {
        emit ContractMapUpdated(_key, contractMap[_key], _address);
        contractMap[_key] = _address;
    }







    function mapToken(
        address _rootToken,
        address _childToken,
        bool _isERC721
    ) external onlyGovernance {
        require(_rootToken != address(0x0) && _childToken != address(0x0), "INVALID_TOKEN_ADDRESS");
        rootToChildToken[_rootToken] = _childToken;
        childToRootToken[_childToken] = _rootToken;
        isERC721[_rootToken] = _isERC721;
        IWithdrawManager(contractMap[WITHDRAW_MANAGER]).createExitQueue(_rootToken);
        emit TokenMapped(_rootToken, _childToken);
    }

    function addErc20Predicate(address predicate) public onlyGovernance {
        require(predicate != address(0x0), "Can not add null address as predicate");
        erc20Predicate = predicate;
        addPredicate(predicate, Type.ERC20);
    }

    function addErc721Predicate(address predicate) public onlyGovernance {
        erc721Predicate = predicate;
        addPredicate(predicate, Type.ERC721);
    }

    function addPredicate(address predicate, Type _type) public onlyGovernance {
        require(predicates[predicate]._type == Type.Invalid, "Predicate already added");
        predicates[predicate]._type = _type;
        emit PredicateAdded(predicate, msg.sender);
    }

    function removePredicate(address predicate) public onlyGovernance {
        require(predicates[predicate]._type != Type.Invalid, "Predicate does not exist");
        delete predicates[predicate];
        emit PredicateRemoved(predicate, msg.sender);
    }

    function getValidatorShareAddress() public view returns (address) {
        return contractMap[VALIDATOR_SHARE];
    }

    function getWethTokenAddress() public view returns (address) {
        return contractMap[WETH_TOKEN];
    }

    function getDepositManagerAddress() public view returns (address) {
        return contractMap[DEPOSIT_MANAGER];
    }

    function getStakeManagerAddress() public view returns (address) {
        return contractMap[STAKE_MANAGER];
    }

    function getSlashingManagerAddress() public view returns (address) {
        return contractMap[SLASHING_MANAGER];
    }

    function getWithdrawManagerAddress() public view returns (address) {
        return contractMap[WITHDRAW_MANAGER];
    }

    function getChildChainAndStateSender() public view returns (address, address) {
        return (contractMap[CHILD_CHAIN], contractMap[STATE_SENDER]);
    }

    function isTokenMapped(address _token) public view returns (bool) {
        return rootToChildToken[_token] != address(0x0);
    }

    function isTokenMappedAndIsErc721(address _token) public view returns (bool) {
        require(isTokenMapped(_token), "TOKEN_NOT_MAPPED");
        return isERC721[_token];
    }

    function isTokenMappedAndGetPredicate(address _token) public view returns (address) {
        if (isTokenMappedAndIsErc721(_token)) {
            return erc721Predicate;
        }
        return erc20Predicate;
    }

    function isChildTokenErc721(address childToken) public view returns (bool) {
        address rootToken ;

        require(rootToken != address(0x0), "Child token is not mapped");
        return isERC721[rootToken];
    }
}







pragma solidity ^0.5.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;
        uint nextPtr;
    }






    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr ;

        uint itemLength ;

        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }






    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }




    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }






    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr ;

        return Iterator(self, ptr);
    }




    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }




    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        return item.len - _payloadOffset(item.memPtr);
    }




    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items ;

        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr ;

        uint dataLen;
        for (uint i ; i < items; i++) {

            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }


    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr ;

        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }




    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }


    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr ;

        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {

        require(item.len == 21);

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        uint offset ;

        uint len ;


        uint result;
        uint memPtr ;

        assembly {
            result := mload(memPtr)


            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }


    function toUintStrict(RLPItem memory item) internal pure returns (uint) {

        require(item.len == 33);

        uint result;
        uint memPtr ;

        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint offset ;

        uint len ;

        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }






    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count ;

        uint currPtr ;

        uint endPtr ;

        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr);
           count++;
        }

        return count;
    }


    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;

        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7)
                memPtr := add(memPtr, 1)


                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        }

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }


    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }






    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;


        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }


        uint mask ;

        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}



pragma solidity ^0.5.2;





library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c ;



        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c ;


        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



pragma solidity ^0.5.2;






contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner());
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity ^0.5.2;


contract ProxyStorage is Ownable {
    address internal proxyTo;
}



pragma solidity ^0.5.2;

contract ChainIdMixin {
  bytes constant public networkId = hex"89";
  uint256 constant public CHAINID = 137;
}



pragma solidity ^0.5.2;





contract RootChainHeader {
    event NewHeaderBlock(
        address indexed proposer,
        uint256 indexed headerBlockId,
        uint256 indexed reward,
        uint256 start,
        uint256 end,
        bytes32 root
    );

    event ResetHeaderBlock(address indexed proposer, uint256 indexed headerBlockId);
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }
}


contract RootChainStorage is ProxyStorage, RootChainHeader, ChainIdMixin {
    bytes32 public heimdallId;
    uint8 public constant VOTE_TYPE = 2;

    uint16 internal constant MAX_DEPOSITS = 10000;
    uint256 public _nextHeaderBlock ;

    uint256 internal _blockDepositId ;

    mapping(uint256 => HeaderBlock) public headerBlocks;
    Registry internal registry;
}



pragma solidity ^0.5.2;


contract IStakeManager {

    function startAuction(uint256 validatorId, uint256 amount) external;

    function confirmAuctionBid(
        uint256 validatorId,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external;

    function transferFunds(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function stake(
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external;

    function unstake(uint256 validatorId) external;

    function totalStakedFor(address addr) external view returns (uint256);

    function supportsHistory() external pure returns (bool);

    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) public;

    function checkSignatures(
        uint256 blockInterval,
        bytes32 voteHash,
        bytes32 stateRoot,
        address proposer,
        bytes memory sigs
    ) public returns (uint256);

    function updateValidatorState(uint256 validatorId, int256 amount) public;

    function ownerOf(uint256 tokenId) public view returns (address);

    function slash(bytes memory slashingInfoList) public returns (uint256);

    function validatorStake(uint256 validatorId) public view returns (uint256);

    function epoch() public view returns (uint256);

    function withdrawalDelay() public view returns (uint256);
}



pragma solidity ^0.5.2;


interface IRootChain {
    function slash() external;

    function submitHeaderBlock(bytes calldata data, bytes calldata sigs)
        external;

    function getLastChildBlock() external view returns (uint256);

    function currentHeaderBlock() external view returns (uint256);
}



pragma solidity ^0.5.2;








contract RootChain is RootChainStorage, IRootChain {
    using SafeMath for uint256;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    modifier onlyDepositManager() {
        require(msg.sender == registry.getDepositManagerAddress(), "UNAUTHORIZED_DEPOSIT_MANAGER_ONLY");
        _;
    }

    function submitHeaderBlock(bytes calldata data, bytes calldata sigs) external {
        (address proposer, uint256 start, uint256 end, bytes32 rootHash, bytes32 accountHash, uint256 _borChainID) = abi
            .decode(data, (address, uint256, uint256, bytes32, bytes32, uint256));
        require(CHAINID == _borChainID, "Invalid bor chain id");

        require(_buildHeaderBlock(proposer, start, end, rootHash), "INCORRECT_HEADER_DATA");


        IStakeManager stakeManager ;

        uint256 _reward ;


        require(_reward != 0, "Invalid checkpoint");
        emit NewHeaderBlock(proposer, _nextHeaderBlock, _reward, start, end, rootHash);
        _nextHeaderBlock = _nextHeaderBlock.add(MAX_DEPOSITS);
        _blockDepositId = 1;
    }

    function updateDepositId(uint256 numDeposits) external onlyDepositManager returns (uint256 depositId) {
        depositId = currentHeaderBlock().add(_blockDepositId);

        _blockDepositId = _blockDepositId.add(numDeposits);
        require(

            _blockDepositId <= MAX_DEPOSITS,
            "TOO_MANY_DEPOSITS"
        );
    }

    function getLastChildBlock() external view returns (uint256) {
        return headerBlocks[currentHeaderBlock()].end;
    }

    function slash() external {

    }

    function currentHeaderBlock() public view returns (uint256) {
        return _nextHeaderBlock.sub(MAX_DEPOSITS);
    }

    function _buildHeaderBlock(
        address proposer,
        uint256 start,
        uint256 end,
        bytes32 rootHash
    ) private returns (bool) {
        uint256 nextChildBlock;




        if (_nextHeaderBlock > MAX_DEPOSITS) {
            nextChildBlock = headerBlocks[currentHeaderBlock()].end + 1;
        }
        if (nextChildBlock != start) {
            return false;
        }

        HeaderBlock memory headerBlock = HeaderBlock({
            root: rootHash,
            start: nextChildBlock,
            end: end,
            createdAt: now,
            proposer: proposer
        });

        headerBlocks[_nextHeaderBlock] = headerBlock;
        return true;
    }


    function setNextHeaderBlock(uint256 _value) public onlyOwner {
        require(_value % MAX_DEPOSITS == 0, "Invalid value");
        for (uint256 i ; i < _nextHeaderBlock; i += MAX_DEPOSITS) {

            delete headerBlocks[i];
        }
        _nextHeaderBlock = _value;
        _blockDepositId = 1;
        emit ResetHeaderBlock(msg.sender, _nextHeaderBlock);
    }


    function setHeimdallId(string memory _heimdallId) public onlyOwner {
        heimdallId = keccak256(abi.encodePacked(_heimdallId));
    }
}



pragma solidity ^0.5.2;



contract StateSender is Ownable {
    using SafeMath for uint256;

    uint256 public counter;
    mapping(address => address) public registrations;

    event NewRegistration(
        address indexed user,
        address indexed sender,
        address indexed receiver
    );
    event RegistrationUpdated(
        address indexed user,
        address indexed sender,
        address indexed receiver
    );
    event StateSynced(
        uint256 indexed id,
        address indexed contractAddress,
        bytes data
    );

    modifier onlyRegistered(address receiver) {
        require(registrations[receiver] == msg.sender, "Invalid sender");
        _;
    }

    function syncState(address receiver, bytes calldata data)
        external
        onlyRegistered(receiver)
    {
        counter = counter.add(1);
        emit StateSynced(counter, receiver, data);
    }


    function register(address sender, address receiver) public {
        require(
            isOwner() || registrations[receiver] == msg.sender,
            "StateSender.register: Not authorized to register"
        );
        registrations[receiver] = sender;
        if (registrations[receiver] == address(0)) {
            emit NewRegistration(msg.sender, sender, receiver);
        } else {
            emit RegistrationUpdated(msg.sender, sender, receiver);
        }
    }
}



pragma solidity ^0.5.2;


contract Lockable is Governable {
    bool public locked;

    modifier onlyWhenUnlocked() {
        require(!locked, "Is Locked");
        _;
    }

    constructor(address _governance) public Governable(_governance) {}

    function lock() external onlyGovernance {
        locked = true;
    }

    function unlock() external onlyGovernance {
        locked = false;
    }
}



pragma solidity ^0.5.2;







contract DepositManagerHeader {
    event NewDepositBlock(address indexed owner, address indexed token, uint256 amountOrNFTId, uint256 depositBlockId);
    event MaxErc20DepositUpdate(uint256 indexed oldLimit, uint256 indexed newLimit);

    struct DepositBlock {
        bytes32 depositHash;
        uint256 createdAt;
    }
}


contract DepositManagerStorage is ProxyStorage, Lockable, DepositManagerHeader {
    Registry public registry;
    RootChain public rootChain;
    StateSender public stateSender;

    mapping(uint256 => DepositBlock) public deposits;

    address public childChain;
    uint256 public maxErc20Deposit ;

}







pragma solidity ^0.5.2;



interface ERCProxy {
    function proxyType() external pure returns (uint256 proxyTypeId);
    function implementation() external view returns (address codeAddr);
}



pragma solidity ^0.5.2;



contract DelegateProxy is ERCProxy {
    function proxyType() external pure returns (uint256 proxyTypeId) {

        proxyTypeId = 2;
    }

    function implementation() external view returns (address);

    function delegatedFwd(address _dst, bytes memory _calldata) internal {

        assembly {
            let result := delegatecall(
                sub(gas, 10000),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)



            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
}



pragma solidity ^0.5.2;




contract Proxy is ProxyStorage, DelegateProxy {
    event ProxyUpdated(address indexed _new, address indexed _old);
    event OwnerUpdate(address _prevOwner, address _newOwner);

    constructor(address _proxyTo) public {
        updateImplementation(_proxyTo);
    }

    function() external payable {


        delegatedFwd(proxyTo, msg.data);
    }

    function implementation() external view returns (address) {
        return proxyTo;
    }

    function updateImplementation(address _newProxyTo) public onlyOwner {
        require(_newProxyTo != address(0x0), "INVALID_PROXY_ADDRESS");
        require(isContract(_newProxyTo), "DESTINATION_ADDRESS_IS_NOT_A_CONTRACT");
        emit ProxyUpdated(_newProxyTo, proxyTo);
        proxyTo = _newProxyTo;
    }

    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}



pragma solidity ^0.5.2;






contract DepositManagerProxy is Proxy, DepositManagerStorage {
    constructor(
        address _proxyTo,
        address _registry,
        address _rootChain,
        address _governance
    ) public Proxy(_proxyTo) Lockable(_governance) {
        registry = Registry(_registry);
        rootChain = RootChain(_rootChain);
    }
}
