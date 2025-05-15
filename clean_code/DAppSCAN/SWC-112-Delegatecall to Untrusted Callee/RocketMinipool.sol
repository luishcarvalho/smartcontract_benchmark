pragma solidity 0.7.6;



import "./RocketMinipoolStorageLayout.sol";
import "../../interface/RocketStorageInterface.sol";
import "../../types/MinipoolDeposit.sol";
import "../../types/MinipoolStatus.sol";



contract RocketMinipool is RocketMinipoolStorageLayout {


    event EtherReceived(address indexed from, uint256 amount, uint256 time);
    event DelegateUpgraded(address oldDelegate, address newDelegate, uint256 time);
    event DelegateRolledBack(address oldDelegate, address newDelegate, uint256 time);




    modifier onlyMinipoolOwner() {

        address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(nodeAddress);
        require(msg.sender == nodeAddress || msg.sender == withdrawalAddress, "Only the node operator can access this method");
        _;
    }


    constructor(RocketStorageInterface _rocketStorageAddress, address _nodeAddress, MinipoolDeposit _depositType) {

        require(address(_rocketStorageAddress) != address(0x0), "Invalid storage address");
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);

        storageState = StorageState.Uninitialised;

        rocketMinipoolDelegate = getContractAddress("rocketMinipoolDelegate");

        rocketMinipoolPenalty = getContractAddress("rocketMinipoolPenalty");

        (bool success, bytes memory data) = getContractAddress("rocketMinipoolDelegate").delegatecall(abi.encodeWithSignature('initialise(address,uint8)', _nodeAddress, uint8(_depositType)));
        if (!success) { revert(getRevertMessage(data)); }
    }


    receive() external payable {

        emit EtherReceived(msg.sender, msg.value, block.timestamp);
    }


    function delegateUpgrade() external onlyMinipoolOwner {

        rocketMinipoolDelegatePrev = rocketMinipoolDelegate;

        rocketMinipoolDelegate = getContractAddress("rocketMinipoolDelegate");

        require(rocketMinipoolDelegate != rocketMinipoolDelegatePrev, "New delegate is the same as the existing one");

        emit DelegateUpgraded(rocketMinipoolDelegatePrev, rocketMinipoolDelegate, block.timestamp);
    }


    function delegateRollback() external onlyMinipoolOwner {

        require(rocketMinipoolDelegatePrev != address(0x0), "Previous delegate contract is not set");

        address originalDelegate = rocketMinipoolDelegate;

        rocketMinipoolDelegate = rocketMinipoolDelegatePrev;
        rocketMinipoolDelegatePrev = address(0x0);

        emit DelegateRolledBack(originalDelegate, rocketMinipoolDelegate, block.timestamp);
    }


    function setUseLatestDelegate(bool _setting) external onlyMinipoolOwner {
        useLatestDelegate = _setting;
    }


    function getUseLatestDelegate() external view returns (bool) {
        return useLatestDelegate;
    }


    function getDelegate() external view returns (address) {
        return rocketMinipoolDelegate;
    }


    function getPreviousDelegate() external view returns (address) {
        return rocketMinipoolDelegatePrev;
    }


    function getEffectiveDelegate() external view returns (address) {
        return useLatestDelegate ? getContractAddress("rocketMinipoolDelegate") : rocketMinipoolDelegate;
    }



    fallback(bytes calldata _input) external payable returns (bytes memory) {

        address delegateContract = useLatestDelegate ? getContractAddress("rocketMinipoolDelegate") : rocketMinipoolDelegate;
        (bool success, bytes memory data) = delegateContract.delegatecall(_input);
        if (!success) { revert(getRevertMessage(data)); }
        return data;
    }


    function getContractAddress(string memory _contractName) private view returns (address) {
        address contractAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        require(contractAddress != address(0x0), "Contract not found");
        return contractAddress;
    }


    function getRevertMessage(bytes memory _returnData) private pure returns (string memory) {
        if (_returnData.length < 68) { return "Transaction reverted silently"; }
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }

}
