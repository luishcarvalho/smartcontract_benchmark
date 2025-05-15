




pragma solidity =0.5.11 >0.4.13 >0.4.20 >=0.4.23 >=0.5.0 <0.6.0 >=0.5.5 <0.6.0 >=0.5.11 <0.6.0;

















contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}



















contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}
























contract DSStop is DSNote, DSAuth {
    bool public stopped;

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}



















contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
















    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}












contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}
























contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    constructor(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            require(_approvals[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "ds-token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }
}

























contract DSToken is DSTokenBase(0), DSStop {

    bytes32  public  symbol;
    uint256  public  decimals = 18;

    constructor(bytes32 symbol_) public {
        symbol = symbol_;
    }

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            require(_approvals[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "ds-token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }

    function mint(uint wad) public {
        mint(msg.sender, wad);
    }
    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    function mint(address guy, uint wad) public auth stoppable {
        _balances[guy] = add(_balances[guy], wad);
        _supply = add(_supply, wad);
        emit Mint(guy, wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            require(_approvals[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        require(_balances[guy] >= wad, "ds-token-insufficient-balance");
        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        emit Burn(guy, wad);
    }


    bytes32   public  name = "";

    function setName(bytes32 name_) public auth {
        name = name_;
    }
}










contract Cdc is DSToken {
    string public constant name = "Certified Diamond Coin";
    uint8 public constant decimals = 18 ;
    bytes32 public cccc;




    constructor(bytes32 cccc_, bytes32 symbol_) DSToken(symbol_) public {
        cccc = cccc_;
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













interface IERC165 {








    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}












contract ERC165 is IERC165 {



    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;




    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {


        _registerInterface(_INTERFACE_ID_ERC165);
    }






    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }












    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}










contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}













contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {

    mapping(address => uint256[]) private _ownedTokens;


    mapping(uint256 => uint256) private _ownedTokensIndex;


    uint256[] private _allTokens;


    mapping(uint256 => uint256) private _allTokensIndex;








    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;




    constructor () public {

        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }







    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }





    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }







    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }








    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }







    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }








    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);

        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }






    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }






    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }





    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }









    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {



        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];


        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }


        _ownedTokens[from].length--;



    }






    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {



        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];




        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;


        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}










contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
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





    function name() public view returns (string memory) {
        return _name;
    }





    function symbol() public view returns (string memory) {
        return _symbol;
    }






    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }







    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }








    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);


        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}















contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {

    }
}














contract DpassEvents {
    event LogConfigChange(bytes32 what, bytes32 value1, bytes32 value2);
    event LogCustodianChanged(uint tokenId, address custodian);
    event LogDiamondAttributesHashChange(uint indexed tokenId, bytes8 hashAlgorithm);
    event LogDiamondMinted(
        address owner,
        uint indexed tokenId,
        bytes3 issuer,
        bytes16 report,
        bytes8 state
    );
    event LogRedeem(uint indexed tokenId);
    event LogSale(uint indexed tokenId);
    event LogStateChanged(uint indexed tokenId, bytes32 state);
}


contract Dpass is DSAuth, ERC721Full, DpassEvents {
    string private _name = "Diamond Passport";
    string private _symbol = "Dpass";

    struct Diamond {
        bytes3 issuer;
        bytes16 report;
        bytes8 state;
        bytes20 cccc;
        uint24 carat;
        bytes8 currentHashingAlgorithm;
    }
    Diamond[] diamonds;

    mapping(uint => address) public custodian;
    mapping (uint => mapping(bytes32 => bytes32)) public proof;
    mapping (bytes32 => mapping (bytes32 => bool)) diamondIndex;
    mapping (uint256 => uint256) public recreated;
    mapping(bytes32 => mapping(bytes32 => bool)) public canTransit;
    mapping(bytes32 => bool) public ccccs;

    constructor () public ERC721Full(_name, _symbol) {

        Diamond memory _diamond = Diamond({
            issuer: "Slf",
            report: "0",
            state: "invalid",
            cccc: "BR,IF,D,0001",
            carat: 1,
            currentHashingAlgorithm: ""
        });

        diamonds.push(_diamond);
        _mint(address(this), 0);


        canTransit["valid"]["invalid"] = true;
        canTransit["valid"]["removed"] = true;
        canTransit["valid"]["sale"] = true;
        canTransit["valid"]["redeemed"] = true;
        canTransit["sale"]["valid"] = true;
        canTransit["sale"]["invalid"] = true;
        canTransit["sale"]["removed"] = true;
    }

    modifier onlyOwnerOf(uint _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "dpass-access-denied");
        _;
    }

    modifier onlyApproved(uint _tokenId) {
        require(
            ownerOf(_tokenId) == msg.sender ||
            isApprovedForAll(ownerOf(_tokenId), msg.sender) ||
            getApproved(_tokenId) == msg.sender
            , "dpass-access-denied");
        _;
    }

    modifier ifExist(uint _tokenId) {
        require(_exists(_tokenId), "dpass-diamond-does-not-exist");
        _;
    }

    modifier onlyValid(uint _tokenId) {

        require(_exists(_tokenId), "dpass-diamond-does-not-exist");

        Diamond storage _diamond = diamonds[_tokenId];
        require(_diamond.state != "invalid", "dpass-invalid-diamond");
        _;
    }













    function mintDiamondTo(
        address _to,
        address _custodian,
        bytes3 _issuer,
        bytes16 _report,
        bytes8 _state,
        bytes20 _cccc,
        uint24 _carat,
        bytes32 _attributesHash,
        bytes8 _currentHashingAlgorithm
    )
        public auth
        returns(uint)
    {
        require(ccccs[_cccc], "dpass-wrong-cccc");
        _addToDiamondIndex(_issuer, _report);

        Diamond memory _diamond = Diamond({
            issuer: _issuer,
            report: _report,
            state: _state,
            cccc: _cccc,
            carat: _carat,
            currentHashingAlgorithm: _currentHashingAlgorithm
        });
        uint _tokenId = diamonds.push(_diamond) - 1;
        proof[_tokenId][_currentHashingAlgorithm] = _attributesHash;
        custodian[_tokenId] = _custodian;

        _mint(_to, _tokenId);
        emit LogDiamondMinted(_to, _tokenId, _issuer, _report, _state);
        return _tokenId;
    }






    function updateAttributesHash(
        uint _tokenId,
        bytes32 _attributesHash,
        bytes8 _currentHashingAlgorithm
    ) public auth onlyValid(_tokenId)
    {
        Diamond storage _diamond = diamonds[_tokenId];
        _diamond.currentHashingAlgorithm = _currentHashingAlgorithm;

        proof[_tokenId][_currentHashingAlgorithm] = _attributesHash;

        emit LogDiamondAttributesHashChange(_tokenId, _currentHashingAlgorithm);
    }




    function linkOldToNewToken(uint _tokenId, uint _newTokenId) public auth {
        require(_exists(_tokenId), "dpass-old-diamond-doesnt-exist");
        require(_exists(_newTokenId), "dpass-new-diamond-doesnt-exist");
        recreated[_tokenId] = _newTokenId;
    }









    function transferFrom(address _from, address _to, uint256 _tokenId) public onlyValid(_tokenId) {
        _checkTransfer(_tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }




    function _checkTransfer(uint256 _tokenId) internal view {
        bytes32 state = diamonds[_tokenId].state;

        require(state != "removed", "dpass-token-removed");
        require(state != "invalid", "dpass-token-deleted");
    }












    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        _checkTransfer(_tokenId);
        super.safeTransferFrom(_from, _to, _tokenId);
    }




    function getState(uint _tokenId) public view ifExist(_tokenId) returns (bytes32) {
        return diamonds[_tokenId].state;
    }







    function getDiamondInfo(uint _tokenId)
        public
        view
        ifExist(_tokenId)
        returns (
            address[2] memory ownerCustodian,
            bytes32[6] memory attrs,
            uint24 carat_
        )
    {
        Diamond storage _diamond = diamonds[_tokenId];
        bytes32 attributesHash = proof[_tokenId][_diamond.currentHashingAlgorithm];

        ownerCustodian[0] = ownerOf(_tokenId);
        ownerCustodian[1] = custodian[_tokenId];

        attrs[0] = _diamond.issuer;
        attrs[1] = _diamond.report;
        attrs[2] = _diamond.state;
        attrs[3] = _diamond.cccc;
        attrs[4] = attributesHash;
        attrs[5] = _diamond.currentHashingAlgorithm;

        carat_ = _diamond.carat;
    }







    function getDiamond(uint _tokenId)
        public
        view
        ifExist(_tokenId)
        returns (
            bytes3 issuer,
            bytes16 report,
            bytes8 state,
            bytes20 cccc,
            uint24 carat,
            bytes32 attributesHash
        )
    {
        Diamond storage _diamond = diamonds[_tokenId];
        attributesHash = proof[_tokenId][_diamond.currentHashingAlgorithm];

        return (
            _diamond.issuer,
            _diamond.report,
            _diamond.state,
            _diamond.cccc,
            _diamond.carat,
            attributesHash
        );
    }







    function getDiamondIssuerAndReport(uint _tokenId) public view ifExist(_tokenId) returns(bytes32, bytes32) {
        Diamond storage _diamond = diamonds[_tokenId];
        return (_diamond.issuer, _diamond.report);
    }






    function setCccc(bytes32 _cccc, bool _allowed) public auth {
        ccccs[_cccc] = _allowed;
        emit LogConfigChange("cccc", _cccc, _allowed ? bytes32("1") : bytes32("0"));
    }




    function setCustodian(uint _tokenId, address _newCustodian) public auth {
        require(_newCustodian != address(0), "dpass-wrong-address");
        custodian[_tokenId] = _newCustodian;
        emit LogCustodianChanged(_tokenId, _newCustodian);
    }




    function getCustodian(uint _tokenId) public view returns(address) {
        return custodian[_tokenId];
    }




    function enableTransition(bytes32 _from, bytes32 _to) public auth {
        canTransit[_from][_to] = true;
        emit LogConfigChange("canTransit", _from, _to);
    }




    function disableTransition(bytes32 _from, bytes32 _to) public auth {
        canTransit[_from][_to] = false;
        emit LogConfigChange("canNotTransit", _from, _to);
    }






    function setSaleState(uint _tokenId) public ifExist(_tokenId) onlyApproved(_tokenId) {
        _setState("sale", _tokenId);
        emit LogSale(_tokenId);
    }





    function setInvalidState(uint _tokenId) public ifExist(_tokenId) onlyApproved(_tokenId) {
        _setState("invalid", _tokenId);
        _removeDiamondFromIndex(_tokenId);
    }






    function redeem(uint _tokenId) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
        _setState("redeemed", _tokenId);
        _removeDiamondFromIndex(_tokenId);
        emit LogRedeem(_tokenId);
    }






    function setState(bytes8 _newState, uint _tokenId) public ifExist(_tokenId) onlyApproved(_tokenId) {
        _setState(_newState, _tokenId);
    }








    function _validateStateTransitionTo(bytes8 _currentState, bytes8 _newState) internal view {
        require(_currentState != _newState, "dpass-already-in-that-state");
        require(canTransit[_currentState][_newState], "dpass-transition-now-allowed");
    }






    function _addToDiamondIndex(bytes32 _issuer, bytes32 _report) internal {
        require(!diamondIndex[_issuer][_report], "dpass-issuer-report-not-unique");
        diamondIndex[_issuer][_report] = true;
    }

    function _removeDiamondFromIndex(uint _tokenId) internal {
        Diamond storage _diamond = diamonds[_tokenId];
        diamondIndex[_diamond.issuer][_diamond.report] = false;
    }






    function _setState(bytes8 _newState, uint _tokenId) internal {
        Diamond storage _diamond = diamonds[_tokenId];
        _validateStateTransitionTo(_diamond.state, _newState);
        _diamond.state = _newState;
        emit LogStateChanged(_tokenId, _newState);
    }
}























contract DSGuardEvents {
    event LogPermit(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );

    event LogForbid(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );
}

contract DSGuard is DSAuth, DSAuthority, DSGuardEvents {
    bytes32 constant public ANY = bytes32(uint(-1));

    mapping (bytes32 => mapping (bytes32 => mapping (bytes32 => bool))) acl;

    function canCall(
        address src_, address dst_, bytes4 sig
    ) public view returns (bool) {
        bytes32 src = bytes32(bytes20(src_));
        bytes32 dst = bytes32(bytes20(dst_));

        return acl[src][dst][sig]
            || acl[src][dst][ANY]
            || acl[src][ANY][sig]
            || acl[src][ANY][ANY]
            || acl[ANY][dst][sig]
            || acl[ANY][dst][ANY]
            || acl[ANY][ANY][sig]
            || acl[ANY][ANY][ANY];
    }

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = true;
        emit LogPermit(src, dst, sig);
    }

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = false;
        emit LogForbid(src, dst, sig);
    }

    function permit(address src, address dst, bytes32 sig) public {
        permit(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }
    function forbid(address src, address dst, bytes32 sig) public {
        forbid(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }

}

contract DSGuardFactory {
    mapping (address => bool)  public  isGuard;

    function newGuard() public returns (DSGuard guard) {
        guard = new DSGuard();
        guard.setOwner(msg.sender);
        isGuard[address(guard)] = true;
    }
}

















contract DSTest {
    event eventListener          (address target, bool exact);
    event logs                   (bytes);
    event log_bytes32            (bytes32);
    event log_named_address      (bytes32 key, address val);
    event log_named_bytes32      (bytes32 key, bytes32 val);
    event log_named_decimal_int  (bytes32 key, int val, uint decimals);
    event log_named_decimal_uint (bytes32 key, uint val, uint decimals);
    event log_named_int          (bytes32 key, int val);
    event log_named_uint         (bytes32 key, uint val);

    bool public IS_TEST;
    bool public failed;
    bool SUPPRESS_SETUP_WARNING;

    constructor() internal {
        IS_TEST = true;
    }

    function setUp() public {
        SUPPRESS_SETUP_WARNING = true;
    }

    function fail() internal {
        failed = true;
    }

    function expectEventsExact(address target) internal {
        emit eventListener(target, true);
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log_bytes32("Assertion failed");
            fail();
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log_bytes32("Error: Wrong `address' value");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }

    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log_bytes32("Error: Wrong `bytes32' value");
            emit log_named_bytes32("  Expected", b);
            emit log_named_bytes32("    Actual", a);
            fail();
        }
    }

    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log_bytes32("Error: Wrong fixed-point decimal");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            fail();
        }
    }

    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log_bytes32("Error: Wrong fixed-point decimal");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            fail();
        }
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log_bytes32("Error: Wrong `int' value");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            fail();
        }
    }

    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log_bytes32("Error: Wrong `uint' value");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }

    function assertEq0(bytes memory a, bytes memory b) internal {
        bool ok = true;

        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }

        if (!ok) {
            emit log_bytes32("Error: Wrong `bytes' value");
            emit log_named_bytes32("  Expected", "[cannot show `bytes' value]");
            emit log_named_bytes32("  Actual", "[cannot show `bytes' value]");
            fail();
        }
    }
}












contract Burner is DSAuth {
    DSToken public token;
    bytes32 public name = "Burner";
    bytes32 public symbol = "Burner";

    constructor(DSToken token_) public {
        token = token_;
    }





    function burn(uint amount_) public auth {
        token.burn(amount_);
    }




    function burnAll() public auth {
        uint totalAmount = token.balanceOf(address(this));
        burn(totalAmount);
    }
}













contract Dcdc is DSToken {

    bytes32 public cccc;
    bool public stopTransfers = true;
    bool public isInteger;
    bytes32 public name;







    constructor(bytes32 cccc_, bytes32 symbol_, bool isInteger_) DSToken(symbol_) public {
        cccc = cccc_;
        isInteger = isInteger_;
        name = symbol_;
    }

    modifier integerOnly(uint256 num) {
        if(isInteger)
            require(num % 10 ** decimals == 0, "dcdc-only-integer-value-allowed");
        _;
    }




    function getDiamondType() public view returns (bytes32) {
        return cccc;
    }




    function transferFrom(address src, address dst, uint wad)
    public
    stoppable
    integerOnly(wad)
    returns (bool) {
        if(!stopTransfers) {
            return super.transferFrom(src, dst, wad);
        }
    }




    function setStopTransfers(bool stopTransfers_) public auth {
        stopTransfers = stopTransfers_;
    }




    function mint(address guy, uint256 wad) public integerOnly(wad) {
        super.mint(guy, wad);
    }




    function burn(address guy, uint256 wad) public integerOnly(wad) {
        super.burn(guy, wad);
    }
}













contract TrustedErc20Wallet {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}




contract TrustedErci721Wallet {
    function balanceOf(address guy) public view returns (uint);
    function ownerOf(uint256 tokenId) public view returns (address);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address);
    function setApprovalForAll(address to, bool approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public;
}





contract Wallet is DSAuth, DSStop, DSMath {
    event LogTransferEth(address src, address dst, uint256 amount);
    address public eth = address(0xee);
    bytes32 public name = "Wal";
    bytes32 public symbol = "Wal";

    function () external payable {
    }

    function transfer(address token, address payable dst, uint256 amt) public auth returns (bool) {
        return sendToken(token, address(this), dst, amt);
    }

    function transferFrom(address token, address src, address payable dst, uint256 amt) public auth returns (bool) {
        return sendToken(token, src, dst, amt);
    }

    function totalSupply(address token) public view returns (uint){
        if (token == eth) {
            require(false, "wal-no-total-supply-for-ether");
        } else {
            return TrustedErc20Wallet(token).totalSupply();
        }
    }

    function balanceOf(address token, address src) public view returns (uint) {
        if (token == eth) {
            return src.balance;
        } else {
            return TrustedErc20Wallet(token).balanceOf(src);
        }
    }

    function allowance(address token, address src, address guy)
    public view returns (uint) {
        if( token == eth) {
            require(false, "wal-no-allowance-for-ether");
        } else {
            return TrustedErc20Wallet(token).allowance(src, guy);
        }
    }

    function approve(address token, address guy, uint wad)
    public auth returns (bool) {
        if( token == eth) {
            require(false, "wal-can-not-approve-ether");
        } else {
            return TrustedErc20Wallet(token).approve(guy, wad);
        }
    }

    function balanceOf721(address token, address guy) public view returns (uint) {
        return TrustedErci721Wallet(token).balanceOf(guy);
    }

    function ownerOf721(address token, uint256 tokenId) public view returns (address) {
        return TrustedErci721Wallet(token).ownerOf(tokenId);
    }

    function approve721(address token, address to, uint256 tokenId) public {
        TrustedErci721Wallet(token).approve(to, tokenId);
    }

    function getApproved721(address token, uint256 tokenId) public view returns (address) {
        return TrustedErci721Wallet(token).getApproved(tokenId);
    }

    function setApprovalForAll721(address token, address to, bool approved) public auth {
        TrustedErci721Wallet(token).setApprovalForAll(to, approved);
    }

    function isApprovedForAll721(address token, address owner, address operator) public view returns (bool) {
        return TrustedErci721Wallet(token).isApprovedForAll(owner, operator);
    }

    function transferFrom721(address token, address from, address to, uint256 tokenId) public auth {
        TrustedErci721Wallet(token).transferFrom(from, to, tokenId);
    }

    function safeTransferFrom721(address token, address from, address to, uint256 tokenId) public auth {
        TrustedErci721Wallet(token).safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom721(address token, address from, address to, uint256 tokenId, bytes memory _data) public auth {
        TrustedErci721Wallet(token).safeTransferFrom(from, to, tokenId, _data);
    }

    function transfer721(address token, address to, uint tokenId) public auth {
        TrustedErci721Wallet(token).transferFrom(address(this), to, tokenId);
    }




    function sendToken(
        address token,
        address src,
        address payable dst,
        uint256 amount
    ) internal returns (bool){
        TrustedErc20Wallet erc20 = TrustedErc20Wallet(token);
        if (token == eth && amount > 0) {
            require(src == address(this), "wal-ether-transfer-invalid-src");
            dst.transfer(amount);
            emit LogTransferEth(src, dst, amount);
        } else {
            if (amount > 0) erc20.transferFrom(src, dst, amount);
        }
        return true;
    }
}








contract Liquidity is Wallet {
    bytes32 public name = "Liq";
    bytes32 public symbol = "Liq";

    function burn(address dpt, address burner, uint256 burnValue) public auth {
        transfer(dpt, address(uint160(address(burner))), burnValue);
    }
}












contract TrustedFeedLike {
    function peek() external view returns (bytes32, bool);
}




contract TrustedDiamondExchangeAsm {
    function buyPrice(address token_, address owner_, uint256 tokenId_) external view returns (uint);
}




contract SimpleAssetManagement is DSAuth {

    event LogAudit(address sender, address custodian_, uint256 status_, bytes32 descriptionHash_, bytes32 descriptionUrl_, uint32 auditInterwal_);
    event LogConfigChange(address sender, bytes32 what, bytes32 value, bytes32 value1);
    event LogTransferEth(address src, address dst, uint256 amount);
    event LogBasePrice(address sender_, address token_, uint256 tokenId_, uint256 price_);
    event LogCdcValue(uint256 totalCdcV, uint256 cdcValue, address token);
    event LogCdcPurchaseValue(uint256 totalCdcPurchaseV, uint256 cdcPurchaseValue, address token);
    event LogDcdcValue(uint256 totalDcdcV, uint256 ddcValue, address token);
    event LogDcdcCustodianValue(uint256 totalDcdcCustV, uint256 dcdcCustV, address dcdc, address custodian);
    event LogDcdcTotalCustodianValue(uint256 totalDcdcCustV, uint256 totalDcdcV, address custodian);
    event LogDpassValue(uint256 totalDpassCustV, uint256 totalDpassV, address custodian);
    event LogForceUpdateCollateralDpass(address sender, uint256 positiveV_, uint256 negativeV_, address custodian);
    event LogForceUpdateCollateralDcdc(address sender, uint256 positiveV_, uint256 negativeV_, address custodian);

    mapping(
        address => mapping(
            uint => uint)) public basePrice;
    mapping(address => bool) public custodians;
    mapping(address => uint)
        public totalDpassCustV;
    mapping(address => uint) private rate;
    mapping(address => uint) public cdcV;
    mapping(address => uint) public dcdcV;
    mapping(address => uint) public totalDcdcCustV;
    mapping(
        address => mapping(
            address => uint)) public dcdcCustV;
    mapping(address => bool) public payTokens;
    mapping(address => bool) public dpasses;
    mapping(address => bool) public dcdcs;
    mapping(address => bool) public cdcs;
    mapping(address => uint) public decimals;
    mapping(address => bool) public decimalsSet;
    mapping(address => address) public priceFeed;
    mapping(address => uint) public tokenPurchaseRate;

    mapping(address => uint) public totalPaidCustV;
    mapping(address => uint) public dpassSoldCustV;
    mapping(address => bool) public manualRate;
    mapping(address => uint) public capCustV;
    mapping(address => uint) public cdcPurchaseV;
    uint public totalDpassV;
    uint public totalDcdcV;
    uint public totalCdcV;
    uint public totalCdcPurchaseV;
    uint public overCollRatio;
    uint public overCollRemoveRatio;

    uint public dust = 1000;
    bool public locked;
    address public eth = address(0xee);
    bytes32 public name = "Asm";
    bytes32 public symbol = "Asm";
    address public dex;

    struct Audit {
        address auditor;
        uint256 status;

        bytes32 descriptionHash;


        bytes32 descriptionUrl;
        uint nextAuditBefore;
    }

    mapping(address => Audit) public audit;
    uint32 public auditInterval = 1776000;




    modifier nonReentrant {
        require(!locked, "asm-reentrancy-detected");
        locked = true;
        _;
        locked = false;
    }


    uint constant WAD = 10 ** 18;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }










    function setConfig(bytes32 what_, bytes32 value_, bytes32 value1_, bytes32 value2_) public nonReentrant auth {
        if (what_ == "rate") {
            address token = addr(value_);
            uint256 value = uint256(value1_);
            require(payTokens[token] || cdcs[token] || dcdcs[token], "asm-token-not-allowed-rate");
            require(value > 0, "asm-rate-must-be-gt-0");
            rate[token] = value;
        } else if (what_ == "custodians") {
            address custodian = addr(value_);
            bool enable = uint(value1_) > 0;
            require(custodian != address(0), "asm-custodian-zero-address");
            custodians[addr(value_)] = enable;
        } else if (what_ == "overCollRatio") {
            overCollRatio = uint(value_);
            require(overCollRatio >= 1 ether, "asm-system-must-be-overcollaterized");
            _requireSystemCollaterized();
        } else if (what_ == "overCollRemoveRatio") {
            overCollRemoveRatio = uint(value_);
            require(overCollRemoveRatio >= 1 ether, "asm-must-be-gt-1-ether");
            require(overCollRemoveRatio <= overCollRatio, "asm-must-be-lt-overcollratio");
            _requireSystemRemoveCollaterized();
        } else if (what_ == "priceFeed") {
            require(addr(value1_) != address(address(0x0)), "asm-wrong-pricefeed-address");
            require(addr(value_) != address(address(0x0)), "asm-wrong-token-address");
            priceFeed[addr(value_)] = addr(value1_);
        } else if (what_ == "decimals") {
            address token = addr(value_);
            uint decimal = uint256(value1_);
            require(token != address(0x0), "asm-wrong-address");
            decimals[token] = 10 ** decimal;
            decimalsSet[token] = true;
        } else if (what_ == "manualRate") {
            address token = addr(value_);
            bool enable = uint(value1_) > 0;
            require(token != address(address(0x0)), "asm-wrong-token-address");
            require(priceFeed[token] != address(address(0x0)), "asm-priceFeed-first");
            manualRate[token] = enable;
        } else if (what_ == "payTokens") {
            address token = addr(value_);
            require(token != address(0), "asm-pay-token-address-no-zero");
            payTokens[token] = uint(value1_) > 0;
        } else if (what_ == "dcdcs") {
            address newDcdc = addr(value_);
            bool enable = uint(value1_) > 0;
            require(newDcdc != address(0), "asm-dcdc-address-zero");
            require(priceFeed[newDcdc] != address(0), "asm-add-pricefeed-first");
            require(decimalsSet[newDcdc],"asm-no-decimals-set-for-token");
            dcdcs[newDcdc] = enable;
            _updateTotalDcdcV(newDcdc);
        } else if (what_ == "cdcPurchaseV") {
            address cdc_ = addr(value_);
            require(cdc_ != address(0), "asm-cdc-address-zero");
            uint addAmt_ = uint(value1_);
            uint subAmt_ = uint(value2_);
            _updateCdcPurchaseV(cdc_, addAmt_, subAmt_);
        } else if (what_ == "cdcs") {
            address newCdc = addr(value_);
            bool enable = uint(value1_) > 0;
            require(priceFeed[newCdc] != address(0), "asm-add-pricefeed-first");
            require(decimalsSet[newCdc], "asm-add-decimals-first");
            require(newCdc != address(0), "asm-cdc-address-zero");
            require(
                DSToken(newCdc).totalSupply() == 0 || cdcPurchaseV[newCdc] > 0,
                "asm-setconfig-cdcpurchasev-first");
            cdcs[newCdc] = enable;
            _updateCdcV(newCdc);
            _requireSystemCollaterized();
        } else if (what_ == "dpasses") {
            address dpass = addr(value_);
            bool enable = uint(value1_) > 0;
            require(dpass != address(0), "asm-dpass-address-zero");
            dpasses[dpass] = enable;
        } else if (what_ == "approve") {
            address token = addr(value_);
            address dst = addr(value1_);
            uint value = uint(value2_);
            require(decimalsSet[token],"asm-no-decimals-set-for-token");
            require(dst != address(0), "asm-dst-zero-address");
            DSToken(token).approve(dst, value);
        }  else if (what_ == "setApproveForAll") {
            address token = addr(value_);
            address dst = addr(value1_);
            bool enable = uint(value2_) > 0;
            require(dpasses[token],"asm-not-a-dpass-token");
            require(dst != address(0), "asm-dst-zero-address");
            Dpass(token).setApprovalForAll(dst, enable);
        } else if (what_ == "dust") {
            dust = uint256(value_);
        } else if (what_ == "dex") {
            dex = addr(value_);
        } else if (what_ == "totalPaidCustV") {
            address custodian_ = addr(value_);
            require(custodians[custodian_], "asm-not-a-custodian");
            require(totalPaidCustV[custodian_] == 0,"asm-only-at-config-time");
            totalPaidCustV[custodian_] = uint(value1_);
        } else {
            require(false, "asm-wrong-config-option");
        }

        emit LogConfigChange(msg.sender, what_, value_, value1_);
    }






    function setRate(address token_, uint256 value_) public auth {
        setConfig("rate", bytes32(uint(token_)), bytes32(value_), "");
    }





    function getRateNewest(address token_) public view auth returns (uint) {
        return _getNewRate(token_);
    }





    function getRate(address token_) public view auth returns (uint) {
        return rate[token_];
    }





    function addr(bytes32 b_) public pure returns (address) {
        return address(uint256(b_));
    }







    function setBasePrice(address token_, uint256 tokenId_, uint256 price_) public nonReentrant auth {
        _setBasePrice(token_, tokenId_, price_);
    }






    function setCapCustV(address custodian_, uint256 capCustV_) public nonReentrant auth {
        require(custodians[custodian_], "asm-should-be-custodian");
        capCustV[custodian_] = capCustV_;
    }





    function setCdcV(address cdc_) public auth {
        _updateCdcV(cdc_);
    }





    function setTotalDcdcV(address dcdc_) public auth {
        _updateTotalDcdcV(dcdc_);
    }






    function setDcdcV(address dcdc_, address custodian_) public auth {
        _updateDcdcV(dcdc_, custodian_);
    }











    function setAudit(
        address custodian_,
        uint256 status_,
        bytes32 descriptionHash_,
        bytes32 descriptionUrl_,
        uint32 auditInterval_
    ) public nonReentrant auth {
        uint32 minInterval_;
        require(custodians[custodian_], "asm-audit-not-a-custodian");
        require(auditInterval_ != 0, "asm-audit-interval-zero");

        minInterval_ = uint32(min(auditInterval_, auditInterval));
        Audit memory audit_ = Audit({
            auditor: msg.sender,
            status: status_,
            descriptionHash: descriptionHash_,
            descriptionUrl: descriptionUrl_,
            nextAuditBefore: block.timestamp + minInterval_
        });
        audit[custodian_] = audit_;
        emit LogAudit(msg.sender, custodian_, status_, descriptionHash_, descriptionUrl_, minInterval_);
    }








    function notifyTransferFrom(
        address token_,
        address src_,
        address dst_,
        uint256 amtOrId_
    ) public nonReentrant auth {
        uint balance;
        address custodian;
        uint buyPrice_;

        require(
            dpasses[token_] || cdcs[token_] || payTokens[token_],
            "asm-invalid-token");

        require(
            !dpasses[token_] || Dpass(token_).getState(amtOrId_) == "sale",
            "asm-ntf-token-state-not-sale");

        if(dpasses[token_] && src_ == address(this)) {
            custodian = Dpass(token_).getCustodian(amtOrId_);

            _updateCollateralDpass(
                0,
                basePrice[token_][amtOrId_],
                custodian);

            buyPrice_ = TrustedDiamondExchangeAsm(dex).buyPrice(token_, address(this), amtOrId_);

            dpassSoldCustV[custodian] = add(
                dpassSoldCustV[custodian],
                buyPrice_ > 0 && buyPrice_ != uint(-1) ?
                    buyPrice_ :
                    basePrice[token_][amtOrId_]);

            Dpass(token_).setState("valid", amtOrId_);

            _requireSystemCollaterized();

        } else if (dst_ == address(this) && !dpasses[token_]) {
            require(payTokens[token_], "asm-we-dont-accept-this-token");

            if (cdcs[token_]) {
                _burn(token_, amtOrId_);
            } else {
                balance = sub(
                    token_ == eth ?
                        address(this).balance :
                        DSToken(token_).balanceOf(address(this)),
                    amtOrId_);



                tokenPurchaseRate[token_] = wdiv(
                    add(
                        wmulV(
                            tokenPurchaseRate[token_],
                            balance,
                            token_),
                        wmulV(_updateRate(token_), amtOrId_, token_)),
                    add(balance, amtOrId_));
            }


        } else if (dst_ == address(this) && dpasses[token_]) {

            require(payTokens[token_], "asm-token-not-accepted");

            _updateCollateralDpass(
                basePrice[token_][amtOrId_],
                0,
                Dpass(token_).getCustodian(amtOrId_));

            Dpass(token_).setState("valid", amtOrId_);

        } else if (dpasses[token_]) {


        }  else {
            require(false, "asm-unsupported-tx");
        }
    }






    function burn(address token_, uint256 amt_) public nonReentrant auth {
        _burn(token_, amt_);
    }






    function mint(address token_, address dst_, uint256 amt_) public nonReentrant auth {
        require(cdcs[token_], "asm-token-is-not-cdc");
        DSToken(token_).mint(dst_, amt_);
        _updateCdcV(token_);
        _updateCdcPurchaseV(token_, amt_, 0);
        _requireSystemCollaterized();
    }







    function mintDcdc(address token_, address dst_, uint256 amt_) public nonReentrant auth {
        require(custodians[msg.sender], "asm-not-a-custodian");
        require(!custodians[msg.sender] || dst_ == msg.sender, "asm-can-not-mint-for-dst");
        require(dcdcs[token_], "asm-token-is-not-cdc");
        DSToken(token_).mint(dst_, amt_);
        _updateDcdcV(token_, dst_);
        _requireCapCustV(dst_);
    }







    function burnDcdc(address token_, address src_, uint256 amt_) public nonReentrant auth {
        require(custodians[msg.sender], "asm-not-a-custodian");
        require(!custodians[msg.sender] || src_ == msg.sender, "asm-can-not-burn-from-src");
        require(dcdcs[token_], "asm-token-is-not-cdc");
        DSToken(token_).burn(src_, amt_);
        _updateDcdcV(token_, src_);
        _requireSystemRemoveCollaterized();
        _requirePaidLessThanSold(src_, _getCustodianCdcV(src_));
    }














    function mintDpass(
        address token_,
        address custodian_,
        bytes3 issuer_,
        bytes16 report_,
        bytes8 state_,
        bytes20 cccc_,
        uint24 carat_,
        bytes32 attributesHash_,
        bytes8 currentHashingAlgorithm_,
        uint256 price_
    ) public nonReentrant auth returns (uint256 id_) {
        require(dpasses[token_], "asm-mnt-not-a-dpass-token");
        require(custodians[msg.sender], "asm-not-a-custodian");
        require(!custodians[msg.sender] || custodian_ == msg.sender, "asm-mnt-no-mint-to-others");

        id_ = Dpass(token_).mintDiamondTo(
            address(this),
            custodian_,
            issuer_,
            report_,
            state_,
            cccc_,
            carat_,
            attributesHash_,
            currentHashingAlgorithm_);

        _setBasePrice(token_, id_, price_);
    }







    function setStateDpass(address token_, uint256 tokenId_, bytes8 state_) public nonReentrant auth {
        bytes32 prevState_;
        address custodian_;

        require(dpasses[token_], "asm-mnt-not-a-dpass-token");

        custodian_ = Dpass(token_).getCustodian(tokenId_);
        require(
            !custodians[msg.sender] ||
            msg.sender == custodian_,
            "asm-ssd-not-authorized");

        prevState_ = Dpass(token_).getState(tokenId_);

        if(
            prevState_ != "invalid" &&
            prevState_ != "removed" &&
            (
                state_ == "invalid" ||
                state_ == "removed"
            )
        ) {
            _updateCollateralDpass(0, basePrice[token_][tokenId_], custodian_);
            _requireSystemRemoveCollaterized();
            _requirePaidLessThanSold(custodian_, _getCustodianCdcV(custodian_));

        } else if(
            prevState_ == "redeemed" ||
            prevState_ == "invalid" ||
            prevState_ == "removed" ||
            (
                state_ != "invalid" &&
                state_ != "removed" &&
                state_ != "redeemed"
            )
        ) {
            _updateCollateralDpass(basePrice[token_][tokenId_], 0, custodian_);
        }

        Dpass(token_).setState(state_, tokenId_);
    }







    function withdraw(address token_, uint256 amt_) public nonReentrant auth {
        address custodian = msg.sender;
        require(custodians[custodian], "asm-not-a-custodian");
        require(payTokens[token_], "asm-cant-withdraw-token");
        require(tokenPurchaseRate[token_] > 0, "asm-token-purchase-rate-invalid");

        uint tokenPurchaseV = wmulV(tokenPurchaseRate[token_], amt_, token_);

        totalPaidCustV[msg.sender] = add(totalPaidCustV[msg.sender], tokenPurchaseV);
        _requirePaidLessThanSold(custodian, _getCustodianCdcV(custodian));

        sendToken(token_, address(this), msg.sender, amt_);
    }





    function getAmtForSale(address token_) public view returns(uint256) {
        require(cdcs[token_], "asm-token-is-not-cdc");

        uint totalCdcAllowedV_ =
            wdiv(
                add(
                    totalDpassV,
                    totalDcdcV),
                overCollRatio);

        if (totalCdcAllowedV_ < add(totalCdcV, dust))
            return 0;

        return wdivT(
            sub(
                totalCdcAllowedV_,
                totalCdcV),
            _getNewRate(token_),
            token_);
    }








    function wmulV(uint256 a_, uint256 b_, address token_) public view returns(uint256) {
        return wdiv(wmul(a_, b_), decimals[token_]);
    }







    function wdivT(uint256 a_, uint256 b_, address token_) public view returns(uint256) {
        return wmul(wdiv(a_,b_), decimals[token_]);
    }








    function setCollateralDpass(uint positiveV_, uint negativeV_, address custodian_) public auth {
        _updateCollateralDpass(positiveV_, negativeV_, custodian_);

        emit LogForceUpdateCollateralDpass(msg.sender, positiveV_, negativeV_, custodian_);
    }








    function setCollateralDcdc(uint positiveV_, uint negativeV_, address custodian_) public auth {
        _updateCollateralDcdc(positiveV_, negativeV_, custodian_);
        emit LogForceUpdateCollateralDcdc(msg.sender, positiveV_, negativeV_, custodian_);
    }





    function _setBasePrice(address token_, uint256 tokenId_, uint256 price_) internal {
        bytes32 state_;
        address custodian_;
        require(dpasses[token_], "asm-invalid-token-address");
        state_ = Dpass(token_).getState(tokenId_);
        custodian_ = Dpass(token_).getCustodian(tokenId_);
        require(!custodians[msg.sender] || msg.sender == custodian_, "asm-not-authorized");

        if(Dpass(token_).ownerOf(tokenId_) == address(this) &&
          (state_ == "valid" || state_ == "sale")) {
            _updateCollateralDpass(price_, basePrice[token_][tokenId_], custodian_);
            if(price_ >= basePrice[token_][tokenId_])
                _requireCapCustV(custodian_);
        }

        basePrice[token_][tokenId_] = price_;
        emit LogBasePrice(msg.sender, token_, tokenId_, price_);
    }




    function () external payable {
        require(msg.value > 0, "asm-check-the-function-signature");
    }




    function _burn(address token_, uint256 amt_) internal {
        require(cdcs[token_], "asm-token-is-not-cdc");
        DSToken(token_).burn(amt_);
        _updateCdcV(token_);
        _updateCdcPurchaseV(token_, 0, amt_);
    }




    function _updateRate(address token_) internal returns (uint256 rate_) {
        require((rate_ = _getNewRate(token_)) > 0, "asm-updateRate-rate-gt-zero");
        rate[token_] = rate_;
    }




    function _updateCdcPurchaseV(address cdc_, uint256 addAmt_, uint256 subAmt_) internal {
        uint currSupply_;
        uint prevPurchaseV_;

        if(addAmt_ > 0) {

            uint currentAddV_ = wmulV(addAmt_, _updateRate(cdc_), cdc_);
            cdcPurchaseV[cdc_] = add(cdcPurchaseV[cdc_], currentAddV_);
            totalCdcPurchaseV = add(totalCdcPurchaseV, currentAddV_);

        } else if (subAmt_ > 0) {

            currSupply_ = DSToken(cdc_).totalSupply();
            prevPurchaseV_ = cdcPurchaseV[cdc_];

            cdcPurchaseV[cdc_] = currSupply_ > dust ?
                wmul(
                    prevPurchaseV_,
                    wdiv(
                        currSupply_,
                        add(
                            currSupply_,
                            subAmt_)
                        )):
                0;

            totalCdcPurchaseV = sub(
                totalCdcPurchaseV,
                min(
                    sub(
                        prevPurchaseV_,
                        min(
                            cdcPurchaseV[cdc_],
                            prevPurchaseV_)),
                    totalCdcPurchaseV));
        } else {
            require(false, "asm-add-or-sub-amount-must-be-0");
        }

        emit LogCdcPurchaseValue(totalCdcPurchaseV, cdcPurchaseV[cdc_], cdc_);
    }




    function _updateCdcV(address cdc_) internal {
        require(cdcs[cdc_], "asm-not-a-cdc-token");
        uint newValue = wmulV(DSToken(cdc_).totalSupply(), _updateRate(cdc_), cdc_);

        totalCdcV = sub(add(totalCdcV, newValue), cdcV[cdc_]);

        cdcV[cdc_] = newValue;

        emit LogCdcValue(totalCdcV, cdcV[cdc_], cdc_);
    }




    function _updateTotalDcdcV(address dcdc_) internal {
        require(dcdcs[dcdc_], "asm-not-a-dcdc-token");
        uint newValue = wmulV(DSToken(dcdc_).totalSupply(), _updateRate(dcdc_), dcdc_);
        totalDcdcV = sub(add(totalDcdcV, newValue), dcdcV[dcdc_]);
        dcdcV[dcdc_] = newValue;
        emit LogDcdcValue(totalDcdcV, cdcV[dcdc_], dcdc_);
    }




    function _updateDcdcV(address dcdc_, address custodian_) internal {
        require(dcdcs[dcdc_], "asm-not-a-dcdc-token");
        require(custodians[custodian_], "asm-not-a-custodian");
        uint newValue = wmulV(DSToken(dcdc_).balanceOf(custodian_), _updateRate(dcdc_), dcdc_);

        totalDcdcCustV[custodian_] = sub(
            add(
                totalDcdcCustV[custodian_],
                newValue),
            dcdcCustV[dcdc_][custodian_]);

        dcdcCustV[dcdc_][custodian_] = newValue;

        emit LogDcdcCustodianValue(totalDcdcCustV[custodian_], dcdcCustV[dcdc_][custodian_], dcdc_, custodian_);

        _updateTotalDcdcV(dcdc_);
    }





    function _getNewRate(address token_) private view returns (uint rate_) {
        bool feedValid;
        bytes32 usdRateBytes;

        require(
            address(0) != priceFeed[token_],
            "asm-no-price-feed");

        (usdRateBytes, feedValid) =
            TrustedFeedLike(priceFeed[token_]).peek();
        if (feedValid) {
            rate_ = uint(usdRateBytes);
        } else {
            require(manualRate[token_], "Manual rate not allowed");
            rate_ = rate[token_];
        }
    }




    function _getCustodianCdcV(address custodian_) internal view returns(uint) {
        uint totalDpassAndDcdcV_ = add(totalDpassV, totalDcdcV);
        return wmul(
            totalCdcPurchaseV,
            totalDpassAndDcdcV_ > 0 ?
                wdiv(
                    add(
                        totalDpassCustV[custodian_],
                        totalDcdcCustV[custodian_]),
                    totalDpassAndDcdcV_):
                1 ether);
    }




    function _requireSystemCollaterized() internal view returns(uint) {
        require(
            add(
                add(
                    totalDpassV,
                    totalDcdcV),
                dust) >=
            wmul(
                overCollRatio,
                totalCdcV)
            , "asm-system-undercollaterized");
    }







    function _requireSystemRemoveCollaterized() internal view returns(uint) {
        require(
            add(
                add(
                    totalDpassV,
                    totalDcdcV),
                dust) >=
            wmul(
                overCollRemoveRatio,
                totalCdcV)
            , "asm-sys-remove-undercollaterized");
    }





    function _requirePaidLessThanSold(address custodian_, uint256 custodianCdcV_) internal view {
        require(
            add(
                add(
                    custodianCdcV_,
                    dpassSoldCustV[custodian_]),
                dust) >=
                totalPaidCustV[custodian_],
            "asm-too-much-withdrawn");
    }







    function _requireCapCustV(address custodian_) internal view {
        if(capCustV[custodian_] != uint(-1))
        require(
            add(capCustV[custodian_], dust) >=
                add(
                    totalDpassCustV[custodian_],
                    totalDcdcCustV[custodian_]),
            "asm-custodian-reached-maximum-coll-value");
    }




    function _updateCollateralDpass(uint positiveV_, uint negativeV_, address custodian_) internal {
        require(custodians[custodian_], "asm-not-a-custodian");

        totalDpassCustV[custodian_] = sub(
            add(
                totalDpassCustV[custodian_],
                positiveV_),
            negativeV_);

        totalDpassV = sub(
            add(
                totalDpassV,
                positiveV_),
            negativeV_);

        emit LogDpassValue(totalDpassCustV[custodian_], totalDpassV, custodian_);
    }




    function _updateCollateralDcdc(uint positiveV_, uint negativeV_, address custodian_) internal {
        require(custodians[custodian_], "asm-not-a-custodian");

        totalDcdcCustV[custodian_] = sub(
            add(
                totalDcdcCustV[custodian_],
                positiveV_),
            negativeV_);

        totalDcdcV = sub(
            add(
                totalDcdcV,
                positiveV_),
            negativeV_);

        emit LogDcdcTotalCustodianValue(totalDcdcCustV[custodian_], totalDcdcV, custodian_);
    }




    function sendToken(
        address token,
        address src,
        address payable dst,
        uint256 amount
    ) internal returns (bool){
        if (token == eth && amount > 0) {
            require(src == address(this), "wal-ether-transfer-invalid-src");
            dst.transfer(amount);
            emit LogTransferEth(src, dst, amount);
        } else {
            if (amount > 0) DSToken(token).transferFrom(src, dst, amount);
        }
        return true;
    }
}














contract Redeemer is DSAuth, DSStop, DSMath {
    event LogRedeem(uint256 redeemId, address sender, address redeemToken_,uint256 redeemAmtOrId_, address feeToken_, uint256 feeAmt_, address payable custodian);
    address public eth = address(0xee);
    event LogTransferEth(address src, address dst, uint256 amount);
    event LogConfigChange(bytes32 what, bytes32 value, bytes32 value1, bytes32 value2);
    mapping(address => address) public dcdc;
    uint256 public fixFee;
    uint256 public varFee;
    address public dpt;
    SimpleAssetManagement public asm;
    DiamondExchange public dex;
    address payable public liq;
    bool public liqBuysDpt;
    address payable public burner;
    address payable wal;
    uint public profitRate;
    bool locked;
    uint redeemId;
    uint dust = 1000;

    bytes32 public name = "Red";
    bytes32 public symbol = "Red";
    bool kycEnabled;
    mapping(address => bool) public kyc;

    modifier nonReentrant {
        require(!locked, "red-reentrancy-detected");
        locked = true;
        _;
        locked = false;
    }

    modifier kycCheck(address sender) {
        require(!kycEnabled || kyc[sender], "red-you-are-not-on-kyc-list");
        _;
    }

    function () external payable {
    }

    function setConfig(bytes32 what_, bytes32 value_, bytes32 value1_, bytes32 value2_) public nonReentrant auth {
        if (what_ == "asm") {

            require(addr(value_) != address(0x0), "red-zero-asm-address");

            asm = SimpleAssetManagement(address(uint160(addr(value_))));

        } else if (what_ == "fixFee") {

            fixFee = uint256(value_);

        } else if (what_ == "varFee") {

            varFee = uint256(value_);
            require(varFee <= 1 ether, "red-var-fee-too-high");

        } else if (what_ == "kyc") {

            address user_ = addr(value_);

            require(user_ != address(0x0), "red-wrong-address");

            kyc[user_] = uint(value1_) > 0;
        } else if (what_ == "dex") {

            require(addr(value_) != address(0x0), "red-zero-red-address");

            dex = DiamondExchange(address(uint160(addr(value_))));

        } else if (what_ == "burner") {

            require(addr(value_) != address(0x0), "red-wrong-address");

            burner = address(uint160(addr(value_)));

        } else if (what_ == "wal") {

            require(addr(value_) != address(0x0), "red-wrong-address");

            wal = address(uint160(addr(value_)));

        } else if (what_ == "profitRate") {

            profitRate = uint256(value_);

            require(profitRate <= 1 ether, "red-profit-rate-out-of-range");

        } else if (what_ == "dcdcOfCdc") {

            require(address(asm) != address(0), "red-setup-asm-first");

            address cdc_ = addr(value_);
            address dcdc_ = addr(value1_);

            require(asm.cdcs(cdc_), "red-setup-cdc-in-asm-first");
            require(asm.dcdcs(dcdc_), "red-setup-dcdc-in-asm-first");

            dcdc[cdc_] = dcdc_;
        } else if (what_ == "dpt") {

            dpt = addr(value_);

            require(dpt != address(0x0), "red-wrong-address");

        } else if (what_ == "liqBuysDpt") {

            require(liq != address(0x0), "red-wrong-address");

            Liquidity(address(uint160(liq))).burn(dpt, address(uint160(burner)), 0);

            liqBuysDpt = uint256(value_) > 0;

        } else if (what_ == "liq") {

            liq = address(uint160(addr(value_)));

            require(liq != address(0x0), "red-wrong-address");

            require(dpt != address(0), "red-add-dpt-token-first");

            require(
                TrustedDSToken(dpt).balanceOf(liq) > 0,
                "red-insufficient-funds-of-dpt");

            if(liqBuysDpt) {

                Liquidity(liq).burn(dpt, burner, 0);
            }

        } else if (what_ == "kycEnabled") {

            kycEnabled = uint(value_) > 0;

        } else if (what_ == "dust") {
            dust = uint256(value_);
            require(dust <= 1 ether, "red-pls-decrease-dust");
        } else {
            require(false, "red-invalid-option");
        }
        emit LogConfigChange(what_, value_, value1_, value2_);
    }




    function addr(bytes32 b_) public pure returns (address) {
        return address(uint256(b_));
    }












    function redeem(
        address sender,
        address redeemToken_,
        uint256 redeemAmtOrId_,
        address feeToken_,
        uint256 feeAmt_,
        address payable custodian_
    ) public payable stoppable nonReentrant kycCheck(sender) returns (uint256) {

        require(feeToken_ != eth || feeAmt_ == msg.value, "red-eth-not-equal-feeamt");
        if( asm.dpasses(redeemToken_) ) {

            Dpass(redeemToken_).redeem(redeemAmtOrId_);
            require(custodian_ == address(uint160(Dpass(redeemToken_).getCustodian(redeemAmtOrId_))), "red-wrong-custodian-provided");

        } else if ( asm.cdcs(redeemToken_) ) {

            require(
                DSToken(dcdc[redeemToken_])
                    .balanceOf(custodian_) >
                redeemAmtOrId_,
                "red-custodian-has-not-enough-cdc");

            require(redeemAmtOrId_ % 10 ** DSToken(redeemToken_).decimals() == 0, "red-cdc-integer-value-pls");

            DSToken(redeemToken_).transfer(address(asm), redeemAmtOrId_);

            asm.notifyTransferFrom(
                redeemToken_,
                address(this),
                address(asm),
                redeemAmtOrId_);

        } else {
            require(false, "red-token-nor-cdc-nor-dpass");
        }

        uint feeToCustodian_ = _sendFeeToCdiamondCoin(redeemToken_, redeemAmtOrId_, feeToken_, feeAmt_);

        _sendToken(feeToken_, address(this), custodian_, feeToCustodian_);

        emit LogRedeem(++redeemId, sender, redeemToken_, redeemAmtOrId_, feeToken_, feeAmt_, custodian_);

        return redeemId;
    }






    function setKyc(address user_, bool enable_) public auth {
        setConfig(
            "kyc",
            bytes32(uint(user_)),
            enable_ ? bytes32(uint(1)) : bytes32(uint(0)),
            "");
    }




    function _sendFeeToCdiamondCoin(
        address redeemToken_,
        uint256 redeemAmtOrId_,
        address feeToken_,
        uint256 feeAmt_
    ) internal returns (uint feeToCustodianT_){

        uint profitV_;
        uint redeemTokenV_ = _calcRedeemTokenV(redeemToken_, redeemAmtOrId_);

        uint feeT_ = _getFeeT(feeToken_, redeemTokenV_);

        uint profitT_ = wmul(profitRate, feeT_);

        if( feeToken_ == dpt) {

            DSToken(feeToken_).transfer(burner, profitT_);
            DSToken(feeToken_).transfer(wal, sub(feeT_, profitT_));

        } else {

            profitV_ = dex.wmulV(profitT_, dex.getLocalRate(feeToken_), feeToken_);

            if(liqBuysDpt) {
                Liquidity(liq).burn(dpt, burner, profitV_);
            } else {
                DSToken(dpt).transferFrom(
                    liq,
                    burner,
                    dex.wdivT(profitV_, dex.getLocalRate(dpt), dpt));
            }
            _sendToken(feeToken_, address(this), wal, feeT_);
        }

        require(add(feeAmt_,dust) >= feeT_, "red-not-enough-fee-sent");
        feeToCustodianT_ = sub(feeAmt_, feeT_);
    }











    function getRedeemCosts(address redeemToken_, uint256 redeemAmtOrId_, address feeToken_) public view returns(uint feeT_) {
            require(asm.dpasses(redeemToken_) || redeemAmtOrId_ % 10 ** DSToken(redeemToken_).decimals() == 0, "red-cdc-integer-value-pls");
        uint redeemTokenV_ = _calcRedeemTokenV(redeemToken_, redeemAmtOrId_);
        feeT_ = _getFeeT(feeToken_, redeemTokenV_);
    }




    function _calcRedeemTokenV(address redeemToken_, uint256 redeemAmtOrId_) internal view returns(uint redeemTokenV_) {
        if(asm.dpasses(redeemToken_)) {
            redeemTokenV_ = asm.basePrice(redeemToken_, redeemAmtOrId_);
        } else {
            redeemTokenV_ = dex.wmulV(
                redeemAmtOrId_,
                dex.getLocalRate(redeemToken_),
                redeemToken_);
        }
    }




    function _getFeeT(address feeToken_, uint256 redeemTokenV_) internal view returns (uint) {
        return
            dex.wdivT(
                add(
                    wmul(
                        varFee,
                        redeemTokenV_),
                    fixFee),
                dex.getLocalRate(feeToken_),
                feeToken_);
    }




    function _sendToken(
        address token,
        address src,
        address payable dst,
        uint256 amount
    ) internal returns (bool){
        if (token == eth && amount > 0) {
            require(src == address(this), "wal-ether-transfer-invalid-src");
            dst.transfer(amount);
            emit LogTransferEth(src, dst, amount);
        } else {
            if (amount > 0) DSToken(token).transferFrom(src, dst, amount);
        }
        return true;
    }
}














contract TrustedFeedLikeDex {
    function peek() external view returns (bytes32, bool);
}






contract TrustedFeeCalculator {

    function calculateFee(
        address sender,
        uint256 value,
        address sellToken,
        uint256 sellAmtOrId,
        address buyToken,
        uint256 buyAmtOrId
    ) external view returns (uint);

    function getCosts(
        address user,
        address sellToken_,
        uint256 sellId_,
        address buyToken_,
        uint256 buyAmtOrId_
    ) public view returns (uint256 sellAmtOrId_, uint256 feeDpt_, uint256 feeV_, uint256 feeSellT_) {

    }
}




contract TrustedRedeemer {

function redeem(
    address sender,
    address redeemToken_,
    uint256 redeemAmtOrId_,
    address feeToken_,
    uint256 feeAmt_,
    address payable custodian_
) public payable returns (uint256);

}




contract TrustedAsm {
    function notifyTransferFrom(address token, address src, address dst, uint256 id721) external;
    function basePrice(address erc721, uint256 id721) external view returns(uint256);
    function getAmtForSale(address token) external view returns(uint256);
    function mint(address token, address dst, uint256 amt) external;
}





contract TrustedErc721 {
    function transferFrom(address src, address to, uint256 amt) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}





contract TrustedDSToken {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address src) external view returns (uint);
    function allowance(address src, address guy) external view returns (uint);
}





contract DiamondExchangeEvents {

    event LogBuyTokenWithFee(
        uint256 indexed txId,
        address indexed sender,
        address custodian20,
        address sellToken,
        uint256 sellAmountT,
        address buyToken,
        uint256 buyAmountT,
        uint256 feeValue
    );

    event LogConfigChange(bytes32 what, bytes32 value, bytes32 value1);

    event LogTransferEth(address src, address dst, uint256 val);
}






contract DiamondExchange is DSAuth, DSStop, DiamondExchangeEvents {
    TrustedDSToken public cdc;
    address public dpt;

    mapping(address => uint256) private rate;
    mapping(address => uint256) public smallest;
    mapping(address => bool) public manualRate;

    mapping(address => TrustedFeedLikeDex)
    public priceFeed;

    mapping(address => bool) public canBuyErc20;
    mapping(address => bool) public canSellErc20;
    mapping(address => bool) public canBuyErc721;
    mapping(address => bool) public canSellErc721;
    mapping(address => mapping(address => bool))
        public denyToken;
    mapping(address => uint) public decimals;
    mapping(address => bool) public decimalsSet;
    mapping(address => address payable) public custodian20;
    mapping(address => bool) public handledByAsm;
    mapping(
        address => mapping(
            address => mapping(
                uint => uint))) public buyPrice;

    mapping(address => bool) redeemFeeToken;
    TrustedFeeCalculator public fca;

    address payable public liq;
    address payable public wal;
    address public burner;
    TrustedAsm public asm;
    uint256 public fixFee;
    uint256 public varFee;
    uint256 public profitRate;

    uint256 public callGas = 2500;
    uint256 public txId;
    bool public takeProfitOnlyInDpt = true;

    uint256 public dust = 10000;
    bytes32 public name = "Dex";
    bytes32 public symbol = "Dex";


    bool liqBuysDpt;


    bool locked;
    address eth = address(0xee);
    bool kycEnabled;
    mapping(address => bool) public kyc;
    address payable public redeemer;


    uint constant WAD = 1 ether;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }


    modifier nonReentrant {
        require(!locked, "dex-reentrancy-detected");
        locked = true;
        _;
        locked = false;
    }

    modifier kycCheck {
        require(!kycEnabled || kyc[msg.sender], "dex-you-are-not-on-kyc-list");
        _;
    }




    function () external payable {
        buyTokensWithFee(eth, msg.value, address(cdc), uint(-1));
    }









    function setConfig(bytes32 what_, bytes32 value_, bytes32 value1_) public auth {
        if (what_ == "profitRate") {

            profitRate = uint256(value_);

            require(profitRate <= 1 ether, "dex-profit-rate-out-of-range");

        } else if (what_ == "rate") {
            address token = addr(value_);
            uint256 value = uint256(value1_);

            require(
                canSellErc20[token] ||
                canBuyErc20[token],
                "dex-token-not-allowed-rate");

            require(value > 0, "dex-rate-must-be-greater-than-0");

            rate[token] = value;

        } else if (what_ == "kyc") {

            address user_ = addr(value_);

            require(user_ != address(0x0), "dex-wrong-address");

            kyc[user_] = uint(value1_) > 0;
        } else if (what_ == "allowTokenPair") {

            address sellToken_ = addr(value_);
            address buyToken_ = addr(value1_);

            require(canSellErc20[sellToken_] || canSellErc721[sellToken_],
                "dex-selltoken-not-listed");
            require(canBuyErc20[buyToken_] || canBuyErc721[buyToken_],
                "dex-buytoken-not-listed");

            denyToken[sellToken_][buyToken_] = false;
        } else if (what_ == "denyTokenPair") {

            address sellToken_ = addr(value_);
            address buyToken_ = addr(value1_);

            require(canSellErc20[sellToken_] || canSellErc721[sellToken_],
                "dex-selltoken-not-listed");
            require(canBuyErc20[buyToken_] || canBuyErc721[buyToken_],
                "dex-buytoken-not-listed");

            denyToken[sellToken_][buyToken_] = true;
        } else if (what_ == "fixFee") {

            fixFee = uint256(value_);

        } else if (what_ == "varFee") {

            varFee = uint256(value_);

            require(varFee <= 1 ether, "dex-var-fee-too-high");

        } else if (what_ == "redeemFeeToken") {

            address token = addr(value_);
            require(token != address(0), "dex-zero-address-redeemfee-token");
            redeemFeeToken[token] = uint256(value1_) > 0;

        } else if (what_ == "manualRate") {

            address token = addr(value_);

            require(
                canSellErc20[token] ||
                canBuyErc20[token],
                "dex-token-not-allowed-manualrate");

            manualRate[token] = uint256(value1_) > 0;

        } else if (what_ == "priceFeed") {

            require(canSellErc20[addr(value_)] || canBuyErc20[addr(value_)],
                "dex-token-not-allowed-pricefeed");

            require(addr(value1_) != address(address(0x0)),
                "dex-wrong-pricefeed-address");

            priceFeed[addr(value_)] = TrustedFeedLikeDex(addr(value1_));

        } else if (what_ == "takeProfitOnlyInDpt") {

            takeProfitOnlyInDpt = uint256(value_) > 0;

        } else if (what_ == "liqBuysDpt") {

            require(liq != address(0x0), "dex-wrong-address");

            Liquidity(liq).burn(dpt, burner, 0);

            liqBuysDpt = uint256(value_) > 0;

        } else if (what_ == "liq") {

            liq = address(uint160(addr(value_)));

            require(liq != address(0x0), "dex-wrong-address");

            require(dpt != address(0), "dex-add-dpt-token-first");

            require(
                TrustedDSToken(dpt).balanceOf(liq) > 0,
                "dex-insufficient-funds-of-dpt");

            if(liqBuysDpt) {

                Liquidity(liq).burn(dpt, burner, 0);
            }

        } else if (what_ == "handledByAsm") {

            address token = addr(value_);

            require(canBuyErc20[token] || canBuyErc721[token],
                    "dex-token-not-allowed-handledbyasm");

            handledByAsm[token] = uint256(value1_) > 0;

        } else if (what_ == "asm") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            asm = TrustedAsm(addr(value_));

        } else if (what_ == "burner") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            burner = address(uint160(addr(value_)));

        } else if (what_ == "cdc") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            cdc = TrustedDSToken(addr(value_));

        } else if (what_ == "fca") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            fca = TrustedFeeCalculator(addr(value_));

        } else if (what_ == "custodian20") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            custodian20[addr(value_)] = address(uint160(addr(value1_)));

        } else if (what_ == "smallest") {
            address token = addr(value_);
            uint256 value = uint256(value1_);

            require(
                canSellErc20[token] ||
                canBuyErc20[token],
                "dex-token-not-allowed-small");

            smallest[token] = value;

        } else if (what_ == "decimals") {

            address token_ = addr(value_);

            require(token_ != address(0x0), "dex-wrong-address");

            uint decimal = uint256(value1_);

            decimals[token_] = 10 ** decimal;

            decimalsSet[token_] = true;

        } else if (what_ == "wal") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            wal = address(uint160(addr(value_)));

        } else if (what_ == "callGas") {

            callGas = uint256(value_);

        } else if (what_ == "dust") {

            dust = uint256(value_);

        } else if (what_ == "canBuyErc20") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            require(decimalsSet[addr(value_)], "dex-buytoken-decimals-not-set");

            canBuyErc20[addr(value_)] = uint(value1_) > 0;

        } else if (what_ == "canSellErc20") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            require(decimalsSet[addr(value_)], "dex-selltoken-decimals-not-set");

            canSellErc20[addr(value_)] = uint(value1_) > 0;

        } else if (what_ == "canBuyErc721") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            canBuyErc721[addr(value_)] = uint(value1_) > 0;

        } else if (what_ == "canSellErc721") {

            require(addr(value_) != address(0x0), "dex-wrong-address");

            canSellErc721[addr(value_)] = uint(value1_) > 0;

        } else if (what_ == "kycEnabled") {

            kycEnabled = uint(value_) > 0;

        } else if (what_ == "dpt") {

            dpt = addr(value_);

            require(dpt != address(0x0), "dex-wrong-address");

            require(decimalsSet[dpt], "dex-dpt-decimals-not-set");

        } else if (what_ == "redeemer") {

            require(addr(value_) != address(0x0), "dex-wrong-redeemer-address");

            redeemer = address(uint160(addr(value_)));

        } else {
            value1_;
            require(false, "dex-no-such-option");
        }

        emit LogConfigChange(what_, value_, value1_);
    }









    function redeem(
        address redeemToken_,
        uint256 redeemAmtOrId_,
        address feeToken_,
        uint256 feeAmt_,
        address payable custodian_
    ) public payable stoppable nonReentrant returns(uint redeemId) {

        require(redeemFeeToken[feeToken_] || feeToken_ == dpt, "dex-token-not-to-pay-redeem-fee");

        if(canBuyErc721[redeemToken_] || canSellErc721[redeemToken_]) {

            Dpass(redeemToken_)
            .transferFrom(
                msg.sender,
                redeemer,
                redeemAmtOrId_);

        } else if (canBuyErc20[redeemToken_] || canSellErc20[redeemToken_]) {

            _sendToken(redeemToken_, msg.sender, redeemer, redeemAmtOrId_);

        } else {
            require(false, "dex-token-can-not-be-redeemed");
        }

        if(feeToken_ == eth) {

            return TrustedRedeemer(redeemer)
                .redeem
                .value(msg.value)
                (msg.sender, redeemToken_, redeemAmtOrId_, feeToken_, feeAmt_, custodian_);

        } else {

            _sendToken(feeToken_, msg.sender, redeemer, feeAmt_);

            return TrustedRedeemer(redeemer)
            .redeem(msg.sender, redeemToken_, redeemAmtOrId_, feeToken_, feeAmt_, custodian_);
        }
    }









    function buyTokensWithFee (
        address sellToken_,
        uint256 sellAmtOrId_,
        address buyToken_,
        uint256 buyAmtOrId_
    ) public payable stoppable nonReentrant kycCheck {
        uint buyV_;
        uint sellV_;
        uint feeV_;
        uint sellT_;
        uint buyT_;

        require(!denyToken[sellToken_][buyToken_], "dex-cant-use-this-token-to-buy");
        require(smallest[sellToken_] <= sellAmtOrId_, "dex-trade-value-too-small");

        _updateRates(sellToken_, buyToken_);

        (buyV_, sellV_) = _getValues(
            sellToken_,
            sellAmtOrId_,
            buyToken_,
            buyAmtOrId_);

        feeV_ = calculateFee(
            msg.sender,
            min(buyV_, sellV_),
            sellToken_,
            sellAmtOrId_,
            buyToken_,
            buyAmtOrId_);

        (sellT_, buyT_) = _takeFee(
            feeV_,
            sellV_,
            buyV_,
            sellToken_,
            sellAmtOrId_,
            buyToken_,
            buyAmtOrId_);

        _transferTokens(
            sellT_,
            buyT_,
            sellToken_,
            sellAmtOrId_,
            buyToken_,
            buyAmtOrId_,
            feeV_);
    }




    function _getValues(
        address sellToken_,
        uint256 sellAmtOrId_,
        address buyToken_,
        uint256 buyAmtOrId_
    ) internal returns (uint256 buyV, uint256 sellV) {
        uint sellAmtT_ = sellAmtOrId_;
        uint buyAmtT_ = buyAmtOrId_;
        uint maxT_;

        require(buyToken_ != eth, "dex-we-do-not-sell-ether");
        require(sellToken_ == eth || msg.value == 0,
                "dex-do-not-send-ether");

        if (canSellErc20[sellToken_]) {

            maxT_ = sellToken_ == eth ?
                msg.value :
                min(
                    TrustedDSToken(sellToken_).balanceOf(msg.sender),
                    TrustedDSToken(sellToken_).allowance(
                        msg.sender, address(this)));

            require(maxT_ > 0, "dex-please-approve-us");

            require(
                sellToken_ == eth ||
                sellAmtOrId_ == uint(-1) ||
                sellAmtOrId_ <= maxT_,
                "dex-sell-amount-exceeds-allowance");

            require(
                sellToken_ != eth ||
                sellAmtOrId_ == uint(-1) ||
                sellAmtOrId_ <= msg.value,
                "dex-sell-amount-exceeds-ether-value");

            if (sellAmtT_ > maxT_ ) {

                sellAmtT_ = maxT_;
            }

            sellV = wmulV(sellAmtT_, rate[sellToken_], sellToken_);

        } else if (canSellErc721[sellToken_]) {

            sellV = getPrice(sellToken_, sellAmtOrId_);

        } else {

            require(false, "dex-token-not-allowed-to-be-sold");

        }

        if (canBuyErc20[buyToken_]) {

            maxT_ = handledByAsm[buyToken_] ?
                asm.getAmtForSale(buyToken_) :
                min(
                    TrustedDSToken(buyToken_).balanceOf(
                        custodian20[buyToken_]),
                    TrustedDSToken(buyToken_).allowance(
                        custodian20[buyToken_], address(this)));

            require(maxT_ > 0, "dex-0-token-is-for-sale");

            require(
                buyToken_ == eth ||
                buyAmtOrId_ == uint(-1) ||
                buyAmtOrId_ <= maxT_,
                "dex-buy-amount-exceeds-allowance");

            if (buyAmtOrId_ > maxT_) {

                buyAmtT_ = maxT_;
            }

            buyV = wmulV(buyAmtT_, rate[buyToken_], buyToken_);

        } else if (canBuyErc721[buyToken_]) {

            require(canSellErc20[sellToken_],
                    "dex-one-of-tokens-must-be-erc20");

            buyV = getPrice(
                buyToken_,
                buyAmtOrId_);

        } else {
            require(false, "dex-token-not-allowed-to-be-bought");
        }
    }











    function calculateFee(
        address sender_,
        uint256 value_,
        address sellToken_,
        uint256 sellAmtOrId_,
        address buyToken_,
        uint256 buyAmtOrId_
    ) public view returns (uint256) {

        if (fca == TrustedFeeCalculator(0)) {

            return add(fixFee, wmul(varFee, value_));

        } else {

            return fca.calculateFee(
                sender_,
                value_,
                sellToken_,
                sellAmtOrId_,
                buyToken_,
                buyAmtOrId_);
        }
    }





    function _takeFee(
        uint256 feeV_,
        uint256 sellV_,
        uint256 buyV_,
        address sellToken_,
        uint256 sellAmtOrId_,
        address buyToken_,
        uint256 buyAmtOrId_
    )
    internal
    returns(uint256 sellT, uint256 buyT) {
        uint feeTakenV_;
        uint amtT_;
        address token_;
        address src_;
        uint restFeeV_;

        feeTakenV_ = sellToken_ != dpt ?
            min(_takeFeeInDptFromUser(feeV_), feeV_) :
            0;

        restFeeV_ = sub(feeV_, feeTakenV_);

        if (feeV_ - feeTakenV_ > dust
            && feeV_ - feeTakenV_ <= feeV_) {

            if (canSellErc20[sellToken_]) {

                require(
                    canBuyErc20[buyToken_] ||
                    sellV_ + dust >=
                        buyV_ + restFeeV_,
                    "dex-not-enough-user-funds-to-sell");

                token_ = sellToken_;
                src_ = msg.sender;
                amtT_ = sellAmtOrId_;

                if (add(sellV_, dust) <
                    add(buyV_, restFeeV_)) {

                    buyV_ = sub(sellV_, restFeeV_);
                }

                sellV_ = buyV_;

            } else if (canBuyErc20[buyToken_]) {
                require(
                    sellV_ <= buyV_ + dust,
                    "dex-not-enough-tokens-to-buy");


                token_ = buyToken_;

                src_ = custodian20[token_];

                amtT_ = buyAmtOrId_;

                if (sellV_ <= add(add(buyV_, restFeeV_), dust))

                    buyV_ = sub(sellV_, restFeeV_);

            } else {

                require(false,
                    "dex-no-token-to-get-fee-from");



            }

            assert(
                token_ != buyToken_ ||
                sub(buyV_, restFeeV_) <= add(sellV_, dust));

            assert(
                token_ != sellToken_ ||
                buyV_ <= add(sellV_, dust));

            _takeFeeInToken(
                restFeeV_,
                feeTakenV_,
                token_,
                src_,
                amtT_);

        } else {
            require(buyV_ <= sellV_ || canBuyErc20[buyToken_],
                "dex-not-enough-funds");

            require(buyV_ >= sellV_ || canSellErc20[sellToken_],
                "dex-not-enough-tokens-to-buy");

            sellV_ = min(buyV_, sellV_);

            buyV_ = sellV_;
        }

        sellT = canSellErc20[sellToken_] ?
            wdivT(sellV_, rate[sellToken_], sellToken_) :
            sellAmtOrId_;

        buyT = canBuyErc20[buyToken_] ?
            wdivT(buyV_, rate[buyToken_], buyToken_) :
            buyAmtOrId_;

        if (sellToken_ == eth) {

            amtT_ = wdivT(
                restFeeV_,
                rate[sellToken_],
                sellToken_);

            _sendToken(
                eth,
                address(this),
                msg.sender,
                sub(msg.value, add(sellT, amtT_)));
        }
    }




    function _transferTokens(
        uint256 sellT_,
        uint256 buyT_,
        address sellToken_,
        uint256 sellAmtOrId_,
        address buyToken_,
        uint256 buyAmtOrId_,
        uint256 feeV_
    ) internal {
        address payable payTo_;

        if (canBuyErc20[buyToken_]) {

            payTo_ = handledByAsm[buyToken_] ?
                address(uint160(address(asm))):
                custodian20[buyToken_];

            _sendToken(buyToken_, payTo_, msg.sender, buyT_);
        }

        if (canSellErc20[sellToken_]) {

            if (canBuyErc721[buyToken_]) {

                payTo_ = address(uint160(address(
                    Dpass(buyToken_).ownerOf(buyAmtOrId_))));

                asm.notifyTransferFrom(
                    buyToken_,
                    payTo_,
                    msg.sender,
                    buyAmtOrId_);

                TrustedErc721(buyToken_)
                .transferFrom(
                    payTo_,
                    msg.sender,
                    buyAmtOrId_);


            }

            _sendToken(sellToken_, msg.sender, payTo_, sellT_);

        } else {

            TrustedErc721(sellToken_)
            .transferFrom(
                msg.sender,
                payTo_,
                sellAmtOrId_);

            sellT_ = sellAmtOrId_;
        }

        require(!denyToken[sellToken_][payTo_],
            "dex-token-denied-by-seller");

        if (payTo_ == address(asm) ||
            (canSellErc721[sellToken_] && handledByAsm[buyToken_]))

            asm.notifyTransferFrom(
                               sellToken_,
                               msg.sender,
                               payTo_,
                               sellT_);

        _logTrade(sellToken_, sellT_, buyToken_, buyT_, buyAmtOrId_, feeV_);
    }






    function setDenyToken(address token_, bool denyOrAccept_) public {
        require(canSellErc20[token_] || canSellErc721[token_], "dex-can-not-use-anyway");
        denyToken[token_][msg.sender] = denyOrAccept_;
    }






    function setKyc(address user_, bool allowed_) public auth {
        require(user_ != address(0), "asm-kyc-user-can-not-be-zero");
        kyc[user_] = allowed_;
    }






    function getBuyPrice(address token_, uint256 tokenId_) public view returns(uint256) {

        return buyPrice[token_][TrustedErc721(token_).ownerOf(tokenId_)][tokenId_];
    }







    function setBuyPrice(address token_, uint256 tokenId_, uint256 price_) public {
        address seller_ = msg.sender;
        require(canBuyErc721[token_], "dex-token-not-for-sale");

        if (
            msg.sender == Dpass(token_).getCustodian(tokenId_) &&
            address(asm) == Dpass(token_).ownerOf(tokenId_)
        ) seller_ = address(asm);

        buyPrice[token_][seller_][tokenId_] = price_;
    }








    function getPrice(address token_, uint256 tokenId_) public view returns(uint256) {
        uint basePrice_;
        address owner_ = TrustedErc721(token_).ownerOf(tokenId_);
        uint buyPrice_ = buyPrice[token_][owner_][tokenId_];
        require(canBuyErc721[token_], "dex-token-not-for-sale");
        if( buyPrice_ == 0 || buyPrice_ == uint(-1)) {
            basePrice_ = asm.basePrice(token_, tokenId_);
            require(basePrice_ != 0, "dex-zero-price-not-allowed");
            return basePrice_;
        } else {
            return buyPrice_;
        }
    }





    function getLocalRate(address token_) public view auth returns(uint256) {
        return rate[token_];
    }







    function getAllowedToken(address token_, bool buy_) public view auth returns(bool) {
        if (buy_) {
            return canBuyErc20[token_] || canBuyErc721[token_];
        } else {
            return canSellErc20[token_] || canSellErc721[token_];
        }
    }





    function addr(bytes32 b_) public pure returns (address) {
        return address(uint256(b_));
    }





    function getDecimals(address token_) public view returns (uint8) {
        require(decimalsSet[token_], "dex-token-with-unset-decimals");
        uint dec = 0;
        while(dec <= 77 && decimals[token_] % uint(10) ** dec == 0){
            dec++;
        }
        dec--;
        return uint8(dec);
    }






    function getRate(address token_) public view auth returns (uint) {
        return _getNewRate(token_);
    }







    function wmulV(uint256 a_, uint256 b_, address token_) public view returns(uint256) {
        return wdiv(wmul(a_, b_), decimals[token_]);
    }







    function wdivT(uint256 a_, uint256 b_, address token_) public view returns(uint256) {
        return wmul(wdiv(a_,b_), decimals[token_]);
    }





    function _getNewRate(address token_) internal view returns (uint rate_) {
        bool feedValid_;
        bytes32 baseRateBytes_;

        require(
            TrustedFeedLikeDex(address(0x0)) != priceFeed[token_],
            "dex-no-price-feed-for-token");

        (baseRateBytes_, feedValid_) = priceFeed[token_].peek();

        if (feedValid_) {

            rate_ = uint(baseRateBytes_);

        } else {

            require(manualRate[token_], "dex-feed-provides-invalid-data");

            rate_ = rate[token_];
        }
    }








    function _updateRates(address sellToken_, address buyToken_) internal {
        if (canSellErc20[sellToken_]) {
            _updateRate(sellToken_);
        }

        if (canBuyErc20[buyToken_]){
            _updateRate(buyToken_);
        }

        _updateRate(dpt);
    }




    function _logTrade(
        address sellToken_,
        uint256 sellT_,
        address buyToken_,
        uint256 buyT_,
        uint256 buyAmtOrId_,
        uint256 feeV_
    ) internal {

        address custodian_ = canBuyErc20[buyToken_] ?
            custodian20[buyToken_] :
            Dpass(buyToken_).getCustodian(buyAmtOrId_);

        txId++;

        emit LogBuyTokenWithFee(
            txId,
            msg.sender,
            custodian_,
            sellToken_,
            sellT_,
            buyToken_,
            buyT_,
            feeV_);
    }




    function _updateRate(address token) internal returns (uint256 rate_) {
        require((rate_ = _getNewRate(token)) > 0, "dex-rate-must-be-greater-than-0");
        rate[token] = rate_;
    }




    function _takeFeeInToken(
        uint256 feeV_,
        uint256 feeTakenV_,
        address token_,
        address src_,
        uint256 amountT_
    ) internal {
        uint profitV_;
        uint profitDpt_;
        uint feeT_;
        uint profitPaidV_;
        uint totalProfitV_;

        totalProfitV_ = wmul(add(feeV_, feeTakenV_), profitRate);

        profitPaidV_ = takeProfitOnlyInDpt ?
            feeTakenV_ :
            wmul(feeTakenV_, profitRate);

        profitV_ = sub(
            totalProfitV_,
            min(
                profitPaidV_,
                totalProfitV_));

        profitDpt_ = wdivT(profitV_, rate[dpt], dpt);

        feeT_ = wdivT(feeV_, rate[token_], token_);

        require(
            feeT_ < amountT_,
            "dex-not-enough-token-to-pay-fee");

        if (token_ == dpt) {
            _sendToken(dpt, src_, address(uint160(address(burner))), profitDpt_);

            _sendToken(dpt, src_, wal, sub(feeT_, profitDpt_));

        } else {

            if (liqBuysDpt) {

                Liquidity(liq).burn(dpt, burner, profitV_);

            } else {

                _sendToken(dpt,
                           liq,
                           address(uint160(address(burner))),
                           profitDpt_);
            }

            _sendToken(token_, src_, wal, feeT_);
        }
    }






    function _takeFeeInDptFromUser(
        uint256 feeV_
    ) internal returns(uint256 feeTakenV_) {
        TrustedDSToken dpt20_ = TrustedDSToken(dpt);
        uint profitDpt_;
        uint costDpt_;
        uint feeTakenDpt_;

        uint dptUser = min(
            dpt20_.balanceOf(msg.sender),
            dpt20_.allowance(msg.sender, address(this))
        );

        if (dptUser == 0) return 0;

        uint feeDpt = wdivT(feeV_, rate[dpt], dpt);

        uint minDpt = min(feeDpt, dptUser);


        if (minDpt > 0) {

            if (takeProfitOnlyInDpt) {

                profitDpt_ = min(wmul(feeDpt, profitRate), minDpt);

            } else {

                profitDpt_ = wmul(minDpt, profitRate);

                costDpt_ = sub(minDpt, profitDpt_);

                _sendToken(dpt, msg.sender, wal, costDpt_);
            }

            _sendToken(dpt,
                       msg.sender,
                       address(uint160(address(burner))),
                       profitDpt_);

            feeTakenDpt_ = add(profitDpt_, costDpt_);

            feeTakenV_ = wmulV(feeTakenDpt_, rate[dpt], dpt);
        }

    }




    function _sendToken(
        address token_,
        address src_,
        address payable dst_,
        uint256 amount_
    ) internal returns(bool) {

        if (token_ == eth && amount_ > dust) {
            require(src_ == msg.sender || src_ == address(this),
                    "dex-wrong-src-address-provided");
            dst_.transfer(amount_);

            emit LogTransferEth(src_, dst_, amount_);

        } else {

            if (amount_ > 0) {
                if( handledByAsm[token_] && src_ == address(asm)) {
                    asm.mint(token_, dst_, amount_);
                } else {
                    TrustedDSToken(token_).transferFrom(src_, dst_, amount_);
                }
            }
        }
        return true;
    }
}









contract TrustedAsmExt {
    function getAmtForSale(address token) external view returns(uint256);
}




contract TrustedFeeCalculatorExt {

    function calculateFee(
        address sender,
        uint256 value,
        address sellToken,
        uint256 sellAmtOrId,
        address buyToken,
        uint256 buyAmtOrId
    ) external view returns (uint);

    function getCosts(
        address user,
        address sellToken_,
        uint256 sellId_,
        address buyToken_,
        uint256 buyAmtOrId_
    ) public view returns (uint256 sellAmtOrId_, uint256 feeDpt_, uint256 feeV_, uint256 feeSellT_) {

    }
}

contract DiamondExchangeExtension is DSAuth {

    uint public dust = 1000;
    bytes32 public name = "Dee";
    bytes32 public symbol = "Dee";
    TrustedAsmExt public asm;
    DiamondExchange public dex;
    Redeemer public red;
    TrustedFeeCalculatorExt public fca;

    uint private buyV;
    uint private dptBalance;
    uint private feeDptV;

    uint constant WAD = 1 ether;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }


    function setConfig(bytes32 what_, bytes32 value_, bytes32 value1_) public auth {
        if (what_ == "asm") {

            require(addr(value_) != address(0x0), "dee-wrong-address");

            asm = TrustedAsmExt(addr(value_));

        } else if (what_ == "dex") {

            require(addr(value_) != address(0x0), "dee-wrong-address");

            dex = DiamondExchange(address(uint160(addr(value_))));

        } else if (what_ == "red") {

            require(addr(value_) != address(0x0), "dee-wrong-address");

            red = Redeemer(address(uint160(addr(value_))));

        } else if (what_ == "dust") {

            dust = uint256(value_);

        } else {
            value1_;
            require(false, "dee-no-such-option");
        }
    }




    function addr(bytes32 b_) public pure returns (address) {
        return address(uint256(b_));
    }
















    function getDiamondInfo(address token_, uint256 tokenId_)
    public view returns(
        address[2] memory ownerCustodian_,
        bytes32[6] memory attrs_,
        uint24 carat_,
        uint priceV_
    ) {
        require(dex.canBuyErc721(token_) || dex.canSellErc721(token_), "dee-token-not-a-dpass-token");
        (ownerCustodian_, attrs_, carat_) = Dpass(token_).getDiamondInfo(tokenId_);
        priceV_ = dex.getPrice(token_, tokenId_);
    }




    function sellerAcceptsToken(address token_, address seller_)
    public view returns (bool) {

        return (dex.canSellErc20(token_) ||
                dex.canSellErc721(token_)) &&
                !dex.denyToken(token_, seller_);
    }










    function getCosts(
        address user_,
        address sellToken_,
        uint256 sellId_,
        address buyToken_,
        uint256 buyAmtOrId_
    ) public view
    returns (
        uint256 sellAmtOrId_,
        uint256 feeDpt_,

        uint256 feeV_,
        uint256 feeSellT_
    ) {
        uint buyV_;
        uint feeDptV_;

        if(fca == TrustedFeeCalculatorExt(0)) {

            require(user_ != address(0),
                "dee-user_-address-zero");

            require(
                dex.canSellErc20(sellToken_) ||
                dex.canSellErc721(sellToken_),
                "dee-selltoken-invalid");

            require(
                dex.canBuyErc20(buyToken_) ||
                dex.canBuyErc721(buyToken_),
                "dee-buytoken-invalid");

            require(
                !(dex.canBuyErc721(buyToken_) &&
                dex.canSellErc721(sellToken_)),
                "dee-both-tokens-dpass");

            require(dex.dpt() != address(0), "dee-dpt-address-zero");

            if(dex.canBuyErc20(buyToken_)) {

                buyV_ = _getBuyV(buyToken_, buyAmtOrId_);

            } else {

                buyV_ = dex.getPrice(buyToken_, buyAmtOrId_);
            }

            feeV_ = add(
                wmul(buyV_, dex.varFee()),
                dex.fixFee());

            feeDpt_ = wmul(
                dex.wdivT(
                    feeV_,
                    dex.getRate(dex.dpt()),
                    dex.dpt()),
                dex.takeProfitOnlyInDpt() ? dex.profitRate() : 1 ether);

            sellAmtOrId_ = min(
                DSToken(dex.dpt()).balanceOf(user_),
                DSToken(dex.dpt()).allowance(user_, address(dex)));

            if(dex.canSellErc20(sellToken_)) {

                if(sellAmtOrId_ <= add(feeDpt_, dust)) {

                    feeDptV_ = dex.wmulV(
                        sellAmtOrId_,
                        dex.getRate(dex.dpt()),
                        dex.dpt());

                    feeDpt_ = sellAmtOrId_;

                } else {

                    feeDptV_ = dex.wmulV(feeDpt_, dex.getRate(dex.dpt()), dex.dpt());

                    feeDpt_ = feeDpt_;

                }

                feeSellT_ = dex.wdivT(sub(feeV_, min(feeV_, feeDptV_)), dex.getRate(sellToken_), sellToken_);

                sellAmtOrId_ = add(
                    dex.wdivT(
                        buyV_,
                        dex.getRate(sellToken_),
                        sellToken_),
                    feeSellT_);

            } else {

                sellAmtOrId_ = add(buyV_, dust) >= dex.getPrice(sellToken_, sellId_) ? 1 : 0;
                feeDpt_ = min(feeDpt_, Dpass(dex.dpt()).balanceOf(user_));
            }

        } else {
            return fca.getCosts(user_, sellToken_, sellId_, buyToken_, buyAmtOrId_);
        }
    }

    function getRedeemCosts(
        address redeemToken_,
        uint256 redeemAmtOrId_,
        address feeToken_
    ) public view returns(uint) {
        return red.getRedeemCosts(redeemToken_, redeemAmtOrId_, feeToken_);
    }

    function _getBuyV(address buyToken_, uint256 buyAmtOrId_) internal view returns (uint buyV_) {
        uint buyT_;

        buyT_ = dex.handledByAsm(buyToken_) ?
            asm.getAmtForSale(buyToken_) :
            min(
                DSToken(buyToken_).balanceOf(
                    dex.custodian20(buyToken_)),
                DSToken(buyToken_).allowance(
                    dex.custodian20(buyToken_), address(dex)));

        buyT_ = min(buyT_, buyAmtOrId_);

        buyV_ = dex.wmulV(buyT_, dex.getRate(buyToken_), buyToken_);
    }
}



















contract DiamondExchangeSetup is DSTest, DSMath, DiamondExchangeEvents, Wallet {
    event LogUintIpartUintFpart(bytes32 key, uint val, uint val1);
    event LogTest(uint256 what);
    event LogTest(bool what);
    event LogTest(address what);
    event LogTest(bytes32 what);

    uint public constant SUPPLY = (10 ** 10) * (10 ** 18);
    uint public constant INITIAL_BALANCE = 1000 ether;

    address public cdc;
    address public dcdc;
    address public dpass;
    address public dpass1;
    address public dpt;
    address public dai;
    address public eth;
    address public eng;
    address payable public exchange;
    address payable public dee;
    address payable public red;

    address payable public liq;
    address payable public wal;
    address payable public asm;
    address payable public user;
    address payable public seller;
    address payable public custodian;

    address payable public burner;
    address payable public fca;


    mapping(address => mapping(address => uint)) public balance;
    mapping(address => mapping(uint => uint)) public usdRateDpass;
    mapping(address => uint) public usdRate;
    mapping(address => address) feed;
    mapping(address => address payable) custodian20;
    mapping(address => uint8) public decimals;
    mapping(address => bool) public decimalsSet;
    mapping(address => uint) public dpassId;
    mapping(address => bool) public erc20;
    mapping(address => uint) dust;
    mapping(address => bool) dustSet;
    mapping(address => uint) public dpassOwnerPrice;

    uint public fixFee = 0 ether;
    uint public varFee = .2 ether;
    uint public fixFeeRedeem = 0 ether;
    uint public varFeeRedeem = .03 ether;
    uint public profitRate = .3 ether;
    uint public profitRateRedeem = .33 ether;
    bool public takeProfitOnlyInDpt = true;


    address origBuyer;
    uint userDpt;
    uint feeDpt;
    uint feeSellTokenT;
    uint restOfFeeT;
    uint restOfFeeV;
    uint restOfFeeDpt;
    uint feeV;
    uint buySellTokenT;
    uint sentV;
    uint profitV;
    uint profitDpt;
    uint feeSpentDpt;
    uint profitSellTokenT;
    uint expectedBalance;
    uint feeSpentDptV;
    uint finalSellV;
    uint finalBuyV;
    uint finalSellT;
    uint finalBuyT;
    uint userDptV;
    uint balanceUserIncreaseT;
    uint balanceUserIncreaseV;
    uint balanceUserDecreaseT;
    uint balanceUserDecreaseV;
    uint actual;
    uint expected;
    address actualA;
    address expectedA;
    bool showActualExpected;
    DSGuard public guard;
    bytes32 constant public ANY = bytes32(uint(-1));
    address origSellerBuyToken;
    address origSellerSellToken;
    uint walDaiBalance;
    uint walEthBalance;
    uint liqDptBalance;
    uint burnerDptBalance;
    uint userCdcBalance;
    uint userDaiBalance;
    uint userEthBalance;

    function setUp() public {
        _createTokens();
        _setErc20Tokens();
        _mintInitialSupply();
        _setUsdRates();
        _setDecimals();
        _setDust();
        _setFeeds();
        _createContracts();
        _createActors();
        _setupGuard();
        _setupCustodian20();
        _setConfigAsm();
        _setConfigExchange();
        _setConfigExchangeExtension();
        _setupConfigRedeemer();
        _approveContracts();
        _mintDpasses();
        _transferToUserAndApproveExchange();
        _storeInitialBalances();
        _logContractAddresses();
    }


    function createDiamond(uint price_) public {
        uint id_;
        Dpass(dpass).setCccc("BR,VVS1,G,10.00", true);
        id_ = Dpass(dpass).mintDiamondTo(
            asm,
            seller,
            "gia",
            "44444444",
            "sale",
            "BR,VVS1,G,10.00",
            10.1 * 100,
            bytes32(0xac5c1daab5131326b23d7f3a4b79bba9f236d227338c5b0fb17494defc319886),
            "20191101"
        );

        SimpleAssetManagement(asm).setBasePrice(dpass, id_, price_);
    }

    function sendSomeCdcToUser() public {
        createDiamond(500000 ether);
        SimpleAssetManagement(asm).mint(cdc, user, wdiv(
            add(
                wdiv(
                    dpassOwnerPrice[asm],
                    sub(1 ether, varFee)),
                fixFee),
            usdRate[cdc]));
        balance[user][cdc] = DSToken(cdc).balanceOf(user);
    }

    function sendSomeCdcToUser(uint256 amt) public {
        createDiamond(500000 ether);
        require(amt <= SimpleAssetManagement(asm).getAmtForSale(cdc), "test-can-not-mint-that-much");
        SimpleAssetManagement(asm).mint(cdc, user, amt);
        balance[user][cdc] = DSToken(cdc).balanceOf(user);
    }

    function balanceOf(address token, address holder) public view returns (uint256) {
        return token == eth ? holder.balance :  DSToken(token).balanceOf(holder);
    }

    function doExchange(address sellToken, uint256 sellAmtOrId, address buyToken, uint256 buyAmtOrId) public {
        uint origUserBalanceT;
        uint buyT;
        uint buyV;
        bool _takeProfitOnlyInDpt = DiamondExchange(exchange).takeProfitOnlyInDpt();
        uint fixFee_;
        uint varFee_;
        origSellerBuyToken = erc20[buyToken] ? address(0) : Dpass(buyToken).ownerOf(buyAmtOrId);
        origSellerSellToken = erc20[sellToken] ? address(0) : Dpass(sellToken).ownerOf(sellAmtOrId);

        origUserBalanceT = balanceOf(sellToken, user);

        sentV = sellAmtOrId == uint(-1) ?
            wmulV(origUserBalanceT, usdRate[sellToken], sellToken) :
            erc20[sellToken] ?
                wmulV(min(sellAmtOrId, origUserBalanceT), usdRate[sellToken], sellToken) :
                dpassOwnerPrice[origSellerSellToken];

        buyT = erc20[buyToken] ?
            DiamondExchange(exchange).handledByAsm(buyToken) ?
                min(buyAmtOrId, SimpleAssetManagement(asm).getAmtForSale(buyToken)) :
                min(
                    buyAmtOrId,
                    balanceOf(buyToken, custodian20[buyToken])) :
            buyAmtOrId;

        buyV = erc20[buyToken] ?
            wmulV(buyT, usdRate[buyToken], buyToken) :
            DiamondExchange(exchange).getPrice(buyToken, buyAmtOrId);

        buySellTokenT = erc20[sellToken] ?
            wdivT(buyV, usdRate[sellToken], sellToken) :
            0;

        fixFee_ = DiamondExchange(exchange).fixFee();
        varFee_ = DiamondExchange(exchange).varFee();

        feeV = add(
            wmul(
                varFee_,
                min(sentV, buyV)),
            fixFee_);

        feeDpt = wdivT(feeV, usdRate[dpt], dpt);

        feeSellTokenT = erc20[sellToken] ?
            wdivT(feeV, usdRate[sellToken], sellToken) :
            0;

        profitV = wmul(feeV, profitRate);

        profitDpt = wdivT(profitV, usdRate[dpt], dpt);

        feeSpentDpt = sellToken == dpt ?
            0 :
            _takeProfitOnlyInDpt ?
                min(userDpt, wdivT(profitV, usdRate[dpt], dpt)) :
                min(userDpt, wdivT(feeV, usdRate[dpt], dpt));

        feeSpentDptV = wmulV(feeSpentDpt, usdRate[dpt], dpt);

        profitSellTokenT = erc20[sellToken] ?
            wdivT(profitV, usdRate[sellToken], sellToken) :
            0;

        if (feeSpentDpt < feeDpt) {

            restOfFeeV = wmulV(sub(feeDpt, feeSpentDpt), usdRate[dpt], dpt);

            restOfFeeDpt = sub(feeDpt, feeSpentDpt);

            restOfFeeT = erc20[sellToken] ?
                wdivT(restOfFeeV, usdRate[sellToken], sellToken) :
                wdivT(restOfFeeV, usdRate[buyToken], buyToken) ;
        }

        finalSellV = sentV;
        finalBuyV = buyV;

        if (sentV - restOfFeeV >= buyV) {

            finalSellV = add(buyV, restOfFeeV);

        } else {

            finalBuyV = sub(sentV, restOfFeeV);
        }

        finalSellT = erc20[sellToken] ?
            wdivT(finalSellV, usdRate[sellToken], sellToken) :
            0;

        finalBuyT = erc20[buyToken] ?
            wdivT(finalBuyV, usdRate[buyToken], buyToken) :
            0;

            emit LogTest("user.balance");
            emit LogTest(user.balance);

        if(erc20[buyToken]) {
            origBuyer = DiamondExchange(exchange).handledByAsm(buyToken) ? asm : custodian20[buyToken];
        } else {
            origBuyer = Dpass(buyToken).ownerOf(buyAmtOrId);
        }

        DiamondExchangeTester(user).doBuyTokensWithFee(
            sellToken,
            sellAmtOrId,
            buyToken,
            buyAmtOrId
        );

        userDptV = wmulV(userDpt, usdRate[dpt], dpt);

        balanceUserIncreaseT = erc20[buyToken] ?
            sub(
                balanceOf(buyToken, user) ,
                balance[user][buyToken]) :
            1;

        balanceUserIncreaseV = erc20[buyToken] ?
            wmulV(
                balanceUserIncreaseT,
                usdRate[buyToken],
                buyToken) :
            dpassOwnerPrice[origSellerBuyToken];

        balanceUserDecreaseT = erc20[sellToken] ?
            sub(
                balance[user][sellToken],
                balanceOf(sellToken, user)) :
            1;

        balanceUserDecreaseV = erc20[sellToken] ?
            wmulV(
                balanceUserDecreaseT,
                usdRate[sellToken],
                sellToken) :
            dpassOwnerPrice[origSellerSellToken];

        emit log_named_uint("---------takeProfitOnlyInDpt", takeProfitOnlyInDpt ? 1 : 0);
        emit log_named_bytes32("----------------sellToken", getName(sellToken));
        logUint("----------sellAmtOrId", sellAmtOrId, 18);
        emit log_named_bytes32("-----------------buyToken", getName(buyToken));
        logUint("-----------buyAmtOrId", buyAmtOrId, 18);
        emit log_bytes32(bytes32("------------------------------"));
        logUint("---------------sentV", sentV, 18);
        logUint("---------------buyV:", buyV, 18);
        logUint("------buySellTokenT:", buySellTokenT, 18);
        logUint("-----feeFixV(fixFee)", fixFee_, 18);
        logUint("-----feeRate(varFee)", varFee_, 18);
        logUint("---------feeV(total)", feeV, 18);
        logUint("-------feeDpt(total)", feeDpt, 18);
        logUint("----------feeT(tot.)", feeSellTokenT, 18);
        logUint("-------------userDpt", userDpt, 18);
        logUint("------------userDptV", userDptV, 18);
        emit log_bytes32(bytes32("------------------------------"));
        logUint("----------profitRate", profitRate, 18);
        logUint("-------------profitV", profitV, 18);
        logUint("-----------profitDpt", profitDpt, 18);
        logUint("-------------profitT", profitSellTokenT, 18);
        logUint("---------feeSpentDpt", feeSpentDpt, 18);
        logUint("--------feeSpentDptV", feeSpentDptV, 18);
        logUint("----------restOfFeeV", restOfFeeV, 18);
        logUint("--------restOfFeeDpt", restOfFeeDpt, 18);
        logUint("----------restOfFeeT", restOfFeeT, 18);
        logUint("balanceUserIncreaseT", balanceUserIncreaseT, 18);
        logUint("balanceUserIncreaseV", balanceUserIncreaseV, 18);
        logUint("balanceUserDecreaseT", balanceUserDecreaseT, 18);
        logUint("balanceUserDecreaseV", balanceUserDecreaseV, 18);


        actual = sub(INITIAL_BALANCE, DSToken(dpt).balanceOf(address(liq)));
        expected = sellToken == dpt ? 0 : sub(profitDpt, _takeProfitOnlyInDpt ? feeSpentDpt : wmul(feeSpentDpt, profitRate));

        assertEqDustLog("dpt from liq", actual, expected, dpt);


        if(erc20[sellToken]) {
            actual = balanceOf(sellToken, address(wal));
            expected = add(balance[wal][sellToken], sub(restOfFeeT, sellToken == dpt ? profitSellTokenT : 0));
        } else {
            actual = balanceOf(buyToken, address(wal));
            expected = add(balance[wal][buyToken], sub(restOfFeeT, buyToken == dpt ? profitSellTokenT : 0));
        }
        assertEqDustLog("sell/buy token as fee to wal", actual, expected, sellToken);


        actual = DSToken(dpt).balanceOf(burner);
        expected = profitDpt;

        assertEqDustLog("dpt to burner", actual, expected, dpt);


        if (erc20[sellToken]) {

            actual = balanceOf(sellToken, origBuyer);

            expected = add(
                balance[origBuyer][sellToken],
                sellToken == cdc && origBuyer == asm ? 0 : sub(finalSellT, restOfFeeT));

            assertEqDustLog("seller bal inc by ERC20 sold", actual, expected, sellToken);
        } else {

            actualA = TrustedErc721(sellToken).ownerOf(sellAmtOrId);

            expectedA = Dpass(sellToken).ownerOf(sellAmtOrId);

            assertEqLog("seller bal inc by ERC721 sold", actualA, expectedA);
        }


        if (erc20[sellToken]) {

            actual = balanceOf(sellToken, user);

            expected = sub( balance[user][sellToken], finalSellT);

            assertEqDustLog("user bal dec by ERC20 sold", actual, expected, sellToken);

        } else {

            actualA = Dpass(sellToken).ownerOf(sellAmtOrId);

            expectedA = user;

            assertNotEqualLog("user not owner of ERC721 sold", actualA, expectedA);
        }


        if (erc20[buyToken]) {

            actual = balanceOf(buyToken, user);

            expected = add(balance[user][buyToken], finalBuyT);

            assertEqDustLog("user bal inc by ERC20 bought", actual, expected, buyToken);

        } else {
            actualA = Dpass(buyToken).ownerOf(buyAmtOrId);
            expectedA = user;
            assertEqLog("user has the ERC721 bought", actualA, expectedA);
        }


        if (erc20[buyToken]) {

            if(DiamondExchange(exchange).handledByAsm(buyToken) ) {
                actual = DSToken(buyToken).balanceOf(asm);
                expected = balance[asm][buyToken];

                assertEqDustLog("seller bal dec by ERC20 bought", actual, expected, buyToken);
            } else {

                actual = balanceOf(buyToken, custodian20[buyToken]);

                expected = sub(
                    balance[custodian20[buyToken]][buyToken],
                    add(balanceUserIncreaseT, !erc20[sellToken] ? restOfFeeT : 0));

                assertEqDustLog("seller bal dec by ERC20 bought", actual, expected, buyToken);
            }
        } else {

            actualA = Dpass(buyToken).ownerOf(buyAmtOrId);
            expectedA = user;

            assertEqLog("seller bal dec by ERC721 bought", actualA, expectedA);

        }


        actual = add(balanceUserIncreaseV, feeV);
        expected = add(balanceUserDecreaseV, feeSpentDptV);

        assertEqDustLog("fees and tokens add up", actual, expected);
    }

    function logMsgActualExpected(bytes32 logMsg, uint256 actual_, uint256 expected_, bool showActualExpected_) public {
        emit log_bytes32(logMsg);
        if(showActualExpected_ || showActualExpected) {
            emit log_bytes32("actual");
            emit LogTest(actual_);
            emit log_bytes32("expected");
            emit LogTest(expected_);
        }
    }

    function logMsgActualExpected(bytes32 logMsg, address actual_, address expected_, bool showActualExpected_) public {
        emit log_bytes32(logMsg);
        if(showActualExpected_ || showActualExpected) {
            emit log_bytes32("actual");
            emit LogTest(actual_);
            emit log_bytes32("expected");
            emit LogTest(expected_);
        }
    }

    function assertEqDustLog(bytes32 logMsg, uint256 actual_, uint256 expected_, address decimalToken) public {
        logMsgActualExpected(logMsg, actual_, expected_, !isEqualDust(actual_, expected_, decimalToken));
        assertEqDust(actual_, expected_, decimalToken);
    }

    function assertEqDustLog(bytes32 logMsg, uint256 actual_, uint256 expected_) public {
        logMsgActualExpected(logMsg, actual_, expected_, !isEqualDust(actual_, expected_));
        assertEqDust(actual_, expected_);
    }

    function assertEqLog(bytes32 logMsg, uint actual_, uint expected_) public {
        logMsgActualExpected(logMsg, actual_, expected_, false);
        assertEq(actual_, expected_);
    }
    function assertEqLog(bytes32 logMsg, address actual_, address expected_) public {
        logMsgActualExpected(logMsg, actual_, expected_, false);
        assertEq(actual_, expected_);
    }

    function assertNotEqualLog(bytes32 logMsg, address actual_, address expected_) public {
        logMsgActualExpected(logMsg, actual_, expected_, actual_ == expected_);
        assertTrue(actual_ != expected_);
    }

    function b(bytes32 a) public pure returns(bytes32) {
        return a;
    }

    function b(address a) public pure returns(bytes32) {
        return bytes32(uint(a));
    }

    function b(uint a) public pure returns(bytes32) {
        return bytes32(a);
    }

    function b(bool a_) public pure returns(bytes32) {
        return a_ ? bytes32(uint(1)) : bytes32(uint(0));
    }





    function assertEqDust(uint a_, uint b_) public {
        assertEqDust(a_, b_, eth);
    }





    function assertEqDust(uint a_, uint b_, address token) public {
        assertTrue(isEqualDust(a_, b_, token));
    }

    function isEqualDust(uint a_, uint b_) public view returns (bool) {
        return isEqualDust(a_, b_, eth);
    }

    function isEqualDust(uint a_, uint b_, address token) public view returns (bool) {
        uint diff = a_ - b_;
        require(dustSet[token], "Dust limit must be set to token.");
        uint dustT = dust[token];
        return diff < dustT || uint(-1) - diff < dustT;
    }

    function getName(address token) public view returns (bytes32 name) {
        if (token == eth) {
            name = "eth";
        } else if (token == dpt) {
            name = "dpt";
        } else if (token == cdc) {
            name = "cdc";
        } else if (token == dai) {
            name = "dai";
        }  else if (token == eng) {
            name = "dai";
        } else if (token == dpass) {
            name = "dpass";
        } else if (token == dpass1) {
            name = "dpass1";
        }

    }

    function logUint(bytes32 what, uint256 num, uint256 dec) public {
        emit LogUintIpartUintFpart( what, num / 10 ** dec, num % 10 ** dec);
    }





    function wmulV(uint256 a_, uint256 b_, address token_) public view returns(uint256) {
        return wmul(toDecimals(a_, getDecimals(token_), 18), b_);
    }




    function wdivT(uint256 a_, uint256 b_, address token_) public view returns(uint256) {
        return wdiv(a_, toDecimals(b_, 18, getDecimals(token_)));
    }




    function getDecimals(address token_) public view returns (uint8) {
        require(decimalsSet[token_], "Token with unset decimals");
        return decimals[token_];
    }




    function toDecimals(uint256 amt_, uint8 srcDec_, uint8 dstDec_) public pure returns (uint256) {
        if (srcDec_ == dstDec_) return amt_;
        if (srcDec_ < dstDec_) return mul(amt_, 10 ** uint256(dstDec_ - srcDec_));
        return amt_ / 10 ** uint256(srcDec_ - dstDec_);
    }






    function b32(address a) public pure returns (bytes32) {
        return bytes32(uint256(a) << 96);
    }






    function b32(uint a) public pure returns (bytes32) {
        return bytes32(a);
    }






    function b32(bool a_) public pure returns (bytes32) {
        return bytes32(uint256(a_ ? 1 : 0));
    }

    function sendToken(address token, address to, uint256 amt) public {
        DSToken(token).transfer(to, amt);
        balance[to][token] = DSToken(token).balanceOf(to);
    }

    function () external payable {
    }

    function _createTokens() internal {
        cdc = address(new Cdc("BR,VS,G,0.05", "CDC"));
        dcdc = address(new Dcdc("BR,VS,G,0.05", "DCDC", true));
        emit log_named_uint("cdc supply", Cdc(cdc).totalSupply());
        dpass = address(new Dpass());
        dpt = address(new DSToken("DPT"));
        dai = address(new DSToken("DAI"));
        eth = address(0xee);
        eng = address(new DSToken("ENG"));
    }

    function _setErc20Tokens() internal {
        erc20[cdc] = true;
        erc20[dpt] = true;
        erc20[dai] = true;
        erc20[eng] = true;
        erc20[eth] = true;
        erc20[dcdc] = true;
    }

    function _mintInitialSupply() internal {
        DSToken(dpt).mint(SUPPLY);
        DSToken(dai).mint(SUPPLY);
        DSToken(eng).mint(SUPPLY);
    }

    function _setUsdRates() internal {
        usdRate[dpt] = 5 ether;
        usdRate[cdc] = 7 ether;
        usdRate[dcdc] = usdRate[cdc];
        usdRate[eth] = 11 ether;
        usdRate[dai] = 13 ether;
        usdRate[eng] = 59 ether;
    }

    function _setDecimals() internal {
        decimals[dpt] = 18;
        decimals[cdc] = 18;
        decimals[dcdc] = 18;
        decimals[eth] = 18;
        decimals[dai] = 18;
        decimals[eng] = 8;

        decimalsSet[dpt] = true;
        decimalsSet[cdc] = true;
        decimalsSet[dcdc] = true;
        decimalsSet[eth] = true;
        decimalsSet[dai] = true;
        decimalsSet[eng] = true;
    }

    function _setDust() internal {
        dust[dpt] = 10000;
        dust[cdc] = 10000;
        dust[dcdc] = dust[cdc];
        dust[eth] = 10000;
        dust[dai] = 10000;
        dust[eng] = 10;
        dust[dpass] = 10000;

        dustSet[dpt] = true;
        dustSet[cdc] = true;
        dustSet[eth] = true;
        dustSet[dai] = true;
        dustSet[eng] = true;
        dustSet[dpass] = true;

    }

    function _setFeeds() internal {
        feed[eth] = address(new TestFeedLike(usdRate[eth], true));
        feed[dpt] = address(new TestFeedLike(usdRate[dpt], true));
        feed[cdc] = address(new TestFeedLike(usdRate[cdc], true));
        feed[dcdc] = address(new TestFeedLike(usdRate[cdc], true));
        feed[dai] = address(new TestFeedLike(usdRate[dai], true));
        feed[eng] = address(new TestFeedLike(usdRate[eng], true));
    }

    function _createContracts() internal {
        burner = address(uint160(address(new Burner(DSToken(dpt)))));
        wal = address(uint160(address(new DptTester(DSToken(dai)))));
        asm = address(uint160(address(new SimpleAssetManagement())));

        uint ourGas = gasleft();
        emit LogTest("cerate DiamondExchange");
        exchange = address(uint160(address(new DiamondExchange())));
        dee = address(uint160(address(new DiamondExchangeExtension())));
        red = address(uint160(address(new Redeemer())));
        emit LogTest(ourGas - gasleft());

        liq = address(uint160(address(new DiamondExchangeTester(exchange, dpt, cdc, dai))));
        DSToken(dpt).transfer(liq, INITIAL_BALANCE);

        fca = address(uint160(address(new TestFeeCalculator())));
    }

    function _setupGuard() internal {
        guard = new DSGuard();
        SimpleAssetManagement(asm).setAuthority(guard);
        SimpleAssetManagement(exchange).setAuthority(guard);
        DSToken(cdc).setAuthority(guard);
        DSToken(dcdc).setAuthority(guard);
        Dpass(dpass).setAuthority(guard);
        guard.permit(address(this), address(asm), ANY);
        guard.permit(address(asm), cdc, ANY);
        guard.permit(address(asm), dcdc, ANY);
        guard.permit(address(asm), dpass, ANY);
        guard.permit(exchange, asm, ANY);
        guard.permit(red, exchange, ANY);
        guard.permit(red, asm, ANY);
        guard.permit(dee, exchange, ANY);
        guard.permit(custodian, asm, ANY);


        DiamondExchangeTester(liq).setAuthority(guard);
        guard.permit(exchange, liq, ANY);
        DiamondExchangeTester(liq).setOwner(exchange);
    }

    function _setupCustodian20() internal {
        custodian20[dpt] = asm;
        custodian20[cdc] = asm;
        custodian20[eth] = asm;
        custodian20[dai] = asm;
        custodian20[eng] = asm;
    }

    function _setConfigAsm() internal {

        SimpleAssetManagement(asm).setConfig("dex", b(exchange), "", "diamonds");
        SimpleAssetManagement(asm).setConfig("overCollRatio", b(1.1 ether), "", "diamonds");
        SimpleAssetManagement(asm).setConfig("priceFeed", b(cdc), b(feed[cdc]), "diamonds");
        SimpleAssetManagement(asm).setConfig("priceFeed", b(dcdc), b(feed[dcdc]), "diamonds");
        SimpleAssetManagement(asm).setConfig("priceFeed", b(dai), b(feed[dai]), "diamonds");
        SimpleAssetManagement(asm).setConfig("priceFeed", b(eth), b(feed[eth]), "diamonds");
        SimpleAssetManagement(asm).setConfig("priceFeed", b(dpt), b(feed[dpt]), "diamonds");
        SimpleAssetManagement(asm).setConfig("priceFeed", b(eng), b(feed[eng]), "diamonds");

        SimpleAssetManagement(asm).setConfig("manualRate", b(cdc), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("manualRate", b(dcdc), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("manualRate", b(dai), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("manualRate", b(eth), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("manualRate", b(dpt), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("manualRate", b(eng), b(true), "diamonds");

        SimpleAssetManagement(asm).setConfig("decimals", b(cdc), b(decimals[cdc]), "diamonds");
        SimpleAssetManagement(asm).setConfig("decimals", b(dcdc), b(decimals[cdc]), "diamonds");
        SimpleAssetManagement(asm).setConfig("decimals", b(dai), b(decimals[dai]), "diamonds");
        SimpleAssetManagement(asm).setConfig("decimals", b(eth), b(decimals[eth]), "diamonds");
        SimpleAssetManagement(asm).setConfig("decimals", b(dpt), b(decimals[dpt]), "diamonds");
        SimpleAssetManagement(asm).setConfig("decimals", b(eng), b(decimals[eng]), "diamonds");

        SimpleAssetManagement(asm).setConfig("cdcs", b(cdc), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("dcdcs", b(dcdc), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("dpasses", b(dpass), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("payTokens", b(cdc), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("payTokens", b(dai), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("payTokens", b(eth), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("payTokens", b(dpt), b(true), "diamonds");
        SimpleAssetManagement(asm).setConfig("payTokens", b(eng), b(true), "diamonds");

        SimpleAssetManagement(asm).setConfig("rate", b(cdc), b(usdRate[cdc]), "diamonds");
        SimpleAssetManagement(asm).setConfig("rate", b(dcdc), b(usdRate[dcdc]), "diamonds");
        SimpleAssetManagement(asm).setConfig("rate", b(dai), b(usdRate[dai]), "diamonds");
        SimpleAssetManagement(asm).setConfig("rate", b(eth), b(usdRate[eth]), "diamonds");
        SimpleAssetManagement(asm).setConfig("rate", b(dpt), b(usdRate[dpt]), "diamonds");
        SimpleAssetManagement(asm).setConfig("rate", b(eng), b(usdRate[eng]), "diamonds");

        SimpleAssetManagement(asm).setConfig("custodians", b(seller), b(true), "diamonds");
        SimpleAssetManagement(asm).setCapCustV(seller, 1000000 ether);
        SimpleAssetManagement(asm).setConfig("setApproveForAll", b(dpass), b(exchange), b(true));

        SimpleAssetManagement(asm).setConfig("custodians", b(custodian), b(true), "diamonds");
        SimpleAssetManagement(asm).setCapCustV(custodian, 1000000 ether);
        SimpleAssetManagement(asm).setConfig("setApproveForAll", b(dpass), b(exchange), b(true));
    }

    function _setConfigExchange() internal {
        DiamondExchange(exchange).setConfig("decimals", b(dpt), b(18));
        DiamondExchange(exchange).setConfig("decimals", b(cdc), b(18));
        DiamondExchange(exchange).setConfig("decimals", b(eth), b(18));
        DiamondExchange(exchange).setConfig("canSellErc20", b(dpt), b(true));
        DiamondExchange(exchange).setConfig("canBuyErc20", b(dpt), b(true));
        DiamondExchange(exchange).setConfig("canSellErc20", b(cdc), b(true));
        DiamondExchange(exchange).setConfig("canBuyErc20", b(cdc), b(true));
        DiamondExchange(exchange).setConfig("canSellErc20", b(eth), b(true));
        DiamondExchange(exchange).setConfig("canBuyErc721", b(dpass), b(true));
        DiamondExchange(exchange).setConfig("dpt", b(dpt), b(""));
        DiamondExchange(exchange).setConfig("cdc", b(cdc), b(""));
        DiamondExchange(exchange).setConfig("handledByAsm", b(cdc), b(true));
        DiamondExchange(exchange).setConfig("handledByAsm", b(dpass), b(true));
        DiamondExchange(exchange).setConfig("priceFeed", b(dpt), b(feed[dpt]));
        DiamondExchange(exchange).setConfig("priceFeed", b(eth), b(feed[eth]));
        DiamondExchange(exchange).setConfig("priceFeed", b(cdc), b(feed[cdc]));
        DiamondExchange(exchange).setConfig("liq", b(liq), b(""));
        DiamondExchange(exchange).setConfig("burner", b(burner), b(""));
        DiamondExchange(exchange).setConfig("asm", b(asm), b(""));
        DiamondExchange(exchange).setConfig("fixFee", b(fixFee), b(""));
        DiamondExchange(exchange).setConfig("varFee", b(varFee), b(""));
        DiamondExchange(exchange).setConfig("profitRate", b(profitRate), b(""));
        DiamondExchange(exchange).setConfig("wal", b(wal), b(""));

        DiamondExchange(exchange).setConfig(b("decimals"), b(dai), b(18));
        DiamondExchange(exchange).setConfig(b("canSellErc20"), b(dai), b(true));
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(dai), b(feed[dai]));
        DiamondExchange(exchange).setConfig(b("rate"), b(dai), b(usdRate[dai]));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(dai), b(true));
        DiamondExchange(exchange).setConfig(b("custodian20"), b(dai), b(custodian20[dai]));


        DiamondExchange(exchange).setConfig(b("decimals"), b(eth), b(18));
        DiamondExchange(exchange).setConfig(b("canSellErc20"), b(eth), b(true));
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(eth), b(feed[eth]));
        DiamondExchange(exchange).setConfig(b("rate"), b(eth), b(usdRate[eth]));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(eth), b(true));
        DiamondExchange(exchange).setConfig(b("custodian20"), b(eth), b(custodian20[eth]));


        DiamondExchange(exchange).setConfig(b("canSellErc20"), b(cdc), b(true));
        DiamondExchange(exchange).setConfig(b("canBuyErc20"), b(cdc), b(true));
        DiamondExchange(exchange).setConfig(b("custodian20"), b(cdc), b(custodian20[cdc]));
        DiamondExchange(exchange).setConfig(b("decimals"), b(cdc), b(18));
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(cdc), b(feed[cdc]));
        DiamondExchange(exchange).setConfig(b("rate"), b(cdc), b(usdRate[cdc]));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(cdc), b(true));
        DiamondExchange(exchange).setConfig(b("handledByAsm"), b(cdc), b(true));

        DiamondExchange(exchange).setConfig(b("decimals"), b(dpt), b(18));
        DiamondExchange(exchange).setConfig(b("canSellErc20"), b(dpt), b(true));
        DiamondExchange(exchange).setConfig(b("custodian20"), b(dpt), b(asm));
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(dpt), b(feed[dpt]));
        DiamondExchange(exchange).setConfig(b("rate"), b(dpt), b(usdRate[dpt]));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(dpt), b(true));
        DiamondExchange(exchange).setConfig(b("custodian20"), b(dpt), b(custodian20[dpt]));
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(takeProfitOnlyInDpt)), b(""));

        DiamondExchange(exchange).setConfig(b("decimals"), b(eng), b(8));
        DiamondExchange(exchange).setConfig(b("canSellErc20"), b(eng), b(true));
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(eng), b(feed[eng]));
        DiamondExchange(exchange).setConfig(b("rate"), b(eng), b(usdRate[eng]));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(eng), b(true));
        DiamondExchange(exchange).setConfig(b("custodian20"), b(eng), b(custodian20[eng]));

        DiamondExchange(exchange).setConfig(b("liq"), b(liq), b(""));
        DiamondExchange(exchange).setConfig(b("redeemFeeToken"), b(cdc), b(true));
        DiamondExchange(exchange).setConfig(b("redeemFeeToken"), b(dpt), b(true));
        DiamondExchange(exchange).setConfig(b("redeemFeeToken"), b(dai), b(true));
        DiamondExchange(exchange).setConfig(b("redeemer"), b(red), "");
    }

    function _setConfigExchangeExtension() internal {
        DiamondExchangeExtension(dee).setConfig("asm", b(asm), "");
        DiamondExchangeExtension(dee).setConfig("dex", b(exchange), "");
        DiamondExchangeExtension(dee).setConfig("dust", b(dust[eth]), "");
    }

    function _setupConfigRedeemer() internal {
        Redeemer(red).setConfig("asm", b(asm), "", "");
        Redeemer(red).setConfig("dex", b(exchange), "", "");
        Redeemer(red).setConfig("burner", b(burner), "", "");
        Redeemer(red).setConfig("wal", b(wal), "", "");
        Redeemer(red).setConfig("dpt", b(dpt), "", "");
        Redeemer(red).setConfig("liq", b(liq), "", "");
        Redeemer(red).setConfig("varFee", b(varFeeRedeem), "", "");
        Redeemer(red).setConfig("fixFee", b(fixFeeRedeem), "", "");
        Redeemer(red).setConfig("profitRate", b(profitRateRedeem), "", "");
        Redeemer(red).setConfig("dcdcOfCdc", b(cdc), b(dcdc), "");
        Redeemer(red).setConfig("dust", b(dust[dcdc]), "", "");
    }

    function _createActors() internal {

        user = address(uint160(address(new DiamondExchangeTester(exchange, dpt, cdc, dai))));
        seller = address(uint160(address(new DiamondExchangeTester(exchange, dpt, cdc, dai))));
        custodian = address(uint160(address(new DiamondExchangeTester(exchange, dpt, cdc, dai))));
    }

    function _approveContracts()  internal {
        Cdc(cdc).approve(exchange, uint(-1));
        DSToken(dpt).approve(exchange, uint(-1));
        DSToken(dai).approve(exchange, uint(-1));
        DSToken(eng).approve(exchange, uint(-1));
        DiamondExchangeTester(liq).doApprove(dpt, exchange, uint(-1));
        DiamondExchangeTester(liq).doApprove(dpt, red, uint(-1));
    }

    function _mintDpasses() internal {

        dpassOwnerPrice[user] = 53 ether;
        Dpass(dpass).setCccc("BR,IF,F,0.01", true);
        dpassId[user] = Dpass(dpass).mintDiamondTo(
            user,
            seller,
            "gia",
            "2141438167",
            "sale",
            "BR,IF,F,0.01",
            0.2 * 100,
            bytes32(uint(0xc0a5d062e13f99c8f70d19dc7993c2f34020a7031c17f29ce2550315879006d7)),
            "20191101"
        );
        SimpleAssetManagement(asm).setBasePrice(dpass, dpassId[user], dpassOwnerPrice[user]);

        dpassOwnerPrice[asm] = 137 ether;
        Dpass(dpass).setCccc("BR,VVS1,F,3.00", true);
        dpassId[seller] = Dpass(dpass).mintDiamondTo(
            asm,
            seller,
            "gia",
            "2141438168",
            "sale",
            "BR,VVS1,F,3.00",
            3.1 * 100,
            bytes32(0xac5c1daab5131326b23d7f3a4b79bba9f236d227338c5b0fb17494defc319886),
            "20191101"
        );

        SimpleAssetManagement(asm).setBasePrice(dpass, dpassId[seller], dpassOwnerPrice[asm]);
        DiamondExchangeTester(custodian).doMintDcdc(asm, dcdc, custodian, 100 ether);
    }

    function _transferToUserAndApproveExchange() internal {
        user.transfer(INITIAL_BALANCE);
        DSToken(dai).transfer(user, INITIAL_BALANCE);
        DSToken(eng).transfer(user, INITIAL_BALANCE);

        DiamondExchangeTester(user).doApprove(dpt, exchange, uint(-1));
        DiamondExchangeTester(user).doApprove(cdc, exchange, uint(-1));
        DiamondExchangeTester(user).doApprove(dai, exchange, uint(-1));

    }

    function _storeInitialBalances() internal {
        balance[address(this)][eth] = address(this).balance;
        balance[user][eth] = user.balance;
        balance[user][cdc] = Cdc(cdc).balanceOf(user);
        balance[user][dpt] = DSToken(dpt).balanceOf(user);
        balance[user][dai] = DSToken(dai).balanceOf(user);

        balance[asm][eth] = asm.balance;
        balance[asm][cdc] = Cdc(cdc).balanceOf(asm);
        balance[asm][dpt] = DSToken(dpt).balanceOf(asm);
        balance[asm][dai] = DSToken(dai).balanceOf(asm);

        balance[liq][eth] = liq.balance;
        balance[wal][eth] = wal.balance;
        balance[custodian20[eth]][eth] = custodian20[eth].balance;
        balance[custodian20[cdc]][cdc] = Cdc(cdc).balanceOf(custodian20[cdc]);
        balance[custodian20[dpt]][dpt] = DSToken(dpt).balanceOf(custodian20[dpt]);
        balance[custodian20[dai]][dai] = DSToken(dai).balanceOf(custodian20[dai]);

    }

    function _logContractAddresses() internal {
        emit log_named_address("exchange", exchange);
        emit log_named_address("dpt", dpt);
        emit log_named_address("cdc", cdc);
        emit log_named_address("asm", asm);
        emit log_named_address("user", user);
        emit log_named_address("seller", seller);
        emit log_named_address("custodian", custodian);
        emit log_named_address("wal", wal);
        emit log_named_address("liq", liq);
        emit log_named_address("burner", burner);
        emit log_named_address("this", address(this));
    }

}




contract TestFeeCalculator is DSMath {
    uint public fee;

    function calculateFee(
        address sender,
        uint256 value,
        address sellToken,
        uint256 sellAmtOrId,
        address buyToken,
        uint256 buyAmtOrId
    ) public view returns (uint256) {
        if (sender == address(0x0)) {return 0;}
        if (sellToken == address(0x0)) {return 0;}
        if (buyToken == address(0x0)) {return 0;}
        return add(add(add(value, sellAmtOrId), buyAmtOrId), fee);
    }

    function setFee(uint fee_) public {
        fee = fee_;
    }
}


contract TestFeedLike {
    bytes32 public rate;
    bool public feedValid;

    constructor(uint rate_, bool feedValid_) public {
        require(rate_ > 0, "TestFeedLike: Rate must be > 0");
        rate = bytes32(rate_);
        feedValid = feedValid_;
    }

    function peek() public view returns (bytes32, bool) {
        return (rate, feedValid);
    }

    function setRate(uint rate_) public {
        rate = bytes32(rate_);
    }

    function setValid(bool feedValid_) public {
        feedValid = feedValid_;
    }
}


contract DptTester {
    DSToken public _dpt;

    constructor(DSToken dpt) public {
        require(address(dpt) != address(0), "CET: dpt 0x0 invalid");
        _dpt = dpt;
    }

    function doApprove(address to, uint amount) public {
        DSToken(_dpt).approve(to, amount);
    }

    function doTransfer(address to, uint amount) public {
        DSToken(_dpt).transfer(to, amount);
    }

    function () external payable {
    }
}


contract DiamondExchangeTester is Wallet, DSTest {
    event LogTest(uint256 what);
    event LogTest(bool what);
    event LogTest(address what);
    event LogTest(bytes32 what);

    DiamondExchange public exchange;

    DSToken public _dpt;
    DSToken public _cdc;
    DSToken public _dai;

    constructor(address payable exchange_, address dpt, address cdc, address dai) public {
        require(exchange_ != address(0), "CET: exchange 0x0 invalid");
        require(dpt != address(0), "CET: dpt 0x0 invalid");
        require(cdc != address(0), "CET: cdc 0x0 invalid");
        require(dai != address(0), "CET: dai 0x0 invalid");
        exchange = DiamondExchange(exchange_);
        _dpt = DSToken(dpt);
        _cdc = DSToken(cdc);
        _dai = DSToken(dai);
    }

    function () external payable {
    }

    function doApprove(address token, address to, uint amount) public {
        require(token != address(0), "Can't approve token of 0x0");
        require(to != address(0), "Can't approve address of 0x0");
        DSToken(token).approve(to, amount);
    }

    function doApprove721(address token, address to, uint amount) public {
        require(token != address(0), "Can't approve token of 0x0");
        require(to != address(0), "Can't approve address of 0x0");
        Dpass(token).approve(to, amount);
    }

    function doTransfer(address token, address to, uint amount) public {
        DSToken(token).transfer(to, amount);
    }

    function doTransferFrom(address token, address from, address to, uint amount) public {
        DSToken(token).transferFrom(from, to, amount);
    }

    function doTransfer721(address token, address to, uint id) public {
        Dpass(token).transferFrom(address(this), to, id);
    }

    function doTransferFrom721(address token, address from, address to, uint amount) public {
        Dpass(token).transferFrom(from, to, amount);
    }

    function doSetState(address token, uint256 tokenId, bytes8 state) public {
        Dpass(token).setState(state, tokenId);
    }

    function doSetBuyPrice(address token, uint256 tokenId, uint256 price) public {
        DiamondExchange(exchange).setBuyPrice(token, tokenId, price);
    }

    function doGetBuyPrice(address token, uint256 tokenId) public view returns(uint256) {
        return DiamondExchange(exchange).getBuyPrice(token, tokenId);
    }

    function doBuyTokensWithFee(
        address sellToken,
        uint256 sellAmtOrId,
        address buyToken,
        uint256 buyAmtOrId
    ) public payable logs_gas {
        if (sellToken == address(0xee)) {

            DiamondExchange(exchange)
            .buyTokensWithFee
            .value(sellAmtOrId == uint(-1) ? address(this).balance : sellAmtOrId > address(this).balance ? address(this).balance : sellAmtOrId)
            (sellToken, sellAmtOrId, buyToken, buyAmtOrId);

        } else {

            DiamondExchange(exchange).buyTokensWithFee(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
        }
    }

    function doRedeem(
        address redeemToken_,
        uint256 redeemAmtOrId_,
        address feeToken_,
        uint256 feeAmt_,
        address payable custodian_
    ) public payable returns (uint) {
        if (feeToken_ == address(0xee)) {

            return  DiamondExchange(exchange)
                .redeem
                .value(feeAmt_ == uint(-1) ? address(this).balance : feeAmt_ > address(this).balance ? address(this).balance : feeAmt_)

                (redeemToken_,
                redeemAmtOrId_,
                feeToken_,
                feeAmt_,
                custodian_);
        } else {
            return  DiamondExchange(exchange).redeem(
                redeemToken_,
                redeemAmtOrId_,
                feeToken_,
                feeAmt_,
                custodian_);
        }
    }

    function doSetConfig(bytes32 what, address value_, address value1_) public { doSetConfig(what, b32(value_), b32(value1_)); }
    function doSetConfig(bytes32 what, address value_, bytes32 value1_) public { doSetConfig(what, b32(value_), value1_); }
    function doSetConfig(bytes32 what, address value_, uint256 value1_) public { doSetConfig(what, b32(value_), b32(value1_)); }
    function doSetConfig(bytes32 what, address value_, bool value1_) public { doSetConfig(what, b32(value_), b32(value1_)); }
    function doSetConfig(bytes32 what, uint256 value_, address value1_) public { doSetConfig(what, b32(value_), b32(value1_)); }
    function doSetConfig(bytes32 what, uint256 value_, bytes32 value1_) public { doSetConfig(what, b32(value_), value1_); }
    function doSetConfig(bytes32 what, uint256 value_, uint256 value1_) public { doSetConfig(what, b32(value_), b32(value1_)); }
    function doSetConfig(bytes32 what, uint256 value_, bool value1_) public { doSetConfig(what, b32(value_), b32(value1_)); }

    function doSetConfig(bytes32 what_, bytes32 value_, bytes32 value1_) public {
        DiamondExchange(exchange).setConfig(what_, value_, value1_);
    }

    function doGetDecimals(address token_) public view returns(uint8) {
        return DiamondExchange(exchange).getDecimals(token_);
    }






    function b32(address a) public pure returns (bytes32) {
        return bytes32(uint256(a));
    }






    function b32(uint a) public pure returns (bytes32) {
        return bytes32(a);
    }






    function b32(bool a_) public pure returns (bytes32) {
        return bytes32(uint256(a_ ? 1 : 0));
    }




    function addr(bytes32 b) public pure returns (address) {
        return address(uint160(uint256(b)));
    }

    function doCalculateFee(
        address sender_,
        uint256 value_,
        address sellToken_,
        uint256 sellAmtOrId_,
        address buyToken_,
        uint256 buyAmtOrId_
    ) public view returns (uint256) {
        return DiamondExchange(exchange).calculateFee(sender_, value_, sellToken_, sellAmtOrId_, buyToken_, buyAmtOrId_);
    }

    function doGetRate(address token_) public view returns (uint rate_) {
        return DiamondExchange(exchange).getRate(token_);
    }

    function doGetLocalRate(address token_) public view returns (uint rate_) {
        return DiamondExchange(exchange).getRate(token_);
    }

    function doMintDcdc(address payable asm_, address token_, address dst_, uint256 amt_) public {
        SimpleAssetManagement(asm_).mintDcdc(token_, dst_, amt_);
    }
}




contract TrustedDiamondExchange {

    function _getValues(
        address sellToken,
        uint256 sellAmtOrId,
        address buyToken,
        uint256 buyAmtOrId
    ) external returns (uint256 buyV, uint256 sellV);

    function _takeFee(
        uint256 fee,
        uint256 sellV,
        uint256 buyV,
        address sellToken,
        uint256 sellAmtOrId,
        address buyToken,
        uint256 buyAmtOrId
    )
    external
    returns(uint256 sellT, uint256 buyT);

    function _transferTokens(
        uint256 sellT,
        uint256 buyT,
        address sellToken,
        uint256 sellAmtOrId,
        address buyToken,
        uint256 buyAmtOrId,
        uint256 feeV
    ) external;

    function _getNewRate(address token_) external view returns (uint rate_);
    function _updateRates(address sellToken, address buyToken) external;

    function _logTrade(
        address sellToken,
        uint256 sellT,
        address buyToken,
        uint256 buyT,
        uint256 buyAmtOrId,
        uint256 fee
    ) external;

    function _updateRate(address token) external returns (uint256 rate_);

    function _takeFeeInToken(
        uint256 fee,
        uint256 feeTaken,
        address token,
        address src,
        uint256 amountToken
    ) external;

    function _takeFeeInDptFromUser(
        uint256 fee
    ) external returns(uint256 feeTaken);

    function _sendToken(
        address token,
        address src,
        address payable dst,
        uint256 amount
    ) external returns(bool);
}



















contract DiamondExchangeTest is DiamondExchangeSetup {


    function testCalculateFeeDex() public {
        uint valueV = 1 ether;

        uint expectedFeeV = add(fixFee, wmul(varFee, valueV));


        assertEq(DiamondExchange(exchange).calculateFee(
            address(this),
            valueV,
            address(0x0),
            0,
            address(0x0),
            0
        ), expectedFeeV);
    }

    function testSetFixFeeDex() public {
        uint fee = 0.1 ether;
        DiamondExchange(exchange).setConfig(b("fixFee"), b(fee), b(""));
        assertEq(DiamondExchange(exchange).calculateFee(
            address(this),
            0 ether,
            address(0x0),
            0,
            address(0x0),
            0
        ), fee);
    }

    function testSetVarFeeDex() public {
        uint fee = 0.5 ether;
        DiamondExchange(exchange).setConfig(b("varFee"), b(fee), b(""));
        assertEq(DiamondExchange(exchange).calculateFee(
            address(this),
            1 ether,
            address(0x0),
            0,
            address(0x0),
            0
        ), fee);
    }

    function testSetVarAndFixFeeDex() public {
        uint value = 1 ether;
        uint varFee1 = 0.5 ether;
        uint fixFee1 = uint(10) / uint(3) * 1 ether;
        DiamondExchange(exchange).setConfig(b("varFee"), b(varFee1), b(""));
        DiamondExchange(exchange).setConfig(b("fixFee"), b(fixFee1), b(""));
        assertEq(DiamondExchange(exchange).calculateFee(
            address(this),
            value,
            address(0x0),
            0,
            address(0x0),
            0
        ), add(fixFee1, wmul(varFee1, value)));
    }

    function testFailNonOwnerSetVarFeeDex() public {

        uint newFee = 0.1 ether;
        DiamondExchangeTester(user).doSetConfig("varFee", newFee, "");
    }

    function testFailNonOwnerSetFixFeeDex() public {

        uint newFee = 0.1 ether;
        DiamondExchangeTester(user).doSetConfig("fixFee", newFee, "");
    }

    function testSetEthPriceFeedDex() public {
        address token = eth;
        uint rate = 1 ether;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(feed[dai]));
        TestFeedLike(feed[dai]).setRate(rate);
        assertEq(DiamondExchange(exchange).getRate(token), rate);
    }

    function testSetDptPriceFeedDex() public {
        address token = dpt;
        uint rate = 2 ether;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(feed[dai]));
        TestFeedLike(feed[dai]).setRate(rate);
        assertEq(DiamondExchange(exchange).getRate(token), rate);
    }

    function testSetCdcPriceFeedDex() public {
        address token = cdc;
        uint rate = 4 ether;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(feed[dai]));
        TestFeedLike(feed[dai]).setRate(rate);
        assertEq(DiamondExchange(exchange).getRate(token), rate);
    }

    function testSetDaiPriceFeedDex() public {
        address token = dai;
        uint rate = 5 ether;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(feed[dai]));
        TestFeedLike(feed[dai]).setRate(rate);
        assertEq(DiamondExchange(exchange).getRate(token), rate);
    }

    function testFailWrongAddressSetPriceFeedDex() public {

        address token = eth;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(address(0)));
    }

    function testFailNonOwnerSetEthPriceFeedDex() public {

        address token = eth;
        DiamondExchangeTester(user).doSetConfig("priceFeed", token, address(0));
    }

    function testFailWrongAddressSetDptPriceFeedDex() public {

        address token = dpt;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(address(0)));
    }

    function testFailWrongAddressSetCdcPriceFeedDex() public {

        address token = cdc;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(address(0)));
    }

    function testFailNonOwnerSetCdcPriceFeedDex() public {

        address token = cdc;
        DiamondExchangeTester(user).doSetConfig("priceFeed", token, address(0));
    }

    function testSetLiquidityContractDex() public {
        DSToken(dpt).transfer(user, 100 ether);
        DiamondExchange(exchange).setConfig(b("liq"), b(user), b(""));
        assertEq(DiamondExchange(exchange).liq(), user);
    }

    function testFailWrongAddressSetLiquidityContractDex() public {

        DiamondExchange(exchange).setConfig(b("liq"), b(address(0x0)), b(""));
    }

    function testFailNonOwnerSetLiquidityContractDex() public {

        DSToken(dpt).transfer(user, 100 ether);
        DiamondExchangeTester(user).doSetConfig("liq", user, "");
    }

    function testFailWrongAddressSetWalletContractDex() public {

        DiamondExchange(exchange).setConfig(b("wal"), b(address(0x0)), b(""));
    }

    function testFailNonOwnerSetWalletContractDex() public {

        DiamondExchangeTester(user).doSetConfig("wal", user, "");
    }

    function testSetManualDptRateDex() public {
        DiamondExchange(exchange).setConfig(b("manualRate"), b(dpt), b(true));
        assertTrue(DiamondExchange(exchange).manualRate(dpt));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(dpt), b(false));
        assertTrue(!DiamondExchange(exchange).manualRate(dpt));
    }

    function testSetManualCdcRateDex() public {
        DiamondExchange(exchange).setConfig(b("manualRate"), b(cdc), b(true));
        assertTrue(DiamondExchange(exchange).manualRate(cdc));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(cdc), b(false));
        assertTrue(!DiamondExchange(exchange).manualRate(cdc));
    }

    function testSetManualEthRateDex() public {
        DiamondExchange(exchange).setConfig(b("manualRate"), b(address(0xee)), b(true));
        assertTrue(DiamondExchange(exchange).manualRate(address(0xee)));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(address(0xee)), b(false));
        assertTrue(!DiamondExchange(exchange).manualRate(address(0xee)));
    }

    function testSetManualDaiRateDex() public {
        DiamondExchange(exchange).setConfig(b("manualRate"), b(dai), b(true));
        assertTrue(DiamondExchange(exchange).manualRate(dai));
        DiamondExchange(exchange).setConfig(b("manualRate"), b(dai), b(false));
        assertTrue(!DiamondExchange(exchange).manualRate(dai));
    }

    function testFailNonOwnerSetManualDptRateDex() public {
        DiamondExchangeTester(user).doSetConfig("manualRate", dpt, false);
    }

    function testFailNonOwnerSetManualCdcRateDex() public {

        DiamondExchangeTester(user).doSetConfig("manualRate", cdc, false);
    }

    function testFailNonOwnerSetManualEthRateDex() public {

        DiamondExchangeTester(user).doSetConfig("manualRate", address(0xee), false);
    }

    function testFailNonOwnerSetManualDaiRateDex() public {

        DiamondExchangeTester(user).doSetConfig("manualRate", dai, false);
    }

    function testSetFeeCalculatorContractDex() public {
        DiamondExchange(exchange).setConfig(b("fca"), b(address(fca)), b(""));
        assertEq(address(DiamondExchange(exchange).fca()), address(fca));
    }

    function testFailWrongAddressSetCfoDex() public {

        DiamondExchange(exchange).setConfig(b("fca"), b(address(0)), b(""));
    }

    function testFailNonOwnerSetCfoDex() public {

        DiamondExchangeTester(user).doSetConfig("fca", user, "");
    }

    function testSetDptUsdRateDex() public {
        uint newRate = 5 ether;
        DiamondExchange(exchange).setConfig(b("rate"), b(dpt), b(newRate));
        assertEq(DiamondExchange(exchange).getLocalRate(dpt), newRate);
    }

    function testFailIncorectRateSetDptUsdRateDex() public {

        DiamondExchange(exchange).setConfig(b("rate"), b(dpt), b(uint(0)));
    }

    function testFailNonOwnerSetDptUsdRateDex() public {

        uint newRate = 5 ether;
        DiamondExchangeTester(user).doSetConfig("rate", dpt, newRate);
    }

    function testSetCdcUsdRateDex() public {
        uint newRate = 5 ether;
        DiamondExchange(exchange).setConfig(b("rate"), b(cdc), b(newRate));
        assertEq(DiamondExchange(exchange).getLocalRate(cdc), newRate);
    }

    function testFailIncorectRateSetCdcUsdRateDex() public {

        DiamondExchange(exchange).setConfig(b("rate"), b(cdc), b(uint(0)));
    }

    function testFailNonOwnerSetCdcUsdRateDex() public {

        uint newRate = 5 ether;
        DiamondExchangeTester(user).doSetConfig("rate", cdc, newRate);
    }

    function testSetEthUsdRateDex() public {
        uint newRate = 5 ether;
        DiamondExchange(exchange).setConfig(b("rate"), b(eth), b(newRate));
        assertEq(DiamondExchange(exchange).getLocalRate(eth), newRate);
    }

    function testFailIncorectRateSetEthUsdRateDex() public {

        DiamondExchange(exchange).setConfig(b("rate"), b(eth), b(uint(0)));
    }

    function testFailNonOwnerSetEthUsdRateDex() public {

        uint newRate = 5 ether;
        DiamondExchangeTester(user).doSetConfig("rate", eth, newRate);
    }

    function testFailInvalidDptFeedAndManualDisabledBuyTokensWithFeeDex() public logs_gas {

        uint sentEth = 1 ether;

        DiamondExchange(exchange).setConfig(b("manualRate"), b(dpt), b(false));

        TestFeedLike(feed[dpt]).setValid(false);

        DiamondExchange(exchange).buyTokensWithFee(dpt, sentEth, cdc, uint(-1));
    }

    function testFailInvalidEthFeedAndManualDisabledBuyTokensWithFeeDex() public logs_gas {

        uint sentEth = 1 ether;

        DiamondExchange(exchange).setConfig(b("manualRate"), b(eth), b(false));

        TestFeedLike(feed[eth]).setValid(false);

        DiamondExchange(exchange).buyTokensWithFee.value(sentEth)(eth, sentEth, cdc, uint(-1));
    }

    function testFailInvalidCdcFeedAndManualDisabledBuyTokensWithFeeDex() public {

        uint sentEth = 1 ether;

        DiamondExchange(exchange).setConfig(b("manualRate"), b(cdc), b(false));

        TestFeedLike(feed[cdc]).setValid(false);

        DiamondExchange(exchange).buyTokensWithFee(cdc, sentEth, cdc, uint(-1));
    }

    function testForFixEthBuyAllCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 41 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testFailForFixEthBuyAllCdcUserDptNotZeroNotEnoughDex() public {

        DiamondExchange(exchange).setConfig(b("canBuyErc20"), b(cdc), b(false));

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixEthBuyAllCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixEthBuyAllCdcUserDptEnoughDex() public {
        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 27 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllEthBuyAllCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForAllEthBuyAllCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }
    function testForAllEthBuyAllCdcUserDptEnoughDex() public {
        userDpt = 3000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }
    function testForAllEthBuyFixCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForAllEthBuyFixCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllEthBuyFixCdcUserDptEnoughDex() public {
        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixEthBuyFixCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixEthBuyFixCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixEthBuyFixCdcUserDptEnoughDex() public {
        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForFixEthBuyFixCdcUserHasNoDptSellAmtTooMuchDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 1001 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testFailForFixEthBuyFixCdcUserHasNoDptBuyAmtTooMuchDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address buyToken = cdc;

        doExchange(eth, 1000 ether, buyToken, 1001 ether);

    }

    function testFailForFixEthBuyFixCdcUserHasNoDptBothTooMuchDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 1001 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 1001 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForFixDaiBuyEthUserHasNoDptBothTooMuchDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 11 ether;
        address buyToken = eth;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }


    function testFailSendEthIfNoEthIsSellTokenDex() public {

        uint sentEth = 1 ether;

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 11 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        DiamondExchange(exchange).buyTokensWithFee.value(sentEth)(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForFixDaiBuyAllCdcUserHasEnoughDptCanNotSellTokenDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc20"), b(dai), b(false));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 11 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        DiamondExchange(exchange).buyTokensWithFee(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForFixDaiBuyAllCdcUserHasEnoughDptCanNotBuyTokenDex() public {

        DiamondExchange(exchange).setConfig(b("canBuyErc20"), b(cdc), b(false));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 11 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        DiamondExchange(exchange).buyTokensWithFee(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForFixDaiBuyAllCdcUserHasEnoughDptZeroTokenForSaleDex() public {


        SimpleAssetManagement(asm).setConfig("setApproveForAll", b(dpass), b(address(this)), b(true));
        Dpass(dpass).transferFrom(asm, user,  dpassId[seller]);
        SimpleAssetManagement(asm).notifyTransferFrom(dpass, asm, user, dpassId[seller]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 11 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        DiamondExchange(exchange).buyTokensWithFee(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixDaiBuyAllCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 41 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixDaiBuyAllCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixDaiBuyAllCdcUserDptEnoughDex() public {
        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 27 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllDaiBuyAllCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForAllDaiBuyAllCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllDaiBuyAllCdcUserDptEnoughDex() public {
        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllDaiBuyFixCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForAllDaiBuyFixCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllDaiBuyFixCdcUserDptEnoughDex() public {
        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixDaiBuyFixCdcUserHasNoDptDex() public {
        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixDaiBuyFixCdcUserDptNotZeroNotEnoughDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixDaiBuyFixCdcUserDptEnoughDex() public {
        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForFixDaiBuyFixCdcUserHasNoDptSellAmtTooMuchDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 1001 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testFailForFixDaiBuyFixCdcUserHasNoDptBuyAmtTooMuchDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 1001 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testFailForFixDaiBuyFixCdcUserHasNoDptBothTooMuchDex() public {

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 1001 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 1001 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixEthBuyAllCdcUserHasNoDptAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 41 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixEthBuyAllCdcUserDptNotZeroNotEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixEthBuyAllCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 27 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllEthBuyAllCdcUserHasNoDptAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForAllEthBuyAllCdcUserDptNotZeroNotEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllEthBuyAllCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllEthBuyFixCdcUserHasNoDptAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForAllEthBuyFixCdcUserDptNotZeroNotEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllEthBuyFixCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixEthBuyFixCdcUserHasNoDptAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testForFixEthBuyFixCdcUserDptNotZeroNotEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixEthBuyFixCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForFixEthBuyFixCdcUserHasNoDptSellAmtTooMuchAllFeeInDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 1001 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);

    }

    function testAssertForTestFailForFixEthBuyFixCdcUserHasNoDptBuyAmtTooMuchAllFeeInDptDex() public {




        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        uint buyAmtOrId = DSToken(cdc).balanceOf(custodian20[cdc]) + 1 ether;
        uint sellAmtOrId = wdivT(wmulV(buyAmtOrId, usdRate[cdc], cdc), usdRate[eth], eth);
        user.transfer(sellAmtOrId);
    }

    function testFailForFixEthBuyFixCdcUserHasNoDptBuyAmtTooMuchAllFeeInDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        uint buyAmtOrId = DSToken(cdc).balanceOf(custodian20[cdc]) + 1 ether;
        uint sellAmtOrId = wdivT(wmulV(buyAmtOrId, usdRate[cdc], cdc), usdRate[eth], eth);
        sendToken(eth, user, sellAmtOrId);

        doExchange(eth, sellAmtOrId, cdc, buyAmtOrId);
    }

    function testFailForFixEthBuyFixCdcUserHasNoDptBothTooMuchAllFeeInDptDex() public {

        userDpt = 123 ether;
        uint buyAmtOrId = 17.79 ether + 1 ether;
        uint sellAmtOrId = user.balance + 1 ether;

        if (wdivT(wmulV(buyAmtOrId, usdRate[cdc], cdc), usdRate[eth], eth) <= sellAmtOrId) {
            sendToken(dpt, user, userDpt);

            doExchange(eth, sellAmtOrId, cdc, buyAmtOrId);
        }
    }

    function testFailSendEthIfNoEthIsSellTokenAllFeeInDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        uint sentEth = 1 ether;

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 11 ether;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        DiamondExchange(exchange).buyTokensWithFee.value(sentEth)(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixDptBuyAllCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);
        uint sellDpt = 10 ether;

        address sellToken = dpt;
        uint sellAmtOrId = sellDpt;
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForAllDptBuyAllCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);


        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }
    function testForAllDptBuyFixCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = uint(-1);
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixDptBuyFixCdcUserDptEnoughAllFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);
        uint sellDpt = 10 ether;

        address sellToken = dpt;
        uint sellAmtOrId = sellDpt;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailBuyTokensWithFeeLiquidityContractHasInsufficientDptDex() public {

        DiamondExchangeTester(liq).doTransfer(dpt, address(this), INITIAL_BALANCE);
        assertEq(DSToken(dpt).balanceOf(liq), 0);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testBuyTokensWithFeeWithManualEthUsdRateDex() public {

        usdRate[eth] = 400 ether;
        DiamondExchange(exchange).setConfig(b("rate"), b(eth), b(usdRate[eth]));
        TestFeedLike(feed[eth]).setValid(false);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testBuyTokensWithFeeWithManualDptUsdRateDex() public {

        usdRate[dpt] = 400 ether;
        DiamondExchange(exchange).setConfig(b("rate"), b(dpt), b(usdRate[dpt]));
        TestFeedLike(feed[dpt]).setValid(false);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testBuyTokensWithFeeWithManualCdcUsdRateDex() public {

        usdRate[cdc] = 400 ether;
        DiamondExchange(exchange).setConfig(b("rate"), b(cdc), b(usdRate[cdc]));
        TestFeedLike(feed[cdc]).setValid(false);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testBuyTokensWithFeeWithManualDaiUsdRateDex() public {

        usdRate[dai] = 400 ether;
        DiamondExchange(exchange).setConfig(b("rate"), b(dai), b(usdRate[dai]));
        TestFeedLike(feed[dai]).setValid(false);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailBuyTokensWithFeeSendZeroEthDex() public {

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, 0, buyToken, buyAmtOrId);
    }
    function testBuyTokensWithFeeWhenFeeIsZeroDex() public {

        DiamondExchange(exchange).setConfig(b("fixFee"), b(uint(0)), b(""));
        DiamondExchange(exchange).setConfig(b("varFee"), b(uint(0)), b(""));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }
    function testUpdateRatesDex() public {
        usdRate[cdc] = 40 ether;
        usdRate[dpt] = 12 ether;
        usdRate[eth] = 500 ether;
        usdRate[dai] = 500 ether;

        TestFeedLike(feed[cdc]).setRate(usdRate[cdc]);
        TestFeedLike(feed[dpt]).setRate(usdRate[dpt]);
        TestFeedLike(feed[eth]).setRate(usdRate[eth]);
        TestFeedLike(feed[dai]).setRate(usdRate[dai]);

        assertEq(DiamondExchange(exchange).getRate(cdc), usdRate[cdc]);
        assertEq(DiamondExchange(exchange).getRate(dpt), usdRate[dpt]);
        assertEq(DiamondExchange(exchange).getRate(eth), usdRate[eth]);
        assertEq(DiamondExchange(exchange).getRate(dai), usdRate[dai]);
    }

    function testForFixEthBuyDpassUserHasNoDptDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 16.5 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForDpassBuyDpassUserHasNoDptDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForDpassBuyDpassUserHasEnoughDptDex() public {

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForDpassBuyDpassUserHasNoDptCanSellErc721Dex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(true));

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForDpassBuyDpassUserHasDptNotEnoughCanSellErc721Dex() public {


        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(true));

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForDpassBuyDpassUserHasEnoughDptCanSellErc721Dex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(true));

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixEthBuyDpassUserDptNotEnoughDex() public {

        userDpt = 5 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 16.5 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixEthBuyDpassUserDptEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 15.65 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixEthBuyDpassUserDptNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 1 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixEthBuyDpassUserEthNotEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixEthBuyDpassUserBothNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllEthBuyDpassUserHasNoDptDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllEthBuyDpassDptNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllEthBuyDpassUserDptEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixDptBuyDpassDex() public {
        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = 36.3 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDptBuyDpassUserDptNotEnoughDex() public {

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = 15.65 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllDptBuyDpassDex() public {

        userDpt = 500 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixCdcBuyDpassUserHasNoDptDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixCdcBuyDpassUserDptNotEnoughDex() public {

        userDpt = 5 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixCdcBuyDpassUserDptEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixCdcBuyDpassUserDptNotEnoughEndDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 7 ether;
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixCdcBuyDpassUserCdcNotEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 10 ether;
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixCdcBuyDpassUserBothNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 10 ether;
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDpassBuyDpassDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        doExchange(dpass, dpassId[user], dpass, dpassId[seller]);
    }
    function testForAllCdcBuyDpassUserHasNoDptDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);
        address sellToken = cdc;
        uint sellAmtOrId = uint(-1);
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testForAllCdcBuyDpassDptNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = uint(-1);
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testForAllCdcBuyDpassUserDptEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = uint(-1);
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testForFixDaiBuyDpassUserHasNoDptDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 13.94 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixDaiBuyDpassUserDptNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 13.94 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixDaiBuyDpassUserDptEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 13.94 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testFailForFixDaiBuyDpassUserDptNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 1 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testFailForFixDaiBuyDpassUserDaiNotEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDaiBuyDpassUserBothNotEnoughDex() public {


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllDaiBuyDpassUserHasNoDptDex() public {

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllDaiBuyDpassDptNotEnoughDex() public {

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllDaiBuyDpassUserDptEnoughDex() public {

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }


    function testForFixEthBuyDpassUserHasNoDptFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 16.5 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testForFixEthBuyDpassUserDptNotEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 5 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 14.2 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixEthBuyDpassUserDptEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 6.4 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 13.73 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixEthBuyDpassUserDptNotEnoughFullFeeDptDex() public {


        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 13.73 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixEthBuyDpassUserEthNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixEthBuyDpassUserBothNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 13.72 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllEthBuyDpassUserHasNoDptFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllEthBuyDpassDptNotEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllEthBuyDpassUserDptEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixDptBuyDpassFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = 36.3 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDptBuyDpassUserDptNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1000 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = 15.65 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testForAllDptBuyDpassFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 500 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpt;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testForFixCdcBuyDpassUserHasNoDptFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixCdcBuyDpassUserDptNotEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 5 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixCdcBuyDpassUserDptEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }


    function testFailForFixCdcBuyDpassUserDptNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 7 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixCdcBuyDpassUserCdcNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixCdcBuyDpassUserBothNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDpassBuyDpassFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        doExchange(dpass, dpassId[user], dpass, dpassId[seller]);
    }

    function testForAllCdcBuyDpassUserHasNoDptFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = uint(-1);
        sendSomeCdcToUser();
        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllCdcBuyDpassDptNotEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = uint(-1);
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllCdcBuyDpassUserDptEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = uint(-1);
        sendSomeCdcToUser();

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }
    function testForFixDaiBuyDpassUserHasNoDptFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 13.94 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixDaiBuyDpassUserDptNotEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 13.94 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForFixDaiBuyDpassUserDptEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 13.94 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDaiBuyDpassUserDptNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 1 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDaiBuyDpassUserDaiNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixDaiBuyDpassUserBothNotEnoughFullFeeDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = 10 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllDaiBuyDpassUserHasNoDptFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllDaiBuyDpassDptNotEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testForAllDaiBuyDpassUserDptEnoughFullFeeDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint sellAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailForFixEthBuyDpassUserDptEnoughDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 1 ether;
        address buyToken = dpass;
        uint buyAmtOrId = dpassId[seller];

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailForDpassBuyCdcUserDptEnoughDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testGetBuyPriceAndSetBuyPriceDex() public {
        uint buyPrice = 43 ether;
        uint otherBuyPrice = 47 ether;

        DiamondExchangeTester(user)
            .doSetBuyPrice(dpass, dpassId[user], buyPrice);

        assertEqLog(
            "setBuyPrice() actually set",
            DiamondExchange(exchange).getBuyPrice(dpass, dpassId[user]),
            buyPrice);

        assertEqLog(
            "user buyPrice var ok",
            DiamondExchange(exchange).buyPrice(dpass, user, dpassId[user]),
            buyPrice);

        DiamondExchangeTester(seller)
            .doSetBuyPrice(dpass, dpassId[user], otherBuyPrice);

        DiamondExchangeTester(seller)
            .doSetBuyPrice(dpass, dpassId[seller], otherBuyPrice);

        assertEqLog(
            "cust set buy price",
            DiamondExchange(exchange).getBuyPrice(dpass, dpassId[seller]),
            otherBuyPrice);

        assertEqLog(
            "cust buyPrice var ok",
            DiamondExchange(exchange).buyPrice(dpass, asm, dpassId[seller]),
            otherBuyPrice);

        assertEqLog(
            "setBuyPrice() by oth don't apply",
            DiamondExchange(exchange).getBuyPrice(dpass, dpassId[user]),
            buyPrice);

        DiamondExchangeTester(user)
            .transferFrom721(dpass, user, seller, dpassId[user]);
        assertEqLog(
            "setBuyPrice() apply once new own",
            DiamondExchange(exchange).getBuyPrice(dpass, dpassId[user]),
            otherBuyPrice);
    }

    function testGetPriceDex() public {
        uint buyPrice = 43 ether;
        uint otherBuyPrice = 47 ether;
        assertEq(DiamondExchange(exchange).getPrice(dpass, dpassId[user]), dpassOwnerPrice[user]);

        DiamondExchangeTester(user)
            .doSetBuyPrice(dpass, dpassId[user], buyPrice);

        assertEqLog(
            "getPrice() is setBuyPrice()",
            DiamondExchange(exchange).getPrice(dpass, dpassId[user]),
            buyPrice
            );

        DiamondExchangeTester(seller)
            .doSetBuyPrice(dpass, dpassId[user], otherBuyPrice);

        assertEqLog(
            "non-owner set price dont change",
            DiamondExchange(exchange).getPrice(dpass, dpassId[user]),
            buyPrice);

        DiamondExchangeTester(user)
            .doSetBuyPrice(dpass, dpassId[user], 0 ether);

        assertEqLog(
            "0 set price base price used",
            DiamondExchange(exchange).getPrice(dpass, dpassId[user]),
            dpassOwnerPrice[user]);

        DiamondExchangeTester(user)
            .doSetBuyPrice(dpass, dpassId[user], uint(-1));

        assertEqLog(
            "uint(-1) price is base price",
            DiamondExchange(exchange).getPrice(dpass, dpassId[user]),
            dpassOwnerPrice[user]);

        DiamondExchangeTester(user)
            .transferFrom721(dpass, user, seller, dpassId[user]);

        assertEqLog(
            "prev set price is now valid",
            DiamondExchange(exchange).getBuyPrice(dpass, dpassId[user]),
            otherBuyPrice);

        DiamondExchangeTester(seller)
            .doSetBuyPrice(dpass, dpassId[user], 0 ether);

        assertEqLog(
            "base price used when 0 set",
            DiamondExchange(exchange).getPrice(dpass, dpassId[user]),
            dpassOwnerPrice[user]);
    }

    function testFailGetPriceBothBasePriceAndSetBuyPriceZeroDex() public {

        SimpleAssetManagement(asm).setBasePrice(dpass, dpassId[user], 0 ether);
        DiamondExchange(exchange).getPrice(dpass, dpassId[user]);
    }

    function testFailGetPriceTokenNotForSaleDex() public {

        DiamondExchange(exchange).setConfig(b("canBuyErc721"), b(dpass), b(b(false)));
        DiamondExchange(exchange).getPrice(dpass, dpassId[user]);
    }

    function testFailSellDpassForFixCdcUserHasNoDptTakeProfitOnlyInDptDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 6.57 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForLimitedCdcUserHasNoDptTakeProfitOnlyInDptDex() public {
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForUnlimitedCdcUserHasNoDptTakeProfitOnlyInDptDex() public {
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailSellDpassForFixCdcUserHasDptNotEnoughTakeProfitOnlyInDptDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 6.51 ether;
        require(buyAmtOrId < 6.511428571428571429 ether, "test-buyAmtOrId-too-high");

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForLimitedCdcUserHasDptNotEnoughTakeProfitOnlyInDptDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForUnlimitedCdcUserHasDptNotEnoughTakeProfitOnlyInDptDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailSellDpassForFixCdcUserHasDptEnoughTakeProfitOnlyInDptDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 6.57 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForLimitedCdcUserHasDptEnoughTakeProfitOnlyInDptDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForUnlimitedCdcUserHasDptEnoughTakeProfitOnlyInDptDex() public {

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }


    function testFailSellDpassForFixCdcUserHasNoDptFullFeeInDptDex() public {

        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 6.57 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForLimitedCdcUserHasNoDptFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForUnlimitedCdcUserHasNoDptFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailSellDpassForFixCdcUserHasDptNotEnoughFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 6.51 ether;
        require(buyAmtOrId < 6.511428571428571429 ether, "test-buyAmtOrId-too-high");

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForLimitedCdcUserHasDptNotEnoughFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForUnlimitedCdcUserHasDptNotEnoughFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailSellDpassForFixCdcUserHasDptEnoughFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 6.57 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForLimitedCdcUserHasDptEnoughFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForUnlimitedCdcUserHasDptEnoughFullFeeInDptDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b(false)), b(""));

        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = cdc;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForLimitedDaiDex() public {

        DSToken(dai).transfer(asm, INITIAL_BALANCE);
        balance[asm][dai] = DSToken(dai).balanceOf(asm);
        DiamondExchange(exchange).setConfig(b("canBuyErc20"), b(dai), b(b(true)));
        SimpleAssetManagement(asm).setConfig("approve", b(dai), b(exchange), b(uint(-1)));
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = dai;
        uint buyAmtOrId = 70 ether;

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testSellDpassForUnlimitedDaiDex() public {

        DSToken(dai).transfer(asm, INITIAL_BALANCE);
        balance[asm][dai] = DSToken(dai).balanceOf(asm);
        DiamondExchange(exchange).setConfig(b("canBuyErc20"), b(dai), b(b(true)));
        SimpleAssetManagement(asm).setConfig("approve", b(dai), b(exchange), b(uint(-1)));
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass),b(true),"");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);

        userDpt = 123 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint sellAmtOrId = dpassId[user];
        address buyToken = dai;
        uint buyAmtOrId = uint(-1);

        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testFailSellDpassForLimitedEthDex() public pure {
        require(false, "approve-not-work-for-eth");
    }

    function testFailSellDpassForUnlimitedEthDex() public pure {
        require(false, "approve-not-work-for-eth");
    }

    function testForFixEthBuyUserDpassUserHasNoDptDex() public {

        DiamondExchangeTester(user)
            .transferFrom721(dpass, user, address(this), dpassId[user]);
        dpassOwnerPrice[address(this)] = 61 ether;
        SimpleAssetManagement(asm).setBasePrice(dpass, dpassId[user], dpassOwnerPrice[address(this)]);
        Dpass(dpass).approve(exchange, dpassId[user]);

        SimpleAssetManagement(asm).setConfig("payTokens", b(dpass), b(true), "");

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 16.5 ether;

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[user]);
    }

    function testForFixCdcBuyUserDpassUserHasNoDptDex() public {

        DiamondExchangeTester(user)
            .transferFrom721(dpass, user, address(this), dpassId[user]);
        dpassOwnerPrice[address(this)] = 61 ether;
        SimpleAssetManagement(asm).setBasePrice(dpass, dpassId[user], dpassOwnerPrice[address(this)]);
        Dpass(dpass).approve(exchange, dpassId[user]);

        SimpleAssetManagement(asm).setConfig("payTokens", b(dpass), b(true), "");

        userDpt = 0 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[user]);
    }

    function testFailAuthCheckSetConfigDex() public {
        DiamondExchange(exchange).setOwner(user);
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(b(true)));
    }

    function testFailAuthCheck_getValuesDex() public {
        TrustedDiamondExchange(exchange)._getValues(eth, 1 ether, cdc, uint(-1));
    }

    function testFailAuthCheck_takeFeeDex() public {
        TrustedDiamondExchange(exchange)._takeFee(.2 ether, 1 ether, 1 ether, eth, 1 ether, cdc, 1 ether);
    }

    function testFailAuthCheck_transferTokensDex() public {
        TrustedDiamondExchange(exchange)._transferTokens(1 ether, 1 ether, eth, 1 ether, cdc, 1 ether, .2 ether);
    }

    function testFailAuthCheckGetLocalRateDex() public {
        DiamondExchange(exchange).setOwner(user);
        DiamondExchange(exchange).getLocalRate(cdc);
    }

    function testFailAuthCheckGetAllowedTokenDex() public {
        DiamondExchange(exchange).setOwner(user);
        DiamondExchange(exchange).getAllowedToken(cdc, true);
    }

    function testFailAuthCheckGetRateDex() public {
        DiamondExchange(exchange).setOwner(user);
        DiamondExchange(exchange).getRate(cdc);
    }

    function testFailAuthCheckSetKycDex() public {
        DiamondExchange(exchange).setOwner(user);
        DiamondExchange(exchange).setKyc(user, true);
    }

    function testFailAuthCheck_getNewRateDex() public view {
        TrustedDiamondExchange(exchange)._getNewRate(eth);
    }

    function testFailAuthCheck_updateRatesDex() public {
        TrustedDiamondExchange(exchange)._updateRates(dai, dpass);
    }

    function testFailAuthCheck_logTradeDex() public {
        TrustedDiamondExchange(exchange)._logTrade(eth, 1 ether, cdc, 1 ether, 1 ether, .2 ether);
    }

    function testFailAuthCheck_updateRateDex() public {
        TrustedDiamondExchange(exchange)._updateRate(dai);
    }

    function testFailAuthCheck_takeFeeInTokenDex() public {
        TrustedDiamondExchange(exchange)._takeFeeInToken(.2 ether, .03 ether, dai, address(this), 1 ether);
    }

    function testFailAuthCheck_takeFeeInDptFromUserDex() public {
        TrustedDiamondExchange(exchange)._takeFeeInDptFromUser(.2 ether);
    }

    function testFailAuthCheck_sendTokenDex() public {
        TrustedDiamondExchange(exchange)._sendToken(dpt, address(this), user, 1 ether);
    }

    function testKycDex() public {
        DiamondExchange(exchange).setKyc(user, true);
        DiamondExchange(exchange).setConfig("kycEnabled", b(true), "");
        testForFixEthBuyAllCdcUserHasNoDptDex();
    }

    function testFailKycDex() public {

        DiamondExchange(exchange).setKyc(user, false);
        DiamondExchange(exchange).setConfig("kycEnabled", b(true), "");
        testForFixEthBuyAllCdcUserHasNoDptDex();
    }

    function testFailDenyTokenDex() public {
        DiamondExchange(exchange).setDenyToken(cdc, true);
        testForFixCdcBuyUserDpassUserHasNoDptDex();
    }

    function testFailDenyTokenPairDex() public {
        DiamondExchange(exchange).setConfig("denyTokenPair", b(cdc), b(dpass));
        testForFixCdcBuyUserDpassUserHasNoDptDex();
    }

    function testAllowTokenlirDenyThenAllowDex() public {
        DiamondExchange(exchange).setConfig("denyTokenPair", b(cdc), b(dpass));
        DiamondExchange(exchange).setConfig("allowTokenPair", b(cdc), b(dpass));
        testForFixCdcBuyUserDpassUserHasNoDptDex();
    }

    function testDenyTokenDex() public {
        DiamondExchange(exchange).setDenyToken(cdc, true);
        DiamondExchange(exchange).setDenyToken(cdc, false);
        testForFixCdcBuyUserDpassUserHasNoDptDex();
    }

    function testIsHandledByAsm() public {
        assertTrue(DiamondExchange(exchange).handledByAsm(cdc));
        DiamondExchange(exchange).setConfig("handledByAsm", b(cdc), b(false));
        assertTrue(!DiamondExchange(exchange).handledByAsm(cdc));
    }

    function testSetPriceFeedDex() public {

        address token = eth;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(address(feed[token])));
        assertEqLog(
            "set-pricefeed-is-returned",
            address(DiamondExchange(exchange).priceFeed(token)),
            address(feed[token]));

        token = dai;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(address(feed[token])));
        assertEqLog(
            "set-pricefeed-is-returned",
            address(DiamondExchange(exchange).priceFeed(token)),
            address(feed[token]));

        token = cdc;
        DiamondExchange(exchange).setConfig(b("priceFeed"), b(token), b(address(feed[token])));
        assertEqLog(
            "set-pricefeed-is-returned",
            address(DiamondExchange(exchange).priceFeed(token)),
            address(feed[token]));
    }

    function testGetAllowedTokenDex() public {
        assertTrue(DiamondExchange(exchange).getAllowedToken(cdc, true));
        assertTrue(DiamondExchange(exchange).getAllowedToken(cdc, false));

        DiamondExchange(exchange).setConfig("canBuyErc20",b(cdc), b(false));
        DiamondExchange(exchange).setConfig("canSellErc20",b(cdc), b(false));

        assertTrue(!DiamondExchange(exchange).getAllowedToken(cdc, true));
        assertTrue(!DiamondExchange(exchange).getAllowedToken(cdc, false));
    }

    function testGetDecimalsSetDex() public {
        assertTrue(DiamondExchange(exchange).decimalsSet(cdc));
        address token1 = address(new DSToken("TEST"));
        assertTrue(!DiamondExchange(exchange).decimalsSet(token1));
        DiamondExchange(exchange).setConfig("decimals",b(token1), b(18));
        assertTrue(DiamondExchange(exchange).decimalsSet(token1));
    }

    function testGetCustodian20() public {
        assertEqLog(
            "default custodian is asm",
            DiamondExchange(exchange).custodian20(cdc),
            custodian20[cdc]
        );
        address token1 = address(new DSToken("TEST"));
        assertEqLog(
            "any token custodian is unset",
            DiamondExchange(exchange).custodian20(token1),
            address(0)
        );
    }

    function testAddrDex() public {
        address someAddress = address(0xee);
        assertEqLog(
            "address eq address",
            DiamondExchange(exchange).addr(b(someAddress)),
            someAddress
        );
    }

    function testGetCostsBuyDpassTakeProfitOnlyDptEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(true)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, cdc, 0, dpass, dpassId[seller]);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            22311428571428571429,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            1644000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            27400000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            2740000000000000000,
            dpt);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testGetCostsBuyDpassTakeProfitOnlyDptNotEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(true)), b(""));


        userDpt = 0.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, cdc, 0, dpass, dpassId[seller]);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            22905714285714285715,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            812000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            27400000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            3334285714285714286,
            dpt);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testGetCostsBuyDpassTakeAllCostsInDptDptEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 5.49 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, cdc, 0, dpass, dpassId[seller]);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            19571428571428571429,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            5480000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            27400000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            0,
            dpt);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }


    function testGetCostsBuyDpassTakeAllCostsInDptDptNotEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 5.3 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = cdc;
        uint sellAmtOrId = 25.89 ether;
        sendSomeCdcToUser(sellAmtOrId);
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, cdc, 0, dpass, dpassId[seller]);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            19700000000000000000,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            5300000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            27400000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            128571428571428571,
            dpt);

        doExchange(sellToken, sellAmtOrId, dpass, dpassId[seller]);
    }

    function testFailGetCostsUserZeroDex() public view{

        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(address(0), cdc, 0, dpass, dpassId[seller]);
        sellAmt_ = sellAmt_ + feeDpt_ + feeV_ + feeSellT_;
    }

    function testFailGetCostsSellTokenInvalidDex() public view{

        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, address(0xffffff), 0, dpass, dpassId[seller]);
        sellAmt_ = sellAmt_ + feeDpt_ + feeV_ + feeSellT_;
    }

    function testFailGetCostsBuyTokenInvalidDex() public view {

        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(address(0), cdc, 0, address(0xffeeff), dpassId[seller]);
        sellAmt_ = sellAmt_ + feeDpt_ + feeV_ + feeSellT_;
    }

    function testFailGetCostsBothTokensDpassDex() public view {

        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dpass, 0, dpass, dpassId[seller]);
        sellAmt_ = sellAmt_ + feeDpt_ + feeV_ + feeSellT_;
    }

    function testGetCostsBuyCdcTakeProfitOnlyDptEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(true)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, uint(-1));

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            69540839160839160840,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            1812000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            152181818181818181819,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            11009370629370629371,
            dpt);

        doExchange(sellToken, uint(-1), cdc, uint(-1));
    }

    function testGetCostsBuyCdcTakeProfitOnlyDptNotEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(true)), b(""));


        userDpt = 0.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, uint(-1));

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            69925454545454545455,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            812000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            152181818181818181819,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            11393986013986013986,
            dpt);

        doExchange(sellToken, uint(-1), cdc, uint(-1));
    }

    function testGetCostsBuyCdcTakeAllCostsInDptDptEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 5.49 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, uint(-1));

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            68126223776223776224,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            5490000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            152181818181818181819,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            9594755244755244755,
            dpt);

        doExchange(sellToken, uint(-1), cdc, uint(-1));
    }

    function testGetCostsBuyCdcTakeAllCostsInDptDptNotEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 5.3 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, uint(-1));

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            68199300699300699301,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            5300000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            152181818181818181819,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            9667832167832167832,
            dpt);

        doExchange(sellToken, uint(-1), cdc, uint(-1));
    }

    function testGetCostsBuyFixCdcTakeProfitOnlyDptEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(true)), b(""));


        userDpt = 1.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint buyAmt = 10 ether;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, buyAmt);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            6138461538461538461,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            840000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            14000000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            753846153846153846,
            dpt);

        doExchange(sellToken, uint(-1), cdc, buyAmt);
    }

    function testGetCostsBuyFixCdcTakeProfitOnlyDptNotEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(true)), b(""));


        userDpt = 0.812 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint buyAmt = 10 ether;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, buyAmt);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            6149230769230769230,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            812000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            14000000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            764615384615384615,
            dpt);

        doExchange(sellToken, uint(-1), cdc, buyAmt);
    }

    function testGetCostsBuyFixCdcTakeAllCostsInDptDptEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 5.49 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint buyAmt = 10 ether;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, buyAmt);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            5384615384615384615,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            2800000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            14000000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            0,
            dpt);

        doExchange(sellToken, uint(-1), cdc, buyAmt);
    }

    function testGetCostsBuyFixCdcTakeAllCostsInDptDptNotEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));


        userDpt = 2.3 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dai;
        uint buyAmt = 10 ether;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, dai, 0, cdc, buyAmt);

        assertEqDustLog("expected sell amount adds up",
            sellAmt_,
            5576923076923076923,
            cdc);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            2300000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            14000000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            192307692307692308,
            dpt);

        doExchange(sellToken, uint(-1), cdc, buyAmt);
    }

    function testGetCostsSellDpassBuyFixCdcTakeAllCostsInDptDptNotEnoughDex() public {
        DiamondExchange(exchange).setConfig(b("takeProfitOnlyInDpt"), b(b32(false)), b(""));
        DiamondExchange(exchange).setConfig(b("canSellErc721"), b(dpass), b(true));
        SimpleAssetManagement(asm).setConfig("payTokens",b(dpass), b(true), "diamonds");
        DiamondExchangeTester(user).doApprove721(dpass, exchange, dpassId[user]);


        userDpt = 2.3 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = dpass;
        uint buyAmt = 10 ether;
        (uint sellAmt_, uint feeDpt_, uint256 feeV_, uint256 feeSellT_) = DiamondExchangeExtension(dee).getCosts(user, sellToken, dpassId[user], cdc, buyAmt);

        assertEqLog("expected sell amount adds up",
            sellAmt_,
            1);

        assertEqDustLog("expected dpt fee adds up",
            feeDpt_,
            2300000000000000000,
            dpt);

        assertEqDustLog("expected fee value adds up",
            feeV_,
            14000000000000000000,
            dpt);

        assertEqDustLog("expected fee in sellTkns adds up",
            feeSellT_,
            0,
            dpt);

        doExchange(dpass, dpassId[user], cdc, buyAmt);
    }

    function testRedeemFeeTokenDex() public {
        DiamondExchange(exchange).setConfig("redeemFeeToken", b(eth), b(true));

        uint ethRedeem = 11 ether;
        address sellToken = eth;
        uint sellAmtOrId = 16.5 ether;

        DiamondExchange(exchange)
            .buyTokensWithFee
            .value(sellAmtOrId)
            (sellToken, sellAmtOrId, dpass, dpassId[seller]);

        approve721(dpass, exchange, dpassId[seller]);

        walEthBalance = wal.balance;
        liqDptBalance = DSToken(dpt).balanceOf(liq);
        burnerDptBalance = DSToken(dpt).balanceOf(burner);
        userCdcBalance = DSToken(cdc).balanceOf(address(this));
        userEthBalance = address(this).balance;

        DiamondExchange(exchange)
        .redeem
        .value(ethRedeem)
        (
            dpass,
            dpassId[seller],
            eth,
            ethRedeem,
            seller
        );


    }

    function testFailRedeemFeeTokenDex() public {

        uint ethRedeem = 11 ether;
        address sellToken = eth;
        uint sellAmtOrId = 16.5 ether;

        DiamondExchange(exchange)
            .buyTokensWithFee
            .value(sellAmtOrId)
            (sellToken, sellAmtOrId, dpass, dpassId[seller]);

        approve721(dpass, exchange, dpassId[seller]);

        walEthBalance = wal.balance;
        liqDptBalance = DSToken(dpt).balanceOf(liq);
        burnerDptBalance = DSToken(dpt).balanceOf(burner);
        userCdcBalance = DSToken(cdc).balanceOf(address(this));
        userEthBalance = address(this).balance;

        DiamondExchange(exchange)
        .redeem
        .value(ethRedeem)
        (
            dpass,
            dpassId[seller],
            eth,
            ethRedeem,
            seller
        );
    }

    function testFailForFixEthBuyFixCdcUserDptNotZeroNotEnoughSmallDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        DiamondExchange(exchange).setConfig("small", b(eth), b(sellAmtOrId + 1));
        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }

    function testForFixEthBuyFixCdcUserDptNotZeroNotEnoughSmallDex() public {
        userDpt = 1 ether;
        sendToken(dpt, user, userDpt);

        address sellToken = eth;
        uint sellAmtOrId = 17 ether;
        address buyToken = cdc;
        uint buyAmtOrId = 17.79 ether;

        DiamondExchange(exchange).setConfig("smallest", b(eth), b(sellAmtOrId));
        doExchange(sellToken, sellAmtOrId, buyToken, buyAmtOrId);
    }
}
