

















pragma solidity ^0.5.9;


interface IStructs {






    struct ActivePool {
        uint256 feesCollected;
        uint256 weightedStake;
        uint256 membersStake;
    }










    struct UnfinalizedState {
        uint256 rewardsAvailable;
        uint256 poolsRemaining;
        uint256 totalFeesCollected;
        uint256 totalWeightedStake;
        uint256 totalRewardsFinalized;
    }









    struct StoredBalance {

        bool isInitialized;
        uint32 currentEpoch;
        uint96 currentEpochBalance;
        uint96 nextEpochBalance;
    }




    struct StakeBalance {
        uint256 currentEpochBalance;
        uint256 nextEpochBalance;
    }


    enum StakeStatus {
        ACTIVE,
        INACTIVE,
        DELEGATED
    }




    struct StakeInfo {
        StakeStatus status;
        bytes32 poolId;
    }




    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }





    struct MakerPoolJoinStatus {
        bytes32 poolId;
        bool confirmed;
    }






    struct Pool {

        bool initialized;
        address payable operator;
        uint32 operatorShare;
        uint32 numberOfMakers;
    }
}
