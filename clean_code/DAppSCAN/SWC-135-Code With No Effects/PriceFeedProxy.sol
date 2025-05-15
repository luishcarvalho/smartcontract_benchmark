

pragma solidity 0.8.4;

import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/utils/Address.sol";




library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

interface IPriceFeed {
    function initialize(
        uint256 maxSafePriceDifference,
        address stableSwapOracleAddress,
        address curvePoolAddress,
        address admin
    ) external;
}

contract PriceFeedProxy is ERC1967Proxy {





    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;




    event AdminChanged(address previousAdmin, address newAdmin);







    constructor(
        address priceFeedImpl,
        uint256 maxSafePriceDifference,
        address stableSwapOracleAddress,
        address curvePoolAddress,
        address admin
    )
        payable
        ERC1967Proxy(
            priceFeedImpl,
            abi.encodeWithSelector(
                IPriceFeed(address(0)).initialize.selector,
                maxSafePriceDifference,
                stableSwapOracleAddress,
                curvePoolAddress,
                admin
            )
        )
    {

        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin);
    }




    function implementation() external view returns (address) {
        return _implementation();
    }








    function upgradeTo(address newImplementation, bytes memory setupCalldata) external {
        require(msg.sender == _getAdmin(), "ERC1967: unauthorized");
        _upgradeTo(newImplementation);
        if (setupCalldata.length > 0) {
            Address.functionDelegateCall(newImplementation, setupCalldata, "ERC1967: setup failed");
        }
    }




    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }




    function _setAdmin(address newAdmin) private {
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }




    function getProxyAdmin() external view returns (address) {
        return _getAdmin();
    }






    function changeProxyAdmin(address newAdmin) external {
        address admin = _getAdmin();
        require(msg.sender == admin, "ERC1967: unauthorized");
        emit AdminChanged(admin, newAdmin);
        _setAdmin(newAdmin);
    }
}
