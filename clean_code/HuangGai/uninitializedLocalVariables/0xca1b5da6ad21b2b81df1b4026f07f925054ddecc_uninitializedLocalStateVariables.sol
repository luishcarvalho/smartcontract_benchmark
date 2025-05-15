





pragma solidity 0.6.2;






contract Ownable
{




  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";




  address public owner;






  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );




  constructor()
    public
  {
    owner = msg.sender;
  }




  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }





  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}



pragma solidity 0.6.2;





interface ERC721Enumerable
{






  function totalSupply()
    external
    view
    returns (uint256);






  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);









  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}



pragma solidity 0.6.2;





interface ERC721Metadata
{





  function name()
    external
    view
    returns (string memory _name);





  function symbol()
    external
    view
    returns (string memory _symbol);







  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}



pragma solidity 0.6.2;







library AddressUtils
{






  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {







    bytes32 codehash;
    bytes32 accountHash ;

    assembly { codehash := extcodehash(_addr) }
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}



pragma solidity 0.6.2;





interface ERC165
{







  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);

}



pragma solidity 0.6.2;





contract SupportsInterface is
  ERC165
{





  mapping(bytes4 => bool) internal supportedInterfaces;




  constructor()
    public
  {
    supportedInterfaces[0x01ffc9a7] = true;
  }






  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}



pragma solidity 0.6.2;






library SafeMath
{




  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";







  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {



    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }







  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {

    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;

  }







  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }







  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }








  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder)
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}



pragma solidity 0.6.2;





interface ERC721TokenReceiver
{














  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}



pragma solidity 0.6.2;





interface ERC721
{







  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );






  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );





  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );














  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;









  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;











  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;








  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;








  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;







  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);







  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);







  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);







  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}



pragma solidity 0.6.2;









contract NFToken is
  ERC721,
  SupportsInterface
{
  using SafeMath for uint256;
  using AddressUtils for address;





  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROWED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";





  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;




  mapping (uint256 => address) internal idToOwner;




  mapping (uint256 => address) internal idToApproval;




  mapping (address => uint256) private ownerToNFTokenCount;




  mapping (address => mapping (address => bool)) internal ownerToOperators;










  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );









  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );









  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );





  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner ;

    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], NOT_OWNER_OR_OPERATOR);
    _;
  }





  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner ;

    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROWED_OR_OPERATOR
    );
    _;
  }





  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }




  constructor()
    public
  {
    supportedInterfaces[0x80ac58cd] = true;
  }















  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    virtual
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }










  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    virtual
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }











  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    virtual
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner ;

    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }








  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    virtual
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner ;

    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }








  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    virtual
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }







  function balanceOf(
    address _owner
  )
    external
    override
    virtual
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }







  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    virtual
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }







  function getApproved(
    uint256 _tokenId
  )
    external
    override
    virtual
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }







  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    virtual
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }







  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from ;

    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }









  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }









  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner ;

    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }







  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }







  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }







  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }








  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner ;

    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval ;

      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }





  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }
  }

}



pragma solidity 0.6.2;







abstract contract NFTokenEnumerableMetadata is
    NFToken,
    ERC721Metadata,
    ERC721Enumerable
{




  string internal nftName;




  string internal nftSymbol;




  string internal nftContractMetadataUri;




  mapping (uint256 => string) internal idToUri;




  mapping (uint256 => string) internal idToPayload;





  constructor()
    public
  {
    supportedInterfaces[0x5b5e139f] = true;
    supportedInterfaces[0x780e9d63] = true;
  }

   function changeName(string calldata name, string calldata symbol) external virtual {
      nftName = name;
      nftSymbol = symbol;
  }





  function name()
    external
    override
    view
    virtual
    returns (string memory _name)
  {
    _name = nftName;
  }





  function symbol()
    external
    override
    view
    virtual
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }






  function tokenURI(
    uint256 _tokenId
  )
    external
    override
    view
    virtual
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToUri[_tokenId];
  }






  function tokenPayload(
    uint256 _tokenId
  )
    external
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToPayload[_tokenId];
  }











  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }

function _setTokenPayload(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToPayload[_tokenId] = _uri;
  }





  string constant INVALID_INDEX = "005007";




  uint256[] internal tokens;




  mapping(uint256 => uint256) internal idToIndex;




  mapping(address => uint256[]) internal ownerToIds;




  mapping(uint256 => uint256) internal idToOwnerIndex;





  function totalSupply()
    external
    override
    virtual
    view
    returns (uint256)
  {
    return tokens.length;
  }






  function tokenByIndex(
    uint256 _index
  )
    external
    override
    view
    virtual
    returns (uint256)
  {
    require(_index < tokens.length, INVALID_INDEX);
    return tokens[_index];
  }







  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    override
    view
    virtual
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
  }









  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;
  }









  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }

    if (bytes(idToPayload[_tokenId]).length != 0)
    {
      delete idToPayload[_tokenId];
    }

    uint256 tokenIndex ;

    uint256 lastTokenIndex ;

    uint256 lastToken ;


    tokens[tokenIndex] = lastToken;

    tokens.pop();

    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }







  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    delete idToOwner[_tokenId];

    uint256 tokenToRemoveIndex ;

    uint256 lastTokenIndex ;


    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken ;

      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].pop();
  }







  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    idToOwner[_tokenId] = _to;

    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
  }







  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override
    virtual
    view
    returns (uint256)
  {
    return ownerToIds[_owner].length;
  }

}



pragma solidity 0.6.2;






contract Proxy is NFTokenEnumerableMetadata, Ownable {





    constructor() public {}

    address private _implementation;

    event Upgraded(address indexed implementation);

    function implementation() public view returns (address) {
        return _implementation;
    }

    function upgradeTo(address impl) public  {
        _implementation = impl;
        emit Upgraded(impl);
    }

    function changeName(string calldata name, string calldata symbol) external override {
      NFTokenEnumerableMetadata(_implementation).changeName(name, symbol);
    }

    function transferOwnershipOfImpl(address _newOwner) external onlyOwner {
        Ownable(_implementation).transferOwnership(_newOwner);
    }

    function name() external view override returns (string memory _name) {
        return ERC721Metadata(_implementation).name();
    }

    function symbol() external view override returns (string memory _symbol) {
        return ERC721Metadata(_implementation).symbol();
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return ERC721Metadata(_implementation).tokenURI(_tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override {
        return ERC721(_implementation).transferFrom(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override {
        ERC721(_implementation).approve(_approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ERC721(_implementation).setApprovalForAll(_operator, _approved);
    }

    function balanceOf(address _owner) external view override returns (uint256){
        return ERC721(_implementation).balanceOf(_owner);
    }

    function ownerOf(uint256 _tokenId) external view override returns (address){
        return ERC721(_implementation).ownerOf(_tokenId);
    }

    function getApproved(uint256 _tokenId) external view override returns (address){
        return ERC721(_implementation).getApproved(_tokenId);
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool){
        return ERC721(_implementation).isApprovedForAll(_owner, _operator);
    }

    function totalSupply() external override view returns (uint256)  {
        return ERC721Enumerable(_implementation).totalSupply();
    }

    function tokenByIndex(uint256 _index) external override view returns (uint256)  {
        return NFTokenEnumerableMetadata(_implementation).tokenByIndex(_index);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external override view returns (uint256) {
        return NFTokenEnumerableMetadata(_implementation).tokenOfOwnerByIndex(_owner, _index);
    }



}
