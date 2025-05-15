
















pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibFillResults.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibExchangeRichErrors.sol";
import "./interfaces/IMatchOrders.sol";
import "./MixinExchangeCore.sol";


contract MixinMatchOrders is
    MixinExchangeCore,
    IMatchOrders
{
    using LibBytes for bytes;
    using LibSafeMath for uint256;
    using LibOrder for LibOrder.Order;









    function batchMatchOrders(
        LibOrder.Order[] memory leftOrders,
        LibOrder.Order[] memory rightOrders,
        bytes[] memory leftSignatures,
        bytes[] memory rightSignatures
    )
        public
        payable
        nonReentrant
        refundFinalBalance
        returns (LibFillResults.BatchMatchedFillResults memory batchMatchedFillResults)
    {
        return _batchMatchOrders(
            leftOrders,
            rightOrders,
            leftSignatures,
            rightSignatures,
            false
        );
    }










    function batchMatchOrdersWithMaximalFill(
        LibOrder.Order[] memory leftOrders,
        LibOrder.Order[] memory rightOrders,
        bytes[] memory leftSignatures,
        bytes[] memory rightSignatures
    )
        public
        payable
        nonReentrant
        refundFinalBalance
        returns (LibFillResults.BatchMatchedFillResults memory batchMatchedFillResults)
    {
        return _batchMatchOrders(
            leftOrders,
            rightOrders,
            leftSignatures,
            rightSignatures,
            true
        );
    }










    function matchOrders(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        bytes memory leftSignature,
        bytes memory rightSignature
    )
        public
        payable
        nonReentrant
        refundFinalBalance
        returns (LibFillResults.MatchedFillResults memory matchedFillResults)
    {
        return _matchOrders(
            leftOrder,
            rightOrder,
            leftSignature,
            rightSignature,
            false
        );
    }










    function matchOrdersWithMaximalFill(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        bytes memory leftSignature,
        bytes memory rightSignature
    )
        public
        payable
        nonReentrant
        refundFinalBalance
        returns (LibFillResults.MatchedFillResults memory matchedFillResults)
    {
        return _matchOrders(
            leftOrder,
            rightOrder,
            leftSignature,
            rightSignature,
            true
        );
    }






    function _assertValidMatch(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        bytes32 leftOrderHash,
        bytes32 rightOrderHash
    )
        internal
        pure
    {








        if (leftOrder.makerAssetAmount.safeMul(rightOrder.makerAssetAmount) <
            leftOrder.takerAssetAmount.safeMul(rightOrder.takerAssetAmount)) {
            LibRichErrors.rrevert(LibExchangeRichErrors.NegativeSpreadError(
                leftOrderHash,
                rightOrderHash
            ));
        }
    }












    function _batchMatchOrders(
        LibOrder.Order[] memory leftOrders,
        LibOrder.Order[] memory rightOrders,
        bytes[] memory leftSignatures,
        bytes[] memory rightSignatures,
        bool shouldMaximallyFillOrders
    )
        internal
        returns (LibFillResults.BatchMatchedFillResults memory batchMatchedFillResults)
    {

        if (leftOrders.length == 0) {
            LibRichErrors.rrevert(LibExchangeRichErrors.BatchMatchOrdersError(
                LibExchangeRichErrors.BatchMatchOrdersErrorCodes.ZERO_LEFT_ORDERS
            ));
        }
        if (rightOrders.length == 0) {
            LibRichErrors.rrevert(LibExchangeRichErrors.BatchMatchOrdersError(
                LibExchangeRichErrors.BatchMatchOrdersErrorCodes.ZERO_RIGHT_ORDERS
            ));
        }


        if (leftOrders.length != leftSignatures.length) {
            LibRichErrors.rrevert(LibExchangeRichErrors.BatchMatchOrdersError(
                LibExchangeRichErrors.BatchMatchOrdersErrorCodes.INVALID_LENGTH_LEFT_SIGNATURES
            ));
        }
        if (rightOrders.length != rightSignatures.length) {
            LibRichErrors.rrevert(LibExchangeRichErrors.BatchMatchOrdersError(
                LibExchangeRichErrors.BatchMatchOrdersErrorCodes.INVALID_LENGTH_RIGHT_SIGNATURES
            ));
        }

        batchMatchedFillResults.left = new LibFillResults.FillResults[](leftOrders.length);
        batchMatchedFillResults.right = new LibFillResults.FillResults[](rightOrders.length);


        uint256 leftIdx = 0;
        uint256 rightIdx = 0;


        LibOrder.Order memory leftOrder = leftOrders[0];
        LibOrder.Order memory rightOrder = rightOrders[0];
        (, uint256 leftOrderTakerAssetFilledAmount) = _getOrderHashAndFilledAmount(leftOrder);
        (, uint256 rightOrderTakerAssetFilledAmount) = _getOrderHashAndFilledAmount(rightOrder);
        LibFillResults.FillResults memory leftFillResults;
        LibFillResults.FillResults memory rightFillResults;



        for (;;) {

            LibFillResults.MatchedFillResults memory matchResults = _matchOrders(
                leftOrder,
                rightOrder,
                leftSignatures[leftIdx],
                rightSignatures[rightIdx],
                shouldMaximallyFillOrders
            );


            leftOrderTakerAssetFilledAmount = leftOrderTakerAssetFilledAmount.safeAdd(matchResults.left.takerAssetFilledAmount);
            rightOrderTakerAssetFilledAmount = rightOrderTakerAssetFilledAmount.safeAdd(matchResults.right.takerAssetFilledAmount);


            leftFillResults = LibFillResults.addFillResults(
                leftFillResults,
                matchResults.left
            );
            rightFillResults = LibFillResults.addFillResults(
                rightFillResults,
                matchResults.right
            );



            batchMatchedFillResults.profitInLeftMakerAsset = batchMatchedFillResults.profitInLeftMakerAsset.safeAdd(
                matchResults.profitInLeftMakerAsset
            );
            batchMatchedFillResults.profitInRightMakerAsset = batchMatchedFillResults.profitInRightMakerAsset.safeAdd(
                matchResults.profitInRightMakerAsset
            );



            if (leftOrderTakerAssetFilledAmount >= leftOrder.takerAssetAmount) {

                batchMatchedFillResults.left[leftIdx++] = leftFillResults;

                leftFillResults = LibFillResults.FillResults(0, 0, 0, 0, 0);



                if (leftIdx == leftOrders.length) {

                    batchMatchedFillResults.right[rightIdx] = rightFillResults;
                    break;
                } else {
                    leftOrder = leftOrders[leftIdx];
                    (, leftOrderTakerAssetFilledAmount) = _getOrderHashAndFilledAmount(leftOrder);
                }
            }



            if (rightOrderTakerAssetFilledAmount >= rightOrder.takerAssetAmount) {

                batchMatchedFillResults.right[rightIdx++] = rightFillResults;

                rightFillResults = LibFillResults.FillResults(0, 0, 0, 0, 0);



                if (rightIdx == rightOrders.length) {

                    batchMatchedFillResults.left[leftIdx] = leftFillResults;
                    break;
                } else {
                    rightOrder = rightOrders[rightIdx];
                    (, rightOrderTakerAssetFilledAmount) = _getOrderHashAndFilledAmount(rightOrder);
                }
            }
        }


        return batchMatchedFillResults;
    }













    function _matchOrders(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        bytes memory leftSignature,
        bytes memory rightSignature,
        bool shouldMaximallyFillOrders
    )
        internal
        returns (LibFillResults.MatchedFillResults memory matchedFillResults)
    {



        rightOrder.makerAssetData = leftOrder.takerAssetData;
        rightOrder.takerAssetData = leftOrder.makerAssetData;


        LibOrder.OrderInfo memory leftOrderInfo = getOrderInfo(leftOrder);
        LibOrder.OrderInfo memory rightOrderInfo = getOrderInfo(rightOrder);


        address takerAddress = _getCurrentContextAddress();


        _assertFillableOrder(
            leftOrder,
            leftOrderInfo,
            takerAddress,
            leftSignature
        );
        _assertFillableOrder(
            rightOrder,
            rightOrderInfo,
            takerAddress,
            rightSignature
        );
        _assertValidMatch(
            leftOrder,
            rightOrder,
            leftOrderInfo.orderHash,
            rightOrderInfo.orderHash
        );


        matchedFillResults = LibFillResults.calculateMatchedFillResults(
            leftOrder,
            rightOrder,
            leftOrderInfo.orderTakerAssetFilledAmount,
            rightOrderInfo.orderTakerAssetFilledAmount,
            protocolFeeMultiplier,
            tx.gasprice,
            shouldMaximallyFillOrders
        );


        _updateFilledState(
            leftOrder,
            takerAddress,
            leftOrderInfo.orderHash,
            leftOrderInfo.orderTakerAssetFilledAmount,
            matchedFillResults.left
        );
        _updateFilledState(
            rightOrder,
            takerAddress,
            rightOrderInfo.orderHash,
            rightOrderInfo.orderTakerAssetFilledAmount,
            matchedFillResults.right
        );


        _settleMatchedOrders(
            leftOrderInfo.orderHash,
            rightOrderInfo.orderHash,
            leftOrder,
            rightOrder,
            takerAddress,
            matchedFillResults
        );

        return matchedFillResults;
    }










    function _settleMatchedOrders(
        bytes32 leftOrderHash,
        bytes32 rightOrderHash,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        address takerAddress,
        LibFillResults.MatchedFillResults memory matchedFillResults
    )
        internal
    {
        address leftMakerAddress = leftOrder.makerAddress;
        address rightMakerAddress = rightOrder.makerAddress;
        address leftFeeRecipientAddress = leftOrder.feeRecipientAddress;
        address rightFeeRecipientAddress = rightOrder.feeRecipientAddress;


        _dispatchTransferFrom(
            rightOrderHash,
            rightOrder.makerAssetData,
            rightMakerAddress,
            leftMakerAddress,
            matchedFillResults.left.takerAssetFilledAmount
        );


        _dispatchTransferFrom(
            leftOrderHash,
            leftOrder.makerAssetData,
            leftMakerAddress,
            rightMakerAddress,
            matchedFillResults.right.takerAssetFilledAmount
        );


        _dispatchTransferFrom(
            rightOrderHash,
            rightOrder.makerFeeAssetData,
            rightMakerAddress,
            rightFeeRecipientAddress,
            matchedFillResults.right.makerFeePaid
        );


        _dispatchTransferFrom(
            leftOrderHash,
            leftOrder.makerFeeAssetData,
            leftMakerAddress,
            leftFeeRecipientAddress,
            matchedFillResults.left.makerFeePaid
        );


        _dispatchTransferFrom(
            leftOrderHash,
            leftOrder.makerAssetData,
            leftMakerAddress,
            takerAddress,
            matchedFillResults.profitInLeftMakerAsset
        );
        _dispatchTransferFrom(
            rightOrderHash,
            rightOrder.makerAssetData,
            rightMakerAddress,
            takerAddress,
            matchedFillResults.profitInRightMakerAsset
        );


        bool didPayProtocolFees = _payTwoProtocolFees(
            leftOrderHash,
            rightOrderHash,
            matchedFillResults.left.protocolFeePaid,
            leftMakerAddress,
            rightMakerAddress,
            takerAddress
        );


        if (!didPayProtocolFees) {
            matchedFillResults.left.protocolFeePaid = 0;
            matchedFillResults.right.protocolFeePaid = 0;
        }


        if (
            leftFeeRecipientAddress == rightFeeRecipientAddress &&
            leftOrder.takerFeeAssetData.equals(rightOrder.takerFeeAssetData)
        ) {


            _dispatchTransferFrom(
                leftOrderHash,
                leftOrder.takerFeeAssetData,
                takerAddress,
                leftFeeRecipientAddress,
                matchedFillResults.left.takerFeePaid.safeAdd(matchedFillResults.right.takerFeePaid)
            );
        } else {

            _dispatchTransferFrom(
                rightOrderHash,
                rightOrder.takerFeeAssetData,
                takerAddress,
                rightFeeRecipientAddress,
                matchedFillResults.right.takerFeePaid
            );


            _dispatchTransferFrom(
                leftOrderHash,
                leftOrder.takerFeeAssetData,
                takerAddress,
                leftFeeRecipientAddress,
                matchedFillResults.left.takerFeePaid
            );
        }
    }
}
