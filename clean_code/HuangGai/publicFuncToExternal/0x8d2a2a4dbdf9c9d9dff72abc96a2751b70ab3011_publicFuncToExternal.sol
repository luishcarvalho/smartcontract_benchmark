







pragma solidity 0.6.12;


interface ICertification  {
	event GuardianCertificationUpdate(address indexed guardian, bool isCertified);







	function isGuardianCertified(address guardian) external view returns (bool isCertified);





	function setGuardianCertification(address guardian, bool isCertified) external  ;
}



pragma solidity 0.6.12;


interface IElections {


	event StakeChanged(address indexed addr, uint256 selfDelegatedStake, uint256 delegatedStake, uint256 effectiveStake);
	event GuardianStatusUpdated(address indexed guardian, bool readyToSync, bool readyForCommittee);


	event GuardianVotedUnready(address indexed guardian);
	event VoteUnreadyCasted(address indexed voter, address indexed subject, uint256 expiration);
	event GuardianVotedOut(address indexed guardian);
	event VoteOutCasted(address indexed voter, address indexed subject);









	function readyToSync() external;




	function readyForCommittee() external;






	function canJoinCommittee(address guardian) external view returns (bool);




	function getEffectiveStake(address guardian) external view returns (uint effectiveStake);







	function getCommittee() external view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips);








	function voteUnready(address subject, uint voteExpiration) external;






	function getVoteUnreadyVote(address voter, address subject) external view returns (bool valid, uint256 expiration);










	function getVoteUnreadyStatus(address subject) external view returns (
		address[] memory committee,
		uint256[] memory weights,
		bool[] memory certification,
		bool[] memory votes,
		bool subjectInCommittee,
		bool subjectInCertifiedCommittee
	);






	function voteOut(address subject) external;




	function getVoteOutVote(address voter) external view returns (address);







	function getVoteOutStatus(address subject) external view returns (bool votedOut, uint votedStake, uint totalDelegatedStake);











	function delegatedStakeChange(address delegate, uint256 selfDelegatedStake, uint256 delegatedStake, uint256 totalDelegatedStake) external ;





	function guardianUnregistered(address guardian) external ;





	function guardianCertificationChanged(address guardian, bool isCertified) external ;






	event VoteUnreadyTimeoutSecondsChanged(uint32 newValue, uint32 oldValue);
	event VoteOutPercentMilleThresholdChanged(uint32 newValue, uint32 oldValue);
	event VoteUnreadyPercentMilleThresholdChanged(uint32 newValue, uint32 oldValue);
	event MinSelfStakePercentMilleChanged(uint32 newValue, uint32 oldValue);




	function setMinSelfStakePercentMille(uint32 minSelfStakePercentMille) external ;



	function getMinSelfStakePercentMille() external view returns (uint32);




	function setVoteOutPercentMilleThreshold(uint32 voteOutPercentMilleThreshold) external ;



	function getVoteOutPercentMilleThreshold() external view returns (uint32);




	function setVoteUnreadyPercentMilleThreshold(uint32 voteUnreadyPercentMilleThreshold) external ;



	function getVoteUnreadyPercentMilleThreshold() external view returns (uint32);





	function getSettings() external view returns (
		uint32 minSelfStakePercentMille,
		uint32 voteUnreadyPercentMilleThreshold,
		uint32 voteOutPercentMilleThreshold
	);





	function initReadyForCommittee(address[] calldata guardians) external ;

}



pragma solidity 0.6.12;


interface IManagedContract  {



    function refreshContracts() external;

}



pragma solidity 0.6.12;







interface IContractRegistry {

	event ContractAddressUpdated(string contractName, address addr, bool managedContract);
	event ManagerChanged(string role, address newManager);
	event ContractRegistryUpdated(address newContractRegistry);










	function setContract(string calldata contractName, address addr, bool managedContract) external ;




	function getContract(string calldata contractName) external view returns (address);




	function getManagedContracts() external view returns (address[] memory);




	function lockContracts() external ;



	function unlockContracts() external ;






	function setManager(string calldata role, address manager) external ;




	function getManager(string calldata role) external view returns (address);






	function setNewContractRegistry(IContractRegistry newRegistry) external ;




	function getPreviousContractRegistry() external view returns (address);
}



pragma solidity 0.6.12;


interface IContractRegistryAccessor {




    function setContractRegistry(IContractRegistry newRegistry) external ;



    function getContractRegistry() external view returns (IContractRegistry contractRegistry);

    function setRegistryAdmin(address _registryAdmin) external ;

}



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



pragma solidity 0.6.12;







contract WithClaimableRegistryManagement is Context {
    address private _registryAdmin;
    address private _pendingRegistryAdmin;

    event RegistryManagementTransferred(address indexed previousRegistryAdmin, address indexed newRegistryAdmin);




    constructor () internal {
        address msgSender = _msgSender();
        _registryAdmin = msgSender;
        emit RegistryManagementTransferred(address(0), msgSender);
    }




    function registryAdmin() public view returns (address) {
        return _registryAdmin;
    }




    modifier onlyRegistryAdmin() {
        require(isRegistryAdmin(), "WithClaimableRegistryManagement: caller is not the registryAdmin");
        _;
    }




    function isRegistryAdmin() public view returns (bool) {
        return _msgSender() == _registryAdmin;
    }








    function renounceRegistryManagement() public onlyRegistryAdmin {
        emit RegistryManagementTransferred(_registryAdmin, address(0));
        _registryAdmin = address(0);
    }




    function _transferRegistryManagement(address newRegistryAdmin) internal {
        require(newRegistryAdmin != address(0), "RegistryAdmin: new registryAdmin is the zero address");
        emit RegistryManagementTransferred(_registryAdmin, newRegistryAdmin);
        _registryAdmin = newRegistryAdmin;
    }




    modifier onlyPendingRegistryAdmin() {
        require(msg.sender == _pendingRegistryAdmin, "Caller is not the pending registryAdmin");
        _;
    }




    function transferRegistryManagement(address newRegistryAdmin) public onlyRegistryAdmin {
        _pendingRegistryAdmin = newRegistryAdmin;
    }




    function claimRegistryManagement() public onlyPendingRegistryAdmin {
        _transferRegistryManagement(_pendingRegistryAdmin);
        _pendingRegistryAdmin = address(0);
    }




    function pendingRegistryAdmin() public view returns (address) {
       return _pendingRegistryAdmin;
    }
}



pragma solidity 0.6.12;

contract Initializable {

    address private _initializationAdmin;

    event InitializationComplete();




    constructor() public{
        _initializationAdmin = msg.sender;
    }

    modifier onlyInitializationAdmin() {
        require(msg.sender == initializationAdmin(), "sender is not the initialization admin");

        _;
    }






    function initializationAdmin() public view returns (address) {
        return _initializationAdmin;
    }


    function initializationComplete() public onlyInitializationAdmin {
        _initializationAdmin = address(0);
        emit InitializationComplete();
    }


    function isInitializationComplete() public view returns (bool) {
        return _initializationAdmin == address(0);
    }

}



pragma solidity 0.6.12;





contract ContractRegistryAccessor is IContractRegistryAccessor, WithClaimableRegistryManagement, Initializable {

    IContractRegistry private contractRegistry;




    constructor(IContractRegistry _contractRegistry, address _registryAdmin) public {
        require(address(_contractRegistry) != address(0), "_contractRegistry cannot be 0");
        setContractRegistry(_contractRegistry);
        _transferRegistryManagement(_registryAdmin);
    }

    modifier onlyAdmin {
        require(isAdmin(), "sender is not an admin (registryManger or initializationAdmin)");

        _;
    }

    modifier onlyMigrationManager {
        require(isMigrationManager(), "sender is not the migration manager");

        _;
    }

    modifier onlyFunctionalManager {
        require(isFunctionalManager(), "sender is not the functional manager");

        _;
    }


    function isAdmin() internal view returns (bool) {
        return msg.sender == address(contractRegistry) || msg.sender == registryAdmin() || msg.sender == initializationAdmin();
    }



    function isManager(string memory role) internal view returns (bool) {
        IContractRegistry _contractRegistry = contractRegistry;
        return isAdmin() || _contractRegistry != IContractRegistry(0) && contractRegistry.getManager(role) == msg.sender;
    }


    function isMigrationManager() internal view returns (bool) {
        return isManager('migrationManager');
    }


    function isFunctionalManager() internal view returns (bool) {
        return isManager('functionalManager');
    }





    function getProtocolContract() internal view returns (address) {
        return contractRegistry.getContract("protocol");
    }

    function getStakingRewardsContract() internal view returns (address) {
        return contractRegistry.getContract("stakingRewards");
    }

    function getFeesAndBootstrapRewardsContract() internal view returns (address) {
        return contractRegistry.getContract("feesAndBootstrapRewards");
    }

    function getCommitteeContract() internal view returns (address) {
        return contractRegistry.getContract("committee");
    }

    function getElectionsContract() internal view returns (address) {
        return contractRegistry.getContract("elections");
    }

    function getDelegationsContract() internal view returns (address) {
        return contractRegistry.getContract("delegations");
    }

    function getGuardiansRegistrationContract() internal view returns (address) {
        return contractRegistry.getContract("guardiansRegistration");
    }

    function getCertificationContract() internal view returns (address) {
        return contractRegistry.getContract("certification");
    }

    function getStakingContract() internal view returns (address) {
        return contractRegistry.getContract("staking");
    }

    function getSubscriptionsContract() internal view returns (address) {
        return contractRegistry.getContract("subscriptions");
    }

    function getStakingRewardsWallet() internal view returns (address) {
        return contractRegistry.getContract("stakingRewardsWallet");
    }

    function getBootstrapRewardsWallet() internal view returns (address) {
        return contractRegistry.getContract("bootstrapRewardsWallet");
    }

    function getGeneralFeesWallet() internal view returns (address) {
        return contractRegistry.getContract("generalFeesWallet");
    }

    function getCertifiedFeesWallet() internal view returns (address) {
        return contractRegistry.getContract("certifiedFeesWallet");
    }

    function getStakingContractHandler() internal view returns (address) {
        return contractRegistry.getContract("stakingContractHandler");
    }





    event ContractRegistryAddressUpdated(address addr);




    function setContractRegistry(IContractRegistry newContractRegistry) public override onlyAdmin {
        require(newContractRegistry.getPreviousContractRegistry() == address(contractRegistry), "new contract registry must provide the previous contract registry");
        contractRegistry = newContractRegistry;
        emit ContractRegistryAddressUpdated(address(newContractRegistry));
    }



    function getContractRegistry() public override view returns (IContractRegistry) {
        return contractRegistry;
    }

    function setRegistryAdmin(address _registryAdmin) public override onlyInitializationAdmin {
        _transferRegistryManagement(_registryAdmin);
    }

}



pragma solidity 0.6.12;


interface ILockable {

    event Locked();
    event Unlocked();






    function lock() external ;




    function unlock() external ;



    function isLocked() view external returns (bool);

}



pragma solidity 0.6.12;




contract Lockable is ILockable, ContractRegistryAccessor {

    bool public locked;




    constructor(IContractRegistry _contractRegistry, address _registryAdmin) ContractRegistryAccessor(_contractRegistry, _registryAdmin) public {}






    function lock() public override onlyMigrationManager {
        locked = true;
        emit Locked();
    }




    function unlock() public override onlyMigrationManager {
        locked = false;
        emit Unlocked();
    }



    function isLocked() public override view returns (bool) {
        return locked;
    }

    modifier onlyWhenActive() {
        require(!locked, "contract is locked for this operation");

        _;
    }
}



pragma solidity 0.6.12;




contract ManagedContract is IManagedContract, Lockable {



    constructor(IContractRegistry _contractRegistry, address _registryAdmin) Lockable(_contractRegistry, _registryAdmin) public {}



    function refreshContracts() virtual override public {}

}



pragma solidity 0.6.12;





contract Certification is ICertification, ManagedContract {
    mapping(address => bool) guardianCertification;

    modifier onlyCertificationManager {
        require(isManager("certificationManager"), "sender is not the certification manager");

        _;
    }




    constructor(IContractRegistry _contractRegistry, address _registryAdmin) ManagedContract(_contractRegistry, _registryAdmin) public {}







    function isGuardianCertified(address guardian) public override view returns (bool isCertified) {
        return guardianCertification[guardian];
    }





    function setGuardianCertification(address guardian, bool isCertified) public override onlyCertificationManager onlyWhenActive {
        guardianCertification[guardian] = isCertified;
        emit GuardianCertificationUpdate(guardian, isCertified);
        electionsContract.guardianCertificationChanged(guardian, isCertified);
    }





    IElections electionsContract;



    function refreshContracts() public override {
        electionsContract = IElections(getElectionsContract());
    }
}
