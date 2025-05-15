



pragma solidity ^0.6.12;




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IMerkleTreeTokensVerification {
  function verify(
    address _leaf,
    bytes32 [] calldata proof,
    uint256 [] calldata positions
  )
    external
    view
    returns (bool);
}
interface ITokensTypeStorage {
  function isRegistred(address _address) external view returns(bool);

  function getType(address _address) external view returns(bytes32);

  function isPermittedAddress(address _address) external view returns(bool);

  function owner() external view returns(address);

  function addNewTokenType(address _token, string calldata _type) external;

  function setTokenTypeAsOwner(address _token, string calldata _type) external;
}





interface PoolPortalViewInterface {
  function getDataForBuyingPool(IERC20 _poolToken, uint _type, uint256 _amount)
    external
    view
    returns(
      address[] memory connectorsAddress,
      uint256[] memory connectorsAmount
  );

  function getBacorConverterAddressByRelay(address relay)
  external
  view
  returns(address converter);

  function getBancorConnectorsAmountByRelayAmount
  (
    uint256 _amount,
    IERC20 _relay
  )
  external view returns(uint256 bancorAmount, uint256 connectorAmount);

  function getBancorConnectorsByRelay(address relay)
  external
  view
  returns(address[] memory connectorsAddress);

  function getBancorRatio(address _from, address _to, uint256 _amount)
  external
  view
  returns(uint256);

  function getUniswapConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
  external
  view
  returns(uint256 ethAmount, uint256 ercAmount);

  function getUniswapV2ConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
  external
  view
  returns(
    uint256 tokenAmountOne,
    uint256 tokenAmountTwo,
    address tokenAddressOne,
    address tokenAddressTwo
  );

  function getBalancerConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _pool
  )
  external
  view
  returns(
    address[] memory tokens,
    uint256[] memory tokensAmount
  );

  function getUniswapTokenAmountByETH(address _token, uint256 _amount)
  external
  view
  returns(uint256);

  function getTokenByUniswapExchange(address _exchange)
  external
  view
  returns(address);
}
interface DefiPortalInterface {
  function callPayableProtocol(
    address[] memory tokensToSend,
    uint256[] memory amountsToSend,
    bytes calldata _additionalData,
    bytes32[] calldata _additionalArgs
  )
    external
    payable
    returns(
      string memory eventType,
      address[] memory tokensToReceive,
      uint256[] memory amountsToReceive
    );

  function callNonPayableProtocol(
    address[] memory tokensToSend,
    uint256[] memory amountsToSend,
    bytes calldata _additionalData,
    bytes32[] calldata _additionalArgs
  )
    external
    returns(
      string memory eventType,
      address[] memory tokensToReceive,
      uint256[] memory amountsToReceive
    );

  function getValue(
    address _from,
    address _to,
    uint256 _amount
  )
   external
   view
   returns(uint256);
}


interface ExchangePortalInterface {
  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    bool _verifyDestanation
  )
    external
    payable
    returns (uint256);


  function getValue(address _from, address _to, uint256 _amount) external view returns (uint256);

  function getTotalValue(
    address[] calldata _fromAddresses,
    uint256[] calldata _amounts,
    address _to
    )
    external
    view
   returns (uint256);
}


interface IOneSplitAudit {
  function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 disableFlags
    ) external payable;

  function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags
    )
      external
      view
      returns(
          uint256 returnAmount,
          uint256[] memory distribution
      );
}




interface BancorNetworkInterface {
   function getReturnByPath(
     IERC20[] calldata _path,
     uint256 _amount)
     external
     view
     returns (uint256, uint256);

    function convert(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn
    ) external payable returns (uint256);

    function claimAndConvert(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn
    ) external returns (uint256);

    function convertFor(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) external payable returns (uint256);

    function claimAndConvertFor(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) external returns (uint256);

    function conversionPath(
        IERC20 _sourceToken,
        IERC20 _targetToken
    ) external view returns (address[] memory);
}


interface IGetBancorData {
  function getBancorContractAddresByName(string calldata _name) external view returns (address result);
  function getBancorRatioForAssets(IERC20 _from, IERC20 _to, uint256 _amount) external view returns(uint256 result);
  function getBancorPathForAssets(IERC20 _from, IERC20 _to) external view returns(address[] memory);
}























contract Context {


    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}













contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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














contract ExchangePortal is ExchangePortalInterface, Ownable {
  using SafeMath for uint256;

  uint public version = 5;


  ITokensTypeStorage public tokensTypes;


  IMerkleTreeTokensVerification public merkleTreeWhiteList;


  IOneSplitAudit public oneInch;


  address public oneInchETH;


  IGetBancorData public bancorData;


  PoolPortalViewInterface public poolPortal;
  DefiPortalInterface public defiPortal;



  uint256 oneInchFlags = 570425349;




  enum ExchangeType { Paraswap, Bancor, OneInch, OneInchETH }


  IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);


  event Trade(
     address trader,
     address src,
     uint256 srcAmount,
     address dest,
     uint256 destReceived,
     uint8 exchangeType
  );


  mapping (address => bool) disabledTokens;


  modifier tokenEnabled(IERC20 _token) {
    require(!disabledTokens[address(_token)]);
    _;
  }












  constructor(
    address _defiPortal,
    address _bancorData,
    address _poolPortal,
    address _oneInch,
    address _oneInchETH,
    address _tokensTypes,
    address _merkleTreeWhiteList
    )
    public
  {
    defiPortal = DefiPortalInterface(_defiPortal);
    bancorData = IGetBancorData(_bancorData);
    poolPortal = PoolPortalViewInterface(_poolPortal);
    oneInch = IOneSplitAudit(_oneInch);
    oneInchETH = _oneInchETH;
    tokensTypes = ITokensTypeStorage(_tokensTypes);
    merkleTreeWhiteList = IMerkleTreeTokensVerification(_merkleTreeWhiteList);
  }


















  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    bool _verifyDestanation
  )
    external
    override
    payable
    tokenEnabled(_destination)
    returns (uint256 receivedAmount)
  {

    if(_verifyDestanation)
      _verifyToken(address(_destination), _proof, _positions);

    require(_source != _destination, "source can not be destination");


    if (_source == ETH_TOKEN_ADDRESS) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }


    if (_type == uint(ExchangeType.Paraswap)) {
      revert("PARASWAP not supported");
    }

    else if (_type == uint(ExchangeType.Bancor)){
      receivedAmount = _tradeViaBancorNewtork(
          address(_source),
          address(_destination),
          _sourceAmount
      );
    }

    else if (_type == uint(ExchangeType.OneInch)){
      receivedAmount = _tradeViaOneInch(
          address(_source),
          address(_destination),
          _sourceAmount,
          _additionalData
      );
    }


    else if (_type == uint(ExchangeType.OneInchETH)){
      receivedAmount = _tradeViaOneInchETH(
          address(_source),
          address(_destination),
          _sourceAmount,
          _additionalData
      );
    }

    else {

      revert();
    }


    require(receivedAmount > 0, "received amount can not be zerro");


    if (_destination == ETH_TOKEN_ADDRESS) {
      (msg.sender).transfer(0);
    } else {

      _destination.transfer(msg.sender, receivedAmount);
    }


    _sendRemains(_source, msg.sender);


    emit Trade(
      msg.sender,
      address(_source),
      _sourceAmount,
      address(_destination),
      receivedAmount,
      uint8(_type)
    );
  }


  function _sendRemains(IERC20 _source, address _receiver) private {

    uint256 endAmount = (_source == ETH_TOKEN_ADDRESS)
    ? address(this).balance
    : _source.balanceOf(address(this));


    if (endAmount > 0) {
      if (_source == ETH_TOKEN_ADDRESS) {
        payable(_receiver).transfer(0);
      } else {
        _source.transfer(_receiver, endAmount);
      }
    }
  }




  function _verifyToken(
    address _destination,
    bytes32 [] memory proof,
    uint256 [] memory positions)
    private
    view
  {
    bool status = merkleTreeWhiteList.verify(_destination, proof, positions);

    if(!status)
      revert("Dest not in white list");
  }


 function _tradeViaOneInch(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount,
   bytes memory _additionalData
   )
   private
   returns(uint256 destinationReceived)
 {
    (uint256 flags,
     uint256[] memory _distribution) = abi.decode(_additionalData, (uint256, uint256[]));

    if(IERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      oneInch.swap.value(sourceAmount)(
        IERC20(sourceToken),
        IERC20(destinationToken),
        sourceAmount,
        1,
        _distribution,
        flags
        );
    } else {
      _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, address(oneInch));
      oneInch.swap(
        IERC20(sourceToken),
        IERC20(destinationToken),
        sourceAmount,
        1,
        _distribution,
        flags
        );
    }

    destinationReceived = tokenBalance(IERC20(destinationToken));
    tokensTypes.addNewTokenType(destinationToken, "CRYPTOCURRENCY");
 }



  function _tradeViaOneInchETH(
    address sourceToken,
    address destinationToken,
    uint256 sourceAmount,
    bytes memory _additionalData
    )
    private
    returns(uint256 destinationReceived)
  {
     bool success;

     if(IERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
       (success, ) = oneInchETH.call.value(sourceAmount)(
         _additionalData
       );
     }

     else {
       _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, address(oneInchETH));
       (success, ) = oneInchETH.call(
         _additionalData
       );
     }

     require(success, "Fail 1inch call");

     destinationReceived = tokenBalance(IERC20(destinationToken));

     tokensTypes.addNewTokenType(destinationToken, "CRYPTOCURRENCY");
  }



 function _tradeViaBancorNewtork(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount
   )
   private
   returns(uint256 returnAmount)
 {

    BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
      bancorData.getBancorContractAddresByName("BancorNetwork")
    );


    address[] memory path = bancorData.getBancorPathForAssets(IERC20(sourceToken), IERC20(destinationToken));


    IERC20[] memory pathInERC20 = new IERC20[](path.length);
    for(uint i=0; i<path.length; i++){
        pathInERC20[i] = IERC20(path[i]);
    }


    if (IERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      returnAmount = bancorNetwork.convert.value(sourceAmount)(pathInERC20, sourceAmount, 1);
    }
    else {
      _transferFromSenderAndApproveTo(IERC20(sourceToken), sourceAmount, address(bancorNetwork));
      returnAmount = bancorNetwork.claimAndConvert(pathInERC20, sourceAmount, 1);
    }

    tokensTypes.addNewTokenType(destinationToken, "BANCOR_ASSET");
 }









  function _transferFromSenderAndApproveTo(IERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount));

    _source.approve(_to, 0);

    _source.approve(_to, _sourceAmount);
  }





  function tokenBalance(IERC20 _token) private view returns (uint256) {
    if (_token == ETH_TOKEN_ADDRESS)
      return address(this).balance;
    return _token.balanceOf(address(this));
  }










  function getValue(address _from, address _to, uint256 _amount)
    public
    override
    view
    returns (uint256)
  {
    if(_amount > 0){

      bytes32 assetType = tokensTypes.getType(_from);


      if(assetType == bytes32("CRYPTOCURRENCY")){
        return getValueViaDEXsAgregators(_from, _to, _amount);
      }
      else if (assetType == bytes32("BANCOR_ASSET")){
        return getValueViaBancor(_from, _to, _amount);
      }
      else if (assetType == bytes32("UNISWAP_POOL")){
        return getValueForUniswapPools(_from, _to, _amount);
      }
      else if (assetType == bytes32("UNISWAP_POOL_V2")){
        return getValueForUniswapV2Pools(_from, _to, _amount);
      }
      else if (assetType == bytes32("BALANCER_POOL")){
        return getValueForBalancerPool(_from, _to, _amount);
      }
      else{

        return findValue(_from, _to, _amount);
      }
    }
    else{
      return 0;
    }
  }










  function findValue(address _from, address _to, uint256 _amount) private view returns (uint256) {
     if(_amount > 0){


       uint256 defiValue = defiPortal.getValue(_from, _to, _amount);
       if(defiValue > 0)
          return defiValue;


       uint256 oneInchResult = getValueViaDEXsAgregators(_from, _to, _amount);
       if(oneInchResult > 0)
         return oneInchResult;


       uint256 bancorResult = getValueViaBancor(_from, _to, _amount);
       if(bancorResult > 0)
          return bancorResult;


       uint256 balancerResult = getValueForBalancerPool(_from, _to, _amount);
       if(balancerResult > 0)
          return balancerResult;


       uint256 uniswapResult = getValueForUniswapPools(_from, _to, _amount);
       if(uniswapResult > 0)
          return uniswapResult;


       return getValueForUniswapV2Pools(_from, _to, _amount);
     }
     else{
       return 0;
     }
  }




  function getValueViaDEXsAgregators(
    address _from,
    address _to,
    uint256 _amount
  )
  public view returns (uint256){

    if(_from == _to)
       return _amount;


    if(_amount > 0){

      return getValueViaOneInch(_from, _to, _amount);
    }
    else{
      return 0;
    }
  }



  function getValueViaOneInch(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    view
    returns (uint256 value)
  {

    if(_from == _to)
       return _amount;


    try oneInch.getExpectedReturn(
       IERC20(_from),
       IERC20(_to),
       _amount,
       10,
       oneInchFlags)
      returns(uint256 returnAmount, uint256[] memory distribution)
     {
       value = returnAmount;
     }
     catch{
       value = 0;
     }
  }



  function getValueViaBancor(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    view
    returns (uint256 value)
  {

    if(_from == _to)
       return _amount;


    if(_amount > 0){
      try poolPortal.getBancorRatio(_from, _to, _amount) returns(uint256 result){
        value = result;
      }catch{
        value = 0;
      }
    }else{
      return 0;
    }
  }



  function getValueForBalancerPool(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    view
    returns (uint256 value)
  {

    try poolPortal.getBalancerConnectorsAmountByPoolAmount(_amount, _from)
    returns(
      address[] memory tokens,
      uint256[] memory tokensAmount
    )
    {

     for(uint i = 0; i < tokens.length; i++){
       value += getValueViaDEXsAgregators(tokens[i], _to, tokensAmount[i]);
     }
    }
    catch{
      value = 0;
    }
  }




  function getValueForUniswapPools(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  view
  returns (uint256)
  {

    try poolPortal.getUniswapConnectorsAmountByPoolAmount(
      _amount,
      _from
    ) returns (uint256 ethAmount, uint256 ercAmount)
    {

      address token = poolPortal.getTokenByUniswapExchange(_from);
      uint256 ercAmountInETH = getValueViaDEXsAgregators(token, address(ETH_TOKEN_ADDRESS), ercAmount);

      uint256 totalETH = ethAmount.add(ercAmountInETH);


      if(_to == address(ETH_TOKEN_ADDRESS)){
        return totalETH;
      }

      else{
        return getValueViaDEXsAgregators(address(ETH_TOKEN_ADDRESS), _to, totalETH);
      }
    }catch{
      return 0;
    }
  }




  function getValueForUniswapV2Pools(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  view
  returns (uint256)
  {

    try poolPortal.getUniswapV2ConnectorsAmountByPoolAmount(
      _amount,
      _from
    ) returns (
      uint256 tokenAmountOne,
      uint256 tokenAmountTwo,
      address tokenAddressOne,
      address tokenAddressTwo
      )
    {

      uint256 amountOne = getValueViaDEXsAgregators(tokenAddressOne, _to, tokenAmountOne);
      uint256 amountTwo = getValueViaDEXsAgregators(tokenAddressTwo, _to, tokenAmountTwo);

      return amountOne + amountTwo;
    }catch{
      return 0;
    }
  }










  function getTotalValue(
    address[] calldata _fromAddresses,
    uint256[] calldata _amounts,
    address _to)
    external
    override
    view
    returns (uint256)
  {
    uint256 sum = 0;
    for (uint256 i = 0; i < _fromAddresses.length; i++) {
      sum = sum.add(getValue(_fromAddresses[i], _to, _amounts[i]));
    }
    return sum;
  }









  function setToken(address _token, bool _enabled) external onlyOwner {
    disabledTokens[_token] = _enabled;
  }


  function setNewOneInch(address _oneInch) external onlyOwner {
    oneInch = IOneSplitAudit(_oneInch);
  }


  function setNewOneInchETH(address _oneInchETH) external onlyOwner {
    oneInchETH = _oneInchETH;
  }


  function setNewPoolPortal(address _poolPortal) external onlyOwner {
    poolPortal = PoolPortalViewInterface(_poolPortal);
  }


  function setNewDefiPortal(address _defiPortal) external onlyOwner {
    defiPortal = DefiPortalInterface(_defiPortal);
  }


  function setOneInchFlags(uint256 _oneInchFlags) external onlyOwner {
    oneInchFlags = _oneInchFlags;
  }


  function setNewGetBancorData(address _bancorData) external onlyOwner {
    bancorData = IGetBancorData(_bancorData);
  }


  fallback() external payable {}

}
