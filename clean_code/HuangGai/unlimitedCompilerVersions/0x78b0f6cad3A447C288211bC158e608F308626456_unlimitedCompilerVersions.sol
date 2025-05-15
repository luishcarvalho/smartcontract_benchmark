





pragma solidity ^0.6.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



pragma solidity ^0.6.0;













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



pragma solidity ^0.6.0;

interface IAddressRegistry {
    function get(bytes32 _key) external view returns(address);
    function set(bytes32 _key, address _value) external;
}


pragma solidity ^0.6.0;



contract AddressRegistryParent is Ownable, IAddressRegistry{
    bytes32[] internal _keys;
    mapping(bytes32 => address) internal _registry;

    event AddressAdded(bytes32 _key, address _value);

    function set(bytes32 _key, address _value) external override onlyOwner() {
        _check(_key, _value);
        emit AddressAdded(_key, _value);
        _keys.push(_key);
        _registry[_key] = _value;
    }

    function get(bytes32 _key) external override view returns(address) {
        return _registry[_key];
    }

    function _check(bytes32 _key, address _value) internal virtual {
        require(_value != address(0), "Nullable address");
        require(_registry[_key] == address(0), "Existed key");
    }
}



pragma solidity ^0.6.0;




interface IDerivativeSpecification {




    function isDerivativeSpecification() external pure returns(bool);





    function oracleSymbols() external view returns (bytes32[] memory);





    function oracleIteratorSymbols() external view returns (bytes32[] memory);




    function collateralTokenSymbol() external view returns (bytes32);





    function collateralSplitSymbol() external view returns (bytes32);




    function mintingPeriod() external view returns (uint);




    function livePeriod() external view returns (uint);




    function primaryNominalValue() external view returns (uint);




    function complementNominalValue() external view returns (uint);




    function authorFee() external view returns (uint);




    function symbol() external view returns (string memory);




    function name() external view returns (string memory);




    function baseURI() external view returns (string memory);




    function author() external view returns (address);
}





pragma solidity ^0.6.0;



contract DerivativeSpecificationRegistry is AddressRegistryParent {
    function _check(bytes32 _key, address _value) internal virtual override{
        super._check(_key, _value);
        IDerivativeSpecification derivative = IDerivativeSpecification(_value);
        require(derivative.isDerivativeSpecification(), "Should be derivative specification");

        require(_key == keccak256(abi.encodePacked(derivative.symbol())), "Incorrect hash");

        for (uint i = 0; i < _keys.length; i++) {
            bytes32 key = _keys[i];
            IDerivativeSpecification value = IDerivativeSpecification(_registry[key]);
            if( keccak256(abi.encodePacked(derivative.oracleSymbols())) == keccak256(abi.encodePacked(value.oracleSymbols())) &&
                keccak256(abi.encodePacked(derivative.oracleIteratorSymbols())) == keccak256(abi.encodePacked(value.oracleIteratorSymbols())) &&
                derivative.collateralTokenSymbol() == value.collateralTokenSymbol() &&
                derivative.collateralSplitSymbol() == value.collateralSplitSymbol() &&
                derivative.mintingPeriod() == value.mintingPeriod() &&
                derivative.livePeriod() == value.livePeriod() &&
                derivative.primaryNominalValue() == value.primaryNominalValue() &&
                derivative.complementNominalValue() == value.complementNominalValue() &&
                derivative.authorFee() == value.authorFee() ) {

                revert("Same spec params");
            }
        }
    }
}
