pragma solidity ^0.5.2;


library LibMathSigned {
    int256 private constant _WAD = 10**18;
    int256 private constant _INT256_MIN = -2**255;

    function WAD() internal pure returns (int256) {
        return _WAD;
    }


    function neg(int256 a) internal pure returns (int256) {
        return sub(int256(0), a);
    }




    function mul(int256 a, int256 b) internal pure returns (int256) {



        if (a == 0) {
            return 0;
        }
        require(!(a == -1 && b == _INT256_MIN), "wmultiplication overflow");

        int256 c = a * b;
        require(c / a == b, "wmultiplication overflow");

        return c;
    }




    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "wdivision by zero");
        require(!(b == -1 && a == _INT256_MIN), "wdivision overflow");

        int256 c = a / b;

        return c;
    }




    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "subtraction overflow");

        return c;
    }




    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "addition overflow");

        return c;
    }

    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = roundHalfUp(mul(x, y), _WAD) / _WAD;
    }


    function wdiv(int256 x, int256 y) internal pure returns (int256 z) {
        if (y < 0) {
            y = -y;
            x = -x;
        }
        z = roundHalfUp(mul(x, _WAD), y) / y;
    }


    function wfrac(int256 x, int256 y, int256 z) internal pure returns (int256 r) {
        int256 t = mul(x, y);
        if (z < 0) {
            z = -z;
            t = -t;
        }
        r = roundHalfUp(t, z) / z;
    }

    function min(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function max(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    function toUint256(int256 x) internal pure returns (uint256) {
        require(x >= 0, "int overflow");
        return uint256(x);
    }




    function wpowi(int256 x, int256 n) internal pure returns (int256 z) {
        z = n % 2 != 0 ? x : _WAD;

        for (n /= 2; n != 0; n /= 2) {
            x = wmul(x, x);

            if (n % 2 != 0) {
                z = wmul(z, x);
            }
        }
    }

    uint8 internal constant fixed_digits = 18;
    int256 internal constant fixed_1 = 1000000000000000000;
    int256 internal constant fixed_e = 2718281828459045235;
    uint8 internal constant longer_digits = 36;
    int256 internal constant longer_fixed_log_e_1_5 = 405465108108164381978013115464349137;
    int256 internal constant longer_fixed_1 = 1000000000000000000000000000000000000;
    int256 internal constant longer_fixed_log_e_10 = 2302585092994045684017991454684364208;


    function roundHalfUp(int256 x, int256 y) internal pure returns (int256) {
        require(y > 0, "roundHalfUp only supports y > 0");
        if (x >= 0) {
            return add(x, y / 2);
        }
        return sub(x, y / 2);
    }



















    function wln(int256 x) internal pure returns (int256) {
        require(x > 0, "logE of negative number");
        require(x <= 10000000000000000000000000000000000000000, "logE only accepts v <= 1e22 * 1e18");
        int256 r = 0;
        uint8 extra_digits = longer_digits - fixed_digits;
        int256 t = int256(uint256(10)**uint256(extra_digits));

        while (x <= fixed_1 / 10) {
            x = x * 10;
            r -= longer_fixed_log_e_10;
        }
        while (x >= 10 * fixed_1) {
            x = x / 10;
            r += longer_fixed_log_e_10;
        }
        while (x < fixed_1) {
            x = wmul(x, fixed_e);
            r -= longer_fixed_1;
        }
        while (x > fixed_e) {
            x = wdiv(x, fixed_e);
            r += longer_fixed_1;
        }
        if (x == fixed_1) {
            return roundHalfUp(r, t) / t;
        }
        if (x == fixed_e) {
            return fixed_1 + roundHalfUp(r, t) / t;
        }
        x *= t;















        r = r + longer_fixed_log_e_1_5;
        int256 a1_5 = (3 * longer_fixed_1) / 2;
        int256 m = (longer_fixed_1 * (x - a1_5)) / (x + a1_5);
        r = r + 2 * m;
        int256 m2 = (m * m) / longer_fixed_1;
        uint8 i = 3;
        while (true) {
            m = (m * m2) / longer_fixed_1;
            r = r + (2 * m) / int256(i);
            i += 2;
            if (i >= 3 + 2 * fixed_digits) {
                break;
            }
        }
        return roundHalfUp(r, t) / t;
    }


    function logBase(int256 base, int256 x) internal pure returns (int256) {
        return wdiv(wln(x), wln(base));
    }

    function ceil(int256 x, int256 m) internal pure returns (int256) {
        require(x >= 0, "ceil need x >= 0");
        require(m > 0, "ceil need m > 0");
        return (sub(add(x, m), 1) / m) * m;
    }
}


library LibMathUnsigned {
    uint256 private constant _WAD = 10**18;
    uint256 private constant _UINT256_MAX = 2**255 - 1;

    function WAD() internal pure returns (uint256) {
        return _WAD;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Unaddition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Unsubtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Unmultiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "Undivision by zero");
        uint256 c = a / b;


        return c;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), _WAD / 2) / _WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, _WAD), y / 2) / y;
    }

    function wfrac(uint256 x, uint256 y, uint256 z) internal pure returns (uint256 r) {
        r = mul(x, y) / z;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function toInt256(uint256 x) internal pure returns (int256) {
        require(x <= _UINT256_MAX, "uint256 overflow");
        return int256(x);
    }

    function mod(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m != 0, "mod by zero");
        return x % m;
    }

    function ceil(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m > 0, "ceil need m > 0");
        return (sub(add(x, m), 1) / m) * m;
    }
}
