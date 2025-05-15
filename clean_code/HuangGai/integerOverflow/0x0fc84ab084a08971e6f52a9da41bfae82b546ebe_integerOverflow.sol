



pragma solidity 0.6.6;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}


interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);
  function getAuthorizationStatus(address node) external view returns (bool);
  function setFulfillmentPermission(address node, bool allowed) external;
  function withdraw(address recipient, uint256 amount) external;
  function withdrawable() external view returns (uint256);
}


interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}




abstract contract LinkTokenReceiver {

  bytes4 constant private ORACLE_REQUEST_SELECTOR = 0x40429946;
  uint256 constant private SELECTOR_LENGTH = 4;
  uint256 constant private EXPECTED_REQUEST_WORDS = 2;
  uint256 constant private MINIMUM_REQUEST_LENGTH = SELECTOR_LENGTH + (32 * EXPECTED_REQUEST_WORDS);








  function onTokenTransfer(
    address _sender,
    uint256 _amount,
    bytes memory _data
  )
    public
    onlyLINK
    validRequestLength(_data)
    permittedFunctionsForLINK(_data)
  {
    assembly {

      mstore(add(_data, 36), _sender)

      mstore(add(_data, 68), _amount)
    }

    (bool success, ) = address(this).delegatecall(_data);
    require(success, "Unable to create request");
  }

  function getChainlinkToken() public view virtual returns (address);




  modifier onlyLINK() {
    require(msg.sender == getChainlinkToken(), "Must use LINK token");
    _;
  }





  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {

      funcSelector := mload(add(_data, 32))
    }
    require(funcSelector == ORACLE_REQUEST_SELECTOR, "Must use whitelisted functions");
    _;
  }





  modifier validRequestLength(bytes memory _data) {
    require(_data.length >= MINIMUM_REQUEST_LENGTH, "Invalid request length");
    _;
  }
}






interface WithdrawalInterface {






  function withdraw(address recipient, uint256 amount) external;




  function withdrawable() external view returns (uint256);
}














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
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }




  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
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
















library SafeMath {









  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;


    return c;
  }










  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

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

    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;


    return c;
  }












  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}






contract Oracle is ChainlinkRequestInterface, OracleInterface, Ownable, LinkTokenReceiver, WithdrawalInterface {
  using SafeMath for uint256;

  uint256 constant public EXPIRY_TIME = 5 minutes;
  uint256 constant private MINIMUM_CONSUMER_GAS_LIMIT = 400000;


  uint256 constant private ONE_FOR_CONSISTENT_GAS_COST = 1;

  LinkTokenInterface internal LinkToken;
  mapping(bytes32 => bytes32) private commitments;
  mapping(address => bool) private authorizedNodes;
  uint256 private withdrawableTokens = ONE_FOR_CONSISTENT_GAS_COST;

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );

  event CancelOracleRequest(
    bytes32 indexed requestId
  );






  constructor(address _link)
    public
    Ownable()
  {
    LinkToken = LinkTokenInterface(_link);
  }














  function oracleRequest(
    address _sender,
    uint256 _payment,
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _nonce,
    uint256 _dataVersion,
    bytes calldata _data
  )
    external
    override
    onlyLINK()
    checkCallbackAddress(_callbackAddress)
  {
    bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
    require(commitments[requestId] == 0, "Must use a unique ID");

    uint256 expiration = now.add(EXPIRY_TIME);

    commitments[requestId] = keccak256(
      abi.encodePacked(
        _payment,
        _callbackAddress,
        _callbackFunctionId,
        expiration
      )
    );

    emit OracleRequest(
      _specId,
      _sender,
      requestId,
      _payment,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      _dataVersion,
      _data);
  }














  function fulfillOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _expiration,
    bytes32 _data
  )
    external
    onlyAuthorizedNode
    override
    isValidRequest(_requestId)
    returns (bool)
  {
    bytes32 paramsHash = keccak256(
      abi.encodePacked(
        _payment,
        _callbackAddress,
        _callbackFunctionId,
        _expiration
      )
    );
    require(commitments[_requestId] == paramsHash, "Params do not match request ID");
    withdrawableTokens = withdrawableTokens.add(_payment);

    delete commitments[_requestId];
    require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "Must provide consumer enough gas");



    (bool success, ) = _callbackAddress.call(abi.encodeWithSelector(_callbackFunctionId, _requestId, _data));
    return success;
  }






  function getAuthorizationStatus(address _node)
    external
    view
    override
    returns (bool)
  {
    return authorizedNodes[_node];
  }






  function setFulfillmentPermission(address _node, bool _allowed)
    external
    override
    onlyOwner()
  {
    authorizedNodes[_node] = _allowed;
  }







  function withdraw(address _recipient, uint256 _amount)
    external
    override(OracleInterface, WithdrawalInterface)
    onlyOwner
    hasAvailableFunds(_amount)
  {
    withdrawableTokens = withdrawableTokens.sub(_amount);

    assert(LinkToken.transfer(_recipient, _amount));
  }






  function withdrawable()
    external
    view
    override(OracleInterface, WithdrawalInterface)
    onlyOwner()
    returns (uint256)
  {
    return withdrawableTokens.sub(ONE_FOR_CONSISTENT_GAS_COST);
  }











  function cancelOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  )
    external
    override
  {
    bytes32 paramsHash = keccak256(
      abi.encodePacked(
        _payment,
        msg.sender,
        _callbackFunc,
        _expiration)
    );
    require(paramsHash == commitments[_requestId], "Params do not match request ID");

    require(_expiration <= now, "Request is not expired");

    delete commitments[_requestId];
    emit CancelOracleRequest(_requestId);

    assert(LinkToken.transfer(msg.sender, _payment));
  }






  function getChainlinkToken()
    public
    view
    override
    returns (address)
  {
    return address(LinkToken);
  }







  modifier hasAvailableFunds(uint256 _amount) {
    require(withdrawableTokens >= _amount.add(ONE_FOR_CONSISTENT_GAS_COST), "Amount requested is greater than withdrawable balance");
    _;
  }





  modifier isValidRequest(bytes32 _requestId) {
    require(commitments[_requestId] != 0, "Must have a valid requestId");
    _;
  }




  modifier onlyAuthorizedNode() {
    require(authorizedNodes[msg.sender] || msg.sender == owner(), "Not an authorized node to fulfill requests");
    _;
  }





  modifier checkCallbackAddress(address _to) {
    require(_to != address(LinkToken), "Cannot callback to LINK");
    _;
  }

}
