

pragma solidity 0.8.4;

import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "OpenZeppelin/openzeppelin-contracts@4.0.0/contracts/utils/Address.sol";

import "./WithdrawalsManagerStub.sol";




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
























contract WithdrawalsManagerProxy is ERC1967Proxy {



    address internal constant LIDO_VOTING = 0x2e59A20f205bB85a89C53f1936454680651E618e;






    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;




    event AdminChanged(address previousAdmin, address newAdmin);





    constructor() ERC1967Proxy(address(new WithdrawalsManagerStub()), new bytes(0)) {
        assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(LIDO_VOTING);
    }




    function implementation() external view returns (address) {
        return _implementation();
    }












    function proxy_upgradeTo(address newImplementation, bytes memory setupCalldata) external {
        address admin = _getAdmin();
        require(admin != address(0), "proxy: ossified");
        require(msg.sender == admin, "proxy: unauthorized");

        _upgradeTo(newImplementation);

        if (setupCalldata.length > 0) {
            Address.functionDelegateCall(newImplementation, setupCalldata, "proxy: setup failed");
        }
    }




    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }




    function _setAdmin(address newAdmin) private {
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }




    function proxy_getAdmin() external view returns (address) {
        return _getAdmin();
    }






    function proxy_changeAdmin(address newAdmin) external {
        address admin = _getAdmin();
        require(msg.sender == admin, "proxy: unauthorized");
        emit AdminChanged(admin, newAdmin);
        _setAdmin(newAdmin);
    }




    function proxy_getIsOssified() external view returns (bool) {
        return _getAdmin() == address(0);
    }
}
