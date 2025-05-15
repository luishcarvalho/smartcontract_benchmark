pragma solidity 0.4.23;

import "./OraclizeAPI.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IExchangeRates.sol";


contract ExchangeRateProvider is usingOraclize {
  uint8 public constant version = 1;

  IRegistry private registry;


  modifier onlyAllowed()
  {
    require(
      msg.sender == registry.getContractAddress("ExchangeRates") ||
      msg.sender == oraclize_cbAddress()
    );
    _;
  }

  modifier onlyExchangeRates()
  {
    require(msg.sender == registry.getContractAddress("ExchangeRates"));
    _;
  }

  constructor(
    address _registryAddress
  )
    public
  {
    require(_registryAddress != address(0));
    registry = IRegistry(_registryAddress);
  }


  function setCallbackGasPrice(uint256 _gasPrice)
    onlyExchangeRates
    external
    returns (bool)
  {
    oraclize_setCustomGasPrice(_gasPrice);
    return true;
  }




  function sendQuery(
    string _queryString,

    uint256 _callInterval,
    uint256 _callbackGasLimit,
    string _queryType
  )
    onlyAllowed
    payable
    public
    returns (bool)
  {

    if (oraclize_getPrice("URL") > address(this).balance) {
      setQueryId(0x0, "");
      return false;
    } else {

      bytes32 _queryId = oraclize_query(
        _callInterval,
        "URL",
        _queryString,
        _callbackGasLimit
      );


      setQueryId(_queryId, _queryType);
      return true;
    }
  }


  function setQueryId(bytes32 _identifier, string _queryType)
    private
    returns (bool)
  {

    IExchangeRates _exchangeRates = IExchangeRates(
      registry.getContractAddress("ExchangeRates")
    );

    _exchangeRates.setQueryId(_identifier, _queryType);
  }



  function __callback(bytes32 _queryId, string _result)
    public
  {

    require(msg.sender == oraclize_cbAddress());

    IExchangeRates _exchangeRates = IExchangeRates(
      registry.getContractAddress("ExchangeRates")
    );

    bool _ratesActive = _exchangeRates.ratesActive();
    uint256 _callInterval;
    uint256 _callbackGasLimit;
    string memory _queryString;
    string memory _queryType = _exchangeRates.queryTypes(_queryId);
    (
      _callInterval,
      _callbackGasLimit,
      _queryString
    ) = _exchangeRates.getCurrencySettings(_queryType);



    require(_exchangeRates.setRate(_queryId, parseInt(_result, 2)));



    if (_callInterval > 0 && _ratesActive) {
      sendQuery(
        _queryString,
        _callInterval,
        _callbackGasLimit,
        _queryType
      );
    }
  }


  function selfDestruct(address _address)
    onlyExchangeRates
    public
  {
    selfdestruct(_address);
  }


  function()
    payable
    public
  {}
}
