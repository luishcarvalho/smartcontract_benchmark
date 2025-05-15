

















pragma solidity ^0.5.9;

import "./LibFixedMathRichErrors.sol";




library LibFixedMath {


    int256 private constant FIXED_1 = int256(0x0000000000000000000000000000000080000000000000000000000000000000);

    int256 private constant FIXED_1_SQUARED = int256(0x4000000000000000000000000000000000000000000000000000000000000000);

    int256 private constant LN_MAX_VAL = FIXED_1;

    int256 private constant LN_MIN_VAL = int256(0x0000000000000000000000000000000000000000000000000000000733048c5a);

    int256 private constant EXP_MAX_VAL = 0;

    int256 private constant EXP_MIN_VAL = -int256(0x0000000000000000000000000000001ff0000000000000000000000000000000);


    function one() internal pure returns (int256 f) {
        f = FIXED_1;
    }


    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = _add(a, b);
    }


    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        c = _add(a, -b);
    }


    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = _mul(a, b) / FIXED_1;
    }


    function div(int256 a, int256 b) internal pure returns (int256 c) {
        c = _div(_mul(a, FIXED_1), b);
    }


    function mulDiv(int256 a, int256 n, int256 d) internal pure returns (int256 c) {
        c = _div(_mul(a, n), d);
    }




    function uintMul(int256 f, uint256 u) internal pure returns (uint256) {
        if (int256(u) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                u
            ));
        }
        int256 c = _mul(f, int256(u));
        if (c <= 0) {
            return 0;
        }
        return uint256(uint256(c) >> 127);
    }


    function abs(int256 f) internal pure returns (int256 c) {
        if (f >= 0) {
            c = f;
        } else {
            c = -f;
        }
    }


    function invert(int256 f) internal pure returns (int256 c) {
        c = _div(FIXED_1_SQUARED, f);
    }


    function toFixed(int256 n) internal pure returns (int256 f) {
        f = _mul(n, FIXED_1);
    }


    function toFixed(int256 n, int256 d) internal pure returns (int256 f) {
        f = _div(_mul(n, FIXED_1), d);
    }



    function toFixed(uint256 n) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                n
            ));
        }
        f = _mul(int256(n), FIXED_1);
    }



    function toFixed(uint256 n, uint256 d) internal pure returns (int256 f) {
        if (int256(n) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                n
            ));
        }
        if (int256(d) < int256(0)) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.UnsignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                d
            ));
        }
        f = _div(_mul(int256(n), FIXED_1), int256(d));
    }


    function toInteger(int256 f) internal pure returns (int256 n) {
        return f / FIXED_1;
    }


    function ln(int256 x) internal pure returns (int256 r) {
        if (x > LN_MAX_VAL) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                x
            ));
        }
        if (x <= 0) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_SMALL,
                x
            ));
        }
        if (x == FIXED_1) {
            return 0;
        }
        if (x <= LN_MIN_VAL) {
            return EXP_MIN_VAL;
        }

        int256 y;
        int256 z;
        int256 w;





        if (x <= int256(0x00000000000000000000000000000000000000000001c8464f76164760000000)) {
            r -= int256(0x0000000000000000000000000000001000000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x00000000000000000000000000000000000000000001c8464f76164760000000);
        }

        if (x <= int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000)) {
            r -= int256(0x0000000000000000000000000000000800000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000);
        }

        if (x <= int256(0x00000000000000000000000000000000000afe10820813d78000000000000000)) {
            r -= int256(0x0000000000000000000000000000000400000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x00000000000000000000000000000000000afe10820813d78000000000000000);
        }

        if (x <= int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000)) {
            r -= int256(0x0000000000000000000000000000000200000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000);
        }

        if (x <= int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000100000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000);
        }

        if (x <= int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000080000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000);
        }

        if (x <= int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000040000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000);
        }

        if (x <= int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000020000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000);
        }

        if (x <= int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) {
            r -= int256(0x0000000000000000000000000000000010000000000000000000000000000000);
            x = x * FIXED_1 / int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d);
        }



        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        r += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1;
        r += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1;
        r += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1;
        r += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1;
        r += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1;
        r += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1;
        r += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1;
        r += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;
    }


    function exp(int256 x) internal pure returns (int256 r) {
        if (x < EXP_MIN_VAL) {

            return 0;
        }
        if (x == 0) {
            return FIXED_1;
        }
        if (x > EXP_MAX_VAL) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.SignedValueError(
                LibFixedMathRichErrors.ValueErrorCodes.TOO_LARGE,
                x
            ));
        }








        int256 y;
        int256 z;

        z = y = x % 0x0000000000000000000000000000000010000000000000000000000000000000;
        z = z * y / FIXED_1; r += z * 0x10e1b3be415a0000;
        z = z * y / FIXED_1; r += z * 0x05a0913f6b1e0000;
        z = z * y / FIXED_1; r += z * 0x0168244fdac78000;
        z = z * y / FIXED_1; r += z * 0x004807432bc18000;
        z = z * y / FIXED_1; r += z * 0x000c0135dca04000;
        z = z * y / FIXED_1; r += z * 0x0001b707b1cdc000;
        z = z * y / FIXED_1; r += z * 0x000036e0f639b800;
        z = z * y / FIXED_1; r += z * 0x00000618fee9f800;
        z = z * y / FIXED_1; r += z * 0x0000009c197dcc00;
        z = z * y / FIXED_1; r += z * 0x0000000e30dce400;
        z = z * y / FIXED_1; r += z * 0x000000012ebd1300;
        z = z * y / FIXED_1; r += z * 0x0000000017499f00;
        z = z * y / FIXED_1; r += z * 0x0000000001a9d480;
        z = z * y / FIXED_1; r += z * 0x00000000001c6380;
        z = z * y / FIXED_1; r += z * 0x000000000001c638;
        z = z * y / FIXED_1; r += z * 0x0000000000001ab8;
        z = z * y / FIXED_1; r += z * 0x000000000000017c;
        z = z * y / FIXED_1; r += z * 0x0000000000000014;
        z = z * y / FIXED_1; r += z * 0x0000000000000001;
        r = r / 0x21c3677c82b40000 + y + FIXED_1;


        x = -x;

        if ((x & int256(0x0000000000000000000000000000001000000000000000000000000000000000)) != 0) {
            r = r * int256(0x00000000000000000000000000000000000000f1aaddd7742e56d32fb9f99744)
                / int256(0x0000000000000000000000000043cbaf42a000812488fc5c220ad7b97bf6e99e);
        }

        if ((x & int256(0x0000000000000000000000000000000800000000000000000000000000000000)) != 0) {
            r = r * int256(0x00000000000000000000000000000000000afe10820813d65dfe6a33c07f738f)
                / int256(0x000000000000000000000000000005d27a9f51c31b7c2f8038212a0574779991);
        }

        if ((x & int256(0x0000000000000000000000000000000400000000000000000000000000000000)) != 0) {
            r = r * int256(0x0000000000000000000000000000000002582ab704279e8efd15e0265855c47a)
                / int256(0x0000000000000000000000000000001b4c902e273a58678d6d3bfdb93db96d02);
        }

        if ((x & int256(0x0000000000000000000000000000000200000000000000000000000000000000)) != 0) {
            r = r * int256(0x000000000000000000000000000000001152aaa3bf81cb9fdb76eae12d029571)
                / int256(0x00000000000000000000000000000003b1cc971a9bb5b9867477440d6d157750);
        }

        if ((x & int256(0x0000000000000000000000000000000100000000000000000000000000000000)) != 0) {
            r = r * int256(0x000000000000000000000000000000002f16ac6c59de6f8d5d6f63c1482a7c86)
                / int256(0x000000000000000000000000000000015bf0a8b1457695355fb8ac404e7a79e3);
        }

        if ((x & int256(0x0000000000000000000000000000000080000000000000000000000000000000)) != 0) {
            r = r * int256(0x000000000000000000000000000000004da2cbf1be5827f9eb3ad1aa9866ebb3)
                / int256(0x00000000000000000000000000000000d3094c70f034de4b96ff7d5b6f99fcd8);
        }

        if ((x & int256(0x0000000000000000000000000000000040000000000000000000000000000000)) != 0) {
            r = r * int256(0x0000000000000000000000000000000063afbe7ab2082ba1a0ae5e4eb1b479dc)
                / int256(0x00000000000000000000000000000000a45af1e1f40c333b3de1db4dd55f29a7);
        }

        if ((x & int256(0x0000000000000000000000000000000020000000000000000000000000000000)) != 0) {
            r = r * int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)
                / int256(0x00000000000000000000000000000000910b022db7ae67ce76b441c27035c6a1);
        }

        if ((x & int256(0x0000000000000000000000000000000010000000000000000000000000000000)) != 0) {
            r = r * int256(0x00000000000000000000000000000000783eafef1c0a8f3978c7f81824d62ebf)
                / int256(0x0000000000000000000000000000000088415abbe9a76bead8d00cf112e4d4a8);
        }
    }


    function _mul(int256 a, int256 b) private pure returns (int256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
    }


    function _div(int256 a, int256 b) private pure returns (int256 c) {
        if (b == 0) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        c = a / b;
    }



    function _add(int256 a, int256 b) private pure returns (int256 c) {
        c = a + b;
        if (c > 0 && a < 0 && b < 0) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.SUBTRACTION_OVERFLOW,
                a,
                b
            ));
        }
        if (c < 0 && a > 0 && b > 0) {
            LibRichErrors.rrevert(LibFixedMathRichErrors.BinOpError(
                LibFixedMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
    }
}
