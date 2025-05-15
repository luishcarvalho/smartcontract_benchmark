




















pragma solidity 0.6.10;

import "@nomiclabs/buidler/console.sol";

import "./delegation/DelegationController.sol";
import "./delegation/PartialDifferences.sol";
import "./delegation/TimeHelpers.sol";

import "./ConstantsHolder.sol";
import "./Nodes.sol";
import "./Permissions.sol";


contract BountyV2 is Permissions {
    using PartialDifferences for PartialDifferences.Value;
    using PartialDifferences for PartialDifferences.Sequence;

    uint public constant YEAR1_BOUNTY = 3850e5 * 1e18;
    uint public constant YEAR2_BOUNTY = 3465e5 * 1e18;
    uint public constant YEAR3_BOUNTY = 3080e5 * 1e18;
    uint public constant YEAR4_BOUNTY = 2695e5 * 1e18;
    uint public constant YEAR5_BOUNTY = 2310e5 * 1e18;
    uint public constant YEAR6_BOUNTY = 1925e5 * 1e18;
    uint public constant EPOCHS_PER_YEAR = 12;
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant BOUNTY_WINDOW_SECONDS = 3 * SECONDS_PER_DAY;

    uint private _nextEpoch;
    uint private _epochPool;
    uint private _bountyWasPaidInCurrentEpoch;
    bool public bountyReduction;
    uint public nodeCreationWindowSeconds;

    PartialDifferences.Value private _effectiveDelegatedSum;

    mapping (uint => uint) public nodesByValidator;

    function calculateBounty(uint nodeIndex)
        external
        allow("SkaleManager")
        returns (uint)
    {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        TimeHelpers timeHelpers = TimeHelpers(contractManager.getContract("TimeHelpers"));

        require(
            _getNextRewardTimestamp(nodeIndex, nodes, timeHelpers) <= now,
            "Transaction is sent too early"
        );

        uint currentMonth = timeHelpers.getCurrentMonth();
        _refillEpochPool(currentMonth, timeHelpers, constantsHolder);

        uint bounty = _calculateMaximumBountyAmount(_epochPool, currentMonth, nodeIndex, constantsHolder, nodes);

        bounty = _reduceBounty(
            bounty,
            nodeIndex,
            nodes,
            constantsHolder
        );

        _epochPool = _epochPool.sub(bounty);
        _bountyWasPaidInCurrentEpoch = _bountyWasPaidInCurrentEpoch.add(bounty);

        return bounty;
    }

    function enableBountyReduction() external onlyOwner {
        bountyReduction = true;
    }

    function disableBountyReduction() external onlyOwner {
        bountyReduction = false;
    }

    function setNodeCreationWindowSeconds(uint window) external allow("Nodes") {
        nodeCreationWindowSeconds = window;
    }

    function handleDelegationAdd(
        uint validatorId,
        uint amount,
        uint month
    )
        external
        allow("DelegationController")
    {
        if (nodesByValidator[validatorId] > 0) {
            _effectiveDelegatedSum.addToValue(amount.mul(nodesByValidator[validatorId]), month);
        }
    }

    function handleDelegationRemoving(
        uint validatorId,
        uint amount,
        uint month
    )
        external
        allow("DelegationController")
    {
        if (nodesByValidator[validatorId] > 0) {
            _effectiveDelegatedSum.subtractFromValue(amount.mul(nodesByValidator[validatorId]), month);
        }
    }

    function handleNodeCreation(uint validatorId) external allow("Nodes") {
        nodesByValidator[validatorId] = nodesByValidator[validatorId].add(1);

        _changeEffectiveDelegatedSum(validatorId, true);
    }

    function handleNodeRemoving(uint validatorId) external allow("Nodes") {
        require(nodesByValidator[validatorId] > 0, "All nodes have been already removed");
        nodesByValidator[validatorId] = nodesByValidator[validatorId].sub(1);

        _changeEffectiveDelegatedSum(validatorId, false);
    }




































































































































































































































































