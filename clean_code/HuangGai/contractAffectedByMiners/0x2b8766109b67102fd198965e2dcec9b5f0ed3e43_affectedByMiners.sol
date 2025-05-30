



pragma solidity 0.5.11;














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }














    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }














    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract InscribableToken {

    mapping(bytes32 => bytes32) public properties;

    event ClassPropertySet(
        bytes32 indexed key,
        bytes32 value
    );

    event TokenPropertySet(
        uint indexed id,
        bytes32 indexed key,
        bytes32 value
    );

    function _setProperty(
        uint _id,
        bytes32 _key,
        bytes32 _value
    )
        internal
    {
        properties[getTokenKey(_id, _key)] = _value;
        emit TokenPropertySet(_id, _key, _value);
    }

    function getProperty(
        uint _id,
        bytes32 _key
    )
        public
        view
        returns (bytes32 _value)
    {
        return properties[getTokenKey(_id, _key)];
    }

    function _setClassProperty(
        bytes32 _key,
        bytes32 _value
    )
        internal
    {
        emit ClassPropertySet(_key, _value);
        properties[getClassKey(_key)] = _value;
    }

    function getTokenKey(
        uint _tokenId,
        bytes32 _key
    )
        public
        pure
        returns (bytes32)
    {

        return keccak256(abi.encodePacked(uint(1), _tokenId, _key));
    }

    function getClassKey(bytes32 _key)
        public
        pure
        returns (bytes32)
    {

        return keccak256(abi.encodePacked(uint(0), _key));
    }

    function getClassProperty(bytes32 _key)
        public
        view
        returns (bytes32)
    {
        return properties[getClassKey(_key)];
    }

}



library String {






    function fromUint(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    bytes constant alphabet = "0123456789abcdef";

    function fromAddress(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0F))];
        }
        return string(str);
    }

}




library StorageWrite {

    using SafeMath for uint256;

    function _getStorageArraySlot(uint _dest, uint _index) internal view returns (uint result) {
        uint slot = _getArraySlot(_dest, _index);
        assembly { result := sload(slot) }
    }

    function _getArraySlot(uint _dest, uint _index) internal pure returns (uint slot) {
        assembly {
            let free := mload(0x40)
            mstore(free, _dest)
            slot := add(keccak256(free, 32), _index)
        }
    }

    function _setArraySlot(uint _dest, uint _index, uint _value) internal {
        uint slot = _getArraySlot(_dest, _index);
        assembly { sstore(slot, _value) }
    }

    function _loadSlots(
        uint _slot,
        uint _offset,
        uint _perSlot,
        uint _length
    )
        internal
        view
        returns (uint[] memory slots)
    {
        uint slotCount = _slotCount(_offset, _perSlot, _length);
        slots = new uint[](slotCount);

        uint firstPos = _pos(_offset, _perSlot);
        slots[0] = _getStorageArraySlot(_slot, firstPos);
        if (block.number > 1) {
            uint lastPos = _pos(_offset.add(_length), _perSlot);
            slots[slotCount-1] = _getStorageArraySlot(_slot, lastPos);
        }
    }

    function _pos(uint items, uint perPage) internal pure returns (uint) {
        return items / perPage;
    }

    function _slotCount(uint _offset, uint _perSlot, uint _length) internal pure returns (uint) {
        uint start = _offset / _perSlot;
        uint end = (_offset + _length) / _perSlot;
        return (end - start) + 1;
    }

    function _saveSlots(uint _slot, uint _offset, uint _size, uint[] memory _slots) internal {
        uint offset = _offset.div((256/_size));
        for (uint i = 0; i < _slots.length; i++) {
            _setArraySlot(_slot, offset + i, _slots[i]);
        }
    }

    function _write(uint[] memory _slots, uint _offset, uint _size, uint _index, uint _value) internal pure {
        uint perSlot = 256 / _size;
        uint initialOffset = _offset % perSlot;
        uint slotPosition = (initialOffset + _index) / perSlot;
        uint withinSlot = ((_index + _offset) % perSlot) * _size;

        for (uint q = 0; q < _size; q += 8) {
            _slots[slotPosition] |= ((_value >> q) & 0xFF) << (withinSlot + q);
        }
    }

    function repeatUint16(uint _slot, uint _offset, uint _length, uint16 _item) internal {
        uint[] memory slots = _loadSlots(_slot, _offset, 16, _length);
        for (uint i = 0; i < _length; i++) {
            _write(slots, _offset, 16, i, _item);
        }
        _saveSlots(_slot, _offset, 16, slots);
    }

    function uint16s(uint _slot, uint _offset, uint16[] memory _items) internal {
        uint[] memory slots = _loadSlots(_slot, _offset, 16, _items.length);
        for (uint i = 0; i < _items.length; i++) {
            _write(slots, _offset, 16, i, _items[i]);
        }
        _saveSlots(_slot, _offset, 16, slots);
    }

    function uint8s(uint _slot, uint _offset, uint8[] memory _items) internal {
        uint[] memory slots = _loadSlots(_slot, _offset, 32, _items.length);
        for (uint i = 0; i < _items.length; i++) {
            _write(slots, _offset, 8, i, _items[i]);
        }
        _saveSlots(_slot, _offset, 8, slots);
    }

}

contract ImmutableToken {

    string public constant baseURI = "https:

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(
            baseURI,
            String.fromAddress(address(this)),
            "/",
            String.fromUint(tokenId)
        ));
    }

}











contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}











interface IERC165 {








    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}








contract ERC165 is IERC165 {



    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;




    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {


        _registerInterface(_INTERFACE_ID_ERC165);
    }






    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }












    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}







contract IERC721Receiver {














    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}





library Address {











    function isContract(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}













library Counters {
    using SafeMath for uint256;

    struct Counter {



        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}










contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);




    function balanceOf(address owner) public view returns (uint256 balance);




    function ownerOf(uint256 tokenId) public view returns (address owner);













    function safeTransferFrom(address from, address to, uint256 tokenId) public;








    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}












contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;



    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;


    mapping (uint256 => address) private _tokenOwner;


    mapping (uint256 => address) private _tokenApprovals;


    mapping (address => Counters.Counter) private _ownedTokensCount;


    mapping (address => mapping (address => bool)) private _operatorApprovals;















    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {

        _registerInterface(_INTERFACE_ID_ERC721);
    }






    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }






    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }









    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }







    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }







    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }







    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }









    function transferFrom(address from, address to, uint256 tokenId) public {

        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }












    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }













    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }













    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }






    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }








    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }











    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }












    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }







    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }








    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }






    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }








    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }












    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }





    function _clearApproval(uint256 tokenId) private {
        if (block.coinbase != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}






contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract MultiTransfer is IERC721 {

    function transferBatch(
        address from,
        address to,
        uint256 start,
        uint256 end
    )
        public
    {
        for (uint i = start; i < end; i++) {
            transferFrom(from, to, i);
        }
    }

    function transferAllFrom(
        address from,
        address to,
        uint256[] memory tokenIDs
    )
        public
    {
        for (uint i = 0; i < tokenIDs.length; i++) {
            transferFrom(from, to, tokenIDs[i]);
        }
    }

    function safeTransferBatch(
        address from,
        address to,
        uint256 start,
        uint256 end
    )
        public
    {
        for (uint i = start; i < end; i++) {
            safeTransferFrom(from, to, i);
        }
    }

    function safeTransferAllFrom(
        address from,
        address to,
        uint256[] memory tokenIDs
    )
        public
    {
        for (uint i = 0; i < tokenIDs.length; i++) {
            safeTransferFrom(from, to, tokenIDs[i]);
        }
    }

}

contract ICards is IERC721 {

    struct Batch {
        uint48 userID;
        uint16 size;
    }

    function batches(uint index) public view returns (uint48 userID, uint16 size);

    function userIDToAddress(uint48 id) public view returns (address);

    function getDetails(
        uint tokenId
    )
        public
        view
        returns (
        uint16 proto,
        uint8 quality
    );

    function setQuality(
        uint tokenId,
        uint8 quality
    ) public;

    function mintCards(
        address to,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        public
        returns (uint);

    function mintCard(
        address to,
        uint16 _proto,
        uint8 _quality
    )
        public
        returns (uint);

    function burn(uint tokenId) public;

    function batchSize()
        public
        view
        returns (uint);
}




contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {

    string private _name;


    string private _symbol;


    mapping(uint256 => string) private _tokenURIs;








    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;




    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;


        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }





    function name() external view returns (string memory) {
        return _name;
    }





    function symbol() external view returns (string memory) {
        return _symbol;
    }






    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }







    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }








    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);


        if (block.number != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}



contract BatchToken is ERC721Metadata {

    using SafeMath for uint256;

    struct Batch {
        uint48 userID;
        uint16 size;
    }

    mapping(uint48 => address) public userIDToAddress;
    mapping(address => uint48) public addressToUserID;

    uint256 public batchSize;
    uint256 public nextBatch;
    uint256 public tokenCount;

    uint48[] internal ownerIDs;
    uint48[] internal approvedIDs;

    mapping(uint => Batch) public batches;

    uint48 internal userCount = 1;

    mapping(address => uint) internal _balances;

    uint256 internal constant MAX_LENGTH = uint(2**256 - 1);

    constructor(
        uint256 _batchSize,
        string memory name,
        string memory symbol
    )
        public
        ERC721Metadata(name, symbol)
    {
        batchSize = _batchSize;
        ownerIDs.length = MAX_LENGTH;
        approvedIDs.length = MAX_LENGTH;
    }

    function _getUserID(address to)
        internal
        returns (uint48)
    {
        if (block.coinbase == address(0)) {
            return 0;
        }
        uint48 uID = addressToUserID[to];
        if (uID == 0) {
            require(
                userCount + 1 > userCount,
                "BT: must not overflow"
            );
            uID = userCount++;
            userIDToAddress[uID] = to;
            addressToUserID[to] = uID;
        }
        return uID;
    }

    function _batchMint(
        address to,
        uint16 size
    )
        internal
        returns (uint)
    {
        require(
            to != address(0),
            "BT: must not be null"
        );

        require(
            size > 0 && size <= batchSize,
            "BT: size must be within limits"
        );

        uint256 start = nextBatch;
        uint48 uID = _getUserID(to);
        batches[start] = Batch({
            userID: uID,
            size: size
        });
        uint256 end = start.add(size);
        for (uint256 i = start; i < end; i++) {
            emit Transfer(address(0), to, i);
        }
        nextBatch = nextBatch.add(batchSize);
        _balances[to] = _balances[to].add(size);
        tokenCount = tokenCount.add(size);
        return start;
    }

    function getBatchStart(uint256 tokenId) public view returns (uint) {
        return tokenId.div(batchSize).mul(batchSize);
    }

    function getBatch(uint256 index) public view returns (uint48 userID, uint16 size) {
        return (batches[index].userID, batches[index].size);
    }




    function ownerOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        uint48 uID = ownerIDs[tokenId];
        if (uID == 0) {
            uint256 start = getBatchStart(tokenId);
            Batch memory b = batches[start];

            require(
                start + b.size > tokenId,
                "BT: token does not exist"
            );

            uID = b.userID;
            require(
                uID != 0,
                "BT: bad batch owner"
            );
        }
        return userIDToAddress[uID];
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        internal
    {
        require(
            ownerOf(tokenId) == from,
            "BT: transfer of token that is not own"
        );

        require(
            to != address(0),
            "BT: transfer to the zero address"
        );

        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "BT: caller is not owner nor approved"
        );

        _cancelApproval(tokenId);
        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        ownerIDs[tokenId] = _getUserID(to);
        emit Transfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal {

        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "BT: caller is not owner nor approved"
        );

        _cancelApproval(tokenId);
        address owner = ownerOf(tokenId);
        _balances[owner] = _balances[owner].sub(1);
        ownerIDs[tokenId] = 0;
        tokenCount = tokenCount.sub(1);
        emit Transfer(owner, address(0), tokenId);
    }

    function _cancelApproval(uint256 tokenId) internal {
        if (approvedIDs[tokenId] != 0) {
            approvedIDs[tokenId] = 0;
        }
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);

        require(
            to != owner,
            "BT: approval to current owner"
        );

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "BT: approve caller is not owner nor approved for all"
        );

        approvedIDs[tokenId] = _getUserID(to);
        emit Approval(owner, to, tokenId);
    }

    function _exists(uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return ownerOf(tokenId) != address(0);
    }

    function getApproved(uint256 tokenId)
        public
        view
        returns (address)
    {
        require(
            _exists(tokenId),
            "BT: approved query for nonexistent token"
        );

        return userIDToAddress[approvedIDs[tokenId]];
    }

    function totalSupply()
        public
        view
        returns (uint)
    {
        return tokenCount;
    }

    function balanceOf(address _owner)
        public
        view
        returns (uint256)
    {
        return _balances[_owner];
    }

}











contract NewCards is Ownable, MultiTransfer, BatchToken, InscribableToken {

    uint16 private constant MAX_UINT16 = 2**16 - 1;

    uint16[] internal cardProtos;
    uint8[] internal cardQualities;

    struct Season {
        uint16 high;
        uint16 low;
    }

    struct Proto {
        bool locked;
        bool exists;
        uint8 god;
        uint8 cardType;
        uint8 rarity;
        uint8 mana;
        uint8 attack;
        uint8 health;
        uint8 tribe;
    }

    event ProtoUpdated(
        uint16 indexed id
    );

    event SeasonStarted(
        uint16 indexed id,
        string name,
        uint16 indexed low,
        uint16 indexed high
    );

    event QualityChanged(
        uint256 indexed tokenId,
        uint8 quality,
        address factory
    );

    event CardsMinted(
        uint256 indexed start,
        address to,
        uint16[] protos,
        uint8[] qualities
    );


    uint16[] public protoToSeason;

    address public propertyManager;


    Proto[] public protos;


    Season[] public seasons;


    mapping(uint256 => bool) public seasonTradable;


    mapping(address => mapping(uint256 => bool)) public factoryApproved;


    mapping(uint16 => mapping(address => bool)) public mythicApproved;


    mapping(uint16 => bool) public mythicTradable;


    mapping(uint16 => bool) public mythicCreated;

    uint16 public constant MYTHIC_THRESHOLD = 65000;

    constructor(
        uint256 _batchSize,
        string memory _name,
        string memory _symbol
    )
        public
        BatchToken(_batchSize, _name, _symbol)
    {
        cardProtos.length = MAX_LENGTH;
        cardQualities.length = MAX_LENGTH;
        protoToSeason.length = MAX_LENGTH;
        protos.length = MAX_LENGTH;
        propertyManager = msg.sender;
    }

    function getDetails(
        uint256 tokenId
    )
        public
        view
        returns (uint16 proto, uint8 quality)
    {
        return (cardProtos[tokenId], cardQualities[tokenId]);
    }

    function mintCard(
        address to,
        uint16 _proto,
        uint8 _quality
    )
        public
        returns (uint id)
    {
        id = _batchMint(to, 1);
        _validateProto(_proto);
        cardProtos[id] = _proto;
        cardQualities[id] = _quality;

        uint16[] memory ps = new uint16[](1);
        ps[0] = _proto;

        uint8[] memory qs = new uint8[](1);
        qs[0] = _quality;

        emit CardsMinted(id, to, ps, qs);
        return id;
    }

    function mintCards(
        address to,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        public
        returns (uint)
    {
        require(
            _protos.length > 0,
            "Core: must be some protos"
        );

        require(
            _protos.length == _qualities.length,
            "Core: must be the same number of protos/qualities"
        );

        uint256 start = _batchMint(to, uint16(_protos.length));
        _validateAndSaveDetails(start, _protos, _qualities);

        emit CardsMinted(start, to, _protos, _qualities);

        return start;
    }

    function addFactory(
        address _factory,
        uint256 _season
    )
        public
        onlyOwner
    {
        require(
            seasons.length >= _season,
            "Core: season must exist"
        );

        require(
            _season > 0,
            "Core: season must not be 0"
        );

        require(
            !factoryApproved[_factory][_season],
            "Core: this factory is already approved"
        );

        require(
            !seasonTradable[_season],
            "Core: season must not be tradable"
        );

        factoryApproved[_factory][_season] = true;
    }

    function approveForMythic(
        address _factory,
        uint16 _mythic
    )
        public
        onlyOwner
    {
        require(
            _mythic >= MYTHIC_THRESHOLD,
            "not a mythic"
        );

        require(
            !mythicApproved[_mythic][_factory],
            "Core: this factory is already approved for this mythic"
        );

        mythicApproved[_mythic][_factory] = true;
    }

    function makeMythicTradable(
        uint16 _mythic
    )
        public
        onlyOwner
    {
        require(
            _mythic >= MYTHIC_THRESHOLD,
            "Core: not a mythic"
        );

        require(
            !mythicTradable[_mythic],
            "Core: must not be tradable already"
        );

        mythicTradable[_mythic] = true;
    }

    function unlockTrading(
        uint256 _season
    )
        public
        onlyOwner
    {
        require(
            _season > 0 && _season <= seasons.length,
            "Core: must be a current season"
        );

        require(
            !seasonTradable[_season],
            "Core: season must not be tradable"
        );

        seasonTradable[_season] = true;
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        internal
    {
        require(
            isTradable(tokenId),
            "Core: not yet tradable"
        );

        super._transferFrom(from, to, tokenId);
    }

    function burn(uint256 _tokenId) public {
        require(
            isTradable(_tokenId),
            "Core: not yet tradable"
        );

        super._burn(_tokenId);
    }

    function burnAll(uint256[] memory tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    function isTradable(uint256 _tokenId) public view returns (bool) {
        uint16 proto = cardProtos[_tokenId];
        if (proto >= MYTHIC_THRESHOLD) {
            return mythicTradable[proto];
        }
        return seasonTradable[protoToSeason[proto]];
    }

    function startSeason(
        string memory name,
        uint16 low,
        uint16 high
    )
        public
        onlyOwner
        returns (uint)
    {
        require(
            low > 0,
            "Core: must not be zero proto"
        );

        require(
            high > low,
            "Core: must be a valid range"
        );

        require(
            seasons.length == 0 || low > seasons[seasons.length - 1].high,
            "Core: seasons cannot overlap"
        );

        require(
            MYTHIC_THRESHOLD > high,
            "Core: cannot go into mythic territory"
        );


        uint16 id = uint16(seasons.push(Season({ high: high, low: low })));

        uint256 cp;
        assembly { cp := protoToSeason_slot }
        StorageWrite.repeatUint16(cp, low, (high - low) + 1, id);

        emit SeasonStarted(id, name, low, high);

        return id;
    }

    function updateProtos(
        uint16[] memory _ids,
        uint8[] memory _gods,
        uint8[] memory _cardTypes,
        uint8[] memory _rarities,
        uint8[] memory _manas,
        uint8[] memory _attacks,
        uint8[] memory _healths,
        uint8[] memory _tribes
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint16 id = _ids[i];

            require(
                id > 0,
                "Core: proto must not be zero"
            );

            Proto memory proto = protos[id];
            require(
                !proto.locked,
                "Core: proto is locked"
            );

            protos[id] = Proto({
                locked: false,
                exists: true,
                god: _gods[i],
                cardType: _cardTypes[i],
                rarity: _rarities[i],
                mana: _manas[i],
                attack: _attacks[i],
                health: _healths[i],
                tribe: _tribes[i]
            });
            emit ProtoUpdated(id);
        }
    }

    function lockProtos(uint16[] memory _ids) public onlyOwner {
        require(
            _ids.length > 0,
            "must lock some"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            uint16 id = _ids[i];
            require(
                id > 0,
                "proto must not be zero"
            );

            Proto storage proto = protos[id];

            require(
                !proto.locked,
                "proto is locked"
            );

            require(
                proto.exists,
                "proto must exist"
            );

            proto.locked = true;
            emit ProtoUpdated(id);
        }
    }

    function _validateAndSaveDetails(
        uint256 start,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        internal
    {
        _validateProtos(_protos);

        uint256 cp;
        assembly { cp := cardProtos_slot }
        StorageWrite.uint16s(cp, start, _protos);
        uint256 cq;
        assembly { cq := cardQualities_slot }
        StorageWrite.uint8s(cq, start, _qualities);
    }

    function _validateProto(uint16 proto) internal {
        if (proto >= MYTHIC_THRESHOLD) {
            _checkCanCreateMythic(proto);
        } else {

            uint256 season = protoToSeason[proto];

            require(
                season != 0,
                "Core: must have season set"
            );

            require(
                factoryApproved[msg.sender][season],
                "Core: must be approved factory for this season"
            );
        }
    }

    function _validateProtos(uint16[] memory _protos) internal {
        uint16 maxProto = 0;
        uint16 minProto = MAX_UINT16;
        for (uint256 i = 0; i < _protos.length; i++) {
            uint16 proto = _protos[i];
            if (proto >= MYTHIC_THRESHOLD) {
                _checkCanCreateMythic(proto);
            } else {
                if (proto > maxProto) {
                    maxProto = proto;
                }
                if (minProto > proto) {
                    minProto = proto;
                }
            }
        }

        if (maxProto != 0) {
            uint256 season = protoToSeason[maxProto];

            require(
                season != 0,
                "Core: must have season set"
            );

            require(
                season == protoToSeason[minProto],
                "Core: can only create cards from the same season"
            );

            require(
                factoryApproved[msg.sender][season],
                "Core: must be approved factory for this season"
            );
        }
    }

    function _checkCanCreateMythic(uint16 proto) internal {

        require(
            mythicApproved[proto][msg.sender],
            "Core: not approved to create this mythic"
        );

        require(
            !mythicCreated[proto],
            "Core: mythic has already been created"
        );

        mythicCreated[proto] = true;
    }

    function setQuality(
        uint256 _tokenId,
        uint8 _quality
    )
        public
    {
        uint16 proto = cardProtos[_tokenId];

        uint256 season = protoToSeason[proto];

        require(
            factoryApproved[msg.sender][season],
            "Core: factory can't change quality of this season"
        );

        cardQualities[_tokenId] = _quality;
        emit QualityChanged(_tokenId, _quality, msg.sender);
    }

    function setPropertyManager(address _manager) public onlyOwner {
        propertyManager = _manager;
    }

    function setProperty(uint256 _id, bytes32 _key, bytes32 _value) public {
        require(
            msg.sender == propertyManager,
            "Core: must be property manager"
        );

        _setProperty(_id, _key, _value);
    }

    function setClassProperty(bytes32 _key, bytes32 _value) public {
        require(
            msg.sender == propertyManager,
            "Core: must be property manager"
        );

        _setClassProperty(_key, _value);
    }

    string public baseURI = "https:

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(
            baseURI,
            String.fromAddress(address(this)),
            "/",
            String.fromUint(tokenId)
        ));
    }

}












contract Cards is Ownable, MultiTransfer, BatchToken, ImmutableToken, InscribableToken {

    uint16 private constant MAX_UINT16 = 2**16 - 1;

    uint16[] public cardProtos;
    uint8[] public cardQualities;

    struct Season {
        uint16 high;
        uint16 low;
    }

    struct Proto {
        bool locked;
        bool exists;
        uint8 god;
        uint8 cardType;
        uint8 rarity;
        uint8 mana;
        uint8 attack;
        uint8 health;
        uint8 tribe;
    }

    event ProtoUpdated(
        uint16 indexed id
    );

    event SeasonStarted(
        uint16 indexed id,
        string name,
        uint16 indexed low,
        uint16 indexed high
    );

    event QualityChanged(
        uint256 indexed tokenId,
        uint8 quality,
        address factory
    );

    event CardsMinted(
        uint256 indexed start,
        address to,
        uint16[] protos,
        uint8[] qualities
    );


    uint16[] public protoToSeason;

    address public propertyManager;


    Proto[] public protos;


    Season[] public seasons;


    mapping(uint256 => bool) public seasonTradable;


    mapping(address => mapping(uint256 => bool)) public factoryApproved;


    mapping(uint16 => mapping(address => bool)) public mythicApproved;


    mapping(uint16 => bool) public mythicTradable;


    mapping(uint16 => bool) public mythicCreated;

    uint16 public constant MYTHIC_THRESHOLD = 65000;

    constructor(
        uint256 _batchSize,
        string memory _name,
        string memory _symbol
    )
        public
        BatchToken(_batchSize, _name, _symbol)
    {
        cardProtos.length = MAX_LENGTH;
        cardQualities.length = MAX_LENGTH;
        protoToSeason.length = MAX_LENGTH;
        protos.length = MAX_LENGTH;
        propertyManager = msg.sender;
    }

    function getDetails(
        uint256 tokenId
    )
        public
        view
        returns (uint16 proto, uint8 quality)
    {
        return (cardProtos[tokenId], cardQualities[tokenId]);
    }

    function mintCard(
        address to,
        uint16 _proto,
        uint8 _quality
    )
        external
        returns (uint id)
    {
        id = _batchMint(to, 1);
        _validateProto(_proto);
        cardProtos[id] = _proto;
        cardQualities[id] = _quality;

        uint16[] memory ps = new uint16[](1);
        ps[0] = _proto;

        uint8[] memory qs = new uint8[](1);
        qs[0] = _quality;

        emit CardsMinted(id, to, ps, qs);
        return id;
    }

    function mintCards(
        address to,
        uint16[] calldata _protos,
        uint8[] calldata _qualities
    )
        external
        returns (uint)
    {
        require(
            _protos.length > 0,
            "Core: must be some protos"
        );

        require(
            _protos.length == _qualities.length,
            "Core: must be the same number of protos/qualities"
        );

        uint256 start = _batchMint(to, uint16(_protos.length));
        _validateAndSaveDetails(start, _protos, _qualities);

        emit CardsMinted(start, to, _protos, _qualities);

        return start;
    }

    function addFactory(
        address _factory,
        uint256 _season
    )
        public
        onlyOwner
    {
        require(
            seasons.length >= _season,
            "Core: season must exist"
        );

        require(
            _season > 0,
            "Core: season must not be 0"
        );

        require(
            !factoryApproved[_factory][_season],
            "Core: this factory is already approved"
        );

        require(
            !seasonTradable[_season],
            "Core: season must not be tradable"
        );

        factoryApproved[_factory][_season] = true;
    }

    function approveForMythic(
        address _factory,
        uint16 _mythic
    )
        public
        onlyOwner
    {
        require(
            _mythic >= MYTHIC_THRESHOLD,
            "not a mythic"
        );

        require(
            !mythicApproved[_mythic][_factory],
            "Core: this factory is already approved for this mythic"
        );

        mythicApproved[_mythic][_factory] = true;
    }

    function makeMythicTradable(
        uint16 _mythic
    )
        public
        onlyOwner
    {
        require(
            _mythic >= MYTHIC_THRESHOLD,
            "Core: not a mythic"
        );

        require(
            !mythicTradable[_mythic],
            "Core: must not be tradable already"
        );

        mythicTradable[_mythic] = true;
    }

    function unlockTrading(
        uint256 _season
    )
        public
        onlyOwner
    {
        require(
            _season > 0 && _season <= seasons.length,
            "Core: must be a current season"
        );

        require(
            !seasonTradable[_season],
            "Core: season must not be tradable"
        );

        seasonTradable[_season] = true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
    {
        require(
            isTradable(tokenId),
            "Core: not yet tradable"
        );

        super.transferFrom(from, to, tokenId);
    }

    function burn(uint256 _tokenId) public {
        require(
            isTradable(_tokenId),
            "Core: not yet tradable"
        );

        super._burn(_tokenId);
    }

    function burnAll(uint256[] memory tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    function isTradable(uint256 _tokenId) public view returns (bool) {
        uint16 proto = cardProtos[_tokenId];
        if (proto >= MYTHIC_THRESHOLD) {
            return mythicTradable[proto];
        }
        return seasonTradable[protoToSeason[proto]];
    }

    function startSeason(
        string memory name,
        uint16 low,
        uint16 high
    )
        public
        onlyOwner
        returns (uint)
    {
        require(
            low > 0,
            "Core: must not be zero proto"
        );

        require(
            high > low,
            "Core: must be a valid range"
        );

        require(
            seasons.length == 0 || low > seasons[seasons.length - 1].high,
            "Core: seasons cannot overlap"
        );

        require(
            MYTHIC_THRESHOLD > high,
            "Core: cannot go into mythic territory"
        );


        uint16 id = uint16(seasons.push(Season({ high: high, low: low })));

        uint256 cp;
        assembly { cp := protoToSeason_slot }
        StorageWrite.repeatUint16(cp, low, (high - low) + 1, id);

        emit SeasonStarted(id, name, low, high);

        return id;
    }

    function updateProtos(
        uint16[] memory _ids,
        uint8[] memory _gods,
        uint8[] memory _cardTypes,
        uint8[] memory _rarities,
        uint8[] memory _manas,
        uint8[] memory _attacks,
        uint8[] memory _healths,
        uint8[] memory _tribes
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint16 id = _ids[i];

            require(
                id > 0,
                "Core: proto must not be zero"
            );

            Proto memory proto = protos[id];
            require(
                !proto.locked,
                "Core: proto is locked"
            );

            protos[id] = Proto({
                locked: false,
                exists: true,
                god: _gods[i],
                cardType: _cardTypes[i],
                rarity: _rarities[i],
                mana: _manas[i],
                attack: _attacks[i],
                health: _healths[i],
                tribe: _tribes[i]
            });
            emit ProtoUpdated(id);
        }
    }

    function lockProtos(uint16[] memory _ids) public onlyOwner {
        require(
            _ids.length > 0,
            "must lock some"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            uint16 id = _ids[i];
            require(
                id > 0,
                "proto must not be zero"
            );

            Proto storage proto = protos[id];

            require(
                !proto.locked,
                "proto is locked"
            );

            require(
                proto.exists,
                "proto must exist"
            );

            proto.locked = true;
            emit ProtoUpdated(id);
        }
    }

    function _validateAndSaveDetails(
        uint256 start,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        internal
    {
        _validateProtos(_protos);

        uint256 cp;
        assembly { cp := cardProtos_slot }
        StorageWrite.uint16s(cp, start, _protos);
        uint256 cq;
        assembly { cq := cardQualities_slot }
        StorageWrite.uint8s(cq, start, _qualities);
    }

    function _validateProto(uint16 proto) internal {
        if (proto >= MYTHIC_THRESHOLD) {
            _checkCanCreateMythic(proto);
        } else {

            uint256 season = protoToSeason[proto];

            require(
                season != 0,
                "Core: must have season set"
            );

            require(
                factoryApproved[msg.sender][season],
                "Core: must be approved factory for this season"
            );
        }
    }

    function _validateProtos(uint16[] memory _protos) internal {
        uint16 maxProto = 0;
        uint16 minProto = MAX_UINT16;
        for (uint256 i = 0; i < _protos.length; i++) {
            uint16 proto = _protos[i];
            if (proto >= MYTHIC_THRESHOLD) {
                _checkCanCreateMythic(proto);
            } else {
                if (proto > maxProto) {
                    maxProto = proto;
                }
                if (minProto > proto) {
                    minProto = proto;
                }
            }
        }

        if (maxProto != 0) {
            uint256 season = protoToSeason[maxProto];

            require(
                season != 0,
                "Core: must have season set"
            );

            require(
                season == protoToSeason[minProto],
                "Core: can only create cards from the same season"
            );

            require(
                factoryApproved[msg.sender][season],
                "Core: must be approved factory for this season"
            );
        }
    }

    function _checkCanCreateMythic(uint16 proto) internal {

        require(
            mythicApproved[proto][msg.sender],
            "Core: not approved to create this mythic"
        );

        require(
            !mythicCreated[proto],
            "Core: mythic has already been created"
        );

        mythicCreated[proto] = true;
    }

    function setQuality(
        uint256 _tokenId,
        uint8 _quality
    )
        public
    {
        uint16 proto = cardProtos[_tokenId];

        uint256 season = protoToSeason[proto];

        require(
            factoryApproved[msg.sender][season],
            "Core: factory can't change quality of this season"
        );

        cardQualities[_tokenId] = _quality;
        emit QualityChanged(_tokenId, _quality, msg.sender);
    }

    function setPropertyManager(address _manager) public onlyOwner {
        propertyManager = _manager;
    }

    function setProperty(uint256 _id, bytes32 _key, bytes32 _value) public {
        require(
            msg.sender == propertyManager,
            "Core: must be property manager"
        );

        _setProperty(_id, _key, _value);
    }

    function setClassProperty(bytes32 _key, bytes32 _value) public {
        require(
            msg.sender == propertyManager,
            "Core: must be property manager"
        );

        _setClassProperty(_key, _value);
    }

}



contract BatchWrapper is NewCards {

    uint16 private constant MAX_UINT16 = 2**16 - 1;
    Cards public old;
    bool public migrating;

    constructor(
        Cards _old,
        uint256 _batchSize,
        string memory _name,
        string memory _symbol
    ) public NewCards(_batchSize, _name, _symbol) {
        old = _old;
    }

    function setMigrating(bool _migrating) public onlyOwner {
        migrating = _migrating;
    }

    function copyUntil(uint gasThreshold) public {
        while (gasleft() > gasThreshold) {
            copyNextBatch();
        }
    }

    function mintCards(address _to, uint16[] memory _protos, uint8[] memory _qualities) public returns (uint id) {
        require(!migrating, "must not be migrating");
        super.mintCards(_to, _protos, _qualities);
    }

    function mintCard(address _to, uint16 _proto, uint8 _quality) public returns (uint id) {
        require(!migrating, "must not be migrating");
        super.mintCard(_to, _proto, _quality);
    }



    function copyNextBatch() public {
        require(migrating, "must be migrating");
        uint256 start = nextBatch;
        (uint48 userID, uint16 size) = old.batches(start);
        require(size > 0 && userID > 0, "incorrect batch or limit reached");
        if (old.cardProtos(start) != 0) {
            address to = old.userIDToAddress(userID);
            uint48 uID = _getUserID(to);
            batches[start] = Batch({
                userID: uID,
                size: size
            });
            uint256 end = start.add(size);
            for (uint256 i = start; i < end; i++) {
                emit Transfer(address(0), to, i);
            }
            _balances[to] = _balances[to].add(size);
            tokenCount = tokenCount.add(size);
        }
        nextBatch = nextBatch.add(batchSize);
    }

    function isOld(uint _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "card does not exist");
        return cardProtos[_tokenId] == 0;
    }

    function getProto(uint _tokenId) public view returns (uint16) {
        return isOld(_tokenId) ? old.cardProtos(_tokenId) : cardProtos[_tokenId];
    }

    function getQuality(uint _tokenId) public view returns (uint8) {
        return isOld(_tokenId) ? old.cardQualities(_tokenId) : cardQualities[_tokenId];
    }

    function getDetails(uint256 tokenId) public view returns (uint16 proto, uint8 quality) {
        return isOld(tokenId) ? old.getDetails(tokenId) : (cardProtos[tokenId], cardQualities[tokenId]);
    }

    function isTradable(uint256 _tokenId) public view returns (bool) {
        uint16 proto = getProto(_tokenId);
        if (proto >= MYTHIC_THRESHOLD) {
            return mythicTradable[proto];
        }
        return seasonTradable[protoToSeason[proto]];
    }

    function _transferFrom(address from, address to, uint tokenId) internal {
        require(
            isTradable(tokenId),
            "BW: not yet tradable"
        );
        super._transferFrom(from, to, tokenId);
    }



    function _validateProtos(uint16[] memory _protos) internal {

        uint16 maxProto = 0;
        uint16 minProto = MAX_UINT16;
        for (uint256 i = 0; i < _protos.length; i++) {
            uint16 proto = _protos[i];
            if (proto >= MYTHIC_THRESHOLD) {
                _checkCanCreateMythic(proto);
            } else {
                require(proto != 0, "proto is zero");
                if (proto > maxProto) {
                    maxProto = proto;
                }
                if (minProto > proto) {
                    minProto = proto;
                }
            }
        }

        if (maxProto != 0) {
            uint256 season = protoToSeason[maxProto];

            require(
                season != 0,
                "Core: must have season set"
            );

            require(
                season == protoToSeason[minProto],
                "Core: can only create cards from the same season"
            );

            require(
                factoryApproved[msg.sender][season],
                "Core: must be approved factory for this season"
            );
        }
    }

}
