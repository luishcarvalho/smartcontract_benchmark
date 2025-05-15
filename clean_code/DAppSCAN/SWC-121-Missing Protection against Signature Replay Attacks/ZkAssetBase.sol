pragma solidity >=0.5.0 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../../ACE/ACE.sol";
import "../../interfaces/IAZTEC.sol";
import "../../interfaces/IZkAsset.sol";
import "../../libs/LibEIP712.sol";
import "../../libs/MetaDataUtils.sol";
import "../../libs/ProofUtils.sol";








contract ZkAssetBase is IZkAsset, IAZTEC, LibEIP712 {
    using NoteUtils for bytes;
    using SafeMath for uint256;


    string constant internal EIP712_DOMAIN_NAME = "ZK_ASSET";

    bytes32 constant internal NOTE_SIGNATURE_TYPEHASH = keccak256(abi.encodePacked(
        "NoteSignature(",
            "bytes32 noteHash,",
            "address spender,",
            "bool status",
        ")"
    ));

    bytes32 constant internal JOIN_SPLIT_SIGNATURE_TYPE_HASH = keccak256(abi.encodePacked(
        "JoinSplitSignature(",
            "uint24 proof,",
            "bytes32 noteHash,",
            "uint256 challenge,",
            "address sender",
        ")"
    ));

    ACE public ace;
    IERC20 public linkedToken;

    mapping(bytes32 => mapping(address => bool)) public confidentialApproved;
    mapping(address => bytes32) noteAccess;

    constructor(
        address _aceAddress,
        address _linkedTokenAddress,
        uint256 _scalingFactor,
        bool _canAdjustSupply
    ) public {
        bool canConvert = (_linkedTokenAddress == address(0x0)) ? false : true;
        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            bytes32(uint256(address(this)))
        ));
        ace = ACE(_aceAddress);
        linkedToken = IERC20(_linkedTokenAddress);
        ace.createNoteRegistry(
            _linkedTokenAddress,
            _scalingFactor,
            _canAdjustSupply,
            canConvert
        );
        emit CreateZkAsset(
            _aceAddress,
            _linkedTokenAddress,
            _scalingFactor,
            _canAdjustSupply,
            canConvert
        );
    }












    function confidentialTransfer(bytes memory _proofData, bytes memory _signatures) public {
        bytes memory proofOutputs = ace.validateProof(JOIN_SPLIT_PROOF, msg.sender, _proofData);
        confidentialTransferInternal(proofOutputs, _signatures, _proofData);
    }














    function confidentialApprove(
        bytes32 _noteHash,
        address _spender,
        bool _status,
        bytes memory _signature
    ) public {
        ( uint8 status, , , ) = ace.getNote(address(this), _noteHash);
        require(status == 1, "only unspent notes can be approved");
        bytes32 _hashStruct = keccak256(abi.encode(
                NOTE_SIGNATURE_TYPEHASH,
                _noteHash,
                _spender,
                status
        ));

        validateSignature(_hashStruct, _noteHash, _signature);
        confidentialApproved[_noteHash][_spender] = _status;
    }








    function validateSignature(
        bytes32 _hashStruct,
        bytes32 _noteHash,
        bytes memory _signature
    ) internal view {
        (, , , address noteOwner ) = ace.getNote(address(this), _noteHash);

        address signer;
        if (_signature.length != 0) {

            bytes32 msgHash = hashEIP712Message(_hashStruct);
            signer = recoverSignature(
                msgHash,
                _signature
            );
        } else {
            signer = msg.sender;
        }
        require(signer == noteOwner, "the note owner did not sign this message");
    }







    function extractSignature(bytes memory _signatures, uint _i) internal pure returns (
        bytes memory _signature
    ){
        bytes32 v;
        bytes32 r;
        bytes32 s;
        assembly {









            v := mload(add(add(_signatures, 0x20), mul(_i, 0x60)))
            r := mload(add(add(_signatures, 0x40), mul(_i, 0x60)))
            s := mload(add(add(_signatures, 0x60), mul(_i, 0x60)))
        }
        _signature = abi.encode(v, r, s);
    }












    function confidentialTransferFrom(uint24 _proof, bytes memory _proofOutput) public {
        (bytes memory inputNotes,
        bytes memory outputNotes,
        address publicOwner,
        int256 publicValue) = _proofOutput.extractProofOutput();

        uint256 length = inputNotes.getLength();
        for (uint i = 0; i < length; i += 1) {
            (, bytes32 noteHash, ) = inputNotes.get(i).extractNote();
            require(
                confidentialApproved[noteHash][msg.sender] == true,
                "sender does not have approval to spend input note"
            );
        }

        ace.updateNoteRegistry(_proof, _proofOutput, msg.sender);

        logInputNotes(inputNotes);
        logOutputNotes(outputNotes);

        if (publicValue < 0) {
            emit ConvertTokens(publicOwner, uint256(-publicValue));
        }
        if (publicValue > 0) {
            emit RedeemTokens(publicOwner, uint256(publicValue));
        }
    }
















    function confidentialTransferInternal(
        bytes memory proofOutputs,
        bytes memory _signatures,
        bytes memory _proofData
    ) internal {
        bytes32 _challenge;
        assembly {
            _challenge := mload(add(_proofData, 0x40))
        }

        for (uint i = 0; i < proofOutputs.getLength(); i += 1) {
            bytes memory proofOutput = proofOutputs.get(i);
            ace.updateNoteRegistry(JOIN_SPLIT_PROOF, proofOutput, address(this));

            (bytes memory inputNotes,
            bytes memory outputNotes,
            address publicOwner,
            int256 publicValue) = proofOutput.extractProofOutput();


            if (inputNotes.getLength() > uint(0)) {

                for (uint j = 0; j < inputNotes.getLength(); j += 1) {
                    bytes memory _signature = extractSignature(_signatures, j);

                    (, bytes32 noteHash, ) = inputNotes.get(j).extractNote();

                    bytes32 hashStruct = keccak256(abi.encode(
                        JOIN_SPLIT_SIGNATURE_TYPE_HASH,
                        JOIN_SPLIT_PROOF,
                        noteHash,
                        _challenge,
                        msg.sender
                    ));

                    validateSignature(hashStruct, noteHash, _signature);
                }
            }

            logInputNotes(inputNotes);
            logOutputNotes(outputNotes);
            if (publicValue < 0) {
                emit ConvertTokens(publicOwner, uint256(-publicValue));
            }
            if (publicValue > 0) {
                emit RedeemTokens(publicOwner, uint256(publicValue));
            }

        }
    }






    function updateNoteMetaData(bytes32 noteHash, bytes calldata metaData) external {

        ( uint8 status, , , address noteOwner ) = ace.getNote(address(this), noteHash);
        require(status == 1, "only unspent notes can be approved");

        require(
            noteAccess[msg.sender] == noteHash || noteOwner == msg.sender,
            'caller does not have permission to update metaData'
        );

        address addressToApprove = MetaDataUtils.extractAddresses(metaData);
        noteAccess[addressToApprove] = noteHash;

        emit ApprovedAddress(addressToApprove, noteHash);
        emit UpdateNoteMetaData(noteOwner, noteHash, metaData);
    }







    function logInputNotes(bytes memory inputNotes) internal {
        for (uint i = 0; i < inputNotes.getLength(); i += 1) {
            (address noteOwner, bytes32 noteHash, bytes memory metadata) = inputNotes.get(i).extractNote();
            emit DestroyNote(noteOwner, noteHash, metadata);
        }
    }







    function logOutputNotes(bytes memory outputNotes) internal {
        for (uint i = 0; i < outputNotes.getLength(); i += 1) {
            (address noteOwner, bytes32 noteHash, bytes memory metadata) = outputNotes.get(i).extractNote();
            emit CreateNote(noteOwner, noteHash, metadata);
        }
    }
}
