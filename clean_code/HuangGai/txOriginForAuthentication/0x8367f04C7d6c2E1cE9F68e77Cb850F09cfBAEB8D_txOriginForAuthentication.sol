














pragma solidity 0.6.12;
















library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}














library ABDKMath64x64 {



  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;




  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;








  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }








  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }








  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }








  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }








  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }








  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }








  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }








  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }








  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }









  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y;
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult);
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }









  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }









  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }









  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x;
      negativeResult = true;
    }
    if (y < 0) {
      y = -y;
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult);
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult);
    }
  }









  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }







  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }







  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }








  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }








  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }









  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m), uint256 (x) + uint256 (y) >> 1));
  }









  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {

      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult);
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult);
    }
  }







  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64, 0x10000000000000000));
  }







  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << 127 - msb;
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }







  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }







  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000);

    if (x < -0x400000000000000000) return 0;

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= 63 - (x >> 64);
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }







  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000);

    if (x < -0x400000000000000000) return 0;

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }









  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo;
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo;

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }









  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;

      int256 xe = msb - 127;
      if (xe > 0) x >>= xe;
      else x <<= -xe;

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0;
          require (re < 128);
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0;
          require (xe < 128);
        }
      }

      if (re > 0) result <<= re;
      else if (re < 0) result >>= -re;

      return result;
    }
  }








  function sqrtu (uint256 x, uint256 r) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      require (r > 0);
      while (true) {
        uint256 rr = x / r;
        if (r == rr || r + 1 == rr) return uint128 (r);
        else if (r == rr + 1) return uint128 (rr);
        r = r + rr + 1 >> 1;
      }
    }
  }
}





interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ICoFiXVaultForTrader {

    event RouterAllowed(address router);
    event RouterDisallowed(address router);

    event ClearPendingRewardOfCNode(uint256 pendingAmount);
    event ClearPendingRewardOfLP(uint256 pendingAmount);

    function setGovernance(address gov) external;

    function setExpectedYieldRatio(uint256 r) external;
    function setLRatio(uint256 lRatio) external;
    function setTheta(uint256 theta) external;

    function allowRouter(address router) external;

    function disallowRouter(address router) external;

    function calcCoFiRate(uint256 bt_phi, uint256 xt, uint256 np) external view returns (uint256 at);

    function currentCoFiRate(address pair, uint256 np) external view returns (uint256);

    function currentThreshold(address pair, uint256 np, uint256 cofiRate) external view returns (uint256);

    function stdMiningRateAndAmount(address pair, uint256 np, uint256 thetaFee) external view returns (uint256 cofiRate, uint256 stdAmount);

    function calcDensity(uint256 _stdAmount) external view returns (uint256);

    function calcLambda(uint256 x, uint256 y) external pure returns (uint256);

    function actualMiningAmountAndDensity(address pair, uint256 thetaFee, uint256 x, uint256 y, uint256 np) external view returns (uint256 amount, uint256 density, uint256 cofiRate);

    function distributeReward(address pair, uint256 thetaFee, uint256 x, uint256 y, uint256 np, address rewardTo) external;

    function clearPendingRewardOfCNode() external;

    function clearPendingRewardOfLP(address pair) external;

    function getPendingRewardOfCNode() external view returns (uint256);

    function getPendingRewardOfLP(address pair) external view returns (uint256);

    function getCoFiRateCache(address pair) external view returns (uint256 cofiRate, uint256 updatedBlock);
}


interface ICoFiToken is IERC20 {



    event NewGovernance(address _new);



    event MinterAdded(address _minter);



    event MinterRemoved(address _minter);



    function setGovernance(address _new) external;



    function addMinter(address _minter) external;



    function removeMinter(address _minter) external;




    function mint(address _to, uint256 _amount) external;
}


















contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}


interface ICoFiXFactory {

    event PairCreated(address indexed token, address pair, uint256);
    event NewGovernance(address _new);
    event NewController(address _new);
    event NewFeeReceiver(address _new);
    event NewVaultForLP(address _new);
    event NewVaultForTrader(address _new);
    event NewVaultForCNode(address _new);




    function createPair(
        address token
        )
        external
        returns (address pair);

    function getPair(address token) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function getTradeMiningStatus(address token) external view returns (bool status);
    function setTradeMiningStatus(address token, bool status) external;

    function setGovernance(address _new) external;
    function setController(address _new) external;
    function setFeeReceiver(address _new) external;
    function setVaultForLP(address _new) external;
    function setVaultForTrader(address _new) external;
    function setVaultForCNode(address _new) external;
    function getController() external view returns (address controller);
    function getFeeReceiver() external view returns (address feeReceiver);
    function getVaultForLP() external view returns (address vaultForLP);
    function getVaultForTrader() external view returns (address vaultForTrader);
    function getVaultForCNode() external view returns (address vaultForCNode);
}


interface ICoFiXVaultForLP {

    enum POOL_STATE {INVALID, ENABLED, DISABLED}

    event NewPoolAdded(address pool, uint256 index);
    event PoolEnabled(address pool);
    event PoolDisabled(address pool);

    function setGovernance(address _new) external;
    function setInitCoFiRate(uint256 _new) external;
    function setDecayPeriod(uint256 _new) external;
    function setDecayRate(uint256 _new) external;

    function addPool(address pool) external;
    function enablePool(address pool) external;
    function disablePool(address pool) external;
    function setPoolWeight(address pool, uint256 weight) external;
    function batchSetPoolWeight(address[] memory pools, uint256[] memory weights) external;
    function distributeReward(address to, uint256 amount) external;

    function getPendingRewardOfLP(address pair) external view returns (uint256);
    function currentPeriod() external view returns (uint256);
    function currentCoFiRate() external view returns (uint256);
    function currentPoolRate(address pool) external view returns (uint256 poolRate);
    function currentPoolRateByPair(address pair) external view returns (uint256 poolRate);




    function stakingPoolForPair(address pair) external view returns (address pool);

    function getPoolInfo(address pool) external view returns (POOL_STATE state, uint256 weight);
    function getPoolInfoByPair(address pair) external view returns (POOL_STATE state, uint256 weight);

    function getEnabledPoolCnt() external view returns (uint256);

    function getCoFiStakingPool() external view returns (address pool);

}


interface ICoFiXStakingRewards {




    function rewardsVault() external view returns (address);



    function lastBlockRewardApplicable() external view returns (uint256);


    function rewardPerToken() external view returns (uint256);




    function earned(address account) external view returns (uint256);



    function accrued() external view returns (uint256);



    function rewardRate() external view returns (uint256);



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);



    function stakingToken() external view returns (address);



    function rewardsToken() external view returns (address);





    function stake(uint256 amount) external;




    function stakeForOther(address other, uint256 amount) external;



    function withdraw(uint256 amount) external;


    function emergencyWithdraw() external;


    function getReward() external;

    function getRewardAndStake() external;


    function exit() external;


    function addReward(uint256 amount) external;


    event RewardAdded(address sender, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event StakedForOther(address indexed user, address indexed other, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}


interface ICoFiXERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);



    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


interface ICoFiXPair is ICoFiXERC20 {

    struct OraclePrice {
        uint256 ethAmount;
        uint256 erc20Amount;
        uint256 blockNum;
        uint256 K;
        uint256 theta;
    }


    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, address outToken, uint outAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address outToken,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function mint(address to) external payable returns (uint liquidity, uint oracleFeeChange);
    function burn(address outToken, address to) external payable returns (uint amountOut, uint oracleFeeChange);
    function swapWithExact(address outToken, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo);
    function swapForExact(address outToken, uint amountOutExact, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange, uint256[4] memory tradeInfo);
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, string memory, string memory) external;





    function getNAVPerShare(uint256 ethAmount, uint256 erc20Amount) external view returns (uint256 navps);
}




contract CoFiXVaultForTrader is ICoFiXVaultForTrader, ReentrancyGuard {
    using SafeMath for uint256;

    struct CoFiRateCache {
        uint128 cofiRate;
        uint128 updatedBlock;
    }

    uint256 public constant RATE_BASE = 1e18;
    uint256 public constant LAMBDA_BASE = 100;
    uint256 public constant RECENT_RANGE = 300;

    uint256 public constant SHARE_BASE = 100;
    uint256 public constant SHARE_FOR_TRADER = 80;
    uint256 public constant SHARE_FOR_LP = 10;
    uint256 public constant SHARE_FOR_CNODE = 10;

    uint256 public constant NAVPS_BASE = 1E18;


    uint256 public constant COFI_DECAY_PERIOD = 2400000;
    uint256 public constant THETA_FEE_UINIT = 1 ether;
    uint256 public constant L_LIMIT = 100 ether;
    uint256 public constant COFI_RATE_UPDATE_INTERVAL = 1000;

    uint256 public constant EXPECT_YIELD_BASE = 10;
    uint256 public constant L_BASE = 1000;
    uint256 public constant THETA_BASE = 1000;

    address public immutable cofiToken;
    address public immutable factory;


    address public governance;
    uint256 public EXPECT_YIELD_RATIO = 3;
    uint256 public L_RATIO = 2;
    uint256 public THETA = 2;

    uint256 public pendingRewardsForCNode;

    mapping (address => CoFiRateCache) internal cofiRateCache;
    mapping(address => uint256) public pendingRewardsForLP;
    mapping (address => bool) public routerAllowed;

    uint128 public lastMinedBlock;
    uint128 public lastDensity;

    modifier onlyGovernance() {
        require(tx.origin == governance, "CVaultForTrader: !governance");

        _;
    }

    constructor(address cofi, address _factory) public {
        cofiToken = cofi;
        factory = _factory;
        governance = msg.sender;
    }


    function setGovernance(address _new) external override onlyGovernance {
        governance = _new;
    }

    function setExpectedYieldRatio(uint256 r) external override onlyGovernance {
        EXPECT_YIELD_RATIO = r;
    }

    function setLRatio(uint256 lRatio) external override onlyGovernance {
        L_RATIO = lRatio;
    }

    function setTheta(uint256 theta) external override onlyGovernance {
        THETA = theta;
    }

    function allowRouter(address router) external override onlyGovernance {
        require(!routerAllowed[router], "CVaultForTrader: router allowed");
        routerAllowed[router] = true;
        emit RouterAllowed(router);
    }

    function disallowRouter(address router) external override onlyGovernance {
        require(routerAllowed[router], "CVaultForTrader: router disallowed");
        routerAllowed[router] = false;
        emit RouterDisallowed(router);
    }

    function calcCoFiRate(uint256 bt_phi, uint256 xt, uint256 np) public override view returns (uint256 at) {











        uint256 tvl = xt.mul(np).div(NAVPS_BASE);
        if (tvl < 20000 ether) {
            tvl = 20000 ether;
        }
        uint256 numerator = bt_phi.mul(COFI_DECAY_PERIOD).mul(1e18).mul(EXPECT_YIELD_BASE);
        at = numerator.div(EXPECT_YIELD_RATIO).div(tvl);
    }


    function currentCoFiRate(address pair, uint256 np) public override view returns (uint256) {




        uint256 updatedBlock = cofiRateCache[pair].updatedBlock;
        if (block.number.sub(updatedBlock) < COFI_RATE_UPDATE_INTERVAL && updatedBlock != 0) {
            return cofiRateCache[pair].cofiRate;
        }
        address vaultForLP = ICoFiXFactory(factory).getVaultForLP();
        require(vaultForLP != address(0), "CVaultForTrader: vaultForLP not set");
        uint256 poolRate = ICoFiXVaultForLP(vaultForLP).currentPoolRateByPair(pair);
        uint256 totalSupply = ICoFiXPair(pair).totalSupply();
        return calcCoFiRate(poolRate, totalSupply, np);
    }


    function currentThreshold(address pair, uint256 np, uint256 cofiRate) public override view returns (uint256) {




        uint256 totalSupply = ICoFiXPair(pair).totalSupply();
        uint256 L = totalSupply.mul(np).mul(L_RATIO).div(L_BASE).div(NAVPS_BASE);


        if (L < L_LIMIT) {
            L = L_LIMIT;
        }
        return L.mul(cofiRate).mul(THETA).div(THETA_BASE).div(THETA_FEE_UINIT);
    }

    function stdMiningRateAndAmount(
        address pair,
        uint256 np,
        uint256 thetaFee
    ) public override view returns (
        uint256 cofiRate,
        uint256 stdAmount
    ) {

        cofiRate = currentCoFiRate(pair, np);
        stdAmount = thetaFee.mul(cofiRate).div(THETA_FEE_UINIT);
        return (cofiRate, stdAmount);
    }



    function calcDensity(uint256 _stdAmount) public override view returns (uint256) {
        uint256 _last = lastMinedBlock;
        uint256 _offset = block.number.sub(_last);
        if (_offset >= RECENT_RANGE) {
            return _stdAmount;
        } else {
            uint256 _lastDensity = lastDensity;
            return _lastDensity.mul(RECENT_RANGE.sub(_offset)).div(RECENT_RANGE).add(_stdAmount);
        }
    }

    function calcLambda(uint256 x, uint256 y) public override pure returns (uint256) {

        uint256 ratio;
        if (y == 0) {
            ratio = 1000;
        } else {
            ratio = x.mul(LAMBDA_BASE).div(y);
        }
        if (ratio >= 1000) {
            return 25;
        } else if (ratio >= 300) {
            return 50;
        } else if (ratio >= 33) {
            return 100;
        } else if (ratio >= 10) {
            return 200;
        } else {
            return 400;
        }
    }

    function actualMiningAmountAndDensity(
        address pair,
        uint256 thetaFee,
        uint256 x,
        uint256 y,
        uint256 np
    ) public override view returns (
        uint256 amount,
        uint256 density,
        uint256 cofiRate
    ) {
        uint256 stdAmount;
        (cofiRate, stdAmount) = stdMiningRateAndAmount(pair, np, thetaFee);
        density = calcDensity(stdAmount);
        uint256 lambda = calcLambda(x, y);
        uint256 th = currentThreshold(pair, np, cofiRate);
        if (density <= th) {

            return (stdAmount.mul(lambda).div(LAMBDA_BASE), density, cofiRate);
        }

        uint256 numerator = stdAmount.mul(th).mul(density.mul(2).sub(th)).mul(lambda);
        return (numerator.div(density).div(density).div(LAMBDA_BASE), density, cofiRate);
    }

    function distributeReward(
        address pair,
        uint256 thetaFee,
        uint256 x,
        uint256 y,
        uint256 np,
        address rewardTo
    ) external override nonReentrant {
        require(routerAllowed[msg.sender], "CVaultForTrader: not allowed router");
        require(pair != address(0), "CVaultForTrader: invalid pair");
        require(rewardTo != address(0), "CVaultForTrader: invalid rewardTo");

        uint256 amount;
        {
            uint256 density;
            uint256 cofiRate;
            (amount, density, cofiRate) = actualMiningAmountAndDensity(pair, thetaFee, x, y, np);


            require(density < 2**128, "CVaultForTrader: density overflow");
            lastDensity = uint128(density);
            lastMinedBlock = uint128(block.number);

            uint128 updatedBlock = cofiRateCache[pair].updatedBlock;
            if (block.number.sub(updatedBlock) >= COFI_RATE_UPDATE_INTERVAL || updatedBlock == 0) {
                cofiRateCache[pair].updatedBlock = uint128(block.number);
                cofiRateCache[pair].cofiRate = uint128(cofiRate);
            }
        }

        {
            uint256 amountForTrader = amount.mul(SHARE_FOR_TRADER).div(SHARE_BASE);
            uint256 amountForLP = amount.mul(SHARE_FOR_LP).div(SHARE_BASE);
            uint256 amountForCNode = amount.mul(SHARE_FOR_CNODE).div(SHARE_BASE);

            ICoFiToken(cofiToken).mint(rewardTo, amountForTrader);
            pendingRewardsForLP[pair] = pendingRewardsForLP[pair].add(amountForLP);
            pendingRewardsForCNode = pendingRewardsForCNode.add(amountForCNode);
        }

    }

    function clearPendingRewardOfCNode() external override nonReentrant {
        address vaultForCNode = ICoFiXFactory(factory).getVaultForCNode();
        require(msg.sender == vaultForCNode, "CVaultForTrader: only vaultForCNode");

        emit ClearPendingRewardOfCNode(pendingRewardsForCNode);
        pendingRewardsForCNode = 0;

    }


    function clearPendingRewardOfLP(address pair) external override nonReentrant {
        address vaultForLP = ICoFiXFactory(factory).getVaultForLP();
        require(msg.sender == vaultForLP, "CVaultForTrader: only vaultForLP");
        emit ClearPendingRewardOfLP(pendingRewardsForLP[pair]);
        pendingRewardsForLP[pair] = 0;

    }

    function getPendingRewardOfCNode() external override view returns (uint256) {
        return pendingRewardsForCNode;
    }

    function getPendingRewardOfLP(address pair) external override view returns (uint256) {
        return pendingRewardsForLP[pair];
    }

    function getCoFiRateCache(address pair) external override view returns (uint256 cofiRate, uint256 updatedBlock) {
        return (cofiRateCache[pair].cofiRate, cofiRateCache[pair].updatedBlock);
    }

}
