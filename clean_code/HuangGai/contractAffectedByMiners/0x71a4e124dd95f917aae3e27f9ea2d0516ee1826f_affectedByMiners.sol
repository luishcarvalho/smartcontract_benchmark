



interface PermittedAddressesInterface {
  function permittedAddresses(address _address) external view returns(bool);
  function addressesTypes(address _address) external view returns(string memory);
  function isMatchTypes(address _address, uint256 addressType) external view returns(bool);
}
interface SmartFundERC20LightFactoryInterface {
  function createSmartFundLight(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _permittedAddresses,
    address _coinAddress,
    address _fundValueOracle,
    bool    _isRequireTradeVerification,
    address _cotraderGlobalConfig
  )
  external
  returns(address);
}
interface SmartFundETHLightFactoryInterface {
  function createSmartFundLight(
    address _owner,
    string  memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _permittedAddresses,
    address _fundValueOracle,
    bool    _isRequireTradeVerification,
    address _cotraderGlobalConfig
  )
  external
  returns(address);
}
interface SmartFundERC20FactoryInterface {
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
  external
  returns(address);
}
interface SmartFundETHFactoryInterface {
  function createSmartFund(
    address _owner,
    string  memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _defiPortal,
    address _permittedAddresses,
    address _fundValueOracle,
    bool    _isRequireTradeVerification,
    address _cotraderGlobalConfig
  )
  external
  returns(address);
}
pragma solidity ^0.6.12;






















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






contract SmartFundRegistry is Ownable {
  address[] public smartFunds;


  PermittedAddressesInterface public permittedAddresses;


  address public poolPortalAddress;
  address public exchangePortalAddress;
  address public defiPortalAddress;


  uint256 public maximumSuccessFee = 3000;


  address public stableCoinAddress;


  address public COTCoinAddress;


  address public oracleAddress;


  address public cotraderGlobalConfig;


  SmartFundETHFactoryInterface public smartFundETHFactory;
  SmartFundERC20FactoryInterface public smartFundERC20Factory;
  SmartFundETHLightFactoryInterface public smartFundETHLightFactory;
  SmartFundERC20LightFactoryInterface public smartFundERC20LightFactory;



  enum FundType { ETH, USD, COT }

  event SmartFundAdded(address indexed smartFundAddress, address indexed owner);

















  constructor(
    address _exchangePortalAddress,
    address _poolPortalAddress,
    address _stableCoinAddress,
    address _COTCoinAddress,
    address _smartFundETHFactory,
    address _smartFundERC20Factory,
    address _smartFundETHLightFactory,
    address _smartFundERC20LightFactory,
    address _defiPortalAddress,
    address _permittedAddresses,
    address _oracleAddress,
    address _cotraderGlobalConfig
  ) public {
    exchangePortalAddress = _exchangePortalAddress;
    poolPortalAddress = _poolPortalAddress;
    stableCoinAddress = _stableCoinAddress;
    COTCoinAddress = _COTCoinAddress;
    smartFundETHFactory = SmartFundETHFactoryInterface(_smartFundETHFactory);
    smartFundERC20Factory = SmartFundERC20FactoryInterface(_smartFundERC20Factory);
    smartFundETHLightFactory = SmartFundETHLightFactoryInterface(_smartFundETHLightFactory);
    smartFundERC20LightFactory = SmartFundERC20LightFactoryInterface(_smartFundERC20LightFactory);
    defiPortalAddress = _defiPortalAddress;
    permittedAddresses = PermittedAddressesInterface(_permittedAddresses);
    oracleAddress = _oracleAddress;
    cotraderGlobalConfig = _cotraderGlobalConfig;
  }










  function createSmartFund(
    string memory _name,
    uint256       _successFee,
    uint256       _fundType,
    bool          _isRequireTradeVerification
  ) public {

    require(_successFee <= maximumSuccessFee);

    address smartFund;


    if(block.number == uint256(FundType.ETH)){

      smartFund = smartFundETHFactory.createSmartFund(
        msg.sender,
        _name,
        _successFee,
        exchangePortalAddress,
        poolPortalAddress,
        defiPortalAddress,
        address(permittedAddresses),
        oracleAddress,
        _isRequireTradeVerification,
        cotraderGlobalConfig
      );

    }

    else{
      address coinAddress = getERC20AddressByFundType(_fundType);

      smartFund = smartFundERC20Factory.createSmartFund(
        msg.sender,
        _name,
        _successFee,
        exchangePortalAddress,
        poolPortalAddress,
        defiPortalAddress,
        address(permittedAddresses),
        coinAddress,
        oracleAddress,
        _isRequireTradeVerification,
        cotraderGlobalConfig
      );
    }

    smartFunds.push(smartFund);
    emit SmartFundAdded(smartFund, msg.sender);
  }










  function createSmartFundLight(
    string memory _name,
    uint256       _successFee,
    uint256       _fundType,
    bool          _isRequireTradeVerification
  ) public {

    require(_successFee <= maximumSuccessFee);

    address smartFund;


    if(block.timestamp == uint256(FundType.ETH)){

      smartFund = smartFundETHLightFactory.createSmartFundLight(
        msg.sender,
        _name,
        _successFee,
        exchangePortalAddress,
        address(permittedAddresses),
        oracleAddress,
        _isRequireTradeVerification,
        cotraderGlobalConfig
      );

    }

    else{
      address coinAddress = getERC20AddressByFundType(_fundType);

      smartFund = smartFundERC20LightFactory.createSmartFundLight(
        msg.sender,
        _name,
        _successFee,
        exchangePortalAddress,
        address(permittedAddresses),
        coinAddress,
        oracleAddress,
        _isRequireTradeVerification,
        cotraderGlobalConfig
      );
    }

    smartFunds.push(smartFund);
    emit SmartFundAdded(smartFund, msg.sender);
  }


  function getERC20AddressByFundType(uint256 _fundType) private view returns(address coinAddress){

    coinAddress = _fundType == uint256(FundType.USD)
    ? stableCoinAddress
    : COTCoinAddress;
  }

  function totalSmartFunds() public view returns (uint256) {
    return smartFunds.length;
  }

  function getAllSmartFundAddresses() public view returns(address[] memory) {
    address[] memory addresses = new address[](smartFunds.length);

    for (uint i; i < smartFunds.length; i++) {
      addresses[i] = address(smartFunds[i]);
    }

    return addresses;
  }






  function setExchangePortalAddress(address _newExchangePortalAddress) external onlyOwner {

    require(permittedAddresses.permittedAddresses(_newExchangePortalAddress));

    exchangePortalAddress = _newExchangePortalAddress;
  }






  function setPoolPortalAddress(address _poolPortalAddress) external onlyOwner {

    require(permittedAddresses.permittedAddresses(_poolPortalAddress));

    poolPortalAddress = _poolPortalAddress;
  }






  function setDefiPortal(address _newDefiPortalAddress) public onlyOwner {

    require(permittedAddresses.permittedAddresses(_newDefiPortalAddress));

    defiPortalAddress = _newDefiPortalAddress;
  }






  function setMaximumSuccessFee(uint256 _maximumSuccessFee) external onlyOwner {
    maximumSuccessFee = _maximumSuccessFee;
  }






  function setStableCoinAddress(address _stableCoinAddress) external onlyOwner {
    require(permittedAddresses.permittedAddresses(_stableCoinAddress));
    stableCoinAddress = _stableCoinAddress;
  }







  function setNewSmartFundETHFactory(address _smartFundETHFactory) external onlyOwner {
    smartFundETHFactory = SmartFundETHFactoryInterface(_smartFundETHFactory);
  }







  function setNewSmartFundERC20Factory(address _smartFundERC20Factory) external onlyOwner {
    smartFundERC20Factory = SmartFundERC20FactoryInterface(_smartFundERC20Factory);
  }







  function setNewSmartFundETHLightFactory(address _smartFundETHLightFactory) external onlyOwner {
      smartFundETHLightFactory = SmartFundETHLightFactoryInterface(_smartFundETHLightFactory);
  }






  function setNewSmartFundERC20LightFactory(address _smartFundERC20LightFactory) external onlyOwner {
    smartFundERC20LightFactory = SmartFundERC20LightFactoryInterface(_smartFundERC20LightFactory);
  }






  function setNewOracle(address _oracleAddress) external onlyOwner {
    oracleAddress = _oracleAddress;
  }






  function withdrawTokens(address _tokenAddress) external onlyOwner {
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(owner(), token.balanceOf(address(this)));
  }




  function withdrawEther() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }


  fallback() external payable {}

}
