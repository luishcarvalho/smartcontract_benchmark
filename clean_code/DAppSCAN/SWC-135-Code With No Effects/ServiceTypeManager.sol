pragma solidity ^0.5.0;

import "./InitializableV2.sol";


contract ServiceTypeManager is InitializableV2 {
    address governanceAddress;





    mapping(bytes32 => bytes32[]) public serviceTypeVersions;





    mapping(bytes32 => mapping(bytes32 => bool)) public serviceTypeVersionInfo;


    bytes32[] private validServiceTypes;


    struct ServiceTypeStakeRequirements {
        uint minStake;
        uint maxStake;
    }


    mapping(bytes32 => ServiceTypeStakeRequirements) serviceTypeStakeRequirements;

    event SetServiceVersion(bytes32 _serviceType, bytes32 _serviceVersion);
    event Test(string msg, bool value);
    event TestAddr(string msg, address addr);





    function initialize(address _governanceAddress) public initializer
    {
        governanceAddress = _governanceAddress;
        InitializableV2.initialize();
    }


    function getGovernanceAddress() external view returns (address addr) {
        return governanceAddress;
    }






    function setGovernanceAddress(address _governanceAddress) external {
        require(msg.sender == governanceAddress, "Only governance");
        governanceAddress = _governanceAddress;
    }










    function addServiceType(
        bytes32 _serviceType,
        uint _serviceTypeMin,
        uint _serviceTypeMax
    ) external
    {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, "Only callable by Governance contract");
        require(!this.serviceTypeIsValid(_serviceType), "Already known service type");

        validServiceTypes.push(_serviceType);
        serviceTypeStakeRequirements[_serviceType] = ServiceTypeStakeRequirements({
            minStake: _serviceTypeMin,
            maxStake: _serviceTypeMax
        });
    }





    function removeServiceType(bytes32 _serviceType) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, "Only callable by Governance contract");

        uint serviceIndex = 0;
        bool foundService = false;
        for (uint i = 0; i < validServiceTypes.length; i ++) {
            if (validServiceTypes[i] == _serviceType) {
                serviceIndex = i;
                foundService = true;
                break;
            }
        }
        require(foundService == true, "Invalid service type, not found");

        uint lastIndex = validServiceTypes.length - 1;
        validServiceTypes[serviceIndex] = validServiceTypes[lastIndex];
        validServiceTypes.length--;

        serviceTypeStakeRequirements[_serviceType].minStake = 0;
        serviceTypeStakeRequirements[_serviceType].maxStake = 0;
    }







    function updateServiceType(
        bytes32 _serviceType,
        uint _serviceTypeMin,
        uint _serviceTypeMax
    ) external
    {
        _requireIsInitialized();
        require(
            msg.sender == governanceAddress,
            "Only callable by Governance contract"
        );

        require(this.serviceTypeIsValid(_serviceType), "Invalid service type");

        serviceTypeStakeRequirements[_serviceType].minStake = _serviceTypeMin;
        serviceTypeStakeRequirements[_serviceType].maxStake = _serviceTypeMax;
    }






    function getServiceTypeStakeInfo(bytes32 _serviceType)
    external view returns (uint min, uint max)
    {
        return (
            serviceTypeStakeRequirements[_serviceType].minStake,
            serviceTypeStakeRequirements[_serviceType].maxStake
        );
    }




    function getValidServiceTypes()
    external view returns (bytes32[] memory types)
    {
        return validServiceTypes;
    }




    function serviceTypeIsValid(bytes32 _serviceType)
    external view returns (bool isValid)
    {
        return serviceTypeStakeRequirements[_serviceType].maxStake > 0;
    }








    function setServiceVersion(
        bytes32 _serviceType,
        bytes32 _serviceVersion
    ) external
    {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, "Only callable by Governance contract");

        require(
            serviceTypeVersionInfo[_serviceType][_serviceVersion] == false,
            "Already registered"
        );


        serviceTypeVersions[_serviceType].push(_serviceVersion);


        serviceTypeVersionInfo[_serviceType][_serviceVersion] = true;

        emit SetServiceVersion(_serviceType, _serviceVersion);
    }






    function getVersion(bytes32 _serviceType, uint _versionIndex)
    external view returns (bytes32 version)
    {
        require(
            serviceTypeVersions[_serviceType].length > _versionIndex,
            "No registered version of serviceType"
        );
        return (serviceTypeVersions[_serviceType][_versionIndex]);
    }






    function getCurrentVersion(bytes32 _serviceType)
    external view returns (bytes32 currentVersion)
    {
        require(
            serviceTypeVersions[_serviceType].length >= 1,
            "No registered version of serviceType"
        );
        uint latestVersionIndex = serviceTypeVersions[_serviceType].length - 1;
        return (serviceTypeVersions[_serviceType][latestVersionIndex]);
    }





    function getNumberOfVersions(bytes32 _serviceType)
    external view returns (uint)
    {
        return serviceTypeVersions[_serviceType].length;
    }






    function serviceVersionIsValid(bytes32 _serviceType, bytes32 _serviceVersion)
    external view returns (bool isValidServiceVersion)
    {
        return serviceTypeVersionInfo[_serviceType][_serviceVersion];
    }
}
