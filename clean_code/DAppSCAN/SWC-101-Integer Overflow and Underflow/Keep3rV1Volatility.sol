

pragma solidity ^0.6.12;

interface IKeep3rV1Oracle {
    function sample(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint[] memory);
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

interface IERC20 {
    function decimals() external view returns (uint);
}

contract Keep3rV1Volatility {

    uint private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint private constant SQRT_1 = 13043817825332782212;
    uint private constant LNX = 3988425491;
    uint private constant LOG_10_2 = 3010299957;
    uint private constant LOG_E_2 = 6931471806;
    uint private constant BASE = 1e10;

    IKeep3rV1Oracle public constant KV1O = IKeep3rV1Oracle(0x73353801921417F465377c8d898c6f4C0270282C);

    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {

            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {

            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (uint(1) << s)) {
                    _n >>= s;

                    res |= s;
                }
            }
        }

        return res;
    }

    function ln(uint256 x) internal pure returns (uint) {
        uint res = 0;


        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);

            x >>= count;

            res = count * FIXED_1;
        }


        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {

                x = (x * x) / FIXED_1;
                if (x >= FIXED_2) {

                    x >>= 1;

                    res += uint(1) << (i - 1);
                }
            }
        }

        return res * LOG_E_2 / BASE;
    }












    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;


        z = y = x % 0x10000000000000000000000000000000;
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000;
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000;
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000;
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000;
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000;
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000;
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800;
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800;
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400;
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480;
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380;
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8;
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001;
        res = res / 0x21c3677c82b40000 + y + FIXED_1;

        if ((x & 0x010000000000000000000000000000000) != 0)
            res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776;
        if ((x & 0x020000000000000000000000000000000) != 0)
            res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4;
        if ((x & 0x040000000000000000000000000000000) != 0)
            res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f;
        if ((x & 0x080000000000000000000000000000000) != 0)
            res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9;
        if ((x & 0x100000000000000000000000000000000) != 0)
            res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea;
        if ((x & 0x200000000000000000000000000000000) != 0)
            res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d;
        if ((x & 0x400000000000000000000000000000000) != 0)
            res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11;

        return res;
    }

    function quote(address tokenIn, address tokenOut, uint t) public view returns (uint call, uint put) {
        uint price = KV1O.current(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut);
        return quotePrice(tokenIn, tokenOut, t, price, price);
    }

    function quotePrice(address tokenIn, address tokenOut, uint t, uint sp, uint st) public view returns (uint call, uint put) {
        uint v = rVol(tokenIn, tokenOut, 48, 2);
        return quoteAll(t, v, sp, st);
    }


pragma solidity ^0.6.12;

interface IKeep3rV1Oracle {
    function sample(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint[] memory);
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

interface IERC20 {
    function decimals() external view returns (uint);
}

contract Keep3rV1Volatility {

    uint private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint private constant SQRT_1 = 13043817825332782212;
    uint private constant LNX = 3988425491;
    uint private constant LOG_10_2 = 3010299957;
    uint private constant LOG_E_2 = 6931471806;
    uint private constant BASE = 1e10;

    IKeep3rV1Oracle public constant KV1O = IKeep3rV1Oracle(0x73353801921417F465377c8d898c6f4C0270282C);

    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {

            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {

            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (uint(1) << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    function ln(uint256 x) internal pure returns (uint) {
        uint res = 0;


        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count;
            res = count * FIXED_1;
        }


        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {
                x = (x * x) / FIXED_1;
                if (x >= FIXED_2) {
                    x >>= 1;
                    res += uint(1) << (i - 1);
                }
            }
        }

        return res * LOG_E_2 / BASE;
    }












    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000;
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000;
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000;
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000;
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000;
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000;
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000;
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800;
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800;
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400;
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480;
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380;
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8;
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001;
        res = res / 0x21c3677c82b40000 + y + FIXED_1;

        if ((x & 0x010000000000000000000000000000000) != 0)
            res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776;
        if ((x & 0x020000000000000000000000000000000) != 0)
            res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4;
        if ((x & 0x040000000000000000000000000000000) != 0)
            res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f;
        if ((x & 0x080000000000000000000000000000000) != 0)
            res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9;
        if ((x & 0x100000000000000000000000000000000) != 0)
            res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea;
        if ((x & 0x200000000000000000000000000000000) != 0)
            res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d;
        if ((x & 0x400000000000000000000000000000000) != 0)
            res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11;

        return res;
    }

    function quote(address tokenIn, address tokenOut, uint t) public view returns (uint call, uint put) {
        uint price = KV1O.current(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut);
        return quotePrice(tokenIn, tokenOut, t, price, price);
    }

    function quotePrice(address tokenIn, address tokenOut, uint t, uint sp, uint st) public view returns (uint call, uint put) {
        uint v = rVol(tokenIn, tokenOut, 48, 2);
        return quoteAll(t, v, sp, st);
    }

    function quoteAll(uint t, uint v, uint sp, uint st) public pure returns (uint call, uint put) {
        uint _c;
        uint _p;

        if (sp > st) {
            _c = C(t, v, sp, st);
            _p = st-sp+_c;
        } else {
            _p = C(t, v, st, sp);
            _c = st-sp+_p;
        }
        return (_c, _p);
    }

	function C(uint t, uint v, uint sp, uint st) public pure returns (uint) {
	    if (sp == st) {
	        return LNX * sp / 1e10 * v / 1e18 * sqrt(1e18 * t / 365) / 1e9;
	    }
	    uint sigma = ((v**2)/2);
        uint sigmaB = 1e36;

        uint sig = 1e18 * sigma / sigmaB * t / 365;

        uint sSQRT = v * sqrt(1e18 * t / 365) / 1e9;

        uint d1 = 1e18 * ln(FIXED_1 * sp / st) / FIXED_1;
        d1 = (d1 + sig) * 1e18 / sSQRT;
        uint d2 = d1 - sSQRT;

        uint cdfD1 = ncdf(FIXED_1 * d1 / 1e18);
        uint cdfD2 = ncdf(FIXED_1 * d2 / 1e18);

        return sp * cdfD1 / 1e14 - st * cdfD2 / 1e14;
	}

    function ncdf(uint x) internal pure returns (uint) {
        int t1 = int(1e7 + (2315419 * x / FIXED_1));
        uint exp = x / 2 * x / FIXED_1;
        int d = int(3989423 * FIXED_1 / optimalExp(uint(exp)));
        uint prob = uint(d * (3193815 + ( -3565638 + (17814780 + (-18212560 + 13302740 * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1);
        if( x > 0 ) prob = 1e14 - prob;
        return prob;
    }

    function generalLog(uint256 x) internal pure returns (uint) {
        uint res = 0;


        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count;
            res = count * FIXED_1;
        }


        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {
                x = (x * x) / FIXED_1;
                if (x >= FIXED_2) {
                    x >>= 1;
                    res += uint(1) << (i - 1);
                }
            }
        }

        return res * LOG_10_2 / BASE;
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function vol(uint[] memory p) public pure returns (uint x) {
        for (uint8 i = 1; i <= (p.length-1); i++) {
            x += ((generalLog(p[i] * FIXED_1) - generalLog(p[i-1] * FIXED_1)))**2;

        }

        x = sqrt(uint(252) * sqrt(x / (p.length-1)));
        return uint(1e18) * x / SQRT_1;
    }

    function rVol(address tokenIn, address tokenOut, uint points, uint window) public view returns (uint) {
        return vol(KV1O.sample(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut, points, window));
    }

    function rVolHourly(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 2);
    }

    function rVolDaily(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 48);
    }

    function rVolWeekly(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 336);
    }

    function rVolHourlyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 2);
    }

    function rVolDailyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 48);
    }

    function rVolWeeklyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 336);
    }
}
    function quoteAll(uint t, uint v, uint sp, uint st) public pure returns (uint call, uint put) {
        uint _c;
        uint _p;

        if (sp > st) {
            _c = C(t, v, sp, st);
            _p = st-sp+_c;
        } else {
            _p = C(t, v, st, sp);
            _c = st-sp+_p;
        }
        return (_c, _p);
    }

	function C(uint t, uint v, uint sp, uint st) public pure returns (uint) {
	    if (sp == st) {
	        return LNX * sp / 1e10 * v / 1e18 * sqrt(1e18 * t / 365) / 1e9;
	    }
	    uint sigma = ((v**2)/2);
        uint sigmaB = 1e36;

        uint sig = 1e18 * sigma / sigmaB * t / 365;

        uint sSQRT = v * sqrt(1e18 * t / 365) / 1e9;

        uint d1 = 1e18 * ln(FIXED_1 * sp / st) / FIXED_1;
        d1 = (d1 + sig) * 1e18 / sSQRT;
        uint d2 = d1 - sSQRT;

        uint cdfD1 = ncdf(FIXED_1 * d1 / 1e18);
        uint cdfD2 = ncdf(FIXED_1 * d2 / 1e18);

        return sp * cdfD1 / 1e14 - st * cdfD2 / 1e14;
	}

    function ncdf(uint x) internal pure returns (uint) {
        int t1 = int(1e7 + (2315419 * x / FIXED_1));
        uint exp = x / 2 * x / FIXED_1;
        int d = int(3989423 * FIXED_1 / optimalExp(uint(exp)));
        uint prob = uint(d * (3193815 + ( -3565638 + (17814780 + (-18212560 + 13302740 * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1);
        if( x > 0 ) prob = 1e14 - prob;
        return prob;
    }

    function generalLog(uint256 x) internal pure returns (uint) {
        uint res = 0;


        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count;
            res = count * FIXED_1;
        }


        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {
                x = (x * x) / FIXED_1;
                if (x >= FIXED_2) {
                    x >>= 1;
                    res += uint(1) << (i - 1);
                }
            }
        }

        return res * LOG_10_2 / BASE;
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function vol(uint[] memory p) public pure returns (uint x) {
        for (uint8 i = 1; i <= (p.length-1); i++) {
            x += ((generalLog(p[i] * FIXED_1) - generalLog(p[i-1] * FIXED_1)))**2;

        }

        x = sqrt(uint(252) * sqrt(x / (p.length-1)));
        return uint(1e18) * x / SQRT_1;
    }

    function rVol(address tokenIn, address tokenOut, uint points, uint window) public view returns (uint) {
        return vol(KV1O.sample(tokenIn, uint(10)**IERC20(tokenIn).decimals(), tokenOut, points, window));
    }

    function rVolHourly(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 2);
    }

    function rVolDaily(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 48);
    }

    function rVolWeekly(address tokenIn, address tokenOut, uint points) external view returns (uint) {
        return rVol(tokenIn, tokenOut, points, 336);
    }

    function rVolHourlyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 2);
    }

    function rVolDailyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 48);
    }

    function rVolWeeklyRecent(address tokenIn, address tokenOut) external view returns (uint) {
        return rVol(tokenIn, tokenOut, 2, 336);
    }
}
