



pragma solidity ^0.5.5;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function MEMCPY184(uint dest, uint src, uint len) private pure {

        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }


        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }


    function TOSLICE667(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }


    function LEN420(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }


    function TOSLICEB32242(bytes32 self) internal pure returns (slice memory ret) {

        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = LEN420(self);
    }


    function COPY737(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }


    function TOSTRING824(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        MEMCPY184(retptr, self._ptr, self._len);
        return ret;
    }


    function LEN420(slice memory self) internal pure returns (uint l) {

        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }


    function EMPTY246(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }


    function COMPARE76(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {

                uint256 mask = uint256(-1);
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }


    function EQUALS848(slice memory self, slice memory other) internal pure returns (bool) {
        return COMPARE76(self, other) == 0;
    }


    function NEXTRUNE884(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;

        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }


        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }


    function NEXTRUNE884(slice memory self) internal pure returns (slice memory ret) {
        NEXTRUNE884(self, ret);
    }


    function ORD412(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;


        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }


        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {

                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }


    function KECCAK7(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }


    function STARTSWITH158(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }


    function BEYOND684(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }


    function ENDSWITH884(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }


    function UNTIL972(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }



    function FINDPTR600(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {

                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }



    function RFINDPTR373(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {

                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }


    function FIND686(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = FINDPTR600(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }


    function RFIND966(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = RFINDPTR373(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }


    function SPLIT752(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = FINDPTR600(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {

            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }


    function SPLIT752(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        SPLIT752(self, needle, token);
    }


    function RSPLIT98(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = RFINDPTR373(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {

            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }


    function RSPLIT98(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        RSPLIT98(self, needle, token);
    }


    function COUNT317(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = FINDPTR600(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = FINDPTR600(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }


    function CONTAINS145(slice memory self, slice memory needle) internal pure returns (bool) {
        return RFINDPTR373(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }


    function CONCAT154(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        MEMCPY184(retptr, self._ptr, self._len);
        MEMCPY184(retptr + self._len, other._ptr, other._len);
        return ret;
    }


    function JOIN989(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            MEMCPY184(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                MEMCPY184(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}


interface IERC165 {

    function SUPPORTSINTERFACE706(bytes4 interfaceId) external view returns (bool);
}



contract IERC721 is IERC165 {
    event TRANSFER150(address indexed from, address indexed to, uint256 indexed tokenId);
    event APPROVAL578(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event APPROVALFORALL29(address indexed owner, address indexed operator, bool approved);


    function BALANCEOF194(address owner) public view returns (uint256 balance);


    function OWNEROF501(uint256 tokenId) public view returns (address owner);


    function SAFETRANSFERFROM763(address from, address to, uint256 tokenId) public;

    function TRANSFERFROM196(address from, address to, uint256 tokenId) public;
    function APPROVE594(address to, uint256 tokenId) public;
    function GETAPPROVED68(uint256 tokenId) public view returns (address operator);

    function SETAPPROVALFORALL944(address operator, bool _approved) public;
    function ISAPPROVEDFORALL189(address owner, address operator) public view returns (bool);


    function SAFETRANSFERFROM763(address from, address to, uint256 tokenId, bytes memory data) public;
}



contract IERC721Metadata is IERC721 {
    function NAME560() external view returns (string memory);
    function SYMBOL235() external view returns (string memory);
    function TOKENURI443(uint256 tokenId) external view returns (string memory);
}


contract Context {


    constructor () internal { }


    function _MSGSENDER492() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA8() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract IERC721Enumerable is IERC721 {
    function TOTALSUPPLY60() public view returns (uint256);
    function TOKENOFOWNERBYINDEX536(address owner, uint256 index) public view returns (uint256 tokenId);

    function TOKENBYINDEX294(uint256 index) public view returns (uint256);
}


contract IERC721Receiver {

    function ONERC721RECEIVED434(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


library SafeMath {

    function ADD556(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB290(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB290(a, b, "SafeMath: subtraction overflow");
    }


    function SUB290(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL948(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV752(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV752(a, b, "SafeMath: division by zero");
    }


    function DIV752(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD555(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD555(a, b, "SafeMath: modulo by zero");
    }


    function MOD555(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {

    function ISCONTRACT48(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }


    function TOPAYABLE256(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}


library Counters {
    using SafeMath for uint256;

    struct Counter {



        uint256 _value;
    }

    function CURRENT546(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function INCREMENT933(Counter storage counter) internal {

        counter._value += 1;
    }

    function DECREMENT749(Counter storage counter) internal {
        counter._value = counter._value.SUB290(1);
    }
}


contract ERC165 is IERC165 {

    bytes4 private constant _interface_id_erc165217 = 0x01ffc9a7;


    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {


        _REGISTERINTERFACE617(_interface_id_erc165217);
    }


    function SUPPORTSINTERFACE706(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }


    function _REGISTERINTERFACE617(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;



    bytes4 private constant _erc721_received995 = 0x150b7a02;


    mapping (uint256 => address) private _tokenOwner;


    mapping (uint256 => address) private _tokenApprovals;


    mapping (address => Counters.Counter) private _ownedTokensCount;


    mapping (address => mapping (address => bool)) private _operatorApprovals;


    bytes4 private constant _interface_id_erc721781 = 0x80ac58cd;

    constructor () public {

        _REGISTERINTERFACE617(_interface_id_erc721781);
    }


    function BALANCEOF194(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].CURRENT546();
    }


    function OWNEROF501(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }


    function APPROVE594(address to, uint256 tokenId) public {
        address owner = OWNEROF501(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_MSGSENDER492() == owner || ISAPPROVEDFORALL189(owner, _MSGSENDER492()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit APPROVAL578(owner, to, tokenId);
    }


    function GETAPPROVED68(uint256 tokenId) public view returns (address) {
        require(_EXISTS310(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }


    function SETAPPROVALFORALL944(address to, bool approved) public {
        require(to != _MSGSENDER492(), "ERC721: approve to caller");

        _operatorApprovals[_MSGSENDER492()][to] = approved;
        emit APPROVALFORALL29(_MSGSENDER492(), to, approved);
    }


    function ISAPPROVEDFORALL189(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function TRANSFERFROM196(address from, address to, uint256 tokenId) public {

        require(_ISAPPROVEDOROWNER717(_MSGSENDER492(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _TRANSFERFROM267(from, to, tokenId);
    }


    function SAFETRANSFERFROM763(address from, address to, uint256 tokenId) public {
        SAFETRANSFERFROM763(from, to, tokenId, "");
    }


    function SAFETRANSFERFROM763(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_ISAPPROVEDOROWNER717(_MSGSENDER492(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _SAFETRANSFERFROM629(from, to, tokenId, _data);
    }


    function _SAFETRANSFERFROM629(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _TRANSFERFROM267(from, to, tokenId);
        require(_CHECKONERC721RECEIVED542(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _EXISTS310(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }


    function _ISAPPROVEDOROWNER717(address spender, uint256 tokenId) internal view returns (bool) {
        require(_EXISTS310(tokenId), "ERC721: operator query for nonexistent token");
        address owner = OWNEROF501(tokenId);
        return (spender == owner || GETAPPROVED68(tokenId) == spender || ISAPPROVEDFORALL189(owner, spender));
    }


    function _SAFEMINT616(address to, uint256 tokenId) internal {
        _SAFEMINT616(to, tokenId, "");
    }


    function _SAFEMINT616(address to, uint256 tokenId, bytes memory _data) internal {
        _MINT975(to, tokenId);
        require(_CHECKONERC721RECEIVED542(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _MINT975(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_EXISTS310(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].INCREMENT933();

        emit TRANSFER150(address(0), to, tokenId);
    }


    function _BURN381(address owner, uint256 tokenId) internal {
        require(OWNEROF501(tokenId) == owner, "ERC721: burn of token that is not own");

        _CLEARAPPROVAL18(tokenId);

        _ownedTokensCount[owner].DECREMENT749();
        _tokenOwner[tokenId] = address(0);

        emit TRANSFER150(owner, address(0), tokenId);
    }


    function _BURN381(uint256 tokenId) internal {
        _BURN381(OWNEROF501(tokenId), tokenId);
    }


    function _TRANSFERFROM267(address from, address to, uint256 tokenId) internal {
        require(OWNEROF501(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _CLEARAPPROVAL18(tokenId);

        _ownedTokensCount[from].DECREMENT749();
        _ownedTokensCount[to].INCREMENT933();

        _tokenOwner[tokenId] = to;

        emit TRANSFER150(from, to, tokenId);
    }


    function _CHECKONERC721RECEIVED542(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.ISCONTRACT48()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).ONERC721RECEIVED434(_MSGSENDER492(), from, tokenId, _data);
        return (retval == _erc721_received995);
    }


    function _CLEARAPPROVAL18(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}


contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {

    mapping(address => uint256[]) private _ownedTokens;


    mapping(uint256 => uint256) private _ownedTokensIndex;


    uint256[] private _allTokens;


    mapping(uint256 => uint256) private _allTokensIndex;


    bytes4 private constant _interface_id_erc721_enumerable707 = 0x780e9d63;


    constructor () public {

        _REGISTERINTERFACE617(_interface_id_erc721_enumerable707);
    }


    function TOKENOFOWNERBYINDEX536(address owner, uint256 index) public view returns (uint256) {
        require(index < BALANCEOF194(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }


    function TOTALSUPPLY60() public view returns (uint256) {
        return _allTokens.length;
    }


    function TOKENBYINDEX294(uint256 index) public view returns (uint256) {
        require(index < TOTALSUPPLY60(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }


    function _TRANSFERFROM267(address from, address to, uint256 tokenId) internal {
        super._TRANSFERFROM267(from, to, tokenId);

        _REMOVETOKENFROMOWNERENUMERATION42(from, tokenId);

        _ADDTOKENTOOWNERENUMERATION485(to, tokenId);
    }


    function _MINT975(address to, uint256 tokenId) internal {
        super._MINT975(to, tokenId);

        _ADDTOKENTOOWNERENUMERATION485(to, tokenId);

        _ADDTOKENTOALLTOKENSENUMERATION66(tokenId);
    }


    function _BURN381(address owner, uint256 tokenId) internal {
        super._BURN381(owner, tokenId);

        _REMOVETOKENFROMOWNERENUMERATION42(owner, tokenId);

        _ownedTokensIndex[tokenId] = 0;

        _REMOVETOKENFROMALLTOKENSENUMERATION970(tokenId);
    }


    function _TOKENSOFOWNER469(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }


    function _ADDTOKENTOOWNERENUMERATION485(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }


    function _ADDTOKENTOALLTOKENSENUMERATION66(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }


    function _REMOVETOKENFROMOWNERENUMERATION42(address from, uint256 tokenId) private {



        uint256 lastTokenIndex = _ownedTokens[from].length.SUB290(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];


        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }


        _ownedTokens[from].length--;



    }


    function _REMOVETOKENFROMALLTOKENSENUMERATION970(uint256 tokenId) private {



        uint256 lastTokenIndex = _allTokens.length.SUB290(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];




        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;


        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}


contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED55(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER492();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED55(address(0), msgSender);
    }


    function OWNER824() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER845() {
        require(ISOWNER804(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER804() public view returns (bool) {
        return _MSGSENDER492() == _owner;
    }


    function RENOUNCEOWNERSHIP585() public ONLYOWNER845 {
        emit OWNERSHIPTRANSFERRED55(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP274(address newOwner) public ONLYOWNER845 {
        _TRANSFEROWNERSHIP356(newOwner);
    }


    function _TRANSFEROWNERSHIP356(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED55(_owner, newOwner);
        _owner = newOwner;
    }
}


contract NoMintERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;



    bytes4 private constant _erc721_received995 = 0x150b7a02;


    mapping (uint256 => address) private _tokenOwner;


    mapping (uint256 => address) private _tokenApprovals;


    mapping (address => Counters.Counter) private _ownedTokensCount;


    mapping (address => mapping (address => bool)) private _operatorApprovals;


    bytes4 private constant _interface_id_erc721781 = 0x80ac58cd;

    constructor () public {

        _REGISTERINTERFACE617(_interface_id_erc721781);
    }


    function BALANCEOF194(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].CURRENT546();
    }


    function OWNEROF501(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }


    function APPROVE594(address to, uint256 tokenId) public {
        address owner = OWNEROF501(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_MSGSENDER492() == owner || ISAPPROVEDFORALL189(owner, _MSGSENDER492()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit APPROVAL578(owner, to, tokenId);
    }


    function GETAPPROVED68(uint256 tokenId) public view returns (address) {
        require(_EXISTS310(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }


    function SETAPPROVALFORALL944(address to, bool approved) public {
        require(to != _MSGSENDER492(), "ERC721: approve to caller");

        _operatorApprovals[_MSGSENDER492()][to] = approved;
        emit APPROVALFORALL29(_MSGSENDER492(), to, approved);
    }


    function ISAPPROVEDFORALL189(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function TRANSFERFROM196(address from, address to, uint256 tokenId) public {

        require(_ISAPPROVEDOROWNER717(_MSGSENDER492(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _TRANSFERFROM267(from, to, tokenId);
    }


    function SAFETRANSFERFROM763(address from, address to, uint256 tokenId) public {
        SAFETRANSFERFROM763(from, to, tokenId, "");
    }


    function SAFETRANSFERFROM763(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_ISAPPROVEDOROWNER717(_MSGSENDER492(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _SAFETRANSFERFROM629(from, to, tokenId, _data);
    }


    function _SAFETRANSFERFROM629(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _TRANSFERFROM267(from, to, tokenId);
        require(_CHECKONERC721RECEIVED542(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _EXISTS310(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }


    function _ISAPPROVEDOROWNER717(address spender, uint256 tokenId) internal view returns (bool) {
        require(_EXISTS310(tokenId), "ERC721: operator query for nonexistent token");
        address owner = OWNEROF501(tokenId);
        return (spender == owner || GETAPPROVED68(tokenId) == spender || ISAPPROVEDFORALL189(owner, spender));
    }


    function _ADDTOKENTO735(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_EXISTS310(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].INCREMENT933();
    }


    function _BURN381(address owner, uint256 tokenId) internal {
        require(OWNEROF501(tokenId) == owner, "ERC721: burn of token that is not own");

        _CLEARAPPROVAL18(tokenId);

        _ownedTokensCount[owner].DECREMENT749();
        _tokenOwner[tokenId] = address(0);

        emit TRANSFER150(owner, address(0), tokenId);
    }


    function _BURN381(uint256 tokenId) internal {
        _BURN381(OWNEROF501(tokenId), tokenId);
    }


    function _TRANSFERFROM267(address from, address to, uint256 tokenId) internal {
        require(OWNEROF501(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _CLEARAPPROVAL18(tokenId);

        _ownedTokensCount[from].DECREMENT749();
        _ownedTokensCount[to].INCREMENT933();

        _tokenOwner[tokenId] = to;

        emit TRANSFER150(from, to, tokenId);
    }


    function _CHECKONERC721RECEIVED542(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.ISCONTRACT48()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).ONERC721RECEIVED434(_MSGSENDER492(), from, tokenId, _data);
        return (retval == _erc721_received995);
    }


    function _CLEARAPPROVAL18(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}


contract NoMintERC721Enumerable is Context, ERC165, NoMintERC721, IERC721Enumerable {

    mapping(address => uint256[]) private _ownedTokens;


    mapping(uint256 => uint256) private _ownedTokensIndex;


    uint256[] private _allTokens;


    mapping(uint256 => uint256) private _allTokensIndex;


    bytes4 private constant _interface_id_erc721_enumerable707 = 0x780e9d63;


    constructor () public {

        _REGISTERINTERFACE617(_interface_id_erc721_enumerable707);
    }


    function TOKENOFOWNERBYINDEX536(address owner, uint256 index) public view returns (uint256) {
        require(index < BALANCEOF194(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }


    function TOTALSUPPLY60() public view returns (uint256) {
        return _allTokens.length;
    }


    function TOKENBYINDEX294(uint256 index) public view returns (uint256) {
        require(index < TOTALSUPPLY60(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }


    function _TRANSFERFROM267(address from, address to, uint256 tokenId) internal {
        super._TRANSFERFROM267(from, to, tokenId);

        _REMOVETOKENFROMOWNERENUMERATION42(from, tokenId);

        _ADDTOKENTOOWNERENUMERATION485(to, tokenId);
    }


    function _ADDTOKENTO735(address to, uint256 tokenId) internal {
        super._ADDTOKENTO735(to, tokenId);

        _ADDTOKENTOOWNERENUMERATION485(to, tokenId);

        _ADDTOKENTOALLTOKENSENUMERATION66(tokenId);
    }


    function _BURN381(address owner, uint256 tokenId) internal {
        super._BURN381(owner, tokenId);

        _REMOVETOKENFROMOWNERENUMERATION42(owner, tokenId);

        _ownedTokensIndex[tokenId] = 0;

        _REMOVETOKENFROMALLTOKENSENUMERATION970(tokenId);
    }


    function _TOKENSOFOWNER469(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }


    function _ADDTOKENTOOWNERENUMERATION485(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }


    function _ADDTOKENTOALLTOKENSENUMERATION66(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }


    function _REMOVETOKENFROMOWNERENUMERATION42(address from, uint256 tokenId) private {



        uint256 lastTokenIndex = _ownedTokens[from].length.SUB290(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];


        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }


        _ownedTokens[from].length--;



    }


    function _REMOVETOKENFROMALLTOKENSENUMERATION970(uint256 tokenId) private {



        uint256 lastTokenIndex = _allTokens.length.SUB290(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];




        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;


        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}


contract OveridableERC721Metadata is Context, ERC165, NoMintERC721, IERC721Metadata {

    string private _name;


    string private _symbol;


    mapping(uint256 => string) private _tokenURIs;


    bytes4 private constant _interface_id_erc721_metadata259 = 0x5b5e139f;


    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;


        _REGISTERINTERFACE617(_interface_id_erc721_metadata259);
    }


    function NAME560() external view returns (string memory) {
        return _name;
    }


    function SYMBOL235() external view returns (string memory) {
        return _symbol;
    }


    function TOKENURI443(uint256 tokenId) public view returns (string memory) {
        require(_EXISTS310(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }


    function _SETTOKENURI639(uint256 tokenId, string memory uri) internal {
        require(_EXISTS310(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }


    function _BURN381(address owner, uint256 tokenId) internal {
        super._BURN381(owner, tokenId);


        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


contract GunToken is NoMintERC721, NoMintERC721Enumerable, OveridableERC721Metadata, Ownable {
    using strings for *;

    address internal factory;

    uint16 public constant maxallocation33 = 4000;
    uint256 public lastAllocation = 0;

    event BATCHTRANSFER76(address indexed from, address indexed to, uint256 indexed batchIndex);

    struct Batch {
        address owner;
        uint16 size;
        uint8 category;
        uint256 startId;
        uint256 startTokenId;
    }

    Batch[] public allBatches;
    mapping(address => uint256) unactivatedBalance;
    mapping(uint256 => bool) isActivated;
    mapping(uint256 => bool) public outOfBatch;


    mapping(address => Batch[]) public batchesOwned;

    mapping(uint256 => uint256) public ownedBatchIndex;

    mapping(uint8 => uint256) internal totalGunsMintedByCategory;
    uint256 internal _totalSupply;

    modifier ONLYFACTORY168 {
        require(msg.sender == factory, "Not authorized");
        _;
    }

    constructor(address factoryAddress) public OveridableERC721Metadata("WarRiders Gun", "WRG") {
        factory = factoryAddress;
    }

    function CATEGORYTYPETOID957(uint8 category, uint256 categoryId) public view returns (uint256) {
        for (uint i = 0; i < allBatches.length; i++) {
            Batch memory a = allBatches[i];
            if (a.category != category)
                continue;

            uint256 endId = a.startId + a.size;
            if (categoryId >= a.startId && categoryId < endId) {
                uint256 dif = categoryId - a.startId;

                return a.startTokenId + dif;
            }
        }

        revert();
    }

    function FALLBACKCOUNT353(address __owner) public view returns (uint256) {

    }

    function FALLBACKINDEX7(address __owner, uint256 index) public view returns (uint256) {

    }

    function MIGRATE859(uint256 count) public ONLYOWNER845 returns (uint256) {

    }

    function MIGRATESINGLE765() public ONLYOWNER845 returns (uint256) {

    }

    function RECOVERBATCH2175(uint256 index, uint256 tokenStart, uint256 tokenEnd) public ONLYOWNER845 {

    }

    function MIGRATEBATCH628(uint256 index) public ONLYOWNER845 returns (uint256) {

    }

    function RECOVERBATCH1434(uint256 index) public ONLYOWNER845 {

    }


    function TOKENOFOWNERBYINDEX536(address owner, uint256 index) public view returns (uint256) {
        return TOKENOFOWNER723(owner)[index];
    }

    function GETBATCHCOUNT927(address owner) public view returns(uint256) {
        return batchesOwned[owner].length;
    }

    function UPDATEGUNFACTORY282(address _factory) public ONLYOWNER845 {

    }

    function GETTOKENSINBATCH347(address owner, uint256 index) public view returns (uint256[] memory) {
        Batch memory a = batchesOwned[owner][index];
        uint256[] memory result = new uint256[](a.size);

        uint256 pos = 0;
        uint end = a.startTokenId + a.size;
        for (uint i = a.startTokenId; i < end; i++) {
            if (isActivated[i] && super.OWNEROF501(i) != owner) {
                continue;
            }

            result[pos] = i;
            pos++;
        }

        require(pos > 0);

        uint256 subAmount = a.size - pos;

        assembly { mstore(result, sub(mload(result), subAmount)) }

        return result;
    }

    function TOKENBYINDEX294(uint256 index) public view returns (uint256) {
        return ALLTOKENS936()[index];
    }

    function ALLTOKENS936() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](TOTALSUPPLY60());

        uint pos = 0;
        for (uint i = 0; i < allBatches.length; i++) {
            Batch memory a = allBatches[i];
            uint end = a.startTokenId + a.size;
            for (uint j = a.startTokenId; j < end; j++) {
                result[pos] = j;
                pos++;
            }
        }

        return result;
    }

    function TOKENOFOWNER723(address owner) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](BALANCEOF194(owner));

        uint pos = 0;
        for (uint i = 0; i < batchesOwned[owner].length; i++) {
            Batch memory a = batchesOwned[owner][i];
            uint end = a.startTokenId + a.size;
            for (uint j = a.startTokenId; j < end; j++) {
                if (isActivated[j] && super.OWNEROF501(j) != owner) {
                    continue;
                }

                result[pos] = j;
                pos++;
            }
        }

        uint256[] memory fallbackOwned = _TOKENSOFOWNER469(owner);
        for (uint i = 0; i < fallbackOwned.length; i++) {
            result[pos] = fallbackOwned[i];
            pos++;
        }

        return result;
    }

    function BALANCEOF194(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return super.BALANCEOF194(owner) + unactivatedBalance[owner];
    }

     function OWNEROF501(uint256 tokenId) public view returns (address) {
         require(EXISTS127(tokenId), "Token doesn't exist!");

         if (isActivated[tokenId]) {
             return super.OWNEROF501(tokenId);
         }
         uint256 index = GETBATCHINDEX786(tokenId);
         require(index < allBatches.length, "Token batch doesn't exist");
         Batch memory a = allBatches[index];
         require(tokenId < a.startTokenId + a.size);
         return a.owner;
     }

    function EXISTS127(uint256 _tokenId) public view returns (bool) {
        if (isActivated[_tokenId]) {
            return super._EXISTS310(_tokenId);
        } else {
            uint256 index = GETBATCHINDEX786(_tokenId);
            if (index < allBatches.length) {
                Batch memory a = allBatches[index];
                uint end = a.startTokenId + a.size;

                return _tokenId < end;
            }
            return false;
        }
    }

    function TOTALSUPPLY60() public view returns (uint256) {
        return _totalSupply;
    }

    function CLAIMALLOCATION316(address to, uint16 size, uint8 category) public ONLYFACTORY168 returns (uint) {
        require(size < maxallocation33, "Size must be smaller than maxAllocation");

        allBatches.push(Batch({
            owner: to,
            size: size,
            category: category,
            startId: totalGunsMintedByCategory[category],
            startTokenId: lastAllocation
        }));

        uint end = lastAllocation + size;
        for (uint i = lastAllocation; i < end; i++) {
            emit TRANSFER150(address(0), to, i);
        }

        lastAllocation += maxallocation33;

        unactivatedBalance[to] += size;
        totalGunsMintedByCategory[category] += size;

        _ADDBATCHTOOWNER461(to, allBatches[allBatches.length - 1]);

        _totalSupply += size;
        return lastAllocation;
    }

    function TRANSFERFROM196(address from, address to, uint256 tokenId) public {
        if (!isActivated[tokenId]) {
            ACTIVATE8(tokenId);
        }
        super.TRANSFERFROM196(from, to, tokenId);
    }

    function ACTIVATE8(uint256 tokenId) public {
        require(!isActivated[tokenId], "Token already activated");
        uint256 index = GETBATCHINDEX786(tokenId);
        require(index < allBatches.length, "Token batch doesn't exist");
        Batch memory a = allBatches[index];
        require(tokenId < a.startTokenId + a.size);
        isActivated[tokenId] = true;
        ADDTOKENTO758(a.owner, tokenId);
        unactivatedBalance[a.owner]--;
    }

    function GETBATCHINDEX786(uint256 tokenId) public pure returns (uint256) {
        uint256 index = (tokenId / maxallocation33);

        return index;
    }

    function CATEGORYFORTOKEN792(uint256 tokenId) public view returns (uint8) {
        uint256 index = GETBATCHINDEX786(tokenId);
        require(index < allBatches.length, "Token batch doesn't exist");

        Batch memory a = allBatches[index];

        return a.category;
    }

    function CATEGORYIDFORTOKEN949(uint256 tokenId) public view returns (uint256) {
        uint256 index = GETBATCHINDEX786(tokenId);
        require(index < allBatches.length, "Token batch doesn't exist");

        Batch memory a = allBatches[index];

        uint256 categoryId = (tokenId % maxallocation33) + a.startId;

        return categoryId;
    }

    function UINTTOSTRING328(uint v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint j = v;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (v != 0) {
            bstr[k--] = byte(uint8(48 + v % 10));
            v /= 10;
        }

        return string(bstr);
    }

    function TOKENURI443(uint256 tokenId) public view returns (string memory) {
        require(EXISTS127(tokenId), "Token doesn't exist!");
        if (isActivated[tokenId]) {
            return super.TOKENURI443(tokenId);
        } else {

            uint8 category = CATEGORYFORTOKEN792(tokenId);
            uint256 _categoryId = CATEGORYIDFORTOKEN949(tokenId);

            string memory id = UINTTOSTRING328(category).TOSLICE667().CONCAT154("/".TOSLICE667()).TOSLICE667().CONCAT154(UINTTOSTRING328(_categoryId).TOSLICE667().CONCAT154(".json".TOSLICE667()).TOSLICE667());
            string memory _base = "https:


            string memory _metadata = _base.TOSLICE667().CONCAT154(id.TOSLICE667());

            return _metadata;
        }
    }

    function ADDTOKENTO758(address _to, uint256 _tokenId) internal {

        uint8 category = CATEGORYFORTOKEN792(_tokenId);
        uint256 _categoryId = CATEGORYIDFORTOKEN949(_tokenId);

        string memory id = UINTTOSTRING328(category).TOSLICE667().CONCAT154("/".TOSLICE667()).TOSLICE667().CONCAT154(UINTTOSTRING328(_categoryId).TOSLICE667().CONCAT154(".json".TOSLICE667()).TOSLICE667());
        string memory _base = "https:


        string memory _metadata = _base.TOSLICE667().CONCAT154(id.TOSLICE667());

        super._ADDTOKENTO735(_to, _tokenId);
        super._SETTOKENURI639(_tokenId, _metadata);
    }

    function CEIL247(uint a, uint m) internal pure returns (uint ) {
        return ((a + m - 1) / m) * m;
    }

    function _REMOVEBATCHFROMOWNER136(address from, Batch memory batch) private {



        uint256 globalIndex = GETBATCHINDEX786(batch.startTokenId);

        uint256 lastBatchIndex = batchesOwned[from].length.SUB290(1);
        uint256 batchIndex = ownedBatchIndex[globalIndex];


        if (batchIndex != lastBatchIndex) {
            Batch memory lastBatch = batchesOwned[from][lastBatchIndex];
            uint256 lastGlobalIndex = GETBATCHINDEX786(lastBatch.startTokenId);

            batchesOwned[from][batchIndex] = lastBatch;
            ownedBatchIndex[lastGlobalIndex] = batchIndex;
        }


        batchesOwned[from].length--;



    }

    function _ADDBATCHTOOWNER461(address to, Batch memory batch) private {
        uint256 globalIndex = GETBATCHINDEX786(batch.startTokenId);

        ownedBatchIndex[globalIndex] = batchesOwned[to].length;
        batchesOwned[to].push(batch);
    }

    function BATCHTRANSFER268(uint256 batchIndex, address to) public {
        Batch storage a = allBatches[batchIndex];

        address previousOwner = a.owner;

        require(a.owner == msg.sender);

        _REMOVEBATCHFROMOWNER136(previousOwner, a);

        a.owner = to;

        _ADDBATCHTOOWNER461(to, a);

        emit BATCHTRANSFER76(previousOwner, to, batchIndex);


        uint end = a.startTokenId + a.size;
        uint256 unActivated = 0;
        for (uint i = a.startTokenId; i < end; i++) {
            if (isActivated[i]) {
                if (OWNEROF501(i) != previousOwner)
                    continue;
            } else {
                unActivated++;
            }
            emit TRANSFER150(previousOwner, to, i);
        }

        unactivatedBalance[to] += unActivated;
        unactivatedBalance[previousOwner] -= unActivated;
    }
}

contract ApproveAndCallFallBack {
    function RECEIVEAPPROVAL438(address from, uint256 tokens, address token, bytes memory data) public payable returns (bool);
}


contract ERC20Basic {
  function TOTALSUPPLY60() public view returns (uint256);
  function BALANCEOF194(address who) public view returns (uint256);
  function TRANSFER702(address to, uint256 value) public returns (bool);
  event TRANSFER150(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function ALLOWANCE798(address owner, address spender)
    public view returns (uint256);

  function TRANSFERFROM196(address from, address to, uint256 value)
    public returns (bool);

  function APPROVE594(address spender, uint256 value) public returns (bool);
  event APPROVAL578(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BurnableToken is ERC20 {
  event BURN595(address indexed burner, uint256 value);
  function BURN840(uint256 _value) public;
}

contract StandardBurnableToken is BurnableToken {
  function BURNFROM813(address _from, uint256 _value) public;
}

interface BZNFeed {

    function CONVERT77(uint256 usd) external view returns (uint256);
}

contract SimpleBZNFeed is BZNFeed, Ownable {

    uint256 private conversion;

    function UPDATECONVERSION150(uint256 conversionRate) public ONLYOWNER845 {
        conversion = conversionRate;
    }

    function CONVERT77(uint256 usd) external view returns (uint256) {
        return usd * conversion;
    }
}

interface IDSValue {

    function PEEK123() external view returns (bytes32, bool);
    function READ988() external view returns (bytes32);
    function POKE435(bytes32 wut) external;
    function VOID212() external;
}

library BytesLib {
    function CONCAT154(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {


            tempBytes := mload(0x40)



            let length := mload(_preBytes)
            mstore(tempBytes, length)




            let mc := add(tempBytes, 0x20)


            let end := add(mc, length)

            for {


                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {

                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {


                mstore(mc, mload(cc))
            }




            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))



            mc := end


            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }






            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)
            ))
        }

        return tempBytes;
    }

    function CONCATSTORAGE572(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {



            let fslot := sload(_preBytes_slot)







            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)



            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {



                sstore(
                    _preBytes_slot,


                    add(


                        fslot,
                        add(
                            mul(
                                div(

                                    mload(add(_postBytes, 0x20)),

                                    exp(0x100, sub(32, mlength))
                                ),


                                exp(0x100, sub(32, newlength))
                            ),


                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {



                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))


                sstore(_preBytes_slot, add(mul(newlength, 2), 1))










                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {

                mstore(0x0, _preBytes_slot)

                let sc := add(keccak256(0x0, 0x20), div(slength, 32))


                sstore(_preBytes_slot, add(mul(newlength, 2), 1))



                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function SLICE625(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {


                tempBytes := mload(0x40)









                let lengthmod := and(_length, 31)





                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {


                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)



                mstore(0x40, and(add(mc, 31), not(31)))
            }

            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function TOADDRESS210(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function TOUINT8119(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function TOUINT16152(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function TOUINT32393(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function TOUINT64646(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function TOUINT96427(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function TOUINT12878(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function TOUINT505(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function TOBYTES32154(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function EQUAL770(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)


            switch eq(length, mload(_postBytes))
            case 1 {




                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)


                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {

                    if iszero(eq(mload(mc), mload(cc))) {

                        success := 0
                        cb := 0
                    }
                }
            }
            default {

                success := 0
            }
        }

        return success;
    }

    function EQUALSTORAGE902(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {

            let fslot := sload(_preBytes_slot)

            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)


            switch eq(slength, mlength)
            case 1 {



                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {

                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {

                            success := 0
                        }
                    }
                    default {




                        let cb := 1


                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)



                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {

                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {

                success := 0
            }
        }

        return success;
    }
}

contract GunPreOrder is Ownable, ApproveAndCallFallBack {
    using BytesLib for bytes;
    using SafeMath for uint256;


    event CONSUMERBULKBUY355(uint8 category, uint256 quanity, address reserver);

    event GUNSBOUGHT917(uint256 gunId, address owner, uint8 category);

    event WITHDRAWAL910(uint256 amount);


    uint256 public constant commission_percent82 = 5;


    mapping(uint8 => bool) public categoryExists;
    mapping(uint8 => bool) public categoryOpen;
    mapping(uint8 => bool) public categoryKilled;


    mapping(address => uint256) internal commissionRate;


    mapping(uint8 => mapping(address => uint256)) public categoryReserveAmount;


    address internal constant opensea308 = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;


    mapping(uint8 => uint256) public categoryPercentIncrease;
    mapping(uint8 => uint256) public categoryPercentBase;


    mapping(uint8 => uint256) public categoryPrice;


    mapping(uint8 => uint256) public requiredEtherPercent;
    mapping(uint8 => uint256) public requiredEtherPercentBase;
    bool public allowCreateCategory = true;


    GunToken public token;

    GunFactory internal factory;

    StandardBurnableToken internal bzn;

    IDSValue public ethFeed;
    BZNFeed public bznFeed;

    address internal gamePool;


    modifier ENSURESHOPOPEN328(uint8 category) {
        require(categoryExists[category], "Category doesn't exist!");
        require(categoryOpen[category], "Category is not open!");
        _;
    }


    modifier PAYINETH352(address referal, uint8 category, address new_owner, uint16 quanity) {
        uint256 usdPrice;
        uint256 totalPrice;
        (usdPrice, totalPrice) = PRICEFOR73(category, quanity);
        require(usdPrice > 0, "Price not yet set");

        categoryPrice[category] = usdPrice;

        uint256 price = CONVERT77(totalPrice, false);

        require(msg.value >= price, "Not enough Ether sent!");

        _;

        if (msg.value > price) {
            uint256 change = msg.value - price;

            msg.sender.transfer(change);
        }

        if (referal != address(0)) {
            require(referal != msg.sender, "The referal cannot be the sender");
            require(referal != tx.origin, "The referal cannot be the tranaction origin");
            require(referal != new_owner, "The referal cannot be the new owner");


            uint256 totalCommision = commission_percent82 + commissionRate[referal];

            uint256 commision = (price * totalCommision) / 100;

            address payable _referal = address(uint160(referal));

            _referal.transfer(commision);
        }

    }


    modifier PAYINBZN388(address referal, uint8 category, address payable new_owner, uint16 quanity) {
        uint256[] memory prices = new uint256[](4);
        (prices[0], prices[3]) = PRICEFOR73(category, quanity);
        require(prices[0] > 0, "Price not yet set");

        categoryPrice[category] = prices[0];

        prices[1] = CONVERT77(prices[3], true);


        if (referal != address(0)) {
            prices[2] = (prices[1] * (commission_percent82 + commissionRate[referal])) / 100;
        }

        uint256 requiredEther = (CONVERT77(prices[3], false) * requiredEtherPercent[category]) / requiredEtherPercentBase[category];

        require(msg.value >= requiredEther, "Buying with BZN requires some Ether!");

        bzn.BURNFROM813(new_owner, (((prices[1] - prices[2]) * 30) / 100));
        bzn.TRANSFERFROM196(new_owner, gamePool, prices[1] - prices[2] - (((prices[1] - prices[2]) * 30) / 100));

        _;

        if (msg.value > requiredEther) {
            new_owner.transfer(msg.value - requiredEther);
        }

        if (referal != address(0)) {
            require(referal != msg.sender, "The referal cannot be the sender");
            require(referal != tx.origin, "The referal cannot be the tranaction origin");
            require(referal != new_owner, "The referal cannot be the new owner");

            bzn.TRANSFERFROM196(new_owner, referal, prices[2]);

            prices[2] = (requiredEther * (commission_percent82 + commissionRate[referal])) / 100;

            address payable _referal = address(uint160(referal));

            _referal.transfer(prices[2]);
        }
    }


    constructor(
        address tokenAddress,
        address tokenFactory,
        address gp,
        address isd,
        address bzn_address
    ) public {
        token = GunToken(tokenAddress);

        factory = GunFactory(tokenFactory);

        ethFeed = IDSValue(isd);
        bzn = StandardBurnableToken(bzn_address);

        gamePool = gp;


        categoryPercentIncrease[1] = 100035;
        categoryPercentBase[1] = 100000;

        categoryPercentIncrease[2] = 100025;
        categoryPercentBase[2] = 100000;

        categoryPercentIncrease[3] = 100015;
        categoryPercentBase[3] = 100000;

        commissionRate[opensea308] = 10;
    }

    function CREATECATEGORY817(uint8 category) public ONLYOWNER845 {
        require(allowCreateCategory);

        categoryExists[category] = true;
    }

    function DISABLECREATECATEGORIES112() public ONLYOWNER845 {
        allowCreateCategory = false;
    }


    function SETCOMMISSION914(address referral, uint256 percent) public ONLYOWNER845 {
        require(percent > commission_percent82);
        require(percent < 95);
        percent = percent - commission_percent82;

        commissionRate[referral] = percent;
    }


    function SETPERCENTINCREASE775(uint256 increase, uint256 base, uint8 category) public ONLYOWNER845 {
        require(increase > base);

        categoryPercentIncrease[category] = increase;
        categoryPercentBase[category] = base;
    }

    function SETETHERPERCENT411(uint256 percent, uint256 base, uint8 category) public ONLYOWNER845 {
        requiredEtherPercent[category] = percent;
        requiredEtherPercentBase[category] = base;
    }

    function KILLCATEGORY428(uint8 category) public ONLYOWNER845 {
        require(!categoryKilled[category]);

        categoryOpen[category] = false;
        categoryKilled[category] = true;
    }


    function SETSHOPSTATE191(uint8 category, bool open) public ONLYOWNER845 {
        require(category == 1 || category == 2 || category == 3);
        require(!categoryKilled[category]);
        require(categoryExists[category]);

        categoryOpen[category] = open;
    }


    function SETPRICE360(uint8 category, uint256 price, bool inWei) public ONLYOWNER845 {
        uint256 multiply = 1e18;
        if (inWei) {
            multiply = 1;
        }

        categoryPrice[category] = price * multiply;
    }


    function WITHDRAW154(uint256 amount) public ONLYOWNER845 {
        uint256 balance = address(this).balance;

        require(amount <= balance, "Requested to much");

        address payable _owner = address(uint160(OWNER824()));

        _owner.transfer(amount);

        emit WITHDRAWAL910(amount);
    }

    function SETBZNFEEDCONTRACT654(address new_bzn_feed) public ONLYOWNER845 {
        bznFeed = BZNFeed(new_bzn_feed);
    }


    function BUYWITHBZN846(address referal, uint8 category, address payable new_owner, uint16 quanity) ENSURESHOPOPEN328(category) PAYINBZN388(referal, category, new_owner, quanity) public payable returns (bool) {
        factory.MINTFOR528(new_owner, quanity, category);

        return true;
    }


    function BUYWITHETHER108(address referal, uint8 category, address new_owner, uint16 quanity) ENSURESHOPOPEN328(category) PAYINETH352(referal, category, new_owner, quanity) public payable returns (bool) {
        factory.MINTFOR528(new_owner, quanity, category);

        return true;
    }

    function CONVERT77(uint256 usdValue, bool isBZN) public view returns (uint256) {
        if (isBZN) {
            return bznFeed.CONVERT77(usdValue);
        } else {
            bool temp;
            bytes32 aaa;
            (aaa, temp) = ethFeed.PEEK123();

            uint256 priceForEtherInUsdWei = uint256(aaa);

            return usdValue / (priceForEtherInUsdWei / 1e18);
        }
    }


    function PRICEFOR73(uint8 category, uint16 quanity) public view returns (uint256, uint256) {
        require(quanity > 0);
        uint256 percent = categoryPercentIncrease[category];
        uint256 base = categoryPercentBase[category];

        uint256 currentPrice = categoryPrice[category];
        uint256 nextPrice = currentPrice;
        uint256 totalPrice = 0;


        for (uint i = 0; i < quanity; i++) {
            nextPrice = (currentPrice * percent) / base;

            currentPrice = nextPrice;

            totalPrice += nextPrice;
        }


        return (nextPrice, totalPrice);
    }


    function SOLD957(uint256 _tokenId) public view returns (bool) {
        return token.EXISTS127(_tokenId);
    }

    function RECEIVEAPPROVAL438(address from, uint256 tokenAmount, address tokenContract, bytes memory data) public payable returns (bool) {
        address referal;
        uint8 category;
        uint16 quanity;

        (referal, category, quanity) = abi.decode(data, (address, uint8, uint16));

        require(quanity >= 1);

        address payable _from = address(uint160(from));

        BUYWITHBZN846(referal, category, _from, quanity);

        return true;
    }
}

contract GunFactory is Ownable {
    using strings for *;

    uint8 public constant premium_category760 = 1;
    uint8 public constant midgrade_category818 = 2;
    uint8 public constant regular_category63 = 3;
    uint256 public constant one_month568 = 2628000;

    uint256 public mintedGuns = 0;
    address preOrderAddress;
    GunToken token;

    mapping(uint8 => uint256) internal gunsMintedByCategory;
    mapping(uint8 => uint256) internal totalGunsMintedByCategory;

    mapping(uint8 => uint256) internal firstMonthLimit;
    mapping(uint8 => uint256) internal secondMonthLimit;
    mapping(uint8 => uint256) internal thirdMonthLimit;

    uint256 internal startTime;
    mapping(uint8 => uint256) internal currentMonthEnd;
    uint256 internal monthOneEnd;
    uint256 internal monthTwoEnd;

    modifier ONLYPREORDER406 {
        require(msg.sender == preOrderAddress, "Not authorized");
        _;
    }

    modifier ISINITIALIZED13 {
        require(preOrderAddress != address(0), "No linked preorder");
        require(address(token) != address(0), "No linked token");
        _;
    }

    constructor() public {
        firstMonthLimit[premium_category760] = 5000;
        firstMonthLimit[midgrade_category818] = 20000;
        firstMonthLimit[regular_category63] = 30000;

        secondMonthLimit[premium_category760] = 2500;
        secondMonthLimit[midgrade_category818] = 10000;
        secondMonthLimit[regular_category63] = 15000;

        thirdMonthLimit[premium_category760] = 600;
        thirdMonthLimit[midgrade_category818] = 3000;
        thirdMonthLimit[regular_category63] = 6000;

        startTime = block.timestamp;
        monthOneEnd = startTime + one_month568;
        monthTwoEnd = startTime + one_month568 + one_month568;

        currentMonthEnd[premium_category760] = monthOneEnd;
        currentMonthEnd[midgrade_category818] = monthOneEnd;
        currentMonthEnd[regular_category63] = monthOneEnd;
    }

    function UINTTOSTRING328(uint v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint j = v;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (v != 0) {
            bstr[k--] = byte(uint8(48 + v % 10));
            v /= 10;
        }

        return string(bstr);
    }

    function MINTFOR528(address newOwner, uint16 size, uint8 category) public ONLYPREORDER406 ISINITIALIZED13 returns (uint256) {
        GunPreOrder preOrder = GunPreOrder(preOrderAddress);
        require(preOrder.categoryExists(category), "Invalid category");

        require(!HASREACHEDLIMIT199(category), "The monthly limit has been reached");

        token.CLAIMALLOCATION316(newOwner, size, category);

        mintedGuns++;

        gunsMintedByCategory[category] = gunsMintedByCategory[category] + 1;
        totalGunsMintedByCategory[category] = totalGunsMintedByCategory[category] + 1;
    }

    function HASREACHEDLIMIT199(uint8 category) internal returns (bool) {
        uint256 currentTime = block.timestamp;
        uint256 limit = CURRENTLIMIT394(category);

        uint256 monthEnd = currentMonthEnd[category];


        if (currentTime >= monthEnd) {




            gunsMintedByCategory[category] = 0;



            while (currentTime >= monthEnd) {
                monthEnd = monthEnd + one_month568;
            }


            limit = CURRENTLIMIT394(category);
            currentMonthEnd[category] = monthEnd;
        }


        return gunsMintedByCategory[category] >= limit;
    }

    function REACHEDLIMIT389(uint8 category) public view returns (bool) {
        uint256 limit = CURRENTLIMIT394(category);

        return gunsMintedByCategory[category] >= limit;
    }

    function CURRENTLIMIT394(uint8 category) public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 limit;
        if (currentTime < monthOneEnd) {
            limit = firstMonthLimit[category];
        } else if (currentTime < monthTwoEnd) {
            limit = secondMonthLimit[category];
        } else {
            limit = thirdMonthLimit[category];
        }

        return limit;
    }

    function SETCATEGORYLIMIT220(uint8 category, uint256 firstLimit, uint256 secondLimit, uint256 thirdLimit) public ONLYOWNER845 {
        require(firstMonthLimit[category] == 0);
        require(secondMonthLimit[category] == 0);
        require(thirdMonthLimit[category] == 0);

        firstMonthLimit[category] = firstLimit;
        secondMonthLimit[category] = secondLimit;
        thirdMonthLimit[category] = thirdLimit;
    }


    function ATTACHPREORDER925(address dst) public ONLYOWNER845 {
        require(preOrderAddress == address(0));
        require(dst != address(0));


        GunPreOrder preOrder = GunPreOrder(dst);

        preOrderAddress = address(preOrder);
    }


    function ATTACHTOKEN953(address dst) public ONLYOWNER845 {
        require(address(token) == address(0));
        require(dst != address(0));


        GunToken ct = GunToken(dst);

        token = ct;
    }
}
