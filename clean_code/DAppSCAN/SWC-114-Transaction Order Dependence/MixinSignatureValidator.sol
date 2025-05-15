

















pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibEIP1271.sol";
import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "@0x/contracts-utils/contracts/src/ReentrancyGuard.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibZeroExTransaction.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibEIP712ExchangeDomain.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibExchangeRichErrors.sol";
import "./interfaces/IWallet.sol";
import "./interfaces/IEIP1271Wallet.sol";
import "./interfaces/ISignatureValidator.sol";
import "./interfaces/IEIP1271Data.sol";
import "./MixinTransactions.sol";


contract MixinSignatureValidator is
    ReentrancyGuard,
    LibEIP712ExchangeDomain,
    LibEIP1271,
    ISignatureValidator,
    MixinTransactions
{
    using LibBytes for bytes;
    using LibOrder for LibOrder.Order;
    using LibZeroExTransaction for LibZeroExTransaction.ZeroExTransaction;



    bytes4 private constant LEGACY_WALLET_MAGIC_VALUE = 0xb0671381;


    mapping (bytes32 => mapping (address => bool)) public preSigned;


    mapping (address => mapping (address => bool)) public allowedValidators;




    function preSign(bytes32 hash)
        external
        payable
        nonReentrant
        refundFinalBalance
    {
        address signerAddress = _getCurrentContextAddress();
        preSigned[hash][signerAddress] = true;
    }






    function setSignatureValidatorApproval(
        address validatorAddress,
        bool approval
    )
        external
        payable
        nonReentrant
        refundFinalBalance
    {
        address signerAddress = _getCurrentContextAddress();
        allowedValidators[signerAddress][validatorAddress] = approval;
        emit SignatureValidatorApproval(
            signerAddress,
            validatorAddress,
            approval
        );
    }






    function isValidHashSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid)
    {
        SignatureType signatureType = _readValidSignatureType(
            hash,
            signerAddress,
            signature
        );


        if (
            signatureType == SignatureType.Validator ||
            signatureType == SignatureType.EIP1271Wallet
        ) {
            LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                LibExchangeRichErrors.SignatureErrorCodes.INAPPROPRIATE_SIGNATURE_TYPE,
                hash,
                signerAddress,
                signature
            ));
        }
        isValid = _validateHashSignatureTypes(
            signatureType,
            hash,
            signerAddress,
            signature
        );
        return isValid;
    }





    function isValidOrderSignature(
        LibOrder.Order memory order,
        bytes memory signature
    )
        public
        view
        returns (bool isValid)
    {
        bytes32 orderHash = order.getTypedDataHash(EIP712_EXCHANGE_DOMAIN_HASH);
        isValid = _isValidOrderWithHashSignature(
            order,
            orderHash,
            signature
        );
        return isValid;
    }





    function isValidTransactionSignature(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        bytes memory signature
    )
        public
        view
        returns (bool isValid)
    {
        bytes32 transactionHash = transaction.getTypedDataHash(EIP712_EXCHANGE_DOMAIN_HASH);
        isValid = _isValidTransactionWithHashSignature(
            transaction,
            transactionHash,
            signature
        );
        return isValid;
    }








    function _doesSignatureRequireRegularValidation(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        internal
        pure
        returns (bool needsRegularValidation)
    {

        SignatureType signatureType = _readSignatureType(
            hash,
            signerAddress,
            signature
        );



        needsRegularValidation =
            signatureType == SignatureType.Wallet ||
            signatureType == SignatureType.Validator ||
            signatureType == SignatureType.EIP1271Wallet;
        return needsRegularValidation;
    }







    function _isValidOrderWithHashSignature(
        LibOrder.Order memory order,
        bytes32 orderHash,
        bytes memory signature
    )
        internal
        view
        returns (bool isValid)
    {
        address signerAddress = order.makerAddress;
        SignatureType signatureType = _readValidSignatureType(
            orderHash,
            signerAddress,
            signature
        );
        if (signatureType == SignatureType.Validator) {

            isValid = _validateBytesWithValidator(
                _encodeEIP1271OrderWithHash(order, orderHash),
                orderHash,
                signerAddress,
                signature
            );
        } else if (signatureType == SignatureType.EIP1271Wallet) {

            isValid = _validateBytesWithWallet(
                _encodeEIP1271OrderWithHash(order, orderHash),
                signerAddress,
                signature
            );
        } else {

            isValid = _validateHashSignatureTypes(
                signatureType,
                orderHash,
                signerAddress,
                signature
            );
        }
        return isValid;
    }







    function _isValidTransactionWithHashSignature(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        bytes32 transactionHash,
        bytes memory signature
    )
        internal
        view
        returns (bool isValid)
    {
        address signerAddress = transaction.signerAddress;
        SignatureType signatureType = _readValidSignatureType(
            transactionHash,
            signerAddress,
            signature
        );
        if (signatureType == SignatureType.Validator) {

            isValid = _validateBytesWithValidator(
                _encodeEIP1271TransactionWithHash(transaction, transactionHash),
                transactionHash,
                signerAddress,
                signature
            );
        } else if (signatureType == SignatureType.EIP1271Wallet) {

            isValid = _validateBytesWithWallet(
                _encodeEIP1271TransactionWithHash(transaction, transactionHash),
                signerAddress,
                signature
            );
        } else {

            isValid = _validateHashSignatureTypes(
                signatureType,
                transactionHash,
                signerAddress,
                signature
            );
        }
        return isValid;
    }



    function _validateHashSignatureTypes(
        SignatureType signatureType,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        private
        view
        returns (bool isValid)
    {




        if (signatureType == SignatureType.Invalid) {
            if (signature.length != 1) {
                LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                    LibExchangeRichErrors.SignatureErrorCodes.INVALID_LENGTH,
                    hash,
                    signerAddress,
                    signature
                ));
            }
            isValid = false;


        } else if (signatureType == SignatureType.EIP712) {
            if (signature.length != 66) {
                LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                    LibExchangeRichErrors.SignatureErrorCodes.INVALID_LENGTH,
                    hash,
                    signerAddress,
                    signature
                ));
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            address recovered = ecrecover(
                hash,
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;


        } else if (signatureType == SignatureType.EthSign) {
            if (signature.length != 66) {
                LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                    LibExchangeRichErrors.SignatureErrorCodes.INVALID_LENGTH,
                    hash,
                    signerAddress,
                    signature
                ));
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            address recovered = ecrecover(
                keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hash
                )),
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;


        } else if (signatureType == SignatureType.Wallet) {
            isValid = _validateHashWithWallet(
                hash,
                signerAddress,
                signature
            );


        } else {
            assert(signatureType == SignatureType.PreSigned);

            isValid = preSigned[hash][signerAddress];
        }
        return isValid;
    }


    function _readSignatureType(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType)
    {
        if (signature.length == 0) {
            LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                LibExchangeRichErrors.SignatureErrorCodes.INVALID_LENGTH,
                hash,
                signerAddress,
                signature
            ));
        }
        return SignatureType(uint8(signature[signature.length - 1]));
    }


    function _readValidSignatureType(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType signatureType)
    {

        signatureType = _readSignatureType(
            hash,
            signerAddress,
            signature
        );


        if (signerAddress == address(0)) {
            LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                LibExchangeRichErrors.SignatureErrorCodes.INVALID_SIGNER,
                hash,
                signerAddress,
                signature
            ));
        }


        if (uint8(signatureType) >= uint8(SignatureType.NSignatureTypes)) {
            LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                LibExchangeRichErrors.SignatureErrorCodes.UNSUPPORTED,
                hash,
                signerAddress,
                signature
            ));
        }






        if (signatureType == SignatureType.Illegal) {
            LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                LibExchangeRichErrors.SignatureErrorCodes.ILLEGAL,
                hash,
                signerAddress,
                signature
            ));
        }

        return signatureType;
    }



    function _encodeEIP1271OrderWithHash(
        LibOrder.Order memory order,
        bytes32 orderHash
    )
        private
        pure
        returns (bytes memory encoded)
    {
        return abi.encodeWithSelector(
            IEIP1271Data(address(0)).OrderWithHash.selector,
            order,
            orderHash
        );
    }



    function _encodeEIP1271TransactionWithHash(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        bytes32 transactionHash
    )
        private
        pure
        returns (bytes memory encoded)
    {
        return abi.encodeWithSelector(
            IEIP1271Data(address(0)).ZeroExTransactionWithHash.selector,
            transaction,
            transactionHash
        );
    }







    function _validateHashWithWallet(
        bytes32 hash,
        address walletAddress,
        bytes memory signature
    )
        private
        view
        returns (bool)
    {

        uint256 signatureLength = signature.length;

        signature.writeLength(signatureLength - 1);

        bytes memory callData = abi.encodeWithSelector(
            IWallet(address(0)).isValidSignature.selector,
            hash,
            signature
        );

        signature.writeLength(signatureLength);

        (bool didSucceed, bytes memory returnData) = walletAddress.staticcall(callData);

        if (didSucceed && returnData.length == 32) {
            return returnData.readBytes4(0) == LEGACY_WALLET_MAGIC_VALUE;
        }

        LibRichErrors.rrevert(LibExchangeRichErrors.SignatureWalletError(
            hash,
            walletAddress,
            signature,
            returnData
        ));
    }







    function _validateBytesWithWallet(
        bytes memory data,
        address walletAddress,
        bytes memory signature
    )
        private
        view
        returns (bool isValid)
    {
        isValid = _staticCallEIP1271WalletWithReducedSignatureLength(
            walletAddress,
            data,
            signature,
            1
        );
        return isValid;
    }








    function _validateBytesWithValidator(
        bytes memory data,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        private
        view
        returns (bool isValid)
    {
        uint256 signatureLength = signature.length;
        if (signatureLength < 21) {
            LibRichErrors.rrevert(LibExchangeRichErrors.SignatureError(
                LibExchangeRichErrors.SignatureErrorCodes.INVALID_LENGTH,
                hash,
                signerAddress,
                signature
            ));
        }


        address validatorAddress = signature.readAddress(signatureLength - 21);

        if (!allowedValidators[signerAddress][validatorAddress]) {
            LibRichErrors.rrevert(LibExchangeRichErrors.SignatureValidatorNotApprovedError(
                signerAddress,
                validatorAddress
            ));
        }
        isValid = _staticCallEIP1271WalletWithReducedSignatureLength(
            validatorAddress,
            data,
            signature,
            21
        );
        return isValid;
    }








    function _staticCallEIP1271WalletWithReducedSignatureLength(
        address verifyingContractAddress,
        bytes memory data,
        bytes memory signature,
        uint256 ignoredSignatureBytesLen
    )
        private
        view
        returns (bool)
    {

        uint256 signatureLength = signature.length;

        signature.writeLength(signatureLength - ignoredSignatureBytesLen);
        bytes memory callData = abi.encodeWithSelector(
            IEIP1271Wallet(address(0)).isValidSignature.selector,
            data,
            signature
        );

        signature.writeLength(signatureLength);

        (bool didSucceed, bytes memory returnData) = verifyingContractAddress.staticcall(callData);

        if (didSucceed && returnData.length == 32) {
            return returnData.readBytes4(0) == EIP1271_MAGIC_VALUE;
        }

        LibRichErrors.rrevert(LibExchangeRichErrors.EIP1271SignatureError(
            verifyingContractAddress,
            data,
            signature,
            returnData
        ));
    }
}
