



pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;





































contract IERC20Token {


    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );





    function transfer(address _to, uint256 _value)
        external
        returns (bool);






    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);





    function approve(address _spender, uint256 _value)
        external
        returns (bool);



    function totalSupply()
        external
        view
        returns (uint256);



    function balanceOf(address _owner)
        external
        view
        returns (uint256);




    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
}





































library LibRichErrors {


    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;







    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }




    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}





































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


    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;


    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

library LibBytes {

    using LibBytes for bytes;






    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }




    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }





    function memCopy(
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






    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {


        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }


        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }







    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {


        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
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




    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
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





    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {



        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }





    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
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





    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
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





    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
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





    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
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





    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }





    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }





    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
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






    function writeLength(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}

library LibERC20Token {
    bytes constant private DECIMALS_CALL_DATA = hex"313ce567";







    function approve(
        address token,
        address spender,
        uint256 allowance
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).approve.selector,
            spender,
            allowance
        );
        _callWithOptionalBooleanResult(token, callData);
    }








    function approveIfBelow(
        address token,
        address spender,
        uint256 amount
    )
        internal
    {
        if (IERC20Token(token).allowance(address(this), spender) < amount) {
            approve(token, spender, uint256(-1));
        }
    }







    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).transfer.selector,
            to,
            amount
        );
        _callWithOptionalBooleanResult(token, callData);
    }








    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).transferFrom.selector,
            from,
            to,
            amount
        );
        _callWithOptionalBooleanResult(token, callData);
    }





    function decimals(address token)
        internal
        view
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = 18;
        (bool didSucceed, bytes memory resultData) = token.staticcall(DECIMALS_CALL_DATA);
        if (didSucceed && resultData.length == 32) {
            tokenDecimals = uint8(LibBytes.readUint256(resultData, 0));
        }
    }







    function allowance(address token, address owner, address spender)
        internal
        view
        returns (uint256 allowance_)
    {
        (bool didSucceed, bytes memory resultData) = token.staticcall(
            abi.encodeWithSelector(
                IERC20Token(0).allowance.selector,
                owner,
                spender
            )
        );
        if (didSucceed && resultData.length == 32) {
            allowance_ = LibBytes.readUint256(resultData, 0);
        }
    }






    function balanceOf(address token, address owner)
        internal
        view
        returns (uint256 balance)
    {
        (bool didSucceed, bytes memory resultData) = token.staticcall(
            abi.encodeWithSelector(
                IERC20Token(0).balanceOf.selector,
                owner
            )
        );
        if (didSucceed && resultData.length == 32) {
            balance = LibBytes.readUint256(resultData, 0);
        }
    }






    function _callWithOptionalBooleanResult(
        address target,
        bytes memory callData
    )
        private
    {
        (bool didSucceed, bytes memory resultData) = target.call(callData);
        if (didSucceed) {
            if (address(this).balance == 0) {
                return;
            }
            if (resultData.length == 32) {
                uint256 result = LibBytes.readUint256(resultData, 0);
                if (result == 1) {
                    return;
                }
            }
        }
        LibRichErrors.rrevert(resultData);
    }
}



















contract IWallet {

    bytes4 internal constant LEGACY_WALLET_MAGIC_VALUE = 0xb0671381;





    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    )
        external
        view
        returns (bytes4 magicValue);
}



















contract DeploymentConstants {





    address constant private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address constant private KYBER_NETWORK_PROXY_ADDRESS = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;

    address constant private KYBER_HINT_HANDLER_ADDRESS = 0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C;

    address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;

    address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;

    address constant private ETH2DAI_ADDRESS = 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;

    address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0x8ED95d1746bf1E4dAb58d8ED4724f1Ef95B20Db0;

    address constant private DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address constant private CHAI_ADDRESS = 0x06AF07097C9Eeb7fD685c692751D5C66dB49c215;

    address constant private DEV_UTILS_ADDRESS = 0x74134CF88b21383713E096a5ecF59e297dc7f547;

    address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address constant private DYDX_ADDRESS = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    address constant private GST_ADDRESS = 0x0000000000b3F879cb30FE243b4Dfee438691c04;

    address constant private GST_COLLECTOR_ADDRESS = 0x000000D3b08566BE75A6DB803C03C85C0c1c5B96;

    address constant private MUSD_ADDRESS = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;

    address constant private MOONISWAP_REGISTRY = 0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303;

    address constant private SHELL_CONTRACT = 0x2E703D658f8dd21709a7B458967aB4081F8D3d05;

    address constant private DODO_REGISTRY = 0x3A97247DF274a17C59A3bd12735ea3FcDFb49950;

    address constant private DODO_HELPER = 0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb;





























































































    function _getKyberNetworkProxyAddress()
        internal
        view
        returns (address kyberAddress)
    {
        return KYBER_NETWORK_PROXY_ADDRESS;
    }



    function _getKyberHintHandlerAddress()
        internal
        view
        returns (address hintHandlerAddress)
    {
        return KYBER_HINT_HANDLER_ADDRESS;
    }



    function _getWethAddress()
        internal
        view
        returns (address wethAddress)
    {
        return WETH_ADDRESS;
    }



    function _getUniswapExchangeFactoryAddress()
        internal
        view
        returns (address uniswapAddress)
    {
        return UNISWAP_EXCHANGE_FACTORY_ADDRESS;
    }



    function _getUniswapV2Router01Address()
        internal
        view
        returns (address uniswapRouterAddress)
    {
        return UNISWAP_V2_ROUTER_01_ADDRESS;
    }



    function _getEth2DaiAddress()
        internal
        view
        returns (address eth2daiAddress)
    {
        return ETH2DAI_ADDRESS;
    }



    function _getERC20BridgeProxyAddress()
        internal
        view
        returns (address erc20BridgeProxyAddress)
    {
        return ERC20_BRIDGE_PROXY_ADDRESS;
    }



    function _getDaiAddress()
        internal
        view
        returns (address daiAddress)
    {
        return DAI_ADDRESS;
    }



    function _getChaiAddress()
        internal
        view
        returns (address chaiAddress)
    {
        return CHAI_ADDRESS;
    }



    function _getDevUtilsAddress()
        internal
        view
        returns (address devUtils)
    {
        return DEV_UTILS_ADDRESS;
    }



    function _getDydxAddress()
        internal
        view
        returns (address dydxAddress)
    {
        return DYDX_ADDRESS;
    }



    function _getGstAddress()
        internal
        view
        returns (address gst)
    {
        return GST_ADDRESS;
    }



    function _getGstCollectorAddress()
        internal
        view
        returns (address collector)
    {
        return GST_COLLECTOR_ADDRESS;
    }



    function _getMUsdAddress()
        internal
        view
        returns (address musd)
    {
        return MUSD_ADDRESS;
    }



    function _getMooniswapAddress()
        internal
        view
        returns (address)
    {
        return MOONISWAP_REGISTRY;
    }



    function _getShellAddress()
        internal
        view
        returns (address)
    {
        return SHELL_CONTRACT;
    }



    function _getDODORegistryAddress()
        internal
        view
        returns (address)
    {
        return DODO_REGISTRY;
    }



    function _getDODOHelperAddress()
        internal
        view
        returns (address)
    {
        return DODO_HELPER;
    }
}



















contract IERC20Bridge {


    bytes4 constant internal BRIDGE_SUCCESS = 0xdc1600f3;








    event ERC20BridgeTransfer(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        address from,
        address to
    );








    function bridgeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success);
}




















interface ICurve {







    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount,
        uint256 minBuyAmount
    )
        external;





    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount
    )
        external
        returns (uint256 dy);





    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 buyAmount
    )
        external
        returns (uint256 dx);



    function underlying_coins(
        int128 i
    )
        external
        returns (address tokenAddress);
}



contract SnowSwapBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct SnowSwapBridgeData {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        address fromTokenAddress;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }











    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {

        SnowSwapBridgeData memory data = abi.decode(bridgeData, (SnowSwapBridgeData));

        require(toTokenAddress != data.fromTokenAddress, "SnowSwapBridge/INVALID_PAIR");
        uint256 fromTokenBalance = IERC20Token(data.fromTokenAddress).balanceOf(address(this));

        LibERC20Token.approveIfBelow(data.fromTokenAddress, data.curveAddress, fromTokenBalance);


        {
            (bool didSucceed, bytes memory resultData) =
                data.curveAddress.call(abi.encodeWithSelector(
                    data.exchangeFunctionSelector,
                    data.fromCoinIdx,
                    data.toCoinIdx,

                    fromTokenBalance,

                    amount
                ));
            if (!didSucceed) {
                assembly { revert(add(resultData, 32), mload(resultData)) }
            }
        }

        uint256 toTokenBalance = IERC20Token(toTokenAddress).balanceOf(address(this));

        LibERC20Token.transfer(toTokenAddress, to, toTokenBalance);

        emit ERC20BridgeTransfer(
            data.fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            toTokenBalance,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }




    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}
