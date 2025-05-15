pragma solidity 0.7.6;



import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/RocketVaultWithdrawerInterface.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsDepositInterface.sol";
import "../../interface/token/RocketTokenRETHInterface.sol";





contract RocketDepositPool is RocketBase, RocketDepositPoolInterface, RocketVaultWithdrawerInterface {


    using SafeMath for uint;


    event DepositReceived(address indexed from, uint256 amount, uint256 time);
    event DepositRecycled(address indexed from, uint256 amount, uint256 time);
    event DepositAssigned(address indexed minipool, uint256 amount, uint256 time);
    event ExcessWithdrawn(address indexed to, uint256 amount, uint256 time);


    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }


    function getBalance() override public view returns (uint256) {
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        return rocketVault.balanceOf("rocketDepositPool");
    }


    function getExcessBalance() override public view returns (uint256) {

        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        uint256 minipoolCapacity = rocketMinipoolQueue.getEffectiveCapacity();

        uint256 balance = getBalance();
        if (minipoolCapacity >= balance) { return 0; }
        else { return balance.sub(minipoolCapacity); }
    }



    function receiveVaultWithdrawalETH() override external payable onlyLatestContract("rocketDepositPool", address(this)) onlyLatestContract("rocketVault", msg.sender) {}


    function deposit() override external payable onlyLatestContract("rocketDepositPool", address(this)) {

        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(getContractAddress("rocketTokenRETH"));

        require(rocketDAOProtocolSettingsDeposit.getDepositEnabled(), "Deposits into Rocket Pool are currently disabled");
        require(msg.value >= rocketDAOProtocolSettingsDeposit.getMinimumDeposit(), "The deposited amount is less than the minimum deposit size");
        require(getBalance().add(msg.value) <= rocketDAOProtocolSettingsDeposit.getMaximumDepositPoolSize(), "The deposit pool size after depositing exceeds the maximum size");

        rocketTokenRETH.mint(msg.value, msg.sender);

        emit DepositReceived(msg.sender, msg.value, block.timestamp);

        processDeposit();
    }



    function recycleDissolvedDeposit() override external payable onlyLatestContract("rocketDepositPool", address(this)) onlyRegisteredMinipool(msg.sender) {
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        processDeposit();
    }



    function recycleWithdrawnDeposit() override external payable onlyLatestContract("rocketDepositPool", address(this)) onlyLatestContract("rocketNetworkWithdrawal", msg.sender) {
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        processDeposit();
    }



    function recycleLiquidatedStake() override external payable onlyLatestContract("rocketDepositPool", address(this)) onlyLatestContract("rocketAuctionManager", msg.sender) {
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        processDeposit();
    }


    function processDeposit() private {

        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));

        rocketVault.depositEther{value: msg.value}();

        if (rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled()) { assignDeposits(); }
    }


    function assignDeposits() override public onlyLatestContract("rocketDepositPool", address(this)) {

        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));

        require(rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled(), "Deposit assignments are currently disabled");


        for (uint256 i = 0; i < rocketDAOProtocolSettingsDeposit.getMaximumDepositAssignments(); ++i) {

            uint256 minipoolCapacity = rocketMinipoolQueue.getNextCapacity();
            if (minipoolCapacity == 0 || getBalance() < minipoolCapacity) { break; }

            address minipoolAddress = rocketMinipoolQueue.dequeueMinipool();
            RocketMinipoolInterface minipool = RocketMinipoolInterface(minipoolAddress);

            rocketVault.withdrawEther(minipoolCapacity);

            minipool.userDeposit{value: minipoolCapacity}();

            emit DepositAssigned(minipoolAddress, minipoolCapacity, block.timestamp);
        }
    }


    function withdrawExcessBalance(uint256 _amount) override external onlyLatestContract("rocketDepositPool", address(this)) onlyLatestContract("rocketTokenRETH", msg.sender) {

        RocketTokenRETHInterface rocketTokenRETH = RocketTokenRETHInterface(getContractAddress("rocketTokenRETH"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));

        require(_amount <= getExcessBalance(), "Insufficient excess balance for withdrawal");

        rocketVault.withdrawEther(_amount);

        rocketTokenRETH.depositExcess{value: _amount}();

        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

}
