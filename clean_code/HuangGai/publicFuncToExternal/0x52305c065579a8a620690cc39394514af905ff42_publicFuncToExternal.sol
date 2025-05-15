























pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;





library SafeMath {



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











interface IErc20 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply(
    )
        external
        view
        returns (uint256);

    function balanceOf(
        address who
    )
        external
        view
        returns (uint256);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address to,
        uint256 value
    )
        external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external;

    function approve(
        address spender,
        uint256 value
    )
        external;

    function name()
        external
        view
        returns (string memory);

    function symbol()
        external
        view
        returns (string memory);

    function decimals()
        external
        view
        returns (uint8);
}









library Monetary {




    struct Price {
        uint256 value;
    }




    struct Value {
        uint256 value;
    }
}









contract IPriceOracle {



    uint256 public constant ONE_DOLLAR = 10 ** 36;












    function getPrice(
        address token
    )
        public
        view
        returns (Monetary.Price memory);
}









library Require {



    uint256 constant ASCII_ZERO = 48;
    uint256 constant ASCII_RELATIVE_ZERO = 87;
    uint256 constant ASCII_LOWER_EX = 120;
    bytes2 constant COLON = 0x3a20;
    bytes2 constant COMMA = 0x2c20;
    bytes2 constant LPAREN = 0x203c;
    byte constant RPAREN = 0x3e;
    uint256 constant FOUR_BIT_MASK = 0xf;



    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }



    function stringifyTruncated(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {

        bytes memory result = abi.encodePacked(input);


        for (uint256 i = 32; i > 0; ) {


            i--;


            if (result[i] != 0) {
                uint256 length = i + 1;


                assembly {
                    mstore(result, length)
                }

                return result;
            }
        }


        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
        private
        pure
        returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }


        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }


        bytes memory bstr = new bytes(length);


        j = input;
        for (uint256 i = length; i > 0; ) {


            i--;


            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));


            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);


        bytes memory result = new bytes(42);


        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));


        for (uint256 i = 0; i < 20; i++) {

            uint256 shift = i * 2;


            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;


            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);


        bytes memory result = new bytes(66);


        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));


        for (uint256 i = 0; i < 32; i++) {

            uint256 shift = i * 2;


            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;


            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
        private
        pure
        returns (byte)
    {

        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }


        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}









library Math {
    using SafeMath for uint256;



    bytes32 constant FILE = "Math";






    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }




    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        if (target == 0 || numerator == 0) {

            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint128"
        );
        return result;
    }

    function to96(
        uint256 number
    )
        internal
        pure
        returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint96"
        );
        return result;
    }

    function to32(
        uint256 number
    )
        internal
        pure
        returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint32"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}









library Time {



    function currentTime()
        internal
        view
        returns (uint32)
    {
        return Math.to32(block.timestamp);
    }
}



























interface ICurve {

    function fee()
        external
        view
        returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    )
        external
        view
        returns (uint256);
}



























interface IUniswapV2Pair {

    function getReserves()
        external
        view
        returns (uint112, uint112, uint32);
}









contract DaiPriceOracle is
    Ownable,
    IPriceOracle
{
    using SafeMath for uint256;



    bytes32 constant FILE = "DaiPriceOracle";


    uint256 constant DECIMALS = 18;
    uint256 constant EXPECTED_PRICE = ONE_DOLLAR / (10 ** DECIMALS);


    int128 constant CURVE_DAI_ID = 0;
    int128 constant CURVE_USDC_ID = 1;
    uint256 constant CURVE_FEE_DENOMINATOR = 10 ** 10;
    uint256 constant CURVE_DECIMALS_BASE = 10 ** 30;


    uint256 constant UNISWAP_DECIMALS_BASE = 10 ** 30;



    struct PriceInfo {
        uint128 price;
        uint32 lastUpdate;
    }

    struct DeviationParams {
        uint64 denominator;
        uint64 maximumPerSecond;
        uint64 maximumAbsolute;
    }



    event PriceSet(
        PriceInfo newPriceInfo
    );



    PriceInfo public g_priceInfo;

    address public g_poker;

    DeviationParams public DEVIATION_PARAMS;

    IErc20 public WETH;

    IErc20 public DAI;

    ICurve public CURVE;

    IUniswapV2Pair public UNISWAP_DAI_ETH;

    IUniswapV2Pair public UNISWAP_USDC_ETH;



    constructor(
        address poker,
        address weth,
        address dai,
        address curve,
        address uniswapDaiEth,
        address uniswapUsdcEth,
        DeviationParams memory deviationParams
    )
        public
    {
        g_poker = poker;
        WETH = IErc20(weth);
        DAI = IErc20(dai);
        CURVE = ICurve(curve);
        UNISWAP_DAI_ETH = IUniswapV2Pair(uniswapDaiEth);
        UNISWAP_USDC_ETH = IUniswapV2Pair(uniswapUsdcEth);
        DEVIATION_PARAMS = deviationParams;
        g_priceInfo = PriceInfo({
            lastUpdate: uint32(block.timestamp),
            price: uint128(EXPECTED_PRICE)
        });
    }



    function ownerSetPokerAddress(
        address newPoker
    )
        public
        onlyOwner
    {
        g_poker = newPoker;
    }



    function updatePrice(
        Monetary.Price memory minimum,
        Monetary.Price memory maximum
    )
        public
        returns (PriceInfo memory)
    {
        Require.that(
            msg.sender == g_poker,
            FILE,
            "Only poker can call updatePrice",
            msg.sender
        );

        Monetary.Price memory newPrice = getBoundedTargetPrice();

        Require.that(
            newPrice.value >= minimum.value,
            FILE,
            "newPrice below minimum",
            newPrice.value,
            minimum.value
        );

        Require.that(
            newPrice.value <= maximum.value,
            FILE,
            "newPrice above maximum",
            newPrice.value,
            maximum.value
        );

        g_priceInfo = PriceInfo({
            price: Math.to128(newPrice.value),
            lastUpdate: Time.currentTime()
        });

        emit PriceSet(g_priceInfo);
        return g_priceInfo;
    }



    function getPrice(
        address
    )
        public
        view
        returns (Monetary.Price memory)
    {
        return Monetary.Price({
            value: g_priceInfo.price
        });
    }






    function getBoundedTargetPrice()
        public
        view
        returns (Monetary.Price memory)
    {
        Monetary.Price memory targetPrice = getTargetPrice();

        PriceInfo memory oldInfo = g_priceInfo;
        uint256 timeDelta = uint256(Time.currentTime()).sub(oldInfo.lastUpdate);
        (uint256 minPrice, uint256 maxPrice) = getPriceBounds(oldInfo.price, timeDelta);
        uint256 boundedTargetPrice = boundValue(targetPrice.value, minPrice, maxPrice);

        return Monetary.Price({
            value: boundedTargetPrice
        });
    }





    function getTargetPrice()
        public
        view
        returns (Monetary.Price memory)
    {
        uint256 targetPrice = getMidValue(
            EXPECTED_PRICE,
            getCurvePrice(),
            getUniswapPrice()
        );

        return Monetary.Price({
            value: targetPrice
        });
    }






    function getCurvePrice()
        public
        view
        returns (uint256)
    {
        ICurve curve = CURVE;




        uint256 dyWithFee = curve.get_dy(CURVE_USDC_ID, CURVE_DAI_ID, 1);
        uint256 fee = curve.fee();
        uint256 dyWithoutFee = dyWithFee.mul(CURVE_FEE_DENOMINATOR).div(
            CURVE_FEE_DENOMINATOR.sub(fee)
        );



        return CURVE_DECIMALS_BASE.div(dyWithoutFee);
    }






    function getUniswapPrice()
        public
        view
        returns (uint256)
    {

        (uint256 daiAmt, uint256 poolOneEthAmt, ) = UNISWAP_DAI_ETH.getReserves();
        (uint256 usdcAmt, uint256 poolTwoEthAmt, ) = UNISWAP_USDC_ETH.getReserves();





        return UNISWAP_DECIMALS_BASE
            .mul(usdcAmt)
            .mul(poolOneEthAmt)
            .div(poolTwoEthAmt)
            .div(daiAmt);
    }



    function getPriceBounds(
        uint256 oldPrice,
        uint256 timeDelta
    )
        private
        view
        returns (uint256, uint256)
    {
        DeviationParams memory deviation = DEVIATION_PARAMS;

        uint256 maxDeviation = Math.getPartial(
            oldPrice,
            Math.min(deviation.maximumAbsolute, timeDelta.mul(deviation.maximumPerSecond)),
            deviation.denominator
        );

        return (
            oldPrice.sub(maxDeviation),
            oldPrice.add(maxDeviation)
        );
    }

    function getMidValue(
        uint256 valueA,
        uint256 valueB,
        uint256 valueC
    )
        private
        pure
        returns (uint256)
    {
        uint256 maximum = Math.max(valueA, Math.max(valueB, valueC));
        if (maximum == valueA) {
            return Math.max(valueB, valueC);
        }
        if (maximum == valueB) {
            return Math.max(valueA, valueC);
        }
        return Math.max(valueA, valueB);
    }

    function boundValue(
        uint256 value,
        uint256 minimum,
        uint256 maximum
    )
        private
        pure
        returns (uint256)
    {
        assert(minimum <= maximum);
        return Math.max(minimum, Math.min(maximum, value));
    }
}
