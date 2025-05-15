
pragma solidity 0.8.13;

import { OrderType, ItemType, Side } from "./ConsiderationEnums.sol";


import {
    OfferItem,
    ConsiderationItem,
    SpentItem,
    ReceivedItem,
    OrderParameters,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver,
    Batch,
    BatchExecution
} from "./ConsiderationStructs.sol";

import { ZoneInterface } from "../interfaces/ZoneInterface.sol";

import { ConsiderationBase } from "./ConsiderationBase.sol";

import "./ConsiderationConstants.sol";






contract ConsiderationPure is ConsiderationBase {













    constructor(
        address legacyProxyRegistry,
        address legacyTokenTransferProxy,
        address requiredProxyImplementation
    )
        ConsiderationBase(
            legacyProxyRegistry,
            legacyTokenTransferProxy,
            requiredProxyImplementation
        )
    {}















    function _applyCriteriaResolvers(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers
    ) internal pure {

        unchecked {

            for (uint256 i = 0; i < criteriaResolvers.length; ++i) {

                CriteriaResolver memory criteriaResolver = criteriaResolvers[i];


                uint256 orderIndex = criteriaResolver.orderIndex;


                if (orderIndex >= advancedOrders.length) {
                    revert OrderCriteriaResolverOutOfRange();
                }


                if (advancedOrders[orderIndex].numerator == 0) {
                    continue;
                }


                OrderParameters memory orderParameters = (
                    advancedOrders[orderIndex].parameters
                );


                uint256 componentIndex = criteriaResolver.index;


                ItemType itemType;
                uint256 identifierOrCriteria;


                if (criteriaResolver.side == Side.OFFER) {

                    if (componentIndex >= orderParameters.offer.length) {
                        revert OfferCriteriaResolverOutOfRange();
                    }


                    OfferItem memory offer = (
                        orderParameters.offer[componentIndex]
                    );


                    itemType = offer.itemType;
                    identifierOrCriteria = offer.identifierOrCriteria;


                    ItemType newItemType;
                    assembly {
                        newItemType := sub(3, eq(itemType, 4))
                    }
                    offer.itemType = newItemType;


                    offer.identifierOrCriteria = criteriaResolver.identifier;
                } else {


                    if (
                        componentIndex >= orderParameters.consideration.length
                    ) {
                        revert ConsiderationCriteriaResolverOutOfRange();
                    }


                    ConsiderationItem memory consideration = (
                        orderParameters.consideration[componentIndex]
                    );


                    itemType = consideration.itemType;
                    identifierOrCriteria = consideration.identifierOrCriteria;


                    ItemType newItemType;
                    assembly {
                        newItemType := sub(3, eq(itemType, 4))
                    }
                    consideration.itemType = newItemType;


                    consideration.identifierOrCriteria = (
                        criteriaResolver.identifier
                    );
                }


                if (!_isItemWithCriteria(itemType)) {
                    revert CriteriaNotEnabledForItem();
                }


                if (identifierOrCriteria != uint256(0)) {

                    _verifyProof(
                        criteriaResolver.identifier,
                        identifierOrCriteria,
                        criteriaResolver.criteriaProof
                    );
                }
            }


            for (uint256 i = 0; i < advancedOrders.length; ++i) {

                AdvancedOrder memory advancedOrder = advancedOrders[i];


                if (advancedOrder.numerator == 0) {
                    continue;
                }


                uint256 totalItems = (
                    advancedOrder.parameters.consideration.length
                );


                for (uint256 j = 0; j < totalItems; ++j) {

                    if (
                        _isItemWithCriteria(
                            advancedOrder.parameters.consideration[j].itemType
                        )
                    ) {
                        revert UnresolvedConsiderationCriteria();
                    }
                }


                totalItems = advancedOrder.parameters.offer.length;


                for (uint256 j = 0; j < totalItems; ++j) {

                    if (
                        _isItemWithCriteria(
                            advancedOrder.parameters.offer[j].itemType
                        )
                    ) {
                        revert UnresolvedOfferCriteria();
                    }
                }
            }
        }
    }

















    function _locateCurrentAmount(
        uint256 startAmount,
        uint256 endAmount,
        uint256 elapsed,
        uint256 remaining,
        uint256 duration,
        bool roundUp
    ) internal pure returns (uint256) {

        if (startAmount != endAmount) {

            uint256 extraCeiling = 0;


            if (roundUp) {

                unchecked {
                    extraCeiling = duration - 1;
                }
            }


            uint256 totalBeforeDivision = ((startAmount * remaining) +
                (endAmount * elapsed) +
                extraCeiling);


            uint256 newAmount;
            assembly {
                newAmount := div(totalBeforeDivision, duration)
            }


            return newAmount;
        }


        return endAmount;
    }












    function _getFraction(
        uint256 numerator,
        uint256 denominator,
        uint256 value
    ) internal pure returns (uint256 newValue) {

        if (numerator == denominator) {
            return value;
        }


        uint256 valueTimesNumerator = value * numerator;


        bool exact;
        assembly {
            newValue := div(valueTimesNumerator, denominator)
            exact := iszero(mulmod(value, numerator, denominator))
        }


        if (!exact) {
            revert InexactFraction();
        }
    }














    function _compressExecutions(Execution[] memory executions)
        internal
        pure
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {

        unchecked {

            uint256 totalExecutions = executions.length;


            if (totalExecutions <= 1) {
                return (executions, new BatchExecution[](0));
            }


            uint256 total1155Executions = 0;


            uint256[] memory indexBy1155 = new uint256[](totalExecutions);


            for (uint256 i = 0; i < executions.length; ++i) {

                if (executions[i].item.itemType == ItemType.ERC1155) {

                    indexBy1155[total1155Executions++] = i;
                }
            }


            if (total1155Executions <= 1) {
                return (executions, new BatchExecution[](0));
            }


            Batch[] memory batches = new Batch[](total1155Executions);


            uint256 initialExecutionIndex = indexBy1155[0];


            bytes32 hash = _getHashByExecutionIndex(
                executions,
                initialExecutionIndex
            );


            uint256[] memory executionIndices = new uint256[](1);


            executionIndices[0] = initialExecutionIndex;


            batches[0].hash = hash;
            batches[0].executionIndices = executionIndices;


            uint256 uniqueHashes = 1;


            for (uint256 i = 1; i < total1155Executions; ++i) {

                uint256 executionIndex = indexBy1155[i];


                hash = _getHashByExecutionIndex(executions, executionIndex);


                bool foundMatchingHash = false;


                for (uint256 j = 0; j < uniqueHashes; ++j) {

                    if (hash == batches[j].hash) {

                        uint256[] memory oldExecutionIndices = (
                            batches[j].executionIndices
                        );


                        uint256 originalLength = oldExecutionIndices.length;


                        uint256[] memory newExecutionIndices = (
                            new uint256[](originalLength + 1)
                        );


                        for (uint256 k = 0; k < originalLength; ++k) {

                            newExecutionIndices[k] = oldExecutionIndices[k];
                        }


                        newExecutionIndices[originalLength] = executionIndex;


                        batches[j].executionIndices = newExecutionIndices;


                        foundMatchingHash = true;


                        break;
                    }
                }


                if (!foundMatchingHash) {

                    executionIndices[0] = executionIndex;


                    batches[uniqueHashes].hash = hash;
                    batches[uniqueHashes++].executionIndices = executionIndices;
                }
            }


            if (uniqueHashes == total1155Executions) {
                return (executions, new BatchExecution[](0));
            }




            uint256[] memory usedInBatch = new uint256[](totalExecutions);



            uint256[] memory totals = new uint256[](2);


            for (uint256 i = 0; i < uniqueHashes; ++i) {

                uint256[] memory indices = batches[i].executionIndices;


                uint256 indicesLength = indices.length;


                if (indicesLength >= 2) {

                    ++totals[1];


                    totals[0] += indicesLength;


                    for (uint256 j = 0; j < indicesLength; ++j) {

                        usedInBatch[indices[j]] = i + 1;
                    }
                }
            }



            return _splitExecution(
                    executions,
                    batches,
                    usedInBatch,
                    totals[0],
                    totals[1]
                );
        }
    }


















    function _splitExecution(
        Execution[] memory executions,
        Batch[] memory batches,
        uint256[] memory batchExecutionPointers,
        uint256 totalUsedInBatch,
        uint256 totalBatches
    ) internal pure returns (Execution[] memory, BatchExecution[] memory) {

        unchecked {

            uint256 totalExecutions = executions.length;


            Execution[] memory standardExecutions = new Execution[](
                totalExecutions - totalUsedInBatch
            );


            BatchExecution[] memory batchExecutions = new BatchExecution[](
                totalBatches
            );


            uint256 nextStandardExecutionIndex = 0;


            uint256[] memory batchElementIndices = new uint256[](totalBatches);


            for (uint256 i = 0; i < totalExecutions; ++i) {

                uint256 batchExecutionPointer = batchExecutionPointers[i];


                Execution memory execution = executions[i];


                if (batchExecutionPointer == 0) {

                    standardExecutions[nextStandardExecutionIndex++] = (
                        execution
                    );

                } else {

                    uint256 batchIndex = batchExecutionPointer - 1;


                    if (batchExecutions[batchIndex].token == address(0)) {

                        uint256 totalElements = (
                            batches[batchIndex].executionIndices.length
                        );


                        batchExecutions[batchIndex] = BatchExecution(
                            execution.item.token,
                            execution.offerer,
                            execution.item.recipient,
                            new uint256[](totalElements),
                            new uint256[](totalElements),
                            execution.conduit
                        );
                    }


                    uint256 batchElementIndex = (
                        batchElementIndices[batchIndex]++
                    );


                    batchExecutions[batchIndex].tokenIds[batchElementIndex] = (
                        execution.item.identifier
                    );


                    uint256 amount = execution.item.amount;


                    _assertNonZeroAmount(amount);


                    batchExecutions[batchIndex].amounts[batchElementIndex] = (
                        amount
                    );
                }
            }


            return (standardExecutions, batchExecutions);
        }
    }
















    function _applyFraction(
        uint256 startAmount,
        uint256 endAmount,
        uint256 numerator,
        uint256 denominator,
        uint256 elapsed,
        uint256 remaining,
        uint256 duration,
        bool roundUp
    ) internal pure returns (uint256 amount) {

        if (startAmount == endAmount) {
            amount = _getFraction(numerator, denominator, endAmount);
        } else {

            amount = _locateCurrentAmount(
                _getFraction(numerator, denominator, startAmount),
                _getFraction(numerator, denominator, endAmount),
                elapsed,
                remaining,
                duration,
                roundUp
            );
        }
    }


















    function _aggregateValidFulfillmentConsiderationItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory considerationComponents,
        uint256 startIndex
    ) internal pure returns (ReceivedItem memory receivedItem) {

        bool invalidFulfillment;


        assembly {

            let totalOrders := mload(advancedOrders)


            let i := startIndex


            let fulfillmentPtr := mload(
                add(add(considerationComponents, 0x20), mul(i, 0x20))
            )


            let orderIndex := mload(fulfillmentPtr)


            let itemIndex := mload(add(fulfillmentPtr, 0x20))


            invalidFulfillment := iszero(lt(orderIndex, totalOrders))


            if iszero(invalidFulfillment) {



                let orderPtr := mload(


                    mload(

                        add(add(advancedOrders, 0x20), mul(orderIndex, 0x20))
                    )
                )


                let considerationArrPtr := mload(
                    add(orderPtr, OrderParameters_consideration_head_offset)
                )


                invalidFulfillment := iszero(
                    lt(itemIndex, mload(considerationArrPtr))
                )


                if iszero(invalidFulfillment) {

                    let considerationItemPtr := mload(
                        add(

                            add(considerationArrPtr, 0x20),

                            mul(itemIndex, 0x20)
                        )
                    )


                    mstore(receivedItem, mload(considerationItemPtr))


                    mstore(
                        add(receivedItem, Common_token_offset),
                        mload(add(considerationItemPtr, Common_token_offset))
                    )


                    mstore(
                        add(receivedItem, Common_identifier_offset),
                        mload(
                            add(considerationItemPtr, Common_identifier_offset)
                        )
                    )


                    let amountPtr := add(
                        considerationItemPtr,
                        Common_amount_offset
                    )

                    mstore(
                        add(receivedItem, Common_amount_offset),
                        mload(amountPtr)
                    )


                    mstore(amountPtr, 0)


                    mstore(
                        add(receivedItem, ReceivedItem_recipient_offset),
                        mload(
                            add(
                                considerationItemPtr,
                                ConsiderationItem_recipient_offset
                            )
                        )
                    )


                    i := add(i, 1)



                    for {} lt(i, mload(considerationComponents)) {
                        i := add(i, 1)
                    } {

                        fulfillmentPtr := mload(
                            add(
                                add(considerationComponents, 0x20),
                                mul(i, 0x20)
                            )
                        )


                        orderIndex := mload(fulfillmentPtr)


                        itemIndex := mload(add(fulfillmentPtr, 0x20))


                        invalidFulfillment := iszero(
                            lt(orderIndex, totalOrders)
                        )


                        if invalidFulfillment {
                            break
                        }


                        orderPtr := mload(
                            add(
                                add(advancedOrders, 0x20),
                                mul(orderIndex, 0x20)
                            )
                        )


                        if mload(
                            add(orderPtr, AdvancedOrder_numerator_offset)
                        ) {


                            orderPtr := mload(orderPtr)


                            considerationArrPtr := mload(
                                add(
                                    orderPtr,
                                    OrderParameters_consideration_head_offset
                                )
                            )


                            invalidFulfillment := iszero(
                                lt(itemIndex, mload(considerationArrPtr))
                            )


                            if invalidFulfillment {
                                break
                            }


                            considerationItemPtr := mload(
                                add(

                                    add(considerationArrPtr, 0x20),

                                    mul(itemIndex, 0x20)
                                )
                            )



                            amountPtr := add(
                                considerationItemPtr,
                                Common_amount_offset
                            )


                            mstore(
                                add(receivedItem, Common_amount_offset),
                                add(
                                    mload(
                                        add(receivedItem, Common_amount_offset)
                                    ),
                                    mload(amountPtr)
                                )
                            )



                            mstore(amountPtr, 0)


                            invalidFulfillment := iszero(
                                and(

                                    eq(
                                        mload(
                                            add(
                                                considerationItemPtr,
                                                ConsiderItem_recipient_offset
                                            )
                                        ),
                                        mload(
                                            add(
                                                receivedItem,
                                                ReceivedItem_recipient_offset
                                            )
                                        )
                                    ),
                                    and(

                                        eq(
                                            mload(considerationItemPtr),
                                            mload(receivedItem)
                                        ),
                                        and(

                                            eq(
                                                mload(
                                                    add(
                                                        considerationItemPtr,
                                                        Common_token_offset
                                                    )
                                                ),
                                                mload(
                                                    add(
                                                        receivedItem,
                                                        Common_token_offset
                                                    )
                                                )
                                            ),

                                            eq(
                                                mload(
                                                    add(
                                                        considerationItemPtr,
                                                        Common_identifier_offset
                                                    )
                                                ),
                                                mload(
                                                    add(
                                                        receivedItem,
                                                        Common_identifier_offset
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )


                            if invalidFulfillment {
                                break
                            }
                        }
                    }
                }
            }
        }


        if (invalidFulfillment) {
            revert InvalidFulfillmentComponentData();
        }
    }










    function _assertIsValidOrderStaticcallSuccess(
        bool success,
        bytes32 orderHash
    ) internal pure {

        if (!success) {

            _revertWithReasonIfOneIsReturned();


            revert InvalidRestrictedOrder(orderHash);
        }


        bytes4 result;
        assembly {

            if eq(returndatasize(), 0x20) {

                returndatacopy(0, 0, 0x20)


                result := mload(0)
            }
        }


        if (result != ZoneInterface.isValidOrder.selector) {
            revert InvalidRestrictedOrder(orderHash);
        }
    }
















    function _verifyOrderStatus(
        bytes32 orderHash,
        OrderStatus memory orderStatus,
        bool onlyAllowUnused,
        bool revertOnInvalid
    ) internal pure returns (bool valid) {

        if (orderStatus.isCancelled) {

            if (revertOnInvalid) {
                revert OrderIsCancelled(orderHash);
            }


            return false;
        }


        if (orderStatus.numerator != 0) {

            if (onlyAllowUnused) {

                revert OrderPartiallyFilled(orderHash);

            } else if (orderStatus.numerator >= orderStatus.denominator) {

                if (revertOnInvalid) {
                    revert OrderAlreadyFilled(orderHash);
                }


                return false;
            }
        }


        valid = true;
    }











    function _getHashByExecutionIndex(
        Execution[] memory executions,
        uint256 executionIndex
    ) internal pure returns (bytes32) {

        Execution memory execution = executions[executionIndex];


        ReceivedItem memory item = execution.item;



        return _hashBatchableItemIdentifier(
            item.token,
            execution.offerer,
            item.recipient,
            execution.conduit
        );
    }













    function _hashBatchableItemIdentifier(
        address token,
        address from,
        address to,
        address conduit
    ) internal pure returns (bytes32 value) {

        assembly {
            mstore(0x20, conduit)
            mstore(0x1c, to)
            mstore(0x08, from)


            mstore(0x00, or(shl(0x60, token), shr(0x40, from)))

            value := keccak256(0x00, 0x40)
        }
    }










    function _hashDigest(bytes32 domainSeparator, bytes32 orderHash)
        internal
        pure
        returns (bytes32 value)
    {

        assembly {

            mstore(
                0x00,
                0x1901000000000000000000000000000000000000000000000000000000000000
            )


            mstore(0x02, domainSeparator)





            mstore(0x22, orderHash)

            value := keccak256(0x00, 0x42)

            mstore(0x22, 0)
        }
    }












    function _isItemWithCriteria(ItemType itemType)
        internal
        pure
        returns (bool withCriteria)
    {


        assembly {
            withCriteria := gt(itemType, 3)
        }
    }











    function _doesNotSupportPartialFills(OrderType orderType)
        internal
        pure
        returns (bool isFullOrder)
    {


        assembly {

            isFullOrder := iszero(and(orderType, 1))
        }
    }









    function _convertOrderToAdvanced(Order calldata order)
        internal
        pure
        returns (AdvancedOrder memory advancedOrder)
    {

        advancedOrder = AdvancedOrder(
            order.parameters,
            1,
            1,
            order.signature,
            ""
        );
    }









    function _convertOrdersToAdvanced(Order[] calldata orders)
        internal
        pure
        returns (AdvancedOrder[] memory advancedOrders)
    {

        uint256 totalOrders = orders.length;


        advancedOrders = new AdvancedOrder[](totalOrders);


        unchecked {

            for (uint256 i = 0; i < totalOrders; ++i) {

                advancedOrders[i] = _convertOrderToAdvanced(orders[i]);
            }
        }


        return advancedOrders;
    }






    function _revertWithReasonIfOneIsReturned() internal pure {
        assembly {

            if returndatasize() {

                returndatacopy(0, 0, returndatasize())


                revert(0, returndatasize())
            }
        }
    }









    function _verifyProof(
        uint256 leaf,
        uint256 root,
        bytes32[] memory proof
    ) internal pure {

        bytes32 computedHash = bytes32(leaf);


        unchecked {

            for (uint256 i = 0; i < proof.length; ++i) {

                bytes32 proofElement = proof[i];

                if (computedHash <= proofElement) {

                    computedHash = _efficientHash(computedHash, proofElement);
                } else {

                    computedHash = _efficientHash(proofElement, computedHash);
                }
            }
        }


        if (computedHash != bytes32(root)) {
            revert InvalidProof();
        }
    }









    function _efficientHash(bytes32 a, bytes32 b)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }











    function _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
        uint256 suppliedConsiderationItemTotal,
        uint256 originalConsiderationItemTotal
    ) internal pure {

        if (suppliedConsiderationItemTotal < originalConsiderationItemTotal) {
            revert MissingOriginalConsiderationItems();
        }
    }







    function _assertNonZeroAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert MissingItemAmount();
        }
    }








    function _assertValidBasicOrderParameterOffsets() internal pure {

        bool validOffsets;


        assembly {






            validOffsets := and(

                eq(calldataload(0x04), 0x20),

                eq(calldataload(0x224), 0x240)
            )
            validOffsets := and(
                validOffsets,
                eq(

                    calldataload(0x244),

                    add(0x260, mul(calldataload(0x264), 0x40))
                )
            )
        }


        if (!validOffsets) {
            revert InvalidBasicOrderParameterEncoding();
        }
    }
}
