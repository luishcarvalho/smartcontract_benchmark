

















pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibMetaTransactionsRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinReentrancyGuard.sol";
import "../fixins/FixinTokenSpender.sol";
import "../fixins/FixinEIP712.sol";
import "../migrations/LibMigrate.sol";
import "../storage/LibMetaTransactionsStorage.sol";
import "./IMetaTransactionsFeature.sol";
import "./ITransformERC20Feature.sol";
import "./libs/LibSignature.sol";
import "./ISignatureValidatorFeature.sol";
import "./IFeature.sol";
import "./INativeOrdersFeature.sol";


contract MetaTransactionsFeature is
    IFeature,
    IMetaTransactionsFeature,
    FixinCommon,
    FixinReentrancyGuard,
    FixinEIP712,
    FixinTokenSpender
{
    using LibBytesV06 for bytes;
    using LibRichErrorsV06 for bytes;


    struct ExecuteState {

        address sender;

        bytes32 hash;

        MetaTransactionData mtx;

        LibSignature.Signature signature;

        bytes4 selector;

        uint256 selfBalance;

        uint256 executedBlockNumber;
    }


    struct ExternalTransformERC20Args {
        IERC20TokenV06 inputToken;
        IERC20TokenV06 outputToken;
        uint256 inputTokenAmount;
        uint256 minOutputTokenAmount;
        ITransformERC20Feature.Transformation[] transformations;
    }


    string public constant override FEATURE_NAME = "MetaTransactions";

    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 0);

    bytes32 public immutable MTX_EIP712_TYPEHASH = keccak256(
        "MetaTransactionData("
            "address signer,"
            "address sender,"
            "uint256 minGasPrice,"
            "uint256 maxGasPrice,"
            "uint256 expirationTimeSeconds,"
            "uint256 salt,"
            "bytes callData,"
            "uint256 value,"
            "address feeToken,"
            "uint256 feeAmount"
        ")"
    );



    modifier refundsAttachedEth() {
        _;
        uint256 remainingBalance =
            LibSafeMathV06.min256(msg.value, address(this).balance);
        if (remainingBalance > 0) {
            msg.sender.transfer(remainingBalance);
        }
    }

    constructor(address zeroExAddress, bytes32 greedyTokensBloomFilter)
        public
        FixinCommon()
        FixinEIP712(zeroExAddress)
        FixinTokenSpender(greedyTokensBloomFilter)
    {

    }




    function migrate()
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.executeMetaTransaction.selector);
        _registerFeatureFunction(this.batchExecuteMetaTransactions.selector);
        _registerFeatureFunction(this._executeMetaTransaction.selector);
        _registerFeatureFunction(this.getMetaTransactionExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionHashExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionHash.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }





    function executeMetaTransaction(
        MetaTransactionData memory mtx,
        LibSignature.Signature memory signature
    )
        public
        payable
        override
        nonReentrant(REENTRANCY_MTX)
        refundsAttachedEth
        returns (bytes memory returnResult)
    {
        ExecuteState memory state;
        state.sender = msg.sender;
        state.mtx = mtx;
        state.hash = getMetaTransactionHash(mtx);
        state.signature = signature;

        returnResult = _executeMetaTransactionPrivate(state);
    }





    function batchExecuteMetaTransactions(
        MetaTransactionData[] memory mtxs,
        LibSignature.Signature[] memory signatures
    )
        public
        payable
        override
        nonReentrant(REENTRANCY_MTX)
        refundsAttachedEth
        returns (bytes[] memory returnResults)
    {
        if (mtxs.length != signatures.length) {
            LibMetaTransactionsRichErrors.InvalidMetaTransactionsArrayLengthsError(
                mtxs.length,
                signatures.length
            ).rrevert();
        }
        returnResults = new bytes[](mtxs.length);
        for (uint256 i = 0; i < mtxs.length; ++i) {
            ExecuteState memory state;
            state.sender = msg.sender;
            state.mtx = mtxs[i];
            state.hash = getMetaTransactionHash(mtxs[i]);
            state.signature = signatures[i];

            returnResults[i] = _executeMetaTransactionPrivate(state);
        }
    }







    function _executeMetaTransaction(
        address sender,
        MetaTransactionData memory mtx,
        LibSignature.Signature memory signature
    )
        public
        payable
        override
        onlySelf
        returns (bytes memory returnResult)
    {
        ExecuteState memory state;
        state.sender = sender;
        state.mtx = mtx;
        state.hash = getMetaTransactionHash(mtx);
        state.signature = signature;

        return _executeMetaTransactionPrivate(state);
    }




    function getMetaTransactionExecutedBlock(MetaTransactionData memory mtx)
        public
        override
        view
        returns (uint256 blockNumber)
    {
        return getMetaTransactionHashExecutedBlock(getMetaTransactionHash(mtx));
    }




    function getMetaTransactionHashExecutedBlock(bytes32 mtxHash)
        public
        override
        view
        returns (uint256 blockNumber)
    {
        return LibMetaTransactionsStorage.getStorage().mtxHashToExecutedBlockNumber[mtxHash];
    }




    function getMetaTransactionHash(MetaTransactionData memory mtx)
        public
        override
        view
        returns (bytes32 mtxHash)
    {
        return _getEIP712Hash(keccak256(abi.encode(
            MTX_EIP712_TYPEHASH,
            mtx.signer,
            mtx.sender,
            mtx.minGasPrice,
            mtx.maxGasPrice,
            mtx.expirationTimeSeconds,
            mtx.salt,
            keccak256(mtx.callData),
            mtx.value,
            mtx.feeToken,
            mtx.feeAmount
        )));
    }





    function _executeMetaTransactionPrivate(ExecuteState memory state)
        private
        returns (bytes memory returnResult)
    {
        _validateMetaTransaction(state);




        LibMetaTransactionsStorage.getStorage()
            .mtxHashToExecutedBlockNumber[state.hash] = block.number;


        if (state.mtx.feeAmount > 0) {
            _transferERC20Tokens(
                state.mtx.feeToken,
                state.mtx.signer,
                state.sender,
                state.mtx.feeAmount
            );
        }


        state.selector = state.mtx.callData.readBytes4(0);
        if (state.selector == ITransformERC20Feature.transformERC20.selector) {
            returnResult = _executeTransformERC20Call(state);
        } else if (state.selector == INativeOrdersFeature.fillLimitOrder.selector) {
            returnResult = _executeFillLimitOrderCall(state);
        } else if (state.selector == INativeOrdersFeature.fillRfqOrder.selector) {
            returnResult = _executeFillRfqOrderCall(state);
        } else {
            LibMetaTransactionsRichErrors
                .MetaTransactionUnsupportedFunctionError(state.hash, state.selector)
                .rrevert();
        }
        emit MetaTransactionExecuted(
            state.hash,
            state.selector,
            state.mtx.signer,
            state.mtx.sender
        );
    }


    function _validateMetaTransaction(ExecuteState memory state)
        private
        view
    {

        if (state.mtx.sender != address(0) && state.mtx.sender != state.sender) {
            LibMetaTransactionsRichErrors
                .MetaTransactionWrongSenderError(
                    state.hash,
                    state.sender,
                    state.mtx.sender
                ).rrevert();
        }

        if (state.mtx.expirationTimeSeconds <= block.timestamp) {
            LibMetaTransactionsRichErrors
                .MetaTransactionExpiredError(
                    state.hash,
                    block.timestamp,
                    state.mtx.expirationTimeSeconds
                ).rrevert();
        }

        if (state.mtx.minGasPrice > tx.gasprice || state.mtx.maxGasPrice < tx.gasprice) {
            LibMetaTransactionsRichErrors
                .MetaTransactionGasPriceError(
                    state.hash,
                    tx.gasprice,
                    state.mtx.minGasPrice,
                    state.mtx.maxGasPrice
                ).rrevert();
        }

        state.selfBalance  = address(this).balance;
        if (state.mtx.value > state.selfBalance) {
            LibMetaTransactionsRichErrors
                .MetaTransactionInsufficientEthError(
                    state.hash,
                    state.selfBalance,
                    state.mtx.value
                ).rrevert();
        }

        if (LibSignature.getSignerOfHash(state.hash, state.signature) !=
                state.mtx.signer) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.WRONG_SIGNER,
                state.hash,
                state.mtx.signer,


                ""
            ).rrevert();
        }

        state.executedBlockNumber = LibMetaTransactionsStorage
            .getStorage().mtxHashToExecutedBlockNumber[state.hash];
        if (state.executedBlockNumber != 0) {
            LibMetaTransactionsRichErrors
                .MetaTransactionAlreadyExecutedError(
                    state.hash,
                    state.executedBlockNumber
                ).rrevert();
        }
    }





    function _executeTransformERC20Call(ExecuteState memory state)
        private
        returns (bytes memory returnResult)
    {




























        ExternalTransformERC20Args memory args;
        {
            bytes memory encodedStructArgs = new bytes(state.mtx.callData.length - 4 + 32);

            bytes memory fromCallData = state.mtx.callData;
            assert(fromCallData.length >= 160);
            uint256 fromMem;
            uint256 toMem;
            assembly {


                mstore(add(encodedStructArgs, 32), 32)

                fromMem := add(fromCallData, 36)

                toMem := add(encodedStructArgs, 64)
            }
            LibBytesV06.memCopy(toMem, fromMem, fromCallData.length - 4);

            args = abi.decode(encodedStructArgs, (ExternalTransformERC20Args));
        }

        return _callSelf(
            state.hash,
            abi.encodeWithSelector(
                ITransformERC20Feature._transformERC20.selector,
                ITransformERC20Feature.TransformERC20Args({
                    taker: state.mtx.signer,
                    inputToken: args.inputToken,
                    outputToken: args.outputToken,
                    inputTokenAmount: args.inputTokenAmount,
                    minOutputTokenAmount: args.minOutputTokenAmount,
                    transformations: args.transformations
              })
            ),
            state.mtx.value
        );
    }





    function _extractArgumentsFromCallData(
        bytes memory callData
    )
        private
        pure
        returns (bytes memory args)
    {
        args = new bytes(callData.length - 4);
        uint256 fromMem;
        uint256 toMem;

        assembly {
            fromMem := add(callData, 36)
            toMem := add(args, 32)
        }

        LibBytesV06.memCopy(toMem, fromMem, args.length);

        return args;
    }





    function _executeFillLimitOrderCall(ExecuteState memory state)
        private
        returns (bytes memory returnResult)
    {
        LibNativeOrder.LimitOrder memory order;
        LibSignature.Signature memory signature;
        uint128 takerTokenFillAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (order, signature, takerTokenFillAmount) = abi.decode(args, (LibNativeOrder.LimitOrder, LibSignature.Signature, uint128));

        return _callSelf(
            state.hash,
            abi.encodeWithSelector(
                INativeOrdersFeature._fillLimitOrder.selector,
                order,
                signature,
                takerTokenFillAmount,
                state.mtx.signer,
                msg.sender
            ),
            state.mtx.value
        );
    }





    function _executeFillRfqOrderCall(ExecuteState memory state)
        private
        returns (bytes memory returnResult)
    {
        LibNativeOrder.RfqOrder memory order;
        LibSignature.Signature memory signature;
        uint128 takerTokenFillAmount;

        bytes memory args = _extractArgumentsFromCallData(state.mtx.callData);
        (order, signature, takerTokenFillAmount) = abi.decode(args, (LibNativeOrder.RfqOrder, LibSignature.Signature, uint128));

        return _callSelf(
            state.hash,
            abi.encodeWithSelector(
                INativeOrdersFeature._fillRfqOrder.selector,
                order,
                signature,
                takerTokenFillAmount,
                state.mtx.signer
            ),
            state.mtx.value
        );
    }



    function _callSelf(bytes32 hash, bytes memory callData, uint256 value)
        private
        returns (bytes memory returnResult)
    {
        bool success;
        (success, returnResult) = address(this).call{value: value}(callData);
        if (!success) {
            LibMetaTransactionsRichErrors.MetaTransactionCallFailedError(
                hash,
                callData,
                returnResult
            ).rrevert();
        }
    }
}
