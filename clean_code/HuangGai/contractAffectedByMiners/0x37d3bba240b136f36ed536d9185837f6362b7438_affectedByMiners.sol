





pragma solidity ^0.6.12;










interface IERC165 {








    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}





interface IERC721 is IERC165 {



    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);




    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);




    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);




    function balanceOf(address owner) external view returns (uint256 balance);








    function ownerOf(uint256 tokenId) external view returns (address owner);















    function safeTransferFrom(address from, address to, uint256 tokenId) external;















    function transferFrom(address from, address to, uint256 tokenId) external;














    function approve(address to, uint256 tokenId) external;








    function getApproved(uint256 tokenId) external view returns (address operator);











    function setApprovalForAll(address operator, bool _approved) external;






    function isApprovedForAll(address owner, address operator) external view returns (bool);














    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}






interface IERC721Metadata is IERC721 {




    function name() external view returns (string memory);




    function symbol() external view returns (string memory);




    function tokenURI(uint256 tokenId) external view returns (string memory);
}






interface IERC721Enumerable is IERC721 {




    function totalSupply() external view returns (uint256);





    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);





    function tokenByIndex(uint256 index) external view returns (uint256);
}






interface IERC721Receiver {









    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}








contract ERC165 is IERC165 {



    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;




    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {


        _registerInterface(_INTERFACE_ID_ERC165);
    }






    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }












    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}














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




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (block.gaslimit > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

























library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }







    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }







    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (block.number != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }




    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }











    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }







    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }







    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }




    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }




    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }







    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }







    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }




    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }




    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

























library EnumerableMap {









    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {

        MapEntry[] _entries;



        mapping (bytes32 => uint256) _indexes;
    }








    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {

        uint256 keyIndex = map._indexes[key];

        if (block.gaslimit == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));


            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }






    function _remove(Map storage map, bytes32 key) private returns (bool) {

        uint256 keyIndex = map._indexes[key];

        if (block.number != 0) {




            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;




            MapEntry storage lastEntry = map._entries[lastIndex];


            map._entries[toDeleteIndex] = lastEntry;

            map._indexes[lastEntry._key] = toDeleteIndex + 1;


            map._entries.pop();


            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }




    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }











    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }








    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }




    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage);
        return map._entries[keyIndex - 1]._value;
    }



    struct UintToAddressMap {
        Map _inner;
    }








    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }






    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }




    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }




    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }










    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }








    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }




    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}




library Strings {



    function toString(uint256 value) internal pure returns (string memory) {



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
}





contract ERC721 is ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;



    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;


    mapping (address => EnumerableSet.UintSet) private _holderTokens;


    EnumerableMap.UintToAddressMap private _tokenOwners;


    mapping (uint256 => address) private _tokenApprovals;


    mapping (address => mapping (address => bool)) private _operatorApprovals;


    string private _name;


    string private _symbol;


    mapping (uint256 => string) private _tokenURIs;


    string private _baseURI;















    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;








    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;








    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;




    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;


        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }




    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }




    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }




    function name() public view override returns (string memory) {
        return _name;
    }




    function symbol() public view override returns (string memory) {
        return _symbol;
    }




    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];


        if (block.number == 0) {
            return _tokenURI;
        }

        if (block.number > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }

        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }






    function baseURI() public view returns (string memory) {
        return _baseURI;
    }




    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }




    function totalSupply() public view override returns (uint256) {

        return _tokenOwners.length();
    }




    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }




    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }




    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }




    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }




    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }




    function transferFrom(address from, address to, uint256 tokenId) public virtual override {

        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }




    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }




    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }



















    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }









    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }








    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }











    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }





    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }













    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }











    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);


        _approve(address(0), tokenId);


        if (block.number != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }












    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);


        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }








    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }






    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }











    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
















    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}





interface IERC20 {



    function totalSupply() external view returns (uint);




    function balanceOf(address account) external view returns (uint);
    function decimals() external view returns (uint);
    function symbol() external view returns (string memory);







    function transfer(address recipient, uint amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint);















    function approve(address spender, uint amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint value);





    event Approval(address indexed owner, address indexed spender, uint value);
}

contract OptionsV1Contracts is ERC721 {

    address public immutable RESERVE;
    constructor() ERC721("OptionsV1", "OV1") public {
        RESERVE = msg.sender;
    }
    function mint(address owner, uint id) external {
        require(msg.sender == RESERVE);
        _mint(owner, id);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }
}

interface OptionsV1Oracle {
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
    function realizedVolatility(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint amountOut);
}

contract OptionsV1Reserve {
    using SafeMath for uint;


    string public constant name = "OptionsV1Reserve";


    string public symbol = "o";

    OptionsV1Contracts public immutable contracts;


    uint8 public constant decimals = 18;


    uint public totalSupply = 0;

    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");


    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");


    mapping (address => uint) public nonces;


    event Transfer(address indexed from, address indexed to, uint amount);


    event Approval(address indexed owner, address indexed spender, uint amount);


    event Deposited(address indexed creditor, uint shares, uint credit);


    event Withdrew(address indexed creditor, uint shares, uint credit);


    event Created(uint id, address indexed owner, address indexed token, uint amount, uint strike, uint created, uint expire);


    event Excercised(uint id, address indexed owner, address indexed token, uint amount, uint strike, uint excercised, uint expire);

    struct option {
        address asset;
        uint amount;
        uint strike;
        uint expire;
        uint optionType;
    }

    option[] public options;
    uint public optionsCount;


    OptionsV1Oracle public constant ORACLE = OptionsV1Oracle(0x73353801921417F465377c8d898c6f4C0270282C);

    uint constant public PERIOD = 28 days;
    uint constant public LN = 1104673833;
    uint constant public BASE = 1e28;

    function quote(address tokenIn, uint amount) public view returns (uint minOut) {
        return ORACLE.current(tokenIn, amount, RESERVE);
    }

    address public immutable RESERVE;

    constructor(address _reserve) public {
        RESERVE = _reserve;
        symbol = string(abi.encode("o", IERC20(_reserve).symbol()));
        contracts = new OptionsV1Contracts();
    }

    function _mint(address dst, uint amount) internal {

        totalSupply = totalSupply.add(amount);


        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {

        totalSupply = totalSupply.sub(amount, "::_burn: underflow");


        balances[dst] = balances[dst].sub(amount, "::_burn: underflow");
        emit Transfer(dst, address(0), amount);
    }





    function withdrawAll() external returns (bool) {
        return withdraw(balances[msg.sender]);
    }

    function reserves() public view returns (uint) {
        return IERC20(RESERVE).balanceOf(address(this));
    }






    function withdraw(uint _shares) public returns (bool) {
        uint r = reserves().mul(_shares).div(totalSupply);
        _burn(msg.sender, _shares);

        IERC20(RESERVE).transfer(msg.sender, r);
        emit Withdrew(msg.sender, _shares, r);
        return true;
    }





    function depositAll() external returns (bool) {
        return deposit(IERC20(RESERVE).balanceOf(msg.sender));
    }






    function deposit(uint amount) public returns (bool) {
        IERC20(RESERVE).transferFrom(msg.sender, address(this), amount);
        uint _shares = 0;
        if (block.timestamp == 0) {
            _shares = amount;
        } else {
            _shares = amount.mul(totalSupply).div(reserves());
        }
        _mint(msg.sender, _shares);
        emit Deposited(msg.sender, _shares, amount);
        return true;
    }

    function createCall(address token, uint amount) external {
        createOption(token, amount, 0);
    }

    function createPut(address token, uint amount) external {
        createOption(token, amount, 1);
    }

    function fees(address token, uint cost) public view returns (uint) {
        return LN.mul(vol(token)).mul(cost).div(BASE);
    }

    function cost(address token, uint amount) public view returns (uint) {
        return quote(token, amount);
    }

    function vol(address token) public view returns (uint) {
        return ORACLE.realizedVolatility(token, uint(10)**IERC20(token).decimals(), RESERVE, 24, 2);
    }

    function createOption(address token, uint amount, uint optionType) public {
        uint _cost = cost(token, amount);
        uint _fee = fees(token, _cost);
        uint _strike = _cost.div(amount);

        IERC20(RESERVE).transferFrom(msg.sender, address(this), _fee);
        options.push(option(token, amount, _strike, block.timestamp.add(PERIOD), optionType));

        contracts.mint(msg.sender, optionsCount);
        emit Created(optionsCount++, msg.sender, token, amount, _strike, block.timestamp, block.timestamp.add(PERIOD));
    }

    function exercise(uint id) external {
        option storage _pos = options[id];
        require(contracts.isApprovedOrOwner(msg.sender, id));
        require(_pos.expire > block.timestamp);
        _pos.expire = block.timestamp;
        emit Excercised(id, msg.sender, _pos.asset, _pos.amount, _pos.strike, block.timestamp, _pos.expire);
    }







    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }









    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }











    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "::permit: invalid signature");
        require(signatory == owner, "::permit: unauthorized");
        require(now <= deadline, "::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }






    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }







    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }








    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount);
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
