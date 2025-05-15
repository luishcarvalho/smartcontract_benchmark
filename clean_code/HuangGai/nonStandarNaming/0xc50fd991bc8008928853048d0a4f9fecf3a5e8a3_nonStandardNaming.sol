







pragma solidity ^0.5.9;


library LibBytesRichErrors {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }


    bytes4 internal constant invalid_byte_operation_error_selector281 =
        0x28006595;


    function INVALIDBYTEOPERATIONERROR28(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            invalid_byte_operation_error_selector281,
            errorCode,
            offset,
            required
        );
    }
}





pragma solidity ^0.5.9;


library LibRichErrors {


    bytes4 internal constant standard_error_selector533 =
        0x08c379a0;







    function STANDARDERROR227(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            standard_error_selector533,
            bytes(message)
        );
    }




    function RREVERT169(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}





pragma solidity ^0.5.9;




library LibBytes {

    using LibBytes for bytes;






    function RAWADDRESS88(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }




    function CONTENTADDRESS690(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }





    function MEMCOPY734(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {



            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {

            if (source == dest) {
                return;
            }
















            if (source > dest) {
                assembly {




                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)





                    let last := mload(sEnd)





                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }


                    mstore(dEnd, last)
                }
            } else {
                assembly {


                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)





                    let first := mload(source)









                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }


                    mstore(dest, first)
                }
            }
        }
    }






    function SLICE874(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {


        if (from > to) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }


        result = new bytes(to - from);
        MEMCOPY734(
            result.CONTENTADDRESS690(),
            b.CONTENTADDRESS690() + from,
            result.length
        );
        return result;
    }







    function SLICEDESTRUCTIVE563(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {


        if (from > to) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }


        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }




    function POPLASTBYTE283(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                b.length,
                0
            ));
        }


        result = b[b.length - 1];

        assembly {

            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }





    function EQUALS967(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {



        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }





    function READADDRESS671(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20
            ));
        }




        index += 20;


        assembly {



            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }





    function WRITEADDRESS597(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20
            ));
        }




        index += 20;


        assembly {








            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )



            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)


            mstore(add(b, index), xor(input, neighbors))
        }
    }





    function READBYTES32715(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }


        index += 32;


        assembly {
            result := mload(add(b, index))
        }
        return result;
    }





    function WRITEBYTES32973(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }


        index += 32;


        assembly {
            mstore(add(b, index), input)
        }
    }





    function READUINT25697(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(READBYTES32715(b, index));
        return result;
    }





    function WRITEUINT256889(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        WRITEBYTES32973(b, index, bytes32(input));
    }





    function READBYTES4250(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            LibRichErrors.RREVERT169(LibBytesRichErrors.INVALIDBYTEOPERATIONERROR28(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                b.length,
                index + 4
            ));
        }


        index += 32;


        assembly {
            result := mload(add(b, index))


            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }






    function WRITELENGTH909(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}





pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IGodsUnchained {




    function GETHEADSOFHYDRA13(uint256 tokenId)
        external
        view
        returns (uint8 heads);
}





pragma solidity ^0.5.9;

interface IPropertyValidator {





    function CHECKBROKERASSET468(
        uint256 tokenId,
        bytes calldata propertyData
    )
        external
        view;
}





pragma solidity ^0.5.9;


contract GodsUnchainedValidator is
    IPropertyValidator
{
    IGodsUnchained internal GODS_UNCHAINED;

    using LibBytes for bytes;

    constructor(address _godsUnchained)
        public
    {
        GODS_UNCHAINED = IGodsUnchained(_godsUnchained);
    }





    function CHECKBROKERASSET468(
        uint256 tokenId,
        bytes calldata propertyData
    )
        external
        view
    {
        (uint8 expectedHeads) = abi.decode(
            propertyData,
            (uint8)
        );


        (uint8 heads) = GODS_UNCHAINED.GETHEADSOFHYDRA13(tokenId);
        require(heads == expectedHeads, "GodsUnchainedValidator/HEADS_MISMATCH");
    }
}
