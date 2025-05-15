



pragma solidity ^0.6.12;














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
interface PermittedAddressesInterface {
  function permittedAddresses(address _address) external view returns(bool);
  function addressesTypes(address _address) external view returns(string memory);
  function isMatchTypes(address _address, uint256 addressType) external view returns(bool);
}
interface ICoTraderGlobalConfig {
  function MAX_TOKENS() external view returns(uint256);

  function TRADE_FREEZE_TIME() external view returns(uint256);

  function DW_FREEZE_TIME() external view returns(uint256);

  function PLATFORM_ADDRESS() external view returns(address);
}
interface IFundValueOracle {
  function requestValue(address _fundAddress, uint256 _fee) external payable returns (bytes32 requestId);
  function getFundValueByID(bytes32 _requestId) external view returns(uint256 value);
  function fee() external returns(uint256);
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
}


interface PoolPortalInterface {
  function buyPool
  (
    uint256 _amount,
    uint _type,
    address _poolToken,
    address[] calldata _connectorsAddress,
    uint256[] calldata _connectorsAmount,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
  external
  payable
  returns(uint256 poolAmountReceive, uint256[] memory connectorsSpended);

  function sellPool
  (
    uint256 _amount,
    uint _type,
    IERC20 _poolToken,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionData
  )
  external
  payable
  returns(
    address[] memory connectorsAddress,
    uint256[] memory connectorsAmount
  );
}



interface IExchangePortal {
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











library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}











library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.number > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


abstract contract SmartFundCore is Ownable, IERC20 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  bool public isLightFund = false;


  uint256 public totalWeiDeposited;


  uint256 public totalWeiWithdrawn;


  IExchangePortal public exchangePortal;


  PoolPortalInterface public poolPortal;


  DefiPortalInterface public defiPortal;


  PermittedAddressesInterface public permittedAddresses;


  IERC20 constant internal ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);


  string public name;


  uint256 public TOTAL_PERCENTAGE = 10000;



  uint256 public successFee;



  uint256 public platformFee;


  address[] public tokenAddresses;



  bool public onlyWhitelist;



  mapping (address => bool) public whitelist;

  uint public version = 8;


  uint256 public totalShares;


  uint256 constant internal INITIAL_SHARES = 10 ** 18;


  uint256 public fundManagerCashedOut;


  address public coreFundAsset;


  bool public isRequireTradeVerification;


  IFundValueOracle public fundValueOracle;


  bytes32 public latestOracleRequestID;
  uint256 public latestOracleCallOnTime;
  uint256 public latestOracleCallOnBlock;
  address public latestOracleCaller;


  ICoTraderGlobalConfig public cotraderGlobalConfig;


  mapping (address => uint256) public addressToShares;


  mapping (address => bool) public tokensTraded;




  mapping (address => int256) public addressesNetDeposit;


  event DefiCall(
    string eventType,
    address[] tokensToSend,
    uint256[] amountsToSend,
    address[] tokensToReceive,
    uint256[] amountsToReceive
    );

  event BuyPool(
    address poolAddress,
    uint256 poolAmount,
    address[] connectorsAddress,
    uint256[] connectorsAmount);

  event SellPool(
    address poolAddress,
    uint256 poolAmount,
    address[] connectorsAddress,
    uint256[] connectorsAmount);

  event Deposit(address indexed user, uint256 amount, uint256 sharesReceived, uint256 totalShares);
  event Withdraw(address indexed user, uint256 sharesRemoved, uint256 totalShares);
  event Trade(address src, uint256 srcAmount, address dest, uint256 destReceived);
  event SmartFundCreated(address indexed owner);
  event OracleUpdate(address caller, uint256 triggerTime, bytes32 id);


  constructor(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _defiPortal,
    address _permittedAddresses,
    address _coreFundAsset,
    address _fundValueOracle,
    bool    _isRequireTradeVerification,
    address _cotraderGlobalConfig
  )public{

    require(_successFee < TOTAL_PERCENTAGE);

    name = _name;
    successFee = _successFee;
    platformFee = _successFee;


    if(block.coinbase == address(0)){
      transferOwnership(msg.sender);
    }
    else{
      transferOwnership(_owner);
    }


    tokenAddresses.push(address(ETH_TOKEN_ADDRESS));


    exchangePortal = IExchangePortal(_exchangePortalAddress);
    poolPortal = PoolPortalInterface(_poolPortalAddress);
    defiPortal = DefiPortalInterface(_defiPortal);
    permittedAddresses = PermittedAddressesInterface(_permittedAddresses);


    coreFundAsset = _coreFundAsset;


    fundValueOracle = IFundValueOracle(_fundValueOracle);


    isRequireTradeVerification = _isRequireTradeVerification;


    cotraderGlobalConfig = ICoTraderGlobalConfig(_cotraderGlobalConfig);

    emit SmartFundCreated(owner());
  }





  function verifyTradeBetweenDW() internal view {
    require(
        now >= latestOracleCallOnTime + cotraderGlobalConfig.TRADE_FREEZE_TIME(),
        "FREEZE_FOR_UPDATE_PRICE"
     );
  }



  function verifyDWSender() internal view {
    if(block.timestamp > 0){
      if(block.gaslimit >= now){
        require(msg.sender == latestOracleCaller, "NOT_LATEST_ORACLE_CALLER");
      }
      else{
        revert("ORACLE_TIME_EXPIRED");
      }
    }
  }



  function updateFundValueFromOracle(address _oracleTokenAddress, uint256 _oracleFee) public payable {

    require(now >= latestOracleCallOnTime + cotraderGlobalConfig.DW_FREEZE_TIME(), "DW_FREEZE");


    if(block.coinbase == address(ETH_TOKEN_ADDRESS)){
      require(msg.value == _oracleFee, "REQUIRE_ETH");

      latestOracleRequestID = fundValueOracle.requestValue.value(_oracleFee)(address(this), _oracleFee);
    }

    else{
      require(msg.value == 0, "NO_NEED_ETH");

      _transferFromSenderAndApproveTo(IERC20(_oracleTokenAddress), _oracleFee, address(fundValueOracle));

      latestOracleRequestID = fundValueOracle.requestValue(address(this), _oracleFee);
    }


    latestOracleCallOnTime = now;
    latestOracleCallOnBlock = block.number;
    latestOracleCaller = msg.sender;


    emit OracleUpdate(latestOracleCaller, latestOracleCallOnTime, latestOracleRequestID);
  }



  function calculateFundValue() public view returns (uint256) {

    return fundValueOracle.getFundValueByID(latestOracleRequestID);
  }













  function _withdraw(
    uint256[] memory _mul,
    uint256[] memory _div,
    address[] memory _withdrawAddress
    )
    internal
    returns (uint256)
  {
    for (uint8 i = 1; i < tokenAddresses.length; i++) {

      IERC20 token = IERC20(tokenAddresses[i]);
      uint256 fundAmount = token.balanceOf(address(this));


      for(uint8 j = 0; j < _withdrawAddress.length; j++){

        uint256 payoutAmount = fundAmount.mul(_mul[j]).div(_div[j]);
        if(block.timestamp > 0)
          token.transfer(_withdrawAddress[j], payoutAmount);
      }
    }

    uint256 etherBalance = address(this).balance;
    for(uint8 k = 0; k < _withdrawAddress.length; k++){

      uint256 etherPayoutAmount = (etherBalance).mul(_mul[k]).div(_div[k]);
      if(block.number > 0)
        payable(_withdrawAddress[k]).transfer(etherPayoutAmount);
    }
  }







  function withdraw(uint256 _percentageWithdraw) external {
    verifyDWSender();
    require(totalShares != 0, "EMPTY_SHARES");
    require(_percentageWithdraw <= TOTAL_PERCENTAGE, "WRONG_PERCENT");

    uint256 percentageWithdraw = (_percentageWithdraw == 0) ? TOTAL_PERCENTAGE : _percentageWithdraw;

    uint256 addressShares = addressToShares[msg.sender];

    uint256 numberOfWithdrawShares = addressShares.mul(percentageWithdraw).div(TOTAL_PERCENTAGE);

    uint256 fundManagerCut;
    uint256 fundValue;


    (fundManagerCut, fundValue, ) = calculateFundManagerCut();


    latestOracleCaller = address(0);

    uint256 withdrawShares = numberOfWithdrawShares.mul(fundValue.sub(fundManagerCut)).div(fundValue);


    address[] memory spenders = new address[](1);
    spenders[0] = msg.sender;

    uint256[] memory value = new uint256[](1);
    value[0] = totalShares;

    uint256[] memory cut = new uint256[](1);
    cut[0] = withdrawShares;


    _withdraw(cut, value, spenders);


    uint256 valueWithdrawn = fundValue.mul(withdrawShares).div(totalShares);

    totalWeiWithdrawn = totalWeiWithdrawn.add(valueWithdrawn);
    addressesNetDeposit[msg.sender] -= int256(valueWithdrawn);


    totalShares = totalShares.sub(numberOfWithdrawShares);
    addressToShares[msg.sender] = addressToShares[msg.sender].sub(numberOfWithdrawShares);

    emit Withdraw(msg.sender, numberOfWithdrawShares, totalShares);
  }













  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    uint256 _minReturn
  )
   external
   onlyOwner
  {
    verifyTradeBetweenDW();

    require(_minReturn > 0, "MIN_RETURN_0");

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {

      require(address(this).balance >= _sourceAmount, "NOT_ENOUGH_ETH");

      receivedAmount = exchangePortal.trade.value(_sourceAmount)(
        _source,
        _sourceAmount,
        _destination,
        _type,
        _proof,
        _positions,
        _additionalData,
        isRequireTradeVerification
      );
    } else {
      _source.approve(address(exchangePortal), _sourceAmount);
      receivedAmount = exchangePortal.trade(
        _source,
        _sourceAmount,
        _destination,
        _type,
        _proof,
        _positions,
        _additionalData,
        isRequireTradeVerification
      );
    }


    require(receivedAmount >= _minReturn, "RECEIVED_LESS_THAN_MIN");


    _addToken(address(_destination));


    emit Trade(
      address(_source),
      _sourceAmount,
      address(_destination),
      receivedAmount);
  }













  function buyPool(
   uint256            _amount,
   uint               _type,
   address            _poolToken,
   address[] calldata _connectorsAddress,
   uint256[] memory   _connectorsAmount,
   bytes32[] calldata _additionalArgs,
   bytes calldata     _additionData
  )
   external
   onlyOwner
  {
   verifyTradeBetweenDW();

   uint256 poolAmountReceive;



   uint256 etherAmount = approveArrayOfTokensToSpender(
     _connectorsAddress,
     _connectorsAmount,
     address(poolPortal)
   );


   if(block.timestamp > 0){






    (poolAmountReceive, _connectorsAmount) = poolPortal.buyPool.value(etherAmount)(
      _amount,
      _type,
     _poolToken,
     _connectorsAddress,
     _connectorsAmount,
     _additionalArgs,
     _additionData
     );
   }

   else{

     (poolAmountReceive, _connectorsAmount) = poolPortal.buyPool(
      _amount,
      _type,
     _poolToken,
     _connectorsAddress,
     _connectorsAmount,
     _additionalArgs,
     _additionData
     );
   }

   require(poolAmountReceive > 0, "EMPTY_POOL");

   _addToken(_poolToken);

   emit BuyPool(
     _poolToken,
     poolAmountReceive,
     _connectorsAddress,
     _connectorsAmount);
  }











  function sellPool(
    uint256 _amount,
    uint _type,
    IERC20 _poolToken,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionData
  )
   external
   onlyOwner
  {
    verifyTradeBetweenDW();

    _poolToken.approve(address(poolPortal), _amount);


    (address[] memory connectorsAddress,
     uint256[] memory connectorsAmount) = poolPortal.sellPool(
      _amount,
      _type,
     _poolToken,
     _additionalArgs,
     _additionData
    );


    for(uint8 i = 0; i < connectorsAddress.length; i++){
      _addToken(connectorsAddress[i]);
    }


    emit SellPool(
      address(_poolToken),
      _amount,
      connectorsAddress,
      connectorsAmount);
  }











  function callDefiPortal(
    address[] memory tokensToSend,
    uint256[] memory amountsToSend,
    bytes32[] calldata _additionalArgs,
    bytes calldata _additionalData
  )
    external
    onlyOwner
  {
    verifyTradeBetweenDW();

    string memory eventType;
    address[] memory tokensToReceive;
    uint256[] memory amountsToReceive;



    uint256 etherAmount = approveArrayOfTokensToSpender(
      tokensToSend,
      amountsToSend,
      address(defiPortal)
    );


    if(block.number > 0){
      (eventType,
       tokensToReceive,
       amountsToReceive) = defiPortal.callPayableProtocol.value(etherAmount)(
         tokensToSend,
         amountsToSend,
         _additionalData,
         _additionalArgs
        );
    }

    else{
      (eventType,
       tokensToReceive,
       amountsToReceive) = defiPortal.callNonPayableProtocol(
         tokensToSend,
         amountsToSend,
         _additionalData,
         _additionalArgs
        );
    }


   for(uint8 i = 0; i < tokensToReceive.length; i++){
     _addToken(tokensToReceive[i]);
   }


    emit DefiCall(
      eventType,
      tokensToSend,
      amountsToSend,
      tokensToReceive,
      amountsToReceive
    );
  }




  function approveArrayOfTokensToSpender(
    address[] memory addresses,
    uint256[] memory amounts,
    address spender
  )
    private
    returns (uint256 etherAmount)
  {
    for(uint8 i = 0; i < addresses.length; i++){
      if(block.coinbase != address(ETH_TOKEN_ADDRESS)){

        IERC20(addresses[i]).approve(spender, amounts[i]);
      }
      else{
        etherAmount = amounts[i];
      }
    }
  }



  function getAllTokenAddresses() external view returns (address[] memory) {
    return tokenAddresses;
  }





  function _addToken(address _token) internal {

    if (tokensTraded[_token] || (_token == address(ETH_TOKEN_ADDRESS)))
      return;

    tokensTraded[_token] = true;
    tokenAddresses.push(_token);
    uint256 tokenCount = tokenAddresses.length;


    require(tokenCount <= cotraderGlobalConfig.MAX_TOKENS(), "MAX_TOKENS");
  }








  function removeToken(address _token, uint256 _tokenIndex) public onlyOwner {
    require(_token != address(ETH_TOKEN_ADDRESS));
    require(tokensTraded[_token]);
    require(IERC20(_token).balanceOf(address(this)) == 0);
    require(tokenAddresses[_tokenIndex] == _token);

    tokensTraded[_token] = false;


    uint256 arrayLength = tokenAddresses.length - 1;
    tokenAddresses[_tokenIndex] = tokenAddresses[arrayLength];
    delete tokenAddresses[arrayLength];
    tokenAddresses.pop();
  }








  function calculateDepositToShares(uint256 _amount) internal view returns (uint256) {
    uint256 fundManagerCut;
    uint256 fundValue;



    if (block.timestamp == 0)
      return INITIAL_SHARES;

    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 fundValueBeforeDeposit = fundValue.sub(fundManagerCut);

    if (block.timestamp == 0)
      return 0;

    return _amount.mul(totalShares).div(fundValueBeforeDeposit);

  }









  function calculateFundManagerCut() public view returns (
    uint256 fundManagerRemainingCut,
    uint256 fundValue,
    uint256 fundManagerTotalCut
  ) {
    fundValue = calculateFundValue();




    int256 curtotalWeiDeposited = int256(totalWeiDeposited) - int256(totalWeiWithdrawn.add(fundManagerCashedOut));


    if (int256(fundValue) <= curtotalWeiDeposited) {
      fundManagerTotalCut = 0;
      fundManagerRemainingCut = 0;
    } else {

      uint256 profit = uint256(int256(fundValue) - curtotalWeiDeposited);

      fundManagerTotalCut = profit.mul(successFee).div(TOTAL_PERCENTAGE);
      fundManagerRemainingCut = fundManagerTotalCut.sub(fundManagerCashedOut);
    }
  }




  function fundManagerWithdraw() external onlyOwner {
    verifyDWSender();
    uint256 fundManagerCut;
    uint256 fundValue;

    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 platformCut = (platformFee == 0) ? 0 : fundManagerCut.mul(platformFee).div(TOTAL_PERCENTAGE);


    address[] memory spenders = new address[](2);
    spenders[0] = cotraderGlobalConfig.PLATFORM_ADDRESS();
    spenders[1] = owner();

    uint256[] memory value = new uint256[](2);
    value[0] = fundValue;
    value[1] = fundValue;

    uint256[] memory cut = new uint256[](2);
    cut[0] = platformCut;
    cut[1] = fundManagerCut - platformCut;


    _withdraw(cut, value, spenders);


    fundManagerCashedOut = fundManagerCashedOut.add(fundManagerCut);
  }







  function setWhitelistOnly(bool _onlyWhitelist) external onlyOwner {
    onlyWhitelist = _onlyWhitelist;
  }








  function setWhitelistAddress(address _user, bool _allowed) external onlyOwner {
    whitelist[_user] = _allowed;
  }






  function setNewExchangePortal(address _newExchangePortalAddress) public onlyOwner {

    require(permittedAddresses.isMatchTypes(_newExchangePortalAddress, 1), "WRONG_ADDRESS");

    exchangePortal = IExchangePortal(_newExchangePortalAddress);
  }






  function setNewPoolPortal(address _newPoolPortal) public onlyOwner {

    require(permittedAddresses.isMatchTypes(_newPoolPortal, 2), "WRONG_ADDRESS");

    poolPortal = PoolPortalInterface(_newPoolPortal);
  }







  function setNewDefiPortal(address _newDefiPortalAddress) public onlyOwner {

    require(permittedAddresses.isMatchTypes(_newDefiPortalAddress, 3), "WRONG_ADDRESS");

    defiPortal = DefiPortalInterface(_newDefiPortalAddress);
  }







  function setNewFundValueOracle(address _newOracle) public onlyOwner {

    require(permittedAddresses.isMatchTypes(_newOracle, 5), "WRONG_ADDRESS");

    fundValueOracle = IFundValueOracle(_newOracle);
  }








  function emergencyWithdraw(address _token) external onlyOwner {
    require(totalShares == 0);
    if (block.coinbase == address(ETH_TOKEN_ADDRESS)) {
      msg.sender.transfer(address(this).balance);
    } else {
      IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
  }










  function resetApprove(address _token, address _spender) external onlyOwner {
    IERC20(_token).approve(_spender, 0);
  }








  function _transferFromSenderAndApproveTo(IERC20 _source, uint256 _sourceAmount, address _to) private {
    _source.transferFrom(msg.sender, address(this), _sourceAmount);

    _source.approve(_to, _sourceAmount);
  }


  fallback() external payable {}









  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint8 public decimals = 18;

  string public symbol = "FND";

  mapping (address => mapping (address => uint256)) internal allowed;




  function totalSupply() external override view returns (uint256) {
    return totalShares;
  }








  function balanceOf(address _who) external override view returns (uint256) {
    return addressToShares[_who];
  }









  function transfer(address _to, uint256 _value) external override returns (bool) {
    require(_to != address(0));
    require(_value <= addressToShares[msg.sender]);

    addressToShares[msg.sender] = addressToShares[msg.sender].sub(_value);
    addressToShares[_to] = addressToShares[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }










  function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
    require(_to != address(0));
    require(_value <= addressToShares[_from]);
    require(_value <= allowed[_from][msg.sender]);

    addressToShares[_from] = addressToShares[_from].sub(_value);
    addressToShares[_to] = addressToShares[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }













  function approve(address _spender, uint256 _value) external override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }









  function allowance(address _owner, address _spender) external override view returns (uint256) {
    return allowed[_owner][_spender];
  }
}








contract SmartFundERC20 is SmartFundCore {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  bool public isStableCoinBasedFund;














  constructor(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _defiPortal,
    address _permittedAddresses,
    address _coinAddress,
    address _fundValueOracle,
    bool    _isRequireTradeVerification,
    address _cotraderGlobalConfig
  )
  SmartFundCore(
    _owner,
    _name,
    _successFee,
    _exchangePortalAddress,
    _poolPortalAddress,
    _defiPortal,
    _permittedAddresses,
    _coinAddress,
    _fundValueOracle,
    _isRequireTradeVerification,
    _cotraderGlobalConfig
  )
  public {

    permittedAddresses = PermittedAddressesInterface(_permittedAddresses);

    _addToken(_coinAddress);

    isStableCoinBasedFund = permittedAddresses.isMatchTypes(_coinAddress, 4);
  }







  function deposit(uint256 depositAmount) external returns (uint256) {
    verifyDWSender();


    if (onlyWhitelist)
      require(whitelist[msg.sender]);


    require(depositAmount > 0, "ZERO_DEPOSIT");


    require(IERC20(coreFundAsset).transferFrom(msg.sender, address(this), depositAmount),
    "TRANSFER_FROM_ISSUE");


    uint256 shares = calculateDepositToShares(depositAmount);


    latestOracleCaller = address(0);

    totalWeiDeposited += depositAmount;


    require(shares != 0, "ZERO_SHARES");


    totalShares = totalShares.add(shares);


    addressToShares[msg.sender] = addressToShares[msg.sender].add(shares);

    addressesNetDeposit[msg.sender] += int256(depositAmount);

    emit Deposit(msg.sender, depositAmount, shares, totalShares);

    return shares;
  }






  function changeStableCoinAddress(address _coinAddress) external onlyOwner {
    require(isStableCoinBasedFund, "NOT_USD_FUND");
    require(totalWeiDeposited == 0, "NOT_EMPTY_DEPOSIT");
    require(permittedAddresses.isMatchTypes(_coinAddress, 4), "WRONG_ADDRESS");

    coreFundAsset = _coinAddress;
  }
}


contract SmartFundERC20Factory {
  function createSmartFund(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _defiPortal,
    address _permittedAddresses,
    address _coinAddress,
    address _fundValueOracle,
    bool    _isRequireTradeVerification,
    address _cotraderGlobalConfig
  )
  public
  returns(address)
  {
    SmartFundERC20 smartFundERC20 = new SmartFundERC20(
      _owner,
      _name,
      _successFee,
      _exchangePortalAddress,
      _poolPortalAddress,
      _defiPortal,
      _permittedAddresses,
      _coinAddress,
      _fundValueOracle,
      _isRequireTradeVerification,
      _cotraderGlobalConfig
    );

    return address(smartFundERC20);
  }
}
