


















pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "../libs/LibStakingRichErrors.sol";
import "../interfaces/IStructs.sol";
import "../sys/MixinAbstract.sol";
import "./MixinStakingPoolRewards.sol";


contract MixinStakingPool is
    MixinAbstract,
    MixinStakingPoolRewards
{
    using LibSafeMath for uint256;
    using LibSafeDowncast for uint256;



    modifier onlyStakingPoolOperatorOrMaker(bytes32 poolId) {
        _assertSenderIsPoolOperatorOrMaker(poolId);
        _;
    }






    function createStakingPool(uint32 operatorShare, bool addOperatorAsMaker)
        external
        returns (bytes32 poolId)
    {

        address payable operator = msg.sender;


        poolId = nextPoolId;
        nextPoolId = _computeNextStakingPoolId(poolId);


        _assertNewOperatorShare(
            poolId,
            PPM_DENOMINATOR,
            operatorShare
        );


        IStructs.Pool memory pool = IStructs.Pool({
            initialized: true,
            operator: operator,
            operatorShare: operatorShare,
            numberOfMakers: 0
        });
        _poolById[poolId] = pool;



        _initializeCumulativeRewards(poolId);


        emit StakingPoolCreated(poolId, operator, operatorShare);

        if (addOperatorAsMaker) {
            _addMakerToStakingPool(poolId, operator);
        }

        return poolId;
    }




    function decreaseStakingPoolOperatorShare(bytes32 poolId, uint32 newOperatorShare)
        external
        onlyStakingPoolOperatorOrMaker(poolId)
    {

        uint32 currentOperatorShare = _poolById[poolId].operatorShare;
        _assertNewOperatorShare(
            poolId,
            currentOperatorShare,
            newOperatorShare
        );


        _poolById[poolId].operatorShare = newOperatorShare;
        emit OperatorShareDecreased(
            poolId,
            currentOperatorShare,
            newOperatorShare
        );
    }



    function joinStakingPoolAsMaker(bytes32 poolId)
        external
    {

        address makerAddress = msg.sender;
        IStructs.MakerPoolJoinStatus memory poolJoinStatus = _poolJoinedByMakerAddress[makerAddress];
        if (poolJoinStatus.confirmed) {
            LibRichErrors.rrevert(LibStakingRichErrors.MakerPoolAssignmentError(
                LibStakingRichErrors.MakerPoolAssignmentErrorCodes.MakerAddressAlreadyRegistered,
                makerAddress,
                poolJoinStatus.poolId
            ));
        }

        poolJoinStatus.poolId = poolId;
        _poolJoinedByMakerAddress[makerAddress] = poolJoinStatus;


        emit PendingAddMakerToPool(
            poolId,
            makerAddress
        );
    }





    function addMakerToStakingPool(
        bytes32 poolId,
        address makerAddress
    )
        external
        onlyStakingPoolOperatorOrMaker(poolId)
    {
        _addMakerToStakingPool(poolId, makerAddress);
    }






    function removeMakerFromStakingPool(
        bytes32 poolId,
        address makerAddress
    )
        external
        onlyStakingPoolOperatorOrMaker(poolId)
    {
        bytes32 makerPoolId = getStakingPoolIdOfMaker(makerAddress);
        if (makerPoolId != poolId) {
            LibRichErrors.rrevert(LibStakingRichErrors.MakerPoolAssignmentError(
                LibStakingRichErrors.MakerPoolAssignmentErrorCodes.MakerAddressNotRegistered,
                makerAddress,
                makerPoolId
            ));
        }


        delete _poolJoinedByMakerAddress[makerAddress];
        _poolById[poolId].numberOfMakers = uint256(_poolById[poolId].numberOfMakers).safeSub(1).downcastToUint32();


        emit MakerRemovedFromStakingPool(
            poolId,
            makerAddress
        );
    }




    function getStakingPoolIdOfMaker(address makerAddress)
        public
        view
        returns (bytes32)
    {
        IStructs.MakerPoolJoinStatus memory poolJoinStatus = _poolJoinedByMakerAddress[makerAddress];
        if (poolJoinStatus.confirmed) {
            return poolJoinStatus.poolId;
        } else {
            return NIL_POOL_ID;
        }
    }



    function getStakingPool(bytes32 poolId)
        public
        view
        returns (IStructs.Pool memory)
    {
        return _poolById[poolId];
    }





    function _addMakerToStakingPool(
        bytes32 poolId,
        address makerAddress
    )
        internal
    {

        IStructs.Pool memory pool = _poolById[poolId];
        IStructs.MakerPoolJoinStatus memory poolJoinStatus = _poolJoinedByMakerAddress[makerAddress];


        if (poolJoinStatus.confirmed) {
            LibRichErrors.rrevert(LibStakingRichErrors.MakerPoolAssignmentError(
                LibStakingRichErrors.MakerPoolAssignmentErrorCodes.MakerAddressAlreadyRegistered,
                makerAddress,
                poolJoinStatus.poolId
            ));
        }


        bytes32 makerPendingPoolId = poolJoinStatus.poolId;
        if (makerPendingPoolId != poolId && makerAddress != pool.operator) {
            LibRichErrors.rrevert(LibStakingRichErrors.MakerPoolAssignmentError(
                LibStakingRichErrors.MakerPoolAssignmentErrorCodes.MakerAddressNotPendingAdd,
                makerAddress,
                makerPendingPoolId
            ));
        }




        if (pool.numberOfMakers >= maximumMakersInPool) {
            LibRichErrors.rrevert(LibStakingRichErrors.MakerPoolAssignmentError(
                LibStakingRichErrors.MakerPoolAssignmentErrorCodes.PoolIsFull,
                makerAddress,
                poolId
            ));
        }


        poolJoinStatus = IStructs.MakerPoolJoinStatus({
            poolId: poolId,
            confirmed: true
        });
        _poolJoinedByMakerAddress[makerAddress] = poolJoinStatus;
        _poolById[poolId].numberOfMakers = uint256(pool.numberOfMakers).safeAdd(1).downcastToUint32();


        emit MakerAddedToStakingPool(
            poolId,
            makerAddress
        );
    }




    function _computeNextStakingPoolId(bytes32 poolId)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(uint256(poolId).safeAdd(POOL_ID_INCREMENT_AMOUNT));
    }



    function _assertStakingPoolExists(bytes32 poolId)
        internal
        view
        returns (bool)
    {
        if (_poolById[poolId].operator == NIL_ADDRESS) {

            LibRichErrors.rrevert(
                LibStakingRichErrors.PoolExistenceError(
                    poolId,
                    false
                )
            );
        }
    }





    function _assertNewOperatorShare(
        bytes32 poolId,
        uint32 currentOperatorShare,
        uint32 newOperatorShare
    )
        private
        pure
    {

        if (newOperatorShare > PPM_DENOMINATOR) {

            LibRichErrors.rrevert(LibStakingRichErrors.OperatorShareError(
                LibStakingRichErrors.OperatorShareErrorCodes.OperatorShareTooLarge,
                poolId,
                newOperatorShare
            ));
        } else if (newOperatorShare >= currentOperatorShare) {

            LibRichErrors.rrevert(LibStakingRichErrors.OperatorShareError(
                LibStakingRichErrors.OperatorShareErrorCodes.CanOnlyDecreaseOperatorShare,
                poolId,
                newOperatorShare
            ));
        }
    }



    function _assertSenderIsPoolOperatorOrMaker(bytes32 poolId)
        private
        view
    {
        address operator = _poolById[poolId].operator;
        if (
            msg.sender != operator &&
            getStakingPoolIdOfMaker(msg.sender) != poolId
        ) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.OnlyCallableByPoolOperatorOrMakerError(
                    msg.sender,
                    poolId
                )
            );
        }
    }
}
