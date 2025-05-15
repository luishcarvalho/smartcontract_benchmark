pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;























library ERC20SafeTransfer {

    function safeTransfer(
        address token,
        address to,
        uint256 value)
    internal
    returns (bool success)
    {





        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
    internal
    returns (bool success)
    {





        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
    )
    internal
    pure
    returns (bool)
    {



        if (success) {
            assembly {
                switch returndatasize()

                case 0 {
                    success := 1
                }

                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }

                default {
                    success := 0
                }
            }
        }
        return success;
    }

}





















library LibBytes {

    using LibBytes for bytes;




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
        if (from > to || to > b.length) {
            return "";
        }


        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }





    function readAddress(
        bytes memory b,
        uint256 index
    )
    internal
    pure
    returns (address result)
    {
        require(
            b.length >= index + 20,
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );




        index += 20;


        assembly {



            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }





    function readBytes32(
        bytes memory b,
        uint256 index
    )
    internal
    pure
    returns (bytes32 result)
    {
        require(
            b.length >= index + 32,
            "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
        );


        index += 32;


        assembly {
            result := mload(add(b, index))
        }
        return result;
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





    function readBytes4(
        bytes memory b,
        uint256 index
    )
    internal
    pure
    returns (bytes4 result)
    {
        require(
            b.length >= index + 4,
            "GREATER_OR_EQUAL_TO_4_LENGTH_REQUIRED"
        );


        index += 32;


        assembly {
            result := mload(add(b, index))


            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}



contract LibMath {




    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }




    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }






    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }





    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }




















    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorFloor(
            numerator,
            denominator,
            target
        ),
            "ROUNDING_ERROR"
        );

        partialAmount = div(
            mul(numerator, target),
            denominator
        );
        return partialAmount;
    }







    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorCeil(
            numerator,
            denominator,
            target
        ),
            "ROUNDING_ERROR"
        );

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }






    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        partialAmount = div(
            mul(numerator, target),
            denominator
        );
        return partialAmount;
    }






    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }






    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );














        if (target == 0 || numerator == 0) {
            return false;
        }










        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = mul(1000, remainder) >= mul(numerator, target);
        return isError;
    }






    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );


        if (target == 0 || numerator == 0) {



            return false;
        }

        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = sub(denominator, remainder) % denominator;
        isError = mul(1000, remainder) >= mul(numerator, target);
        return isError;
    }
}








contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner());
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }







    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




interface IExchangeHandler {





    function getAvailableToFill(
        bytes calldata data
    )
    external
    view
    returns (uint256 availableToFill, uint256 feePercentage);






    function fillOrder(
        bytes calldata data,
        uint256 takerAmountToFill
    )
    external
    payable
    returns (uint256 makerAmountReceived);
}



contract RouterCommon {
    struct GeneralOrder {
        address handler;
        address makerToken;
        address takerToken;
        uint256 makerAmount;
        uint256 takerAmount;
        bytes data;
    }

    struct FillResults {
        uint256 makerAmountReceived;
        uint256 takerAmountSpentOnOrder;
        uint256 takerAmountSpentOnFee;
    }
}




interface IEtherDelta {
    function feeTake() external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function depositToken(address token, uint256 amount) external;
    function withdrawToken(address token, uint256 amount) external;
    function trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s, uint256 amount) external;
    function availableVolume(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s) external view returns (uint256);
}


interface IERC20 {
    function approve(address spender, uint256 value) external returns (bool);
}


contract EtherDeltaHandler is IExchangeHandler, LibMath, Ownable {

    using LibBytes for bytes;

    IEtherDelta constant internal EXCHANGE = IEtherDelta(0x8d12A197cB00D4747a1fe03395095ce2A5CC6819);
    address internal ROUTER;
    address payable internal FEE_ACCOUNT;
    uint256 internal PROCESSING_FEE_PERCENTAGE;

    struct Order {
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 expires;
        uint256 nonce;
        address user;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(
        address router,
        address payable feeAccount,
        uint256 processingFeePercentage
    )
    public
    {
        ROUTER = router;
        FEE_ACCOUNT = feeAccount;
        PROCESSING_FEE_PERCENTAGE = processingFeePercentage;
    }


    function() external payable {}



    function setFeeAccount(
        address payable feeAccount
    )
    external
    onlyOwner
    {
        FEE_ACCOUNT = feeAccount;
    }





    function getAvailableToFill(
        bytes calldata data
    )
    external
    view
    returns (uint256 availableToFill, uint256 feePercentage)
    {
        Order memory order = getOrder(data);
        availableToFill = EXCHANGE.availableVolume(
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive,
            order.expires,
            order.nonce,
            order.user,
            order.v,
            order.r,
            order.s
        );
        feePercentage = add(EXCHANGE.feeTake(), PROCESSING_FEE_PERCENTAGE);
    }






    function fillOrder(
        bytes calldata data,
        uint256 takerAmountToFill
    )
    external
    payable
    returns (uint256 makerAmountReceived)
    {
        require(msg.sender == ROUTER, "SENDER_NOT_ROUTER");
        Order memory order = getOrder(data);
        uint256 exchangeFeePercentage = EXCHANGE.feeTake();
        uint256 exchangeFee = mul(takerAmountToFill, exchangeFeePercentage) / (1 ether);
        uint256 processingFee = sub(
            mul(takerAmountToFill, add(exchangeFeePercentage, PROCESSING_FEE_PERCENTAGE)) / (1 ether),
            exchangeFee
        );
        uint256 depositAmount = add(takerAmountToFill, exchangeFee);
        makerAmountReceived = getPartialAmountFloor(order.amountGive, order.amountGet, takerAmountToFill);


        if (order.tokenGet == address(0)) {
            EXCHANGE.deposit.value(depositAmount)();
            if (processingFee > 0) {
                require(FEE_ACCOUNT.send(processingFee), "FAILED_SEND_ETH_TO_FEE_ACCOUNT");
            }
        } else {
            require(IERC20(order.tokenGet).approve(address(EXCHANGE), depositAmount));
            EXCHANGE.depositToken(order.tokenGet, depositAmount);
            if (processingFee > 0) {
                require(ERC20SafeTransfer.safeTransfer(order.tokenGet, FEE_ACCOUNT, processingFee), "FAILED_SEND_ERC20_TO_FEE_ACCOUNT");
            }
        }


        trade(order, takerAmountToFill);


        if (order.tokenGive == address(0)) {
            EXCHANGE.withdraw(makerAmountReceived);
            require(msg.sender.send(makerAmountReceived), "FAILED_SEND_ETH_TO_ROUTER");
        } else {
            EXCHANGE.withdrawToken(order.tokenGive, makerAmountReceived);
            require(ERC20SafeTransfer.safeTransfer(order.tokenGive, msg.sender, makerAmountReceived), "FAILED_SEND_ERC20_TO_ROUTER");
        }
    }



    function trade(
        Order memory order,
        uint256 takerAmountToFill
    )
    internal
    {
        EXCHANGE.trade(
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive,
            order.expires,
            order.nonce,
            order.user,
            order.v,
            order.r,
            order.s,
            takerAmountToFill
        );
    }




    function getOrder(
        bytes memory data
    )
    internal
    pure
    returns (Order memory order)
    {
        order.tokenGet = data.readAddress(12);
        order.amountGet = data.readUint256(32);
        order.tokenGive = data.readAddress(76);
        order.amountGive = data.readUint256(96);
        order.expires = data.readUint256(128);
        order.nonce = data.readUint256(160);
        order.user = data.readAddress(204);
        order.v = uint8(data.readUint256(224));
        order.r = data.readBytes32(256);
        order.s = data.readBytes32(288);
    }
}
