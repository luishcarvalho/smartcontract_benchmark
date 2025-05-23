
pragma solidity 0.8.10;

import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import "./BaseFlywheelRewards.sol";

import {ERC20Gauges} from "../token/ERC20Gauges.sol";


interface IRewardsStream {

    function getRewards() external returns (uint256);
}

















contract FlywheelGaugeRewards is Auth, BaseFlywheelRewards {
    using SafeTransferLib for ERC20;
    using SafeCastLib for uint256;


    error CycleError();


    error EmptyGaugesError();


    event CycleStart(uint32 indexed cycleStart, uint256 rewardAmount);


    event QueueRewards(address indexed gauge, uint32 indexed cycleStart, uint256 rewardAmount);


    uint32 public gaugeCycle;


    uint32 public immutable gaugeCycleLength;


    uint32 internal nextCycle;


    uint112 internal nextCycleQueuedRewards;


    uint32 internal paginationOffset;


    struct QueuedRewards {
        uint112 priorCycleRewards;
        uint112 cycleRewards;
        uint32 storedCycle;
    }


    mapping(ERC20 => QueuedRewards) public gaugeQueuedRewards;


    ERC20Gauges public immutable gaugeToken;


    IRewardsStream public rewardsStream;

    constructor(
        FlywheelCore _flywheel,
        address _owner,
        Authority _authority,
        ERC20Gauges _gaugeToken,
        IRewardsStream _rewardsStream
    ) BaseFlywheelRewards(_flywheel) Auth(_owner, _authority) {
        gaugeCycleLength = _gaugeToken.gaugeCycleLength();


        gaugeCycle = (block.timestamp.safeCastTo32() / gaugeCycleLength) * gaugeCycleLength;

        gaugeToken = _gaugeToken;

        rewardsStream = _rewardsStream;
    }





    function queueRewardsForCycle() external requiresAuth returns (uint256 totalQueuedForCycle) {

        uint32 currentCycle = (block.timestamp.safeCastTo32() / gaugeCycleLength) * gaugeCycleLength;
        uint32 lastCycle = gaugeCycle;


        if (currentCycle <= lastCycle) revert CycleError();

        gaugeCycle = currentCycle;


        uint256 balanceBefore = rewardToken.balanceOf(address(this));
        totalQueuedForCycle = rewardsStream.getRewards();
        require(rewardToken.balanceOf(address(this)) - balanceBefore >= totalQueuedForCycle);


        totalQueuedForCycle += nextCycleQueuedRewards;


        address[] memory gauges = gaugeToken.gauges();

        _queueRewards(gauges, currentCycle, lastCycle, totalQueuedForCycle);

        nextCycleQueuedRewards = 0;
        paginationOffset = 0;

        emit CycleStart(currentCycle, totalQueuedForCycle);
    }




    function queueRewardsForCyclePaginated(uint256 numRewards) external requiresAuth {

        uint32 currentCycle = (block.timestamp.safeCastTo32() / gaugeCycleLength) * gaugeCycleLength;
        uint32 lastCycle = gaugeCycle;


        if (currentCycle <= lastCycle) revert CycleError();

        if (currentCycle > nextCycle) {
            nextCycle = currentCycle;
            paginationOffset = 0;
        }

        uint32 offset = paginationOffset;


        if (offset == 0) {

            uint256 balanceBefore = rewardToken.balanceOf(address(this));
            uint256 newRewards = rewardsStream.getRewards();
            require(rewardToken.balanceOf(address(this)) - balanceBefore >= newRewards);
            require(newRewards <= type(uint112).max);
            nextCycleQueuedRewards += uint112(newRewards);
        }

        uint112 queued = nextCycleQueuedRewards;

        uint256 remaining = gaugeToken.numGauges() - offset;


        if (remaining <= numRewards) {
            numRewards = remaining;
            gaugeCycle = currentCycle;
            nextCycleQueuedRewards = 0;
            paginationOffset = 0;
            emit CycleStart(currentCycle, queued);
        } else {
            paginationOffset = offset + numRewards.safeCastTo32();
        }


        address[] memory gauges = gaugeToken.gauges(offset, numRewards);

        _queueRewards(gauges, currentCycle, lastCycle, queued);
    }

    function _queueRewards(
        address[] memory gauges,
        uint32 currentCycle,
        uint32 lastCycle,
        uint256 totalQueuedForCycle
    ) internal {
        uint256 size = gauges.length;

        if (size == 0) revert EmptyGaugesError();

        for (uint256 i = 0; i < size; i++) {
            ERC20 gauge = ERC20(gauges[i]);

            QueuedRewards memory queuedRewards = gaugeQueuedRewards[gauge];


            require(queuedRewards.storedCycle < currentCycle);
            assert(queuedRewards.storedCycle == 0 || queuedRewards.storedCycle >= lastCycle);

            uint112 completedRewards = queuedRewards.storedCycle == lastCycle ? queuedRewards.cycleRewards : 0;
            uint256 nextRewards = gaugeToken.calculateGaugeAllocation(address(gauge), totalQueuedForCycle);
            require(nextRewards <= type(uint112).max);

            gaugeQueuedRewards[gauge] = QueuedRewards({
                priorCycleRewards: queuedRewards.priorCycleRewards + completedRewards,
                cycleRewards: uint112(nextRewards),
                storedCycle: currentCycle
            });

            emit QueueRewards(address(gauge), currentCycle, nextRewards);
        }
    }







    function getAccruedRewards(ERC20 gauge, uint32 lastUpdatedTimestamp)
        external
        override
        onlyFlywheel
        returns (uint256 accruedRewards)
    {
        QueuedRewards memory queuedRewards = gaugeQueuedRewards[gauge];

        uint32 cycle = gaugeCycle;
        bool incompleteCycle = queuedRewards.storedCycle > cycle;


        if (queuedRewards.priorCycleRewards == 0 && (queuedRewards.cycleRewards == 0 || incompleteCycle)) {
            return 0;
        }


        assert(queuedRewards.storedCycle >= cycle);

        uint32 cycleEnd = cycle + gaugeCycleLength;


        accruedRewards = queuedRewards.priorCycleRewards;
        uint112 cycleRewardsNext = queuedRewards.cycleRewards;

        if (incompleteCycle) {

        } else if (block.timestamp >= cycleEnd) {

            accruedRewards += cycleRewardsNext;
            cycleRewardsNext = 0;
        } else {
            uint32 beginning = lastUpdatedTimestamp > cycle ? lastUpdatedTimestamp : cycle;


            uint32 elapsed = block.timestamp.safeCastTo32() - beginning;
            uint32 remaining = cycleEnd - beginning;



            uint256 currentAccrued = (uint256(queuedRewards.cycleRewards) * elapsed) / remaining;


            accruedRewards += currentAccrued;
            cycleRewardsNext -= uint112(currentAccrued);
        }

        gaugeQueuedRewards[gauge] = QueuedRewards({
            priorCycleRewards: 0,
            cycleRewards: cycleRewardsNext,
            storedCycle: queuedRewards.storedCycle
        });
    }


    function setRewardsStream(IRewardsStream newRewardsStream) external requiresAuth {
        rewardsStream = newRewardsStream;
    }
}
