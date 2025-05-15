
pragma solidity 0.8.13;


import {
    ConsiderationInterface
} from "./interfaces/ConsiderationInterface.sol";


import {
    OrderType,
    ItemType,
    BasicOrderRouteType
} from "./lib/ConsiderationEnums.sol";


import {
    BasicOrderParameters,
    OfferItem,
    ConsiderationItem,
    OrderParameters,
    OrderComponents,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver,
    BatchExecution
} from "./lib/ConsiderationStructs.sol";

import { ConsiderationInternal } from "./lib/ConsiderationInternal.sol";















contract Consideration is ConsiderationInterface, ConsiderationInternal {













    constructor(
        address legacyProxyRegistry,
        address legacyTokenTransferProxy,
        address requiredProxyImplementation
    )
        ConsiderationInternal(
            legacyProxyRegistry,
            legacyTokenTransferProxy,
            requiredProxyImplementation
        )
    {}


























    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        override
        returns (bool)
    {

        BasicOrderRouteType route;
        OrderType orderType;


        ItemType additionalRecipientsItemType;


        assembly {

            orderType := and(calldataload(0x124), 3)


            route := div(calldataload(0x124), 4)


            additionalRecipientsItemType := gt(route, 1)
        }

        {

            bool correctPayableStatus;


            assembly {

                correctPayableStatus := eq(
                    additionalRecipientsItemType,
                    iszero(callvalue())
                )
            }



            if (!correctPayableStatus) {
                revert InvalidMsgValue(msg.value);
            }
        }


        address additionalRecipientsToken;
        ItemType receivedItemType;
        ItemType offeredItemType;


        assembly {

            let offerTypeIsAdditionalRecipientsType := gt(route, 3)


            additionalRecipientsToken := calldataload(
                add(0x24, mul(0xa0, offerTypeIsAdditionalRecipientsType))
            )



            receivedItemType := add(
                mul(sub(route, 2), gt(route, 2)),
                eq(route, 2)
            )



            offeredItemType := sub(
                add(route, mul(iszero(additionalRecipientsItemType), 2)),
                mul(
                    offerTypeIsAdditionalRecipientsType,
                    add(receivedItemType, 1)
                )
            )
        }


        _prepareBasicFulfillmentFromCalldata(
            parameters,
            orderType,
            receivedItemType,
            additionalRecipientsItemType,
            additionalRecipientsToken,
            offeredItemType
        );


        address payable offerer = parameters.offerer;


        address conduit;


        assembly {

            conduit := calldataload(add(0x1c4, mul(gt(route, 3), 0x20)))
        }


        if (route == BasicOrderRouteType.ETH_TO_ERC721) {

            _transferERC721(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );


            _transferEthAndFinalize(parameters.considerationAmount, parameters);
        } else if (route == BasicOrderRouteType.ETH_TO_ERC1155) {

            _transferERC1155(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );


            _transferEthAndFinalize(parameters.considerationAmount, parameters);
        } else if (route == BasicOrderRouteType.ERC20_TO_ERC721) {

            _transferERC721(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );


            _transferERC20AndFinalize(
                msg.sender,
                offerer,
                parameters.considerationToken,
                parameters.considerationAmount,
                parameters,
                false
            );
        } else if (route == BasicOrderRouteType.ERC20_TO_ERC1155) {

            _transferERC1155(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );


            _transferERC20AndFinalize(
                msg.sender,
                offerer,
                parameters.considerationToken,
                parameters.considerationAmount,
                parameters,
                false
            );
        } else if (route == BasicOrderRouteType.ERC721_TO_ERC20) {

            _transferERC721(
                parameters.considerationToken,
                msg.sender,
                offerer,
                parameters.considerationIdentifier,
                parameters.considerationAmount,
                conduit
            );


            _transferERC20AndFinalize(
                offerer,
                msg.sender,
                parameters.offerToken,
                parameters.offerAmount,
                parameters,
                true
            );
        } else {



            _transferERC1155(
                parameters.considerationToken,
                msg.sender,
                offerer,
                parameters.considerationIdentifier,
                parameters.considerationAmount,
                conduit
            );


            _transferERC20AndFinalize(
                offerer,
                msg.sender,
                parameters.offerToken,
                parameters.offerAmount,
                parameters,
                true
            );
        }

        return true;
    }























    function fulfillOrder(Order calldata order, address fulfillerConduit)
        external
        payable
        override
        returns (bool)
    {


        return _validateAndFulfillAdvancedOrder(
            _convertOrderToAdvanced(order),
            new CriteriaResolver[](0),
            fulfillerConduit
        );
    }





































    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        address fulfillerConduit
    ) external payable override returns (bool) {

        return
            _validateAndFulfillAdvancedOrder(
                advancedOrder,
                criteriaResolvers,
                fulfillerConduit
            );
    }



































































    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        address fulfillerConduit
    )
        external
        payable
        override
        returns (
            bool[] memory availableOrders,
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {

        _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            false
        );


        (
            availableOrders,
            standardExecutions,
            batchExecutions
        ) = _fulfillAvailableOrders(
            advancedOrders,
            offerFulfillments,
            considerationFulfillments,
            fulfillerConduit
        );


        return (availableOrders, standardExecutions, batchExecutions);
    }




























    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {

        AdvancedOrder[] memory advancedOrders = _convertOrdersToAdvanced(
            orders
        );


        _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            new CriteriaResolver[](0),
            true
        );


        return _fulfillAdvancedOrders(advancedOrders, fulfillments);
    }








































    function matchAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {

        _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            true
        );


        return _fulfillAdvancedOrders(advancedOrders, fulfillments);
    }










    function cancel(OrderComponents[] calldata orders)
        external
        override
        returns (bool)
    {

        _assertNonReentrant();

        address offerer;
        address zone;


        unchecked {

            uint256 totalOrders = orders.length;


            for (uint256 i = 0; i < totalOrders; ) {

                OrderComponents calldata order = orders[i];

                offerer = order.offerer;
                zone = order.zone;


                if (msg.sender != offerer && msg.sender != zone) {
                    revert InvalidCanceller();
                }


                bytes32 orderHash = _getOrderHash(
                    OrderParameters(
                        offerer,
                        zone,
                        order.offer,
                        order.consideration,
                        order.orderType,
                        order.startTime,
                        order.endTime,
                        order.zoneHash,
                        order.salt,
                        order.conduit,
                        order.consideration.length
                    ),
                    order.nonce
                );


                _orderStatus[orderHash].isValidated = false;
                _orderStatus[orderHash].isCancelled = true;


                emit OrderCancelled(orderHash, offerer, zone);


                ++i;
            }
        }

        return true;
    }












    function validate(Order[] calldata orders)
        external
        override
        returns (bool)
    {

        _assertNonReentrant();


        bytes32 orderHash;
        address offerer;


        unchecked {

            uint256 totalOrders = orders.length;


            for (uint256 i = 0; i < totalOrders; ) {

                Order calldata order = orders[i];


                OrderParameters calldata orderParameters = order.parameters;


                offerer = orderParameters.offerer;


                orderHash = _assertConsiderationLengthAndGetNoncedOrderHash(
                    orderParameters
                );


                OrderStatus memory orderStatus = _orderStatus[orderHash];


                _verifyOrderStatus(
                    orderHash,
                    orderStatus,
                    false,
                    true
                );


                if (!orderStatus.isValidated) {

                    _verifySignature(offerer, orderHash, order.signature);


                    _orderStatus[orderHash].isValidated = true;


                    emit OrderValidated(
                        orderHash,
                        offerer,
                        orderParameters.zone
                    );
                }


                ++i;
            }
        }

        return true;
    }








    function incrementNonce() external override returns (uint256 newNonce) {

        _assertNonReentrant();


        unchecked {

            newNonce = ++_nonces[msg.sender];
        }


        emit NonceIncremented(newNonce, msg.sender);
    }








    function getOrderHash(OrderComponents memory order)
        external
        view
        override
        returns (bytes32)
    {


        return _getOrderHash(
            OrderParameters(
                order.offerer,
                order.zone,
                order.offer,
                order.consideration,
                order.orderType,
                order.startTime,
                order.endTime,
                order.zoneHash,
                order.salt,
                order.conduit,
                order.consideration.length
            ),
            order.nonce
        );
    }


















    function getOrderStatus(bytes32 orderHash)
        external
        view
        override
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        )
    {

        OrderStatus memory orderStatus = _orderStatus[orderHash];


        return (
            orderStatus.isValidated,
            orderStatus.isCancelled,
            orderStatus.numerator,
            orderStatus.denominator
        );
    }








    function getNonce(address offerer)
        external
        view
        override
        returns (uint256)
    {

        return _nonces[offerer];
    }







    function DOMAIN_SEPARATOR() external view override returns (bytes32) {

        return _domainSeparator();
    }






    function name() external pure override returns (string memory) {

        return _NAME;
    }






    function version() external pure override returns (string memory) {

        return _VERSION;
    }
}
