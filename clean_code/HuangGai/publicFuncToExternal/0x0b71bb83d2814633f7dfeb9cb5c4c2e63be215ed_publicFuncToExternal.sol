





pragma solidity ^0.5.0;








library RLP {


    uint constant DATA_SHORT_START = 0x80;
    uint constant DATA_LONG_START = 0xB8;
    uint constant LIST_SHORT_START = 0xC0;
    uint constant LIST_LONG_START = 0xF8;

    uint constant DATA_LONG_OFFSET = 0xB7;
    uint constant LIST_LONG_OFFSET = 0xF7;


    struct RLPItem {
        uint _unsafe_memPtr;
        uint _unsafe_length;
    }

    struct Iterator {
        RLPItem _unsafe_item;
        uint _unsafe_nextPtr;
    }





    function next(
        Iterator memory self
    )
        internal
        pure
        returns (RLPItem memory subItem_)
    {
        require(hasNext(self));
        uint ptr = self._unsafe_nextPtr;
        uint itemLength = _itemLength(ptr);
        subItem_._unsafe_memPtr = ptr;
        subItem_._unsafe_length = itemLength;
        self._unsafe_nextPtr = ptr + itemLength;
    }

    function next(
        Iterator memory self,
        bool strict
    )
        internal
        pure
        returns (RLPItem memory subItem_)
    {
        subItem_ = next(self);
        require(!(strict && !_validate(subItem_)));
    }

    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self._unsafe_item;
        return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
    }










    function toRLPItem(
        bytes memory self
    )
        internal
        pure
        returns (RLPItem memory)
    {
        uint len = self.length;
        if (len == 0) {
            return RLPItem(0, 0);
        }
        uint memPtr;


        assembly {
            memPtr := add(self, 0x20)
        }

        return RLPItem(memPtr, len);
    }









    function toRLPItem(
        bytes memory self,
        bool strict
    )
        internal
        pure
        returns (RLPItem memory)
    {
        RLPItem memory item = toRLPItem(self);
        if(strict) {
            uint len = self.length;
            require(_payloadOffset(item) <= len);
            require(_itemLength(item._unsafe_memPtr) == len);
            require(_validate(item));
        }
        return item;
    }








    function isNull(RLPItem memory self) internal pure returns (bool ret) {
        return self._unsafe_length == 0;
    }








    function isList(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;


        assembly {
            ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
        }
    }








    function isData(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;


        assembly {
            ret := lt(byte(0, mload(memPtr)), 0xC0)
        }
    }








    function isEmpty(RLPItem memory self) internal pure returns (bool ret) {
        if(isNull(self)) {
            return false;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;


        assembly {
            b0 := byte(0, mload(memPtr))
        }
        return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
    }








    function items(RLPItem memory self) internal pure returns (uint) {
        if (!isList(self)) {
            return 0;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;


        assembly {
            b0 := byte(0, mload(memPtr))
        }
        uint pos = memPtr + _payloadOffset(self);
        uint last = memPtr + self._unsafe_length - 1;
        uint itms;
        while(pos <= last) {
            pos += _itemLength(pos);
            itms++;
        }
        return itms;
    }








    function iterator(
        RLPItem memory self
    )
        internal
        pure
        returns (Iterator memory it_)
    {
        require (isList(self));
        uint ptr = self._unsafe_memPtr + _payloadOffset(self);
        it_._unsafe_item = self;
        it_._unsafe_nextPtr = ptr;
    }








    function toBytes(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes memory bts_)
    {
        uint len = self._unsafe_length;
        if (len == 0) {
            return bts_;
        }
        bts_ = new bytes(len);
        _copyToBytes(self._unsafe_memPtr, bts_, len);
    }








    function toData(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes memory bts_)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bts_ = new bytes(len);
        _copyToBytes(rStartPos, bts_, len);
    }









    function toList(
        RLPItem memory self
    )
        internal
        pure
        returns (RLPItem[] memory list_)
    {
        require(isList(self));
        uint numItems = items(self);
        list_ = new RLPItem[](numItems);
        Iterator memory it = iterator(self);
        uint idx = 0;
        while(hasNext(it)) {
            list_[idx] = next(it);
            idx++;
        }
    }









    function toAscii(
        RLPItem memory self
    )
        internal
        pure
        returns (string memory str_)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bytes memory bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
        str_ = string(bts);
    }









    function toUint(RLPItem memory self) internal pure returns (uint data_) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        if (len > 32 || len == 0) {
            revert();
        }


        assembly {
            data_ := div(mload(rStartPos), exp(256, sub(32, len)))
        }
    }









    function toBool(RLPItem memory self) internal pure returns (bool data) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require(len == 1);
        uint temp;


        assembly {
            temp := byte(0, mload(rStartPos))
        }
        require (temp <= 1);

        return temp == 1 ? true : false;
    }









    function toByte(RLPItem memory self) internal pure returns (byte data) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require(len == 1);
        uint temp;


        assembly {
            temp := byte(0, mload(rStartPos))
        }

        return byte(uint8(temp));
    }









    function toInt(RLPItem memory self) internal pure returns (int data) {
        return int(toUint(self));
    }









    function toBytes32(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes32 data)
    {
        return bytes32(toUint(self));
    }









    function toAddress(
        RLPItem memory self
    )
        internal
        pure
        returns (address data)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require (len == 20);


        assembly {
            data := div(mload(rStartPos), exp(256, 12))
        }
    }









    function _payloadOffset(RLPItem memory self) private pure returns (uint) {
        if(self._unsafe_length == 0)
            return 0;
        uint b0;
        uint memPtr = self._unsafe_memPtr;


        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if(b0 < DATA_SHORT_START)
            return 0;
        if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
            return 1;
        if(b0 < LIST_SHORT_START)
            return b0 - DATA_LONG_OFFSET + 1;
        return b0 - LIST_LONG_OFFSET + 1;
    }









    function _itemLength(uint memPtr) private pure returns (uint len) {
        uint b0;


        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START) {
            len = 1;
        } else if (b0 < DATA_LONG_START) {
            len = b0 - DATA_SHORT_START + 1;
        } else if (b0 < LIST_SHORT_START) {

            assembly {
                let bLen := sub(b0, 0xB7)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen)))
                len := add(1, add(bLen, dLen))
            }
        } else if (b0 < LIST_LONG_START) {
            len = b0 - LIST_SHORT_START + 1;
        } else {

            assembly {
                let bLen := sub(b0, 0xF7)
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen)))
                len := add(1, add(bLen, dLen))
            }
        }
    }









    function _decode(
        RLPItem memory self
    )
        private
        pure
        returns (uint memPtr_, uint len_)
    {
        require(isData(self));
        uint b0;
        uint start = self._unsafe_memPtr;


        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr_ = start;
            len_ = 1;

            return (memPtr_, len_);
        }
        if (b0 < DATA_LONG_START) {
            len_ = self._unsafe_length - 1;
            memPtr_ = start + 1;
        } else {
            uint bLen;


            assembly {
                bLen := sub(b0, 0xB7)
            }
            len_ = self._unsafe_length - 1 - bLen;
            memPtr_ = start + bLen + 1;
        }
    }









    function _copyToBytes(
        uint btsPtr,
        bytes memory tgt,
        uint btsLen
    )
        private
        pure
    {



        assembly {
                let i := 0
                let stopOffset := add(btsLen, 31)
                let rOffset := btsPtr
                let wOffset := add(tgt, 32)
                for {} lt(i, stopOffset) { i := add(i, 32) }
                {
                    mstore(add(wOffset, i), mload(add(rOffset, i)))
                }
        }
    }






    function _validate(RLPItem memory self) private pure returns (bool ret) {

        uint b0;
        uint b1;
        uint memPtr = self._unsafe_memPtr;


        assembly {
            b0 := byte(0, mload(memPtr))
            b1 := byte(1, mload(memPtr))
        }
        if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
            return false;
        return true;
    }
}



pragma solidity ^0.5.0;








library MerklePatriciaProof {








    function verify(
        bytes32 value,
        bytes calldata encodedPath,
        bytes calldata rlpParentNodes,
        bytes32 root
    )
        external
        pure
        returns (bool)
    {
        RLP.RLPItem memory item = RLP.toRLPItem(rlpParentNodes);
        RLP.RLPItem[] memory parentNodes = RLP.toList(item);

        bytes memory currentNode;
        RLP.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint pathPtr = 0;

        bytes memory path = _getNibbleArray2(encodedPath);
        if(path.length == 0) {return false;}

        for (uint i=0; i<parentNodes.length; i++) {
            if(pathPtr > path.length) {return false;}

            currentNode = RLP.toBytes(parentNodes[i]);
            if(nodeKey != keccak256(abi.encodePacked(currentNode))) {return false;}
            currentNodeList = RLP.toList(parentNodes[i]);

            if(currentNodeList.length == 17) {
                if(pathPtr == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toBytes(currentNodeList[16]))) == value) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if(nextPathNibble > 16) {return false;}
                nodeKey = RLP.toBytes32(currentNodeList[nextPathNibble]);
                pathPtr += 1;
            } else if(currentNodeList.length == 2) {


                uint traverseLength = _nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr);

                if(pathPtr + traverseLength == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toData(currentNodeList[1]))) == value) {
                        return true;
                    } else {
                        return false;
                    }
                } else if (traverseLength == 0) {
                    return false;
                } else {
                    pathPtr += traverseLength;
                    nodeKey = RLP.toBytes32(currentNodeList[1]);
                }

            } else {
                return false;
            }
        }
    }

    function verifyDebug(
        bytes32 value,
        bytes memory not_encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    )
        public
        pure
        returns (bool res_, uint loc_, bytes memory path_debug_)
    {
        RLP.RLPItem memory item = RLP.toRLPItem(rlpParentNodes);
        RLP.RLPItem[] memory parentNodes = RLP.toList(item);

        bytes memory currentNode;
        RLP.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint pathPtr = 0;

        bytes memory path = _getNibbleArray2(not_encodedPath);
        path_debug_ = path;
        if(path.length == 0) {
            loc_ = 0;
            res_ = false;
            return (res_, loc_, path_debug_);
        }

        for (uint i=0; i<parentNodes.length; i++) {
            if(pathPtr > path.length) {
                loc_ = 1;
                res_ = false;
                return (res_, loc_, path_debug_);
            }

            currentNode = RLP.toBytes(parentNodes[i]);
            if(nodeKey != keccak256(abi.encodePacked(currentNode))) {
                res_ = false;
                loc_ = 100 + i;
                return (res_, loc_, path_debug_);
            }
            currentNodeList = RLP.toList(parentNodes[i]);

            loc_ = currentNodeList.length;

            if(currentNodeList.length == 17) {
                if(pathPtr == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toBytes(currentNodeList[16]))) == value) {
                        res_ = true;
                        return (res_, loc_, path_debug_);
                    } else {
                        loc_ = 3;
                        return (res_, loc_, path_debug_);
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if(nextPathNibble > 16) {
                    loc_ = 4;
                    return (res_, loc_, path_debug_);
                }
                nodeKey = RLP.toBytes32(currentNodeList[nextPathNibble]);
                pathPtr += 1;
            } else if(currentNodeList.length == 2) {
                pathPtr += _nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr);

                if(pathPtr == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toData(currentNodeList[1]))) == value) {
                        res_ = true;
                        return (res_, loc_, path_debug_);
                    } else {
                        loc_ = 5;
                        return (res_, loc_, path_debug_);
                    }
                }

                if(_nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr) == 0) {
                    loc_ = 6;
                    res_ = (keccak256(abi.encodePacked()) == value);
                    return (res_, loc_, path_debug_);
                }

                nodeKey = RLP.toBytes32(currentNodeList[1]);
            } else {
                loc_ = 7;
                return (res_, loc_, path_debug_);
            }
        }

        loc_ = 8;
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint pathPtr
    )
        private
        pure
        returns (uint len_)
    {


        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);



        for(uint i=pathPtr; i<pathPtr+partialPath.length; i++) {
            byte pathNibble = path[i];
            slicedPath[i-pathPtr] = pathNibble;
        }

        if(keccak256(abi.encodePacked(partialPath)) == keccak256(abi.encodePacked(slicedPath))) {
            len_ = partialPath.length;
        } else {
            len_ = 0;
        }
    }


    function _getNibbleArray(
        bytes memory b
    )
        private
        pure
        returns (bytes memory nibbles_)
    {
        if(b.length>0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0,b));
            if(hpNibble == 1 || hpNibble == 3) {
                nibbles_ = new bytes(b.length*2-1);
                byte oddNibble = _getNthNibbleOfBytes(1,b);
                nibbles_[0] = oddNibble;
                offset = 1;
            } else {
                nibbles_ = new bytes(b.length*2-2);
                offset = 0;
            }

            for(uint i=offset; i<nibbles_.length; i++) {
                nibbles_[i] = _getNthNibbleOfBytes(i-offset+2,b);
            }
        }
    }


    function _getNibbleArray2(
        bytes memory b
    )
        private
        pure
        returns (bytes memory nibbles_)
    {
        nibbles_ = new bytes(b.length*2);
        for (uint i = 0; i < nibbles_.length; i++) {
            nibbles_[i] = _getNthNibbleOfBytes(i, b);
        }
    }

    function _getNthNibbleOfBytes(
        uint n,
        bytes memory str
    )
        private
        pure returns (byte)
    {
        return byte(n%2==0 ? uint8(str[n/2])/0x10 : uint8(str[n/2])%0x10);
    }
}



pragma solidity ^0.5.0;

































library SafeMath {











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {





        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(
            c / a == b,
            "Overflow when multiplying."
        );

        return c;
    }










    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(
            b > 0,
            "Cannot do attempted division by less than or equal to zero."
        );
        uint256 c = a / b;




        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(
            b <= a,
            "Underflow when subtracting."
        );
        uint256 c = a - b;

        return c;
    }









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(
            c >= a,
            "Overflow when adding."
        );

        return c;
    }










    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(
            b != 0,
            "Cannot do attempted division by zero (in `mod()`)."
        );

        return a % b;
    }
}



pragma solidity ^0.5.0;

library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure returns (bytes memory bytes_)
    {

        assembly {


            bytes_ := mload(0x40)



            let length := mload(_preBytes)
            mstore(bytes_, length)




            let mc := add(bytes_, 0x20)


            let end := add(mc, length)

            for {


                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {

                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {


                mstore(mc, mload(cc))
            }




            length := mload(_postBytes)
            mstore(bytes_, add(length, mload(bytes_)))



            mc := end


            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }






            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)
            ))
        }
    }


    function leftPad(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes memory padded_)
    {
        bytes memory padding = new bytes(32 - _bytes.length);
        padded_ = concat(padding, _bytes);
    }








    function bytes32ToBytes(bytes32 _inBytes32)
        internal
        pure
        returns (bytes memory bytes_)
    {
        bytes_ = new bytes(32);


        assembly {
            mstore(add(32, bytes_), _inBytes32)
        }
    }

}



pragma solidity ^0.5.0;
























library MessageBus {



    using SafeMath for uint256;





    enum MessageStatus {
        Undeclared,
        Declared,
        Progressed,
        DeclaredRevocation,
        Revoked
    }


    enum MessageBoxType {
        Outbox,
        Inbox
    }





    struct MessageBox {


        mapping(bytes32 => MessageStatus) outbox;


        mapping(bytes32 => MessageStatus) inbox;
    }


    struct Message {


        bytes32 intentHash;


        uint256 nonce;


        uint256 gasPrice;


        uint256 gasLimit;


        address sender;


        bytes32 hashLock;





        uint256 gasConsumed;
    }




    bytes32 public constant MESSAGE_TYPEHASH = keccak256(
        abi.encode(
            "Message(bytes32 intentHash,uint256 nonce,uint256 gasPrice,uint256 gasLimit,address sender,bytes32 hashLock)"
        )
    );





    uint8 public constant OUTBOX_OFFSET = 0;





    uint8 public constant INBOX_OFFSET = 1;













    function declareMessage(
        MessageBox storage _messageBox,
        Message storage _message
    )
        public
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] == MessageStatus.Undeclared,
            "Message on source must be Undeclared."
        );


        _messageBox.outbox[messageHash_] = MessageStatus.Declared;
    }
















    function confirmMessage(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Undeclared,
            "Message on target must be Undeclared."
        );


        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                OUTBOX_OFFSET,
                messageHash_
            )
        );


        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(MessageStatus.Declared)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );


        _messageBox.inbox[messageHash_] = MessageStatus.Declared;
    }











    function progressOutbox(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes32 _unlockSecret
    )
        public
        returns (bytes32 messageHash_)
    {
        require(
            _message.hashLock == keccak256(abi.encode(_unlockSecret)),
            "Invalid unlock secret."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] == MessageStatus.Declared,
            "Message on source must be Declared."
        );


        _messageBox.outbox[messageHash_] = MessageStatus.Progressed;
    }





















    function progressOutboxWithProof(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot,
        MessageStatus _messageStatus
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);

        if(_messageBox.outbox[messageHash_] == MessageStatus.Declared) {





            require(
                _messageStatus == MessageStatus.Declared ||
                _messageStatus == MessageStatus.Progressed,
                "Message on target must be Declared or Progressed."
            );

        } else if (_messageBox.outbox[messageHash_] == MessageStatus.DeclaredRevocation) {





            require(
                _messageStatus == MessageStatus.Progressed,
                "Message on target must be Progressed."
            );

        } else {
            revert("Status of message on source must be Declared or DeclareRevocation.");
        }

        bytes memory storagePath = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                INBOX_OFFSET,
                messageHash_
            )
        );


        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(_messageStatus)),
                storagePath,
                _rlpParentNodes,
                _storageRoot),
            "Merkle proof verification failed."
        );

        _messageBox.outbox[messageHash_] = MessageStatus.Progressed;
    }












    function progressInbox(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes32 _unlockSecret
    )
        public
        returns (bytes32 messageHash_)
    {
        require(
            _message.hashLock == keccak256(abi.encode(_unlockSecret)),
            "Invalid unlock secret."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Declared,
            "Message on target status must be Declared."
        );

        _messageBox.inbox[messageHash_] = MessageStatus.Progressed;
    }





















    function progressInboxWithProof(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot,
        MessageStatus _messageStatus
    )
        external
        returns (bytes32 messageHash_)
    {

        require(
            _messageStatus == MessageStatus.Declared ||
            _messageStatus == MessageStatus.Progressed,
            "Message on source must be Declared or Progressed."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Declared,
            "Message on target must be Declared."
        );


        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                OUTBOX_OFFSET,
                messageHash_
            )
        );


        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(_messageStatus)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );

        _messageBox.inbox[messageHash_] = MessageStatus.Progressed;
    }













    function declareRevocationMessage(
        MessageBox storage _messageBox,
        Message storage _message
    )
        public
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] == MessageStatus.Declared,
            "Message on source must be Declared."
        );

        _messageBox.outbox[messageHash_] = MessageStatus.DeclaredRevocation;
    }


















    function confirmRevocation(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Declared,
            "Message on target must be Declared."
        );


        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                OUTBOX_OFFSET,
                messageHash_
            )
        );


        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(MessageStatus.DeclaredRevocation)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );

        _messageBox.inbox[messageHash_] = MessageStatus.Revoked;
    }





















    function progressOutboxRevocation(
        MessageBox storage _messageBox,
        Message storage _message,
        uint8 _messageBoxOffset,
        bytes calldata _rlpParentNodes,
        bytes32 _storageRoot,
        MessageStatus _messageStatus
    )
        external
        returns (bytes32 messageHash_)
    {
        require(
            _messageStatus == MessageStatus.Revoked,
            "Message on target status must be Revoked."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] ==
            MessageStatus.DeclaredRevocation,
            "Message status on source must be DeclaredRevocation."
        );


        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                INBOX_OFFSET,
                messageHash_
            )
        );


        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(_messageStatus)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );

        _messageBox.outbox[messageHash_] = MessageStatus.Revoked;
    }






    function messageTypehash() public pure returns(bytes32 messageTypehash_) {
        messageTypehash_ = MESSAGE_TYPEHASH;
    }













    function messageDigest(
        bytes32 _intentHash,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _sender,
        bytes32 _hashLock
    )
        public
        pure
        returns (bytes32 messageHash_)
    {
        messageHash_ = keccak256(
            abi.encode(
                MESSAGE_TYPEHASH,
                _intentHash,
                _nonce,
                _gasPrice,
                _gasLimit,
                _sender,
                _hashLock
            )
        );
    }











    function messageDigest(
        Message storage _message
    )
        private
        view
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(
            _message.intentHash,
            _message.nonce,
            _message.gasPrice,
            _message.gasLimit,
            _message.sender,
            _message.hashLock
        );
    }










    function storageVariablePathForStruct(
        uint8 _structPosition,
        uint8 _offset,
        bytes32 _key
    )
        private
        pure
        returns(bytes32 storagePath_)
    {
        if(_offset > 0){
            _structPosition = _structPosition + _offset;
        }

        bytes memory indexBytes = BytesLib.leftPad(
            BytesLib.bytes32ToBytes(bytes32(uint256(_structPosition)))
        );

        bytes memory keyBytes = BytesLib.leftPad(BytesLib.bytes32ToBytes(_key));
        bytes memory path = BytesLib.concat(keyBytes, indexBytes);

        storagePath_ = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(path)))
        );
    }
}
