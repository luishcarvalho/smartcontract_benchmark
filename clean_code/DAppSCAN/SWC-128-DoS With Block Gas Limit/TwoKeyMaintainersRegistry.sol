pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/storage-contracts/ITwoKeyMaintainersRegistryStorage.sol";
import "../upgradability/Upgradeable.sol";







contract TwoKeyMaintainersRegistry is Upgradeable {



    bool initialized;

    address public TWO_KEY_SINGLETON_REGISTRY;

    ITwoKeyMaintainersRegistryStorage public PROXY_STORAGE_CONTRACT;





    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage,
        address [] _maintainers
    )
    public
    {
        require(initialized == false);


        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        PROXY_STORAGE_CONTRACT = ITwoKeyMaintainersRegistryStorage(_proxyStorage);



        addMaintainer(msg.sender);


        for(uint i=0; i<_maintainers.length; i++) {
            addMaintainer(_maintainers[i]);
        }


        initialized = true;
    }





    function onlyTwoKeyAdmin(address sender) public view returns (bool) {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(sender == address(twoKeyAdmin));
        return true;
    }

    function onlyMaintainer(address _sender) public view returns (bool) {
        return isMaintainer(_sender);
    }






    function addMaintainers(
        address [] _maintainers
    )
    public
    {
        require(onlyTwoKeyAdmin(msg.sender) == true);

        uint numberOfMaintainers = _maintainers.length;

        for(uint i=0; i<numberOfMaintainers; i++) {
            addMaintainer(_maintainers[i]);
        }
    }






    function removeMaintainers(
        address [] _maintainers
    )
    public
    {
        require(onlyTwoKeyAdmin(msg.sender) == true);

        uint numberOfMaintainers = _maintainers.length;

        for(uint i=0; i<numberOfMaintainers; i++) {

            removeMaintainer(_maintainers[i]);
        }
    }


    function isMaintainer(
        address _address
    )
    internal
    view
    returns (bool)
    {
        bytes32 keyHash = keccak256("isMaintainer", _address);
        return PROXY_STORAGE_CONTRACT.getBool(keyHash);
    }

    function addMaintainer(
        address _maintainer
    )
    internal
    {
        bytes32 keyHash = keccak256("isMaintainer", _maintainer);
        PROXY_STORAGE_CONTRACT.setBool(keyHash, true);
    }

    function removeMaintainer(
        address _maintainer
    )
    internal
    {
        bytes32 keyHash = keccak256("isMaintainer", _maintainer);
        PROXY_STORAGE_CONTRACT.setBool(keyHash, false);
    }


    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }

}
