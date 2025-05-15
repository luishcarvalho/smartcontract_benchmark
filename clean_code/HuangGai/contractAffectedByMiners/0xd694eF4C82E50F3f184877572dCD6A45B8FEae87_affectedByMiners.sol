














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


interface INest_3_OfferPrice {
    function transfer(address to, uint value) external returns (bool);








    function updateAndCheckPriceNow(address tokenAddress) external payable returns(uint256 ethAmount, uint256 erc20Amount, uint256 blockNum);







    function updateAndCheckPriceList(address tokenAddress, uint256 num) external payable returns (uint256[] memory);


    function activation() external;


    function checkPriceCostLeast(address tokenAddress) external view returns(uint256);


    function checkPriceCostMost(address tokenAddress) external view returns(uint256);


    function checkPriceCostSingle(address tokenAddress) external view returns(uint256);


    function checkUseNestPrice(address target) external view returns (bool);


    function checkBlocklist(address add) external view returns(bool);


    function checkDestructionAmount() external view returns(uint256);


    function checkEffectTime() external view returns (uint256);
}


interface ICoFiXKTable {
    function setK0(uint256 tIdx, uint256 sigmaIdx, int128 k0) external;
    function setK0InBatch(uint256[] memory tIdxs, uint256[] memory sigmaIdxs, int128[] memory k0s) external;
    function getK0(uint256 tIdx, uint256 sigmaIdx) external view returns (int128);
}



library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


interface ICoFiXController {

    event NewK(address token, int128 K, int128 sigma, uint256 T, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum, uint256 tIdx, uint256 sigmaIdx, int128 K0);
    event NewGovernance(address _new);
    event NewOracle(address _priceOracle);
    event NewKTable(address _kTable);
    event NewTimespan(uint256 _timeSpan);
    event NewKRefreshInterval(uint256 _interval);
    event NewKLimit(int128 maxK0);
    event NewGamma(int128 _gamma);
    event NewTheta(address token, uint32 theta);

    function addCaller(address caller) external;

    function queryOracle(address token, uint8 op, bytes memory data) external payable returns (uint256 k, uint256 ethAmount, uint256 erc20Amount, uint256 blockNum, uint256 theta);
}


interface INest_3_VoteFactory {

	function checkAddress(string calldata name) external view returns (address contractAddress);

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




contract CoFiXController is ICoFiXController {

    using SafeMath for uint256;

    enum CoFiX_OP { QUERY, MINT, BURN, SWAP_WITH_EXACT, SWAP_FOR_EXACT }

    uint256 constant public AONE = 1 ether;
    uint256 constant public K_BASE = 1E8;
    uint256 constant public NAVPS_BASE = 1E18;
    uint256 constant internal TIMESTAMP_MODULUS = 2**32;
    int128 constant internal SIGMA_STEP = 0x346DC5D638865;
    int128 constant internal ZERO_POINT_FIVE = 0x8000000000000000;
    uint256 constant internal K_EXPECTED_VALUE = 0.0025*1E8;

    uint256 constant internal C_BUYIN_ALPHA = 25700000000000;
    uint256 constant internal C_BUYIN_BETA = 854200000000;
    uint256 constant internal C_SELLOUT_ALPHA = 117100000000000;
    uint256 constant internal C_SELLOUT_BETA = 838600000000;

    mapping(address => uint32[3]) internal KInfoMap;
    mapping(address => bool) public callerAllowed;

    INest_3_VoteFactory public immutable voteFactory;


    address public governance;
    address public immutable nestToken;
    address public immutable factory;
    address public kTable;
    uint256 public timespan = 14;
    uint256 public kRefreshInterval = 5 minutes;
    uint256 public DESTRUCTION_AMOUNT = 0 ether;
    int128 public MAX_K0 = 0xCCCCCCCCCCCCD00;
    int128 public GAMMA = 0x8000000000000000;

    modifier onlyGovernance() {
        require(msg.sender == governance, "CoFiXCtrl: !governance");
        _;
    }

    constructor(address _voteFactory, address _nest, address _factory, address _kTable) public {
        governance = msg.sender;
        voteFactory = INest_3_VoteFactory(address(_voteFactory));
        nestToken = _nest;
        factory = _factory;
        kTable = _kTable;
    }

    receive() external payable {}


    function setGovernance(address _new) external onlyGovernance {
        governance = _new;
        emit NewGovernance(_new);
    }

    function setKTable(address _kTable) external onlyGovernance {
        kTable = _kTable;
        emit NewKTable(_kTable);
    }

    function setTimespan(uint256 _timeSpan) external onlyGovernance {
        timespan = _timeSpan;
        emit NewTimespan(_timeSpan);
    }

    function setKRefreshInterval(uint256 _interval) external onlyGovernance {
        kRefreshInterval = _interval;
        emit NewKRefreshInterval(_interval);
    }

    function setOracleDestructionAmount(uint256 _amount) external onlyGovernance {
        DESTRUCTION_AMOUNT = _amount;
    }

    function setKLimit(int128 maxK0) external onlyGovernance {
        MAX_K0 = maxK0;
        emit NewKLimit(maxK0);
    }

    function setGamma(int128 _gamma) external onlyGovernance {
        GAMMA = _gamma;
        emit NewGamma(_gamma);
    }

    function setTheta(address token, uint32 theta) external onlyGovernance {
        KInfoMap[token][2] = theta;
        emit NewTheta(token, theta);
    }


    function activate() external onlyGovernance {

        TransferHelper.safeTransferFrom(nestToken, msg.sender, address(this), DESTRUCTION_AMOUNT);
        address oracle = voteFactory.checkAddress("nest.v3.offerPrice");

        TransferHelper.safeApprove(nestToken, oracle, DESTRUCTION_AMOUNT);
        INest_3_OfferPrice(oracle).activation();
        TransferHelper.safeApprove(nestToken, oracle, 0);
    }

    function addCaller(address caller) external override {
        require(msg.sender == factory || msg.sender == governance, "CoFiXCtrl: only factory or gov");
        callerAllowed[caller] = true;
    }





    function queryOracle(address token, uint8 op, bytes memory data) external override payable returns (uint256 _k, uint256 _ethAmount, uint256 _erc20Amount, uint256 _blockNum, uint256 _theta) {
        require(callerAllowed[msg.sender], "CoFiXCtrl: caller not allowed");
        (_ethAmount, _erc20Amount, _blockNum) = getLatestPrice(token);
        CoFiX_OP cop = CoFiX_OP(op);
        uint256 impactCost;
        if (cop == CoFiX_OP.SWAP_WITH_EXACT) {
            impactCost = calcImpactCostFor_SWAP_WITH_EXACT(token, data, _ethAmount, _erc20Amount);
        } else if (cop == CoFiX_OP.SWAP_FOR_EXACT) {
            impactCost = calcImpactCostFor_SWAP_FOR_EXACT(token, data, _ethAmount, _erc20Amount);
         } else if (cop == CoFiX_OP.BURN) {
            impactCost = calcImpactCostFor_BURN(token, data, _ethAmount, _erc20Amount);
        }
        return (K_EXPECTED_VALUE.add(impactCost), _ethAmount, _erc20Amount, _blockNum, KInfoMap[token][2]);
    }

    function calcImpactCostFor_BURN(address token, bytes memory data, uint256 ethAmount, uint256 erc20Amount) public view returns (uint256 impactCost) {

        (, address outToken, , uint256 liquidity) = abi.decode(data, (address, address, address, uint256));

        uint256 navps = ICoFiXPair(msg.sender).getNAVPerShare(ethAmount, erc20Amount);
        uint256 vol = liquidity.mul(navps).div(NAVPS_BASE);
        if (block.coinbase != token) {

            return impactCostForBuyInETH(vol);
        }

        return impactCostForSellOutETH(vol);
    }

    function calcImpactCostFor_SWAP_WITH_EXACT(address token, bytes memory data, uint256 ethAmount, uint256 erc20Amount) public pure returns (uint256 impactCost) {
        (, address outToken, , uint256 amountIn) = abi.decode(data, (address, address, address, uint256));
        if (outToken != token) {


            uint256 vol = uint256(amountIn).mul(ethAmount).div(erc20Amount);
            return impactCostForBuyInETH(vol);
        }

        return impactCostForSellOutETH(amountIn);
    }

    function calcImpactCostFor_SWAP_FOR_EXACT(address token, bytes memory data, uint256 ethAmount, uint256 erc20Amount) public pure returns (uint256 impactCost) {
        (, address outToken, uint256 amountOutExact,) = abi.decode(data, (address, address, uint256, address));
        if (outToken != token) {

            return impactCostForBuyInETH(amountOutExact);
        }


        uint256 vol = uint256(amountOutExact).mul(ethAmount).div(erc20Amount);
        return impactCostForSellOutETH(vol);
    }






    function impactCostForBuyInETH(uint256 vol) public pure returns (uint256 impactCost) {
        if (vol < 500 ether) {
            return 0;
        }

        return C_BUYIN_ALPHA.add(C_BUYIN_BETA.mul(vol).div(1e18)).div(1e10);
    }


    function impactCostForSellOutETH(uint256 vol) public pure returns (uint256 impactCost) {
        if (vol < 500 ether) {
            return 0;
        }

        return (C_SELLOUT_BETA.mul(vol).div(1e18)).sub(C_SELLOUT_ALPHA).div(1e10);
    }













































































    function getKInfo(address token) external view returns (uint32 k, uint32 updatedAt, uint32 theta) {
        k = uint32(K_EXPECTED_VALUE);
        updatedAt = uint32(block.timestamp);
        theta = KInfoMap[token][2];
    }

    function getLatestPrice(address token) internal returns (uint256 _ethAmount, uint256 _erc20Amount, uint256 _blockNum) {
        uint256 _balanceBefore = address(this).balance;
        address oracle = voteFactory.checkAddress("nest.v3.offerPrice");
        uint256[] memory _rawPriceList = INest_3_OfferPrice(oracle).updateAndCheckPriceList{value: msg.value}(token, 1);
        require(_rawPriceList.length == 3, "CoFiXCtrl: bad price len");

        uint256 _T = block.number.sub(_rawPriceList[2]).mul(timespan);
        require(_T < 900, "CoFiXCtrl: oralce price outdated");
        uint256 oracleFeeChange = msg.value.sub(_balanceBefore.sub(address(this).balance));
        if (block.number > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
        return (_rawPriceList[0], _rawPriceList[1], _rawPriceList[2]);

    }


    function calcVariance(address token) internal returns (
        int128 _variance,
        uint256 _T,
        uint256 _ethAmount,
        uint256 _erc20Amount,
        uint256 _blockNum
    )
    {
        address oracle = voteFactory.checkAddress("nest.v3.offerPrice");

        uint256[] memory _rawPriceList = INest_3_OfferPrice(oracle).updateAndCheckPriceList{value: msg.value}(token, 50);
        require(_rawPriceList.length == 150, "CoFiXCtrl: bad price len");

        uint256[] memory _prices = new uint256[](50);
        for (uint256 i = 0; i < 50; i++) {

            _prices[i] = calcPrice(_rawPriceList[i*3], _rawPriceList[i*3+1]);
        }


        int128[] memory _stdSeq = new int128[](49);
        for (uint256 i = 0; i < 49; i++) {
            _stdSeq[i] = calcStdSeq(_prices[i], _prices[i+1], _prices[49], _rawPriceList[i*3+2], _rawPriceList[(i+1)*3+2]);
        }




        int128 _sumSq;
        int128 _sum;
        for (uint256 i = 0; i < 49; i++) {
            _sumSq = ABDKMath64x64.add(ABDKMath64x64.pow(_stdSeq[i], 2), _sumSq);
            _sum = ABDKMath64x64.add(_stdSeq[i], _sum);
        }
        _variance = ABDKMath64x64.sub(
            ABDKMath64x64.div(
                _sumSq,
                ABDKMath64x64.fromUInt(49)
            ),
            ABDKMath64x64.div(
                ABDKMath64x64.pow(_sum, 2),
                ABDKMath64x64.fromUInt(49*49)
            )
        );

        _T = block.number.sub(_rawPriceList[2]).mul(timespan);
        return (_variance, _T, _rawPriceList[0], _rawPriceList[1], _rawPriceList[2]);
    }

    function calcPrice(uint256 _ethAmount, uint256 _erc20Amount) internal pure returns (uint256) {
        return AONE.mul(_erc20Amount).div(_ethAmount);
    }





    function calcDiffRatio(uint256 p2, uint256 p1, uint256 p0) internal pure returns (int128) {
        int128 _p2 = ABDKMath64x64.fromUInt(p2);
        int128 _p1 = ABDKMath64x64.fromUInt(p1);
        int128 _p0 = ABDKMath64x64.fromUInt(p0);
        return ABDKMath64x64.div(ABDKMath64x64.sub(_p2, _p1), _p0);
    }






    function calcStdSeq(uint256 p2, uint256 p1, uint256 p0, uint256 bn2, uint256 bn1) internal pure returns (int128) {
        return ABDKMath64x64.div(
                calcDiffRatio(p2, p1, p0),
                ABDKMath64x64.sqrt(
                    ABDKMath64x64.fromUInt(bn2.sub(bn1))
                )
            );
    }
}
