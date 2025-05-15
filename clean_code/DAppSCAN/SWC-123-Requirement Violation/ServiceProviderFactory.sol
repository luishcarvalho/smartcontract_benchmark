pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./ServiceTypeManager.sol";
import "./ClaimsManager.sol";
import "./Staking.sol";


contract ServiceProviderFactory is InitializableV2 {
    using SafeMath for uint;

    address private stakingAddress;
    address private delegateManagerAddress;
    address private governanceAddress;
    address private serviceTypeManagerAddress;
    address private claimsManagerAddress;
    uint private decreaseStakeLockupDuration;








    struct ServiceProviderDetails {
        uint deployerStake;
        uint deployerCut;
        bool validBounds;
        uint numberOfEndpoints;
        uint minAccountStake;
        uint maxAccountStake;
    }


    struct DecreaseStakeRequest {
        uint decreaseAmount;
        uint lockupExpiryBlock;
    }


    mapping(address => ServiceProviderDetails) spDetails;



    uint minDeployerStake;


    uint8 private constant DECIMALS = 18;



    uint private constant DEPLOYER_CUT_BASE = 100;



    struct ServiceEndpoint {
        address owner;
        string endpoint;
        uint blocknumber;
        address delegateOwnerWallet;
    }




    mapping(bytes32 => uint) serviceProviderTypeIDs;




    mapping(bytes32 => mapping(uint => ServiceEndpoint)) serviceProviderInfo;




    mapping(bytes32 => uint) serviceProviderEndpointToId;




    mapping(address => mapping(bytes32 => uint[])) serviceProviderAddressToId;


    mapping(address => DecreaseStakeRequest) decreaseStakeRequests;

    event RegisteredServiceProvider(
      uint _spID,
      bytes32 _serviceType,
      address _owner,
      string _endpoint,
      uint256 _stakeAmount
    );

    event DeregisteredServiceProvider(
      uint _spID,
      bytes32 _serviceType,
      address _owner,
      string _endpoint,
      uint256 _unstakeAmount
    );

    event UpdatedStakeAmount(
      address _owner,
      uint256 _stakeAmount
    );

    event UpdateEndpoint(
      bytes32 _serviceType,
      address _owner,
      string _oldEndpoint,
      string _newEndpoint,
      uint spId
    );





    function initialize (address _governanceAddress) public initializer
    {
        governanceAddress = _governanceAddress;


        minDeployerStake = 5 * 10**uint256(DECIMALS);


        decreaseStakeLockupDuration = 10;

        InitializableV2.initialize();
    }









    function register(
        bytes32 _serviceType,
        string calldata _endpoint,
        uint256 _stakeAmount,
        address _delegateOwnerWallet
    ) external returns (uint spID)
    {
        _requireIsInitialized();
        require(serviceTypeManagerAddress != address(0x00), "serviceTypeManagerAddress not set");
        require(stakingAddress != address(0x00), "stakingAddress not set");

        require(
            ServiceTypeManager(serviceTypeManagerAddress).serviceTypeIsValid(_serviceType),
            "Valid service type required");


        if (_stakeAmount > 0) {
            require(!_claimPending(msg.sender), "No claim expected to be pending prior to stake transfer");
            Staking(stakingAddress).stakeFor(msg.sender, _stakeAmount);
        }

        require (
            serviceProviderEndpointToId[keccak256(bytes(_endpoint))] == 0,
            "Endpoint already registered");

        uint newServiceProviderID = serviceProviderTypeIDs[_serviceType].add(1);
        serviceProviderTypeIDs[_serviceType] = newServiceProviderID;


        serviceProviderInfo[_serviceType][newServiceProviderID] = ServiceEndpoint({
            owner: msg.sender,
            endpoint: _endpoint,
            blocknumber: block.number,
            delegateOwnerWallet: _delegateOwnerWallet
        });


        serviceProviderEndpointToId[keccak256(bytes(_endpoint))] = newServiceProviderID;


        serviceProviderAddressToId[msg.sender][_serviceType].push(newServiceProviderID);


        spDetails[msg.sender].numberOfEndpoints = spDetails[msg.sender].numberOfEndpoints.add(1);


        spDetails[msg.sender].deployerStake = (
            spDetails[msg.sender].deployerStake.add(_stakeAmount)
        );


        (uint typeMin, uint typeMax) = ServiceTypeManager(
            serviceTypeManagerAddress
        ).getServiceTypeStakeInfo(_serviceType);
        spDetails[msg.sender].minAccountStake = spDetails[msg.sender].minAccountStake.add(typeMin);
        spDetails[msg.sender].maxAccountStake = spDetails[msg.sender].maxAccountStake.add(typeMax);


        this.validateAccountStakeBalance(msg.sender);
        uint currentlyStakedForOwner = Staking(stakingAddress).totalStakedFor(msg.sender);



        spDetails[msg.sender].validBounds = true;

        emit RegisteredServiceProvider(
            newServiceProviderID,
            _serviceType,
            msg.sender,
            _endpoint,
            currentlyStakedForOwner
        );

        return newServiceProviderID;
    }








    function deregister(
        bytes32 _serviceType,
        string calldata _endpoint
    ) external returns (uint deregisteredSpID)
    {
        _requireIsInitialized();


        uint unstakeAmount = 0;
        bool unstaked = false;

        if (spDetails[msg.sender].numberOfEndpoints == 1) {
            unstakeAmount = spDetails[msg.sender].deployerStake;


            decreaseStakeRequests[msg.sender] = DecreaseStakeRequest({
                decreaseAmount: unstakeAmount,
                lockupExpiryBlock: block.number.add(decreaseStakeLockupDuration)
            });

            unstaked = true;
        }

        require (
            serviceProviderEndpointToId[keccak256(bytes(_endpoint))] != 0,
            "Endpoint not registered");


        uint deregisteredID = serviceProviderEndpointToId[keccak256(bytes(_endpoint))];


        serviceProviderEndpointToId[keccak256(bytes(_endpoint))] = 0;

        require(
            keccak256(bytes(serviceProviderInfo[_serviceType][deregisteredID].endpoint)) == keccak256(bytes(_endpoint)),
            "Invalid endpoint for service type");

        require (
            serviceProviderInfo[_serviceType][deregisteredID].owner == msg.sender,
            "Only callable by endpoint owner");


        delete serviceProviderInfo[_serviceType][deregisteredID];

        uint spTypeLength = serviceProviderAddressToId[msg.sender][_serviceType].length;
        for (uint i = 0; i < spTypeLength; i ++) {
            if (serviceProviderAddressToId[msg.sender][_serviceType][i] == deregisteredID) {

                serviceProviderAddressToId[msg.sender][_serviceType][i] = serviceProviderAddressToId[msg.sender][_serviceType][spTypeLength - 1];

                serviceProviderAddressToId[msg.sender][_serviceType].length--;

                break;
            }
        }


        spDetails[msg.sender].numberOfEndpoints -= 1;


        (uint typeMin, uint typeMax) = ServiceTypeManager(
            serviceTypeManagerAddress
        ).getServiceTypeStakeInfo(_serviceType);
        spDetails[msg.sender].minAccountStake = spDetails[msg.sender].minAccountStake.sub(typeMin);
        spDetails[msg.sender].maxAccountStake = spDetails[msg.sender].maxAccountStake.sub(typeMax);

        emit DeregisteredServiceProvider(
            deregisteredID,
            _serviceType,
            msg.sender,
            _endpoint,
            unstakeAmount);



        if (!unstaked) {
            this.validateAccountStakeBalance(msg.sender);

            spDetails[msg.sender].validBounds = true;
        }

        return deregisteredID;
    }






    function increaseStake(
        uint256 _increaseStakeAmount
    ) external returns (uint newTotalStake)
    {
        _requireIsInitialized();


        require(
            spDetails[msg.sender].numberOfEndpoints > 0,
            "Registered endpoint required to increase stake"
        );
        require(
            !_claimPending(msg.sender),
            "No claim expected to be pending prior to stake transfer"
        );

        Staking stakingContract = Staking(
            stakingAddress
        );


        stakingContract.stakeFor(msg.sender, _increaseStakeAmount);

        uint newStakeAmount = stakingContract.totalStakedFor(msg.sender);


        spDetails[msg.sender].deployerStake = (
            spDetails[msg.sender].deployerStake.add(_increaseStakeAmount)
        );


        this.validateAccountStakeBalance(msg.sender);


        spDetails[msg.sender].validBounds = true;

        emit UpdatedStakeAmount(
            msg.sender,
            newStakeAmount
        );

        return newStakeAmount;
    }








    function requestDecreaseStake(uint _decreaseStakeAmount)
    external returns (uint newStakeAmount)
    {
        _requireIsInitialized();
        require(
            !_claimPending(msg.sender),
            "No claim expected to be pending prior to stake transfer"
        );

        Staking stakingContract = Staking(
            stakingAddress
        );

        uint currentStakeAmount = stakingContract.totalStakedFor(msg.sender);


        _validateBalanceInternal(msg.sender, (currentStakeAmount.sub(_decreaseStakeAmount)));

        decreaseStakeRequests[msg.sender] = DecreaseStakeRequest({
            decreaseAmount: _decreaseStakeAmount,
            lockupExpiryBlock: block.number.add(decreaseStakeLockupDuration)
        });

        return currentStakeAmount.sub(_decreaseStakeAmount);
    }







    function cancelDecreaseStakeRequest(address _account) external
    {
        require(
            msg.sender == _account || msg.sender == delegateManagerAddress,
            "Only callable from owner or DelegateManager"
        );
        require(_decreaseRequestIsPending(_account), "Decrease stake request must be pending");


        decreaseStakeRequests[_account] = DecreaseStakeRequest({
            decreaseAmount: 0,
            lockupExpiryBlock: 0
        });
    }






    function decreaseStake() external returns (uint newTotalStake)
    {
        _requireIsInitialized();

        require(_decreaseRequestIsPending(msg.sender), "Decrease stake request must be pending");
        require(
            decreaseStakeRequests[msg.sender].lockupExpiryBlock <= block.number,
            "Lockup must be expired"
        );

        Staking stakingContract = Staking(
            stakingAddress
        );


        stakingContract.unstakeFor(msg.sender, decreaseStakeRequests[msg.sender].decreaseAmount);


        uint newStakeAmount = stakingContract.totalStakedFor(msg.sender);


        spDetails[msg.sender].deployerStake = (
            spDetails[msg.sender].deployerStake.sub(decreaseStakeRequests[msg.sender].decreaseAmount)
        );



        if (spDetails[msg.sender].numberOfEndpoints > 0) {
            this.validateAccountStakeBalance(msg.sender);
        }


        spDetails[msg.sender].validBounds = true;


        delete decreaseStakeRequests[msg.sender];

        emit UpdatedStakeAmount(
            msg.sender,
            newStakeAmount
        );

        return newStakeAmount;
    }







    function updateDelegateOwnerWallet(
        bytes32 _serviceType,
        string calldata _endpoint,
        address _updatedDelegateOwnerWallet
    ) external
    {
        uint spID = this.getServiceProviderIdFromEndpoint(_endpoint);

        require(
            serviceProviderInfo[_serviceType][spID].owner == msg.sender,
            "Invalid update operation, wrong owner");

        serviceProviderInfo[_serviceType][spID].delegateOwnerWallet = _updatedDelegateOwnerWallet;
    }







    function updateEndpoint(
        bytes32 _serviceType,
        string calldata _oldEndpoint,
        string calldata _newEndpoint
    ) external returns (uint spID)
    {
        uint spId = this.getServiceProviderIdFromEndpoint(_oldEndpoint);

        require (spId != 0, "Could not find service provider with that endpoint");

        ServiceEndpoint memory sp = serviceProviderInfo[_serviceType][spId];

        require(sp.owner == msg.sender,"Invalid update endpoint operation, wrong owner");

        require(
            keccak256(bytes(sp.endpoint)) == keccak256(bytes(_oldEndpoint)),
            "Old endpoint doesn't match what's registered for the service provider"
        );


        serviceProviderEndpointToId[keccak256(bytes(sp.endpoint))] = 0;


        sp.endpoint = _newEndpoint;
        serviceProviderInfo[_serviceType][spId] = sp;
        serviceProviderEndpointToId[keccak256(bytes(_newEndpoint))] = spId;
        return spId;
    }







    function updateServiceProviderStake(
        address _serviceProvider,
        uint _amount
     ) external
    {
        require(delegateManagerAddress != address(0x00), "delegateManagerAddress not set");
        require(
            msg.sender == delegateManagerAddress,
            "updateServiceProviderStake - only callable by DelegateManager"
        );

        spDetails[_serviceProvider].deployerStake = _amount;
        _updateServiceProviderBoundStatus(_serviceProvider);
    }









    function updateServiceProviderCut(
        address _serviceProvider,
        uint _cut
    ) external
    {
        require(
            msg.sender == _serviceProvider,
            "Service Provider cut update operation restricted to deployer");

        require(
            _cut <= DEPLOYER_CUT_BASE,
            "Service Provider cut cannot exceed base value");
        spDetails[_serviceProvider].deployerCut = _cut;
    }


    function updateDecreaseStakeLockupDuration(uint _duration) external {
        _requireIsInitialized();

        require(
            msg.sender == governanceAddress,
            "Only callable by Governance contract"
        );

        decreaseStakeLockupDuration = _duration;
    }


    function getServiceProviderDeployerCutBase()
    external pure returns (uint base)
    {
        return DEPLOYER_CUT_BASE;
    }


    function getTotalServiceTypeProviders(bytes32 _serviceType)
    external view returns (uint numberOfProviders)
    {
        return serviceProviderTypeIDs[_serviceType];
    }


    function getServiceProviderIdFromEndpoint(string calldata _endpoint)
    external view returns (uint spID)
    {
        return serviceProviderEndpointToId[keccak256(bytes(_endpoint))];
    }


    function getMinDeployerStake()
    external view returns (uint min)
    {
        return minDeployerStake;
    }





    function getServiceProviderIdsFromAddress(address _ownerAddress, bytes32 _serviceType)
    external view returns (uint[] memory spIds)
    {
        return serviceProviderAddressToId[_ownerAddress][_serviceType];
    }






    function getServiceEndpointInfo(bytes32 _serviceType, uint _serviceId)
    external view returns (address owner, string memory endpoint, uint blockNumber, address delegateOwnerWallet)
    {
        ServiceEndpoint memory sp = serviceProviderInfo[_serviceType][_serviceId];
        return (sp.owner, sp.endpoint, sp.blocknumber, sp.delegateOwnerWallet);
    }





    function getServiceProviderDetails(address _sp)
    external view returns (
        uint deployerStake,
        uint deployerCut,
        bool validBounds,
        uint numberOfEndpoints,
        uint minAccountStake,
        uint maxAccountStake)
    {
        return (
            spDetails[_sp].deployerStake,
            spDetails[_sp].deployerCut,
            spDetails[_sp].validBounds,
            spDetails[_sp].numberOfEndpoints,
            spDetails[_sp].minAccountStake,
            spDetails[_sp].maxAccountStake
        );
    }





    function getPendingDecreaseStakeRequest(address _sp)
    external view returns (uint amount, uint lockupExpiryBlock)
    {
        return (
            decreaseStakeRequests[_sp].decreaseAmount,
            decreaseStakeRequests[_sp].lockupExpiryBlock
        );
    }


    function getDecreaseStakeLockupDuration()
    external view returns (uint duration)
    {
        return decreaseStakeLockupDuration;
    }






    function validateAccountStakeBalance(address _sp)
    external view
    {
        _validateBalanceInternal(_sp, Staking(stakingAddress).totalStakedFor(_sp));
    }


    function getGovernanceAddress() external view returns (address addr) {
        return governanceAddress;
    }


    function getStakingAddress() external view returns (address addr) {
        return stakingAddress;
    }


    function getDelegateManagerAddress() external view returns (address addr) {
        return delegateManagerAddress;
    }


    function getServiceTypeManagerAddress() external view returns (address addr) {
        return serviceTypeManagerAddress;
    }


    function getClaimsManagerAddress() external view returns (address addr) {
        return claimsManagerAddress;
    }






    function setGovernanceAddress(address _address) external {
        require(msg.sender == governanceAddress, "Only callable by Governance contract");
        governanceAddress = _address;
    }






    function setStakingAddress(address _address) external {
        require(msg.sender == governanceAddress, "Only callable by Governance contract");
        stakingAddress = _address;
    }






    function setDelegateManagerAddress(address _address) external {
        require(msg.sender == governanceAddress, "Only callable by Governance contract");
        delegateManagerAddress = _address;
    }






    function setServiceTypeManagerAddress(address _address) external {
        require(msg.sender == governanceAddress, "Only callable by Governance contract");
        serviceTypeManagerAddress = _address;
    }






    function setClaimsManagerAddress(address _address) external {
        require(msg.sender == governanceAddress, "Only callable by Governance contract");
        claimsManagerAddress = _address;
    }




    function _updateServiceProviderBoundStatus(address _serviceProvider) internal {

        uint totalSPStake = Staking(stakingAddress).totalStakedFor(_serviceProvider);
        if (totalSPStake < spDetails[_serviceProvider].minAccountStake ||
            totalSPStake > spDetails[_serviceProvider].maxAccountStake) {

            spDetails[_serviceProvider].validBounds = false;
        } else {

            spDetails[_serviceProvider].validBounds = true;
        }
    }






    function _validateBalanceInternal(address _sp, uint _amount) internal view
    {
        require(
            _amount >= spDetails[_sp].minAccountStake,
            "Minimum stake requirement not met");

        require(
            _amount <= spDetails[_sp].maxAccountStake,
            "Maximum stake amount exceeded");

        require(
            spDetails[_sp].deployerStake == 0 || spDetails[_sp].deployerStake >= minDeployerStake,
            "Direct stake restriction violated for this service provider");
    }






    function _decreaseRequestIsPending(address _serviceProvider)
    internal view returns (bool pending)
    {
        return (
            (decreaseStakeRequests[_serviceProvider].lockupExpiryBlock > 0) &&
            (decreaseStakeRequests[_serviceProvider].decreaseAmount > 0)
        );
    }









    function _claimPending(address _sp) internal view returns (bool pending) {
        return ClaimsManager(claimsManagerAddress).claimPending(_sp);
    }
}
