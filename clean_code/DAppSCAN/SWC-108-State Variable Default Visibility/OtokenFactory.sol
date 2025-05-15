pragma solidity =0.6.10;

import {OtokenSpawner} from "./OtokenSpawner.sol";
import {SafeMath} from "./packages/oz/SafeMath.sol";
import {AddressBookInterface} from "./interfaces/AddressBookInterface.sol";
import {OtokenInterface} from "./interfaces/OtokenInterface.sol";
import {WhitelistInterface} from "./interfaces/WhitelistInterface.sol";









contract OtokenFactory is OtokenSpawner {
    using SafeMath for uint256;

    address public addressBook;


    address[] public otokens;


    mapping(bytes32 => address) private idToAddress;

    constructor(address _addressBook) public {
        addressBook = _addressBook;
    }


    event OtokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        address underlying,
        address strike,
        address collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );












    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address) {
        require(_expiry > now, "OtokenFactory: Can't create expired option");

        require(_expiry < 11865398400, "OtokenFactory: Can't create option with expiry > 2345/12/31");
        require(_expiry.sub(28800).mod(86400) == 0, "OtokenFactory: Option has to expire 08:00 UTC");
        bytes32 id = _getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        require(idToAddress[id] == address(0), "OtokenFactory: Option already created");

        address whitelist = AddressBookInterface(addressBook).getWhitelist();
        require(
            WhitelistInterface(whitelist).isWhitelistedProduct(
                _underlyingAsset,
                _strikeAsset,
                _collateralAsset,
                _isPut
            ),
            "OtokenFactory: Unsupported Product"
        );

        require(!_isPut || _strikePrice > 0, "OtokenFactory: Can't create a $0 strike put option");

        address otokenImpl = AddressBookInterface(addressBook).getOtokenImpl();

        bytes memory initializationCalldata = abi.encodeWithSelector(
            OtokenInterface(otokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        address newOtoken = _spawn(otokenImpl, initializationCalldata);

        idToAddress[id] = newOtoken;
        otokens.push(newOtoken);
        WhitelistInterface(whitelist).whitelistOtoken(newOtoken);

        emit OtokenCreated(
            newOtoken,
            msg.sender,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        return newOtoken;
    }





    function getOtokensLength() external view returns (uint256) {
        return otokens.length;
    }











    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        bytes32 id = _getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        return idToAddress[id];
    }












    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        address otokenImpl = AddressBookInterface(addressBook).getOtokenImpl();
        bytes memory initializationCalldata = abi.encodeWithSelector(
            OtokenInterface(otokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );
        return _computeAddress(AddressBookInterface(addressBook).getOtokenImpl(), initializationCalldata);
    }











    function _getOptionId(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut)
            );
    }
}
