pragma solidity 0.7.6;



import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../RocketBase.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/network/RocketNetworkPricesInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/RocketVaultInterface.sol";



contract RocketNodeStaking is RocketBase, RocketNodeStakingInterface {


    using SafeMath for uint;


    event RPLStaked(address indexed from, uint256 amount, uint256 time);
    event RPLWithdrawn(address indexed to, uint256 amount, uint256 time);
    event RPLSlashed(address indexed node, uint256 amount, uint256 ethValue, uint256 time);


    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }


    function getTotalRPLStake() override public view returns (uint256) {
        return getUintS("rpl.staked.total.amount");
    }
    function setTotalRPLStake(uint256 _amount) private {
        setUintS("rpl.staked.total.amount", _amount);
    }
    function increaseTotalRPLStake(uint256 _amount) private {
        setTotalRPLStake(getTotalRPLStake().add(_amount));
    }
    function decreaseTotalRPLStake(uint256 _amount) private {
        setTotalRPLStake(getTotalRPLStake().sub(_amount));
    }


    function getNodeRPLStake(address _nodeAddress) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("rpl.staked.node.amount", _nodeAddress)));
    }
    function setNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        setUint(keccak256(abi.encodePacked("rpl.staked.node.amount", _nodeAddress)), _amount);
    }
    function increaseNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        setNodeRPLStake(_nodeAddress, getNodeRPLStake(_nodeAddress).add(_amount));
    }
    function decreaseNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        setNodeRPLStake(_nodeAddress, getNodeRPLStake(_nodeAddress).sub(_amount));
    }


    function getNodeRPLStakedBlock(address _nodeAddress) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("rpl.staked.node.block", _nodeAddress)));
    }
    function setNodeRPLStakedBlock(address _nodeAddress, uint256 _block) private {
        setUint(keccak256(abi.encodePacked("rpl.staked.node.block", _nodeAddress)), _block);
    }


    function getTotalEffectiveRPLStake() override public view returns (uint256) {

        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));

        uint256 rplStake = getTotalRPLStake();

        uint256 maxRplStake = rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
            .mul(rocketDAOProtocolSettingsNode.getMaximumPerMinipoolStake())
            .mul(rocketMinipoolManager.getMinipoolCount())
            .div(rocketNetworkPrices.getRPLPrice());

        if (rplStake < maxRplStake) { return rplStake; }
        else { return maxRplStake; }
    }


    function getNodeEffectiveRPLStake(address _nodeAddress) override public view returns (uint256) {

        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));

        uint256 rplStake = getNodeRPLStake(_nodeAddress);

        uint256 maxRplStake = rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
            .mul(rocketDAOProtocolSettingsNode.getMaximumPerMinipoolStake())
            .mul(rocketMinipoolManager.getNodeMinipoolCount(_nodeAddress))
            .div(rocketNetworkPrices.getRPLPrice());

        if (rplStake < maxRplStake) { return rplStake; }
        else { return maxRplStake; }
    }


    function getNodeMinimumRPLStake(address _nodeAddress) override public view returns (uint256) {

        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));

        return rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
            .mul(rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake())
            .mul(rocketMinipoolManager.getNodeMinipoolCount(_nodeAddress))
            .div(rocketNetworkPrices.getRPLPrice());
    }


    function getNodeMinipoolLimit(address _nodeAddress) override public view returns (uint256) {

        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));

        return getNodeRPLStake(_nodeAddress)
            .mul(rocketNetworkPrices.getRPLPrice())
            .div(
                rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
                .mul(rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake())
            );
    }



    function stakeRPL(uint256 _amount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(msg.sender) {

        address rplTokenAddress = getContractAddress("rocketTokenRPL");
        address rocketVaultAddress = getContractAddress("rocketVault");
        IERC20 rplToken = IERC20(rplTokenAddress);
        RocketVaultInterface rocketVault = RocketVaultInterface(rocketVaultAddress);

        require(rplToken.transferFrom(msg.sender, address(this), _amount), "Could not transfer RPL to staking contract");

        require(rplToken.approve(rocketVaultAddress, _amount), "Could not approve vault RPL deposit");

        rocketVault.depositToken("rocketNodeStaking", rplTokenAddress, _amount);

        increaseTotalRPLStake(_amount);
        increaseNodeRPLStake(msg.sender, _amount);
        setNodeRPLStakedBlock(msg.sender, block.number);

        emit RPLStaked(msg.sender, _amount, block.timestamp);
    }



    function withdrawRPL(uint256 _amount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(msg.sender) {

        RocketDAOProtocolSettingsRewardsInterface rocketDAOProtocolSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));


        require(block.number.sub(getNodeRPLStakedBlock(msg.sender)) >= rocketDAOProtocolSettingsRewards.getRewardsClaimIntervalBlocks(), "The withdrawal cooldown period has not passed");

        uint256 rplStake = getNodeRPLStake(msg.sender);
        require(rplStake >= _amount, "Withdrawal amount exceeds node's staked RPL balance");

        require(rplStake.sub(_amount) >= getNodeMinimumRPLStake(msg.sender), "Node's staked RPL balance after withdrawal is less than minimum balance");

        rocketVault.withdrawToken(msg.sender, getContractAddress("rocketTokenRPL"), _amount);

        decreaseTotalRPLStake(_amount);
        decreaseNodeRPLStake(msg.sender, _amount);

        emit RPLWithdrawn(msg.sender, _amount, block.timestamp);
    }



    function slashRPL(address _nodeAddress, uint256 _ethSlashAmount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyLatestContract("rocketMinipoolStatus", msg.sender) {

        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));

        uint256 calcBase = 1 ether;
        uint256 rplSlashAmount = calcBase.mul(_ethSlashAmount).div(rocketNetworkPrices.getRPLPrice());

        uint256 rplStake = getNodeRPLStake(_nodeAddress);
        if (rplSlashAmount > rplStake) { rplSlashAmount = rplStake; }

        rocketVault.transferToken("rocketAuctionManager", getContractAddress("rocketTokenRPL"), rplSlashAmount);

        decreaseTotalRPLStake(rplSlashAmount);
        decreaseNodeRPLStake(_nodeAddress, rplSlashAmount);

        emit RPLSlashed(_nodeAddress, rplSlashAmount, _ethSlashAmount, block.timestamp);
    }

}
