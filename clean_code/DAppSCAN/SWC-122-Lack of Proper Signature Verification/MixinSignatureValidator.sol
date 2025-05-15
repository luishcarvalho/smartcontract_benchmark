

















pragma solidity 0.4.24;

import "../../utils/LibBytes/LibBytes.sol";
import "./mixins/MSignatureValidator.sol";
import "./mixins/MTransactions.sol";
import "./interfaces/IWallet.sol";
import "./interfaces/IValidator.sol";


contract MixinSignatureValidator is
    MSignatureValidator,
    MTransactions
{
    using LibBytes for bytes;


    mapping (bytes32 => mapping (address => bool)) public preSigned;


    mapping (address => mapping (address => bool)) public allowedValidators;





    function preSign(
        bytes32 hash,
        address signerAddress,
        bytes signature
    )
        external
    {

        require(
            isValidSignature(
                hash,
                signerAddress,
                signature
            ),
            "INVALID_SIGNATURE"
        );
        preSigned[hash][signerAddress] = true;
    }




    function setSignatureValidatorApproval(
        address validatorAddress,
        bool approval
    )
        external
    {
        address signerAddress = getCurrentContextAddress();
        allowedValidators[signerAddress][validatorAddress] = approval;
        emit SignatureValidatorApproval(
            signerAddress,
            validatorAddress,
            approval
        );
    }






    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid)
    {
        require(
            signature.length > 0,
            "LENGTH_GREATER_THAN_0_REQUIRED"
        );


        uint8 signatureTypeRaw = uint8(signature.popLastByte());
        require(
            signatureTypeRaw < uint8(SignatureType.NSignatureTypes),
            "SIGNATURE_UNSUPPORTED"
        );


        SignatureType signatureType = SignatureType(signatureTypeRaw);


        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;






        if (signatureType == SignatureType.Illegal) {
            revert("SIGNATURE_ILLEGAL");





        } else if (signatureType == SignatureType.Invalid) {
            require(
                signature.length == 0,
                "LENGTH_0_REQUIRED"
            );
            isValid = false;
            return isValid;


        } else if (signatureType == SignatureType.EIP712) {
            require(
                signature.length == 65,
                "LENGTH_65_REQUIRED"
            );
            v = uint8(signature[0]);
            r = signature.readBytes32(1);
            s = signature.readBytes32(33);
            recovered = ecrecover(hash, v, r, s);
            isValid = signerAddress == recovered;
            return isValid;


        } else if (signatureType == SignatureType.EthSign) {
            require(
                signature.length == 65,
                "LENGTH_65_REQUIRED"
            );
            v = uint8(signature[0]);
            r = signature.readBytes32(1);
            s = signature.readBytes32(33);
            recovered = ecrecover(
                keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hash
                )),
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;
            return isValid;









        } else if (signatureType == SignatureType.Caller) {
            require(
                signature.length == 0,
                "LENGTH_0_REQUIRED"
            );
            isValid = signerAddress == msg.sender;
            return isValid;



        } else if (signatureType == SignatureType.Wallet) {
            isValid = IWallet(signerAddress).isValidSignature(hash, signature);
            return isValid;








        } else if (signatureType == SignatureType.Validator) {


            address validatorAddress = signature.popLast20Bytes();


            if (!allowedValidators[signerAddress][validatorAddress]) {
                return false;
            }
            isValid = IValidator(validatorAddress).isValidSignature(
                hash,
                signerAddress,
                signature
            );
            return isValid;


        } else if (signatureType == SignatureType.PreSigned) {
            isValid = preSigned[hash][signerAddress];
            return isValid;









        } else if (signatureType == SignatureType.Trezor) {
            require(
                signature.length == 65,
                "LENGTH_65_REQUIRED"
            );
            v = uint8(signature[0]);
            r = signature.readBytes32(1);
            s = signature.readBytes32(33);
            recovered = ecrecover(
                keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n\x20",
                    hash
                )),
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;
            return isValid;
        }






        revert("SIGNATURE_UNSUPPORTED");
    }
}
