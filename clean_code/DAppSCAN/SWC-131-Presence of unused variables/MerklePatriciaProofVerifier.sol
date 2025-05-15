





pragma solidity 0.6.12;

import {RLPReader} from "hamdiallam/Solidity-RLP@2.0.4/contracts/RLPReader.sol";


library MerklePatriciaProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;













    function extractProofValue(
        bytes32 rootHash,
        bytes memory path,
        RLPReader.RLPItem[] memory stack
    ) internal pure returns (bytes memory value) {
        bytes memory mptKey = _decodeNibbles(path, 0);
        uint256 mptKeyOffset = 0;

        bytes32 nodeHashHash;

        bytes memory rlpNode;
        RLPReader.RLPItem[] memory node;

        RLPReader.RLPItem memory rlpValue;

        if (stack.length == 0) {

            require(rootHash == 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421);
            return new bytes(0);
        }


        for (uint256 i = 0; i < stack.length; i++) {






            if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
                revert();
            }


            if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
                revert();
            }


            node = stack[i].toList();

            if (node.length == 2) {


                bool isLeaf;
                bytes memory nodeKey;
                (isLeaf, nodeKey) = _merklePatriciaCompactDecode(node[0].toBytes());

                uint256 prefixLength = _sharedPrefixLength(mptKeyOffset, mptKey, nodeKey);
                mptKeyOffset += prefixLength;

                if (prefixLength < nodeKey.length) {












                    if (i < stack.length - 1) {

                        revert();
                    }

                    return new bytes(0);
                }

                if (isLeaf) {

                    if (i < stack.length - 1) {

                        revert();
                    }

                    if (mptKeyOffset < mptKey.length) {
                        return new bytes(0);
                    }

                    rlpValue = node[1];
                    return rlpValue.toBytes();
                } else {

                    if (i == stack.length - 1) {

                        revert();
                    }

                    if (!node[1].isList()) {


                        nodeHashHash = node[1].payloadKeccak256();
                    } else {


                        nodeHashHash = node[1].rlpBytesKeccak256();
                    }
                }
            } else if (node.length == 17) {


                if (mptKeyOffset != mptKey.length) {

                    uint8 nibble = uint8(mptKey[mptKeyOffset]);
                    mptKeyOffset += 1;
                    if (nibble >= 16) {

                        revert();
                    }

                    if (_isEmptyBytesequence(node[nibble])) {

                        if (i != stack.length - 1) {

                            revert();
                        }

                        return new bytes(0);
                    } else if (!node[nibble].isList()) {
                        nodeHashHash = node[nibble].payloadKeccak256();
                    } else {
                        nodeHashHash = node[nibble].rlpBytesKeccak256();
                    }
                } else {



                    if (i != stack.length - 1) {

                        revert();
                    }

                    return node[16].toBytes();
                }
            }
        }
    }











    function _mptHashHash(RLPReader.RLPItem memory item) private pure returns (bytes32) {
        if (item.len < 32) {
            return item.rlpBytesKeccak256();
        } else {
            return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
        }
    }

    function _isEmptyBytesequence(RLPReader.RLPItem memory item) private pure returns (bool) {
        if (item.len != 1) {
            return false;
        }
        uint8 b;
        uint256 memPtr = item.memPtr;
        assembly {
            b := byte(0, mload(memPtr))
        }





























































