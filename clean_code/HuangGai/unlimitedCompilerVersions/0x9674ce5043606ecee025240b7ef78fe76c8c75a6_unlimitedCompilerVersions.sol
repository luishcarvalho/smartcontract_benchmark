



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





contract PermittedAddresses is Ownable {
  event AddNewPermittedAddress(address newAddress, uint256 addressType);
  event RemovePermittedAddress(address Address);


  mapping (address => bool) public permittedAddresses;
  mapping (address => uint256) public addressesTypes;

  enum Types { EMPTY, EXCHANGE_PORTAL, POOL_PORTAL, DEFI_PORTAL, STABLE_COIN }









  constructor(
    address _exchangePortal,
    address _poolPortal,
    address _stableCoin,
    address _defiPortal
  ) public
  {
    _enableAddress(_exchangePortal, uint256(Types.EXCHANGE_PORTAL));
    _enableAddress(_poolPortal, uint256(Types.POOL_PORTAL));
    _enableAddress(_defiPortal, uint256(Types.DEFI_PORTAL));
    _enableAddress(_stableCoin, uint256(Types.STABLE_COIN));
  }







  function addNewAddress(address _newAddress, uint256 addressType) public onlyOwner {
    _enableAddress(_newAddress, addressType);
  }






  function updateAddressType(address _newAddress, uint256 addressType) public onlyOwner {
    addressesTypes[_newAddress] = addressType;
  }







  function disableAddress(address _address) public onlyOwner {
    permittedAddresses[_address] = false;
    emit RemovePermittedAddress(_address);
  }







  function _enableAddress(address _newAddress, uint256 addressType) private {
    permittedAddresses[_newAddress] = true;
    addressesTypes[_newAddress] = addressType;

    emit AddNewPermittedAddress(_newAddress, addressType);
  }




  function isMatchTypes(address _address, uint256 addressType) public view returns(bool){
    return addressesTypes[_address] == addressType;
  }




  function getType(address _address) public view returns(uint256){
    return addressesTypes[_address];
  }
}
