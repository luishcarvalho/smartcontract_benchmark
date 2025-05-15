

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IRegistry.sol";





contract Registry is IRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;


    mapping(address => uint8) public safeGuardVersion;

    EnumerableSet.AddressSet private safeGuards;


    event Register(address indexed safeGuard, uint8 version);




    function register(address safeGuard, uint8 version) external override {
        require(version != 0, "Registry: Invalid version");

        require(
            !safeGuards.contains(safeGuard),
            "Registry: SafeGuard already registered"
        );

        safeGuards.add(safeGuard);
        safeGuardVersion[safeGuard] = version;

        emit Register(safeGuard, version);
    }





    function getSafeGuard(uint256 index)
        external
        view
        override
        returns (address)
    {
        require(index < safeGuards.length(), "Registry: Invalid index");

        return safeGuards.at(index);
    }


    function getSafeGuardCount() external view override returns (uint256) {
        return safeGuards.length();
    }


}
