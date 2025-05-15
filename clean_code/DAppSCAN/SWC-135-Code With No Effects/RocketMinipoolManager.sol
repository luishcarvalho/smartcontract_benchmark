pragma solidity 0.7.6;



import "@openzeppelin/contracts/math/SafeMath.sol";

import "./RocketMinipool.sol";
import "../RocketBase.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";
import "../../interface/util/AddressSetStorageInterface.sol";
import "../../types/MinipoolDeposit.sol";
import "../../interface/network/RocketNetworkPricesInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";



contract RocketMinipoolManager is RocketBase, RocketMinipoolManagerInterface {


    using SafeMath for uint;


    event MinipoolCreated(address indexed minipool, address indexed node, uint256 time);
    event MinipoolDestroyed(address indexed minipool, address indexed node, uint256 time);


    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }


    function getMinipoolCount() override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(bytes("minipools.index")));
    }


    function getStakingMinipoolCount() override external view returns (uint256) {
        return getUint(keccak256(bytes("minipools.staking.count")));
    }


    function getFinalisedMinipoolCount() override external view returns (uint256) {
        return getUint(keccak256(bytes("minipools.finalised.count")));
    }


    function getActiveMinipoolCount() override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        uint256 total = addressSetStorage.getCount(keccak256(bytes("minipools.index")));
        uint256 finalised = getUint(keccak256(bytes("minipools.finalised.count")));
        return total.sub(finalised);
    }



    function getMinipoolCountPerStatus(uint256 offset, uint256 limit) override external view
    returns (uint256 initializedCount, uint256 prelaunchCount, uint256 stakingCount, uint256 withdrawableCount, uint256 dissolvedCount) {

        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));

        bytes32 minipoolKey = keccak256(abi.encodePacked("minipools.index"));

        uint256 totalMinipools = getMinipoolCount();
        uint256 max = offset.add(limit);
        if (max > totalMinipools || limit == 0) { max = totalMinipools; }
        for (uint256 i = offset; i < max; i++) {

            RocketMinipoolInterface minipool = RocketMinipoolInterface(addressSetStorage.getItem(minipoolKey, i));

            MinipoolStatus status = minipool.getStatus();
            if (status == MinipoolStatus.Initialized) {
                initializedCount++;
            }
            else if (status == MinipoolStatus.Prelaunch) {
                prelaunchCount++;
            }
            else if (status == MinipoolStatus.Staking) {
                stakingCount++;
            }
            else if (status == MinipoolStatus.Withdrawable) {
                withdrawableCount++;
            }
            else if (status == MinipoolStatus.Dissolved) {
                dissolvedCount++;
            }
        }
    }


    function getMinipoolAt(uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("minipools.index")), _index);
    }


    function getNodeMinipoolCount(address _nodeAddress) override external view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)));
    }


    function getNodeActiveMinipoolCount(address _nodeAddress) override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        uint256 finalised = getUint(keccak256(abi.encodePacked("node.minipools.finalised.count", _nodeAddress)));
        uint256 total = addressSetStorage.getCount(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)));
        return total.sub(finalised);
    }


    function getNodeFinalisedMinipoolCount(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("node.minipools.finalised.count", _nodeAddress)));
    }


    function getNodeStakingMinipoolCount(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress)));
    }


    function getNodeMinipoolAt(address _nodeAddress, uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)), _index);
    }


    function getNodeValidatingMinipoolCount(address _nodeAddress) override external view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("node.minipools.validating.index", _nodeAddress)));
    }


    function getNodeValidatingMinipoolAt(address _nodeAddress, uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("node.minipools.validating.index", _nodeAddress)), _index);
    }


    function getMinipoolByPubkey(bytes memory _pubkey) override external view returns (address) {
        return getAddress(keccak256(abi.encodePacked("validator.minipool", _pubkey)));
    }


    function getMinipoolExists(address _minipoolAddress) override external view returns (bool) {
        return getBool(keccak256(abi.encodePacked("minipool.exists", _minipoolAddress)));
    }


    function getMinipoolPubkey(address _minipoolAddress) override external view returns (bytes memory) {
        return getBytes(keccak256(abi.encodePacked("minipool.pubkey", _minipoolAddress)));
    }


    function incrementNodeStakingMinipoolCount(address _nodeAddress) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {

        bytes32 nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress));
        uint256 nodeValue = getUint(nodeKey);
        setUint(nodeKey, nodeValue.add(1));

        bytes32 totalKey = keccak256(abi.encodePacked("minipools.staking.count"));
        uint256 totalValue = getUint(totalKey);
        setUint(totalKey, totalValue.add(1));

        updateTotalEffectiveRPLStake(_nodeAddress, nodeValue, nodeValue.add(1));
    }


    function decrementNodeStakingMinipoolCount(address _nodeAddress) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {

        bytes32 nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress));
        uint256 nodeValue = getUint(nodeKey);
        setUint(nodeKey, nodeValue.sub(1));

        bytes32 totalKey = keccak256(abi.encodePacked("minipools.staking.count"));
        uint256 totalValue = getUint(totalKey);
        setUint(totalKey, totalValue.sub(1));

        updateTotalEffectiveRPLStake(_nodeAddress, nodeValue, nodeValue.sub(1));
    }


    function incrementNodeFinalisedMinipoolCount(address _nodeAddress) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {

        addUint(keccak256(abi.encodePacked("node.minipools.finalised.count", _nodeAddress)), 1);

        addUint(keccak256(bytes("minipools.finalised.count")), 1);
    }



    function createMinipool(address _nodeAddress, MinipoolDeposit _depositType) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyLatestContract("rocketNodeDeposit", msg.sender) returns (RocketMinipoolInterface) {

        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));

        require(
            getNodeActiveMinipoolCount(_nodeAddress) < rocketNodeStaking.getNodeMinipoolLimit(_nodeAddress),
            "Minipool count after deposit exceeds limit based on node RPL stake"
        );
        {
          RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));

          uint256 totalMinipoolCount = getActiveMinipoolCount();
          require(totalMinipoolCount.add(1) <= rocketDAOProtocolSettingsMinipool.getMaximumCount(), "Global minipool limit reached");
        }

        address contractAddress = address(new RocketMinipool(RocketStorageInterface(rocketStorage), _nodeAddress, _depositType));
        RocketMinipoolInterface minipool = RocketMinipoolInterface(contractAddress);


        setBool(keccak256(abi.encodePacked("minipool.exists", contractAddress)), true);

        addressSetStorage.addItem(keccak256(abi.encodePacked("minipools.index")), contractAddress);
        addressSetStorage.addItem(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)), contractAddress);

        if (_depositType == MinipoolDeposit.Empty) {
            RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
            rocketDAONodeTrusted.incrementMemberUnbondedValidatorCount(_nodeAddress);
        }

        emit MinipoolCreated(contractAddress, _nodeAddress, block.timestamp);

        RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue")).enqueueMinipool(_depositType, contractAddress);

        return minipool;
    }



    function destroyMinipool() override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {

        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));

        RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
        address nodeAddress = minipool.getNodeAddress();

        setBool(keccak256(abi.encodePacked("minipool.exists", msg.sender)), false);

        addressSetStorage.removeItem(keccak256(abi.encodePacked("minipools.index")), msg.sender);
        addressSetStorage.removeItem(keccak256(abi.encodePacked("node.minipools.index", nodeAddress)), msg.sender);

        emit MinipoolDestroyed(msg.sender, nodeAddress, block.timestamp);
    }


    function updateTotalEffectiveRPLStake(address _nodeAddress, uint256 _oldCount, uint256 _newCount) private {

        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));

        require(rocketNetworkPrices.inConsensus(), "Network is not in consensus");

        uint256 rplStake = rocketNodeStaking.getNodeRPLStake(_nodeAddress);

        uint256 maxRplStakePerMinipool = rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
            .mul(rocketDAOProtocolSettingsNode.getMaximumPerMinipoolStake());
        uint256 oldMaxRplStake = maxRplStakePerMinipool
            .mul(_oldCount)
            .div(rocketNetworkPrices.getRPLPrice());
        uint256 newMaxRplStake = maxRplStakePerMinipool
            .mul(_newCount)
            .div(rocketNetworkPrices.getRPLPrice());

        if (_oldCount > _newCount) {
            if (rplStake <= newMaxRplStake) {
                return;
            }
            uint256 decrease = oldMaxRplStake.sub(newMaxRplStake);
            uint256 delta = rplStake.sub(newMaxRplStake);
            if (delta > decrease) { delta = decrease; }
            rocketNetworkPrices.decreaseEffectiveRPLStake(delta);
            return;
        }

        if (_newCount > _oldCount) {
            if (rplStake <= oldMaxRplStake) {
                return;
            }
            uint256 increase = newMaxRplStake.sub(oldMaxRplStake);
            uint256 delta = rplStake.sub(oldMaxRplStake);
            if (delta > increase) { delta = increase; }
            rocketNetworkPrices.increaseEffectiveRPLStake(delta);
            return;
        }

    }



    function setMinipoolPubkey(bytes calldata _pubkey) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {

        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));

        RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
        address nodeAddress = minipool.getNodeAddress();

        setBytes(keccak256(abi.encodePacked("minipool.pubkey", msg.sender)), _pubkey);
        setAddress(keccak256(abi.encodePacked("validator.minipool", _pubkey)), msg.sender);

        addressSetStorage.addItem(keccak256(abi.encodePacked("node.minipools.validating.index", nodeAddress)), msg.sender);
    }

}
