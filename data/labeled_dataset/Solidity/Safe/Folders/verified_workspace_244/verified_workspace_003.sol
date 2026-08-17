pragma solidity ^0.6.0;
import "./ABDKMath64x64.sol";
library YieldMath {
  function yDaiOutForDaiIn (
    uint128 daiReserves, uint128 yDAIReserves, uint128 daiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  internal pure returns (uint128) {
    int128 t = ABDKMath64x64.mul (k, ABDKMath64x64.fromUInt (timeTillMaturity));
    int128 a = ABDKMath64x64.sub (0x10000000000000000, ABDKMath64x64.mul (g, t));
    require (a > 0, "YieldMath: Too far from maturity");
    uint256 xdx = uint256 (daiReserves) + uint256 (daiAmount);
    require (xdx < 0x100000000000000000000000000000000, "YieldMath: Too much Dai in");
    uint256 sum =
      uint256 (pow (daiReserves, uint128 (a), 0x10000000000000000)) +
      uint256 (pow (yDAIReserves, uint128 (a), 0x10000000000000000)) -
      uint256 (pow (uint128(xdx), uint128 (a), 0x10000000000000000));
    require (sum < 0x100000000000000000000000000000000, "YieldMath: Insufficient yDAI reserves");
    uint256 result = yDAIReserves - pow (uint128 (sum), 0x10000000000000000, uint128 (a));
    require (result < 0x100000000000000000000000000000000, "YieldMath: Rounding induced error");
    return uint128 (result);
  }
  function daiOutForYDaiIn (
    uint128 daiReserves, uint128 yDAIReserves, uint128 yDAIAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  internal pure returns (uint128) {
    int128 t = ABDKMath64x64.mul (k, ABDKMath64x64.fromUInt (timeTillMaturity));
    int128 a = ABDKMath64x64.sub (0x10000000000000000, ABDKMath64x64.mul (g, t));
    require (a > 0, "YieldMath: Too far from maturity");
    uint256 ydy = uint256 (yDAIReserves) + uint256 (yDAIAmount);
    require (ydy < 0x100000000000000000000000000000000, "YieldMath: Too much yDai in");
    uint256 sum =
      uint256 (pow (uint128 (daiReserves), uint128 (a), 0x10000000000000000)) -
      uint256 (pow (uint128 (ydy), uint128 (a), 0x10000000000000000)) +
      uint256 (pow (yDAIReserves, uint128 (a), 0x10000000000000000));
    require (sum < 0x100000000000000000000000000000000, "YieldMath: Insufficient Dai reserves");
    uint256 result =
      daiReserves -
      pow (uint128 (sum), 0x10000000000000000, uint128 (a));
    require (result < 0x100000000000000000000000000000000, "YieldMath: Rounding induced error");
    return uint128 (result);
  }
  function yDaiInForDaiOut (
    uint128 daiReserves, uint128 yDAIReserves, uint128 daiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  internal pure returns (uint128) {
    int128 t = ABDKMath64x64.mul (k, ABDKMath64x64.fromUInt (timeTillMaturity));
    int128 a = ABDKMath64x64.sub (0x10000000000000000, ABDKMath64x64.mul (g, t));
    require (a > 0, "YieldMath: Too far from maturity");
    uint256 xdx = uint256 (daiReserves) - uint256 (daiAmount);
    require (xdx < 0x100000000000000000000000000000000, "YieldMath: Too much Dai out");
    uint256 sum =
      uint256 (pow (uint128 (daiReserves), uint128 (a), 0x10000000000000000)) +
      uint256 (pow (yDAIReserves, uint128 (a), 0x10000000000000000)) -
      uint256 (pow (uint128 (xdx), uint128 (a), 0x10000000000000000));
    require (sum < 0x100000000000000000000000000000000, "YieldMath: Resulting yDai reserves too high");
    uint256 result = pow (uint128 (sum), 0x10000000000000000, uint128 (a)) - yDAIReserves;
    require (result < 0x100000000000000000000000000000000, "YieldMath: Rounding induced error");
    return uint128 (result);
  }
  function daiInForYDaiOut (
    uint128 daiReserves, uint128 yDAIReserves, uint128 yDAIAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  internal pure returns (uint128) {
    int128 a = ABDKMath64x64.sub (0x10000000000000000, ABDKMath64x64.mul (g, ABDKMath64x64.mul (k, ABDKMath64x64.fromUInt (timeTillMaturity))));
    require (a > 0, "YieldMath: Too far from maturity");
    uint256 ydy = uint256 (yDAIReserves) - uint256 (yDAIAmount);
    require (ydy < 0x100000000000000000000000000000000, "YieldMath: Too much yDai out");
    uint256 sum =
      uint256 (pow (daiReserves, uint128 (a), 0x10000000000000000)) +
      uint256 (pow (yDAIReserves, uint128 (a), 0x10000000000000000)) -
      uint256 (pow (uint128 (ydy), uint128 (a), 0x10000000000000000));
    require (sum < 0x100000000000000000000000000000000, "YieldMath: Resulting Dai reserves too high");
    uint256 result =
      pow (uint128 (sum), 0x10000000000000000, uint128 (a)) -
      daiReserves;
    require (result < 0x100000000000000000000000000000000, "YieldMath: Rounding induced error");
    return uint128 (result);
  }
  function pow (uint128 x, uint128 y, uint128 z)
  internal pure returns (uint128) {
    require (z != 0);
    if (x == 0) {
      require (y != 0);
      return 0;
    } else {
      uint256 l =
        uint256 (0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - log_2 (x)) * y / z;
      if (l > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0;
      else return pow_2 (uint128 (0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - l));
    }
  }
  function log_2 (uint128 x)
  internal pure returns (uint128) {
    require (x != 0);
    uint b = x;
    uint l = 0xFE000000000000000000000000000000;
    if (b < 0x10000000000000000) {l -= 0x80000000000000000000000000000000; b <<= 64;}
    if (b < 0x1000000000000000000000000) {l -= 0x40000000000000000000000000000000; b <<= 32;}
    if (b < 0x10000000000000000000000000000) {l -= 0x20000000000000000000000000000000; b <<= 16;}
    if (b < 0x1000000000000000000000000000000) {l -= 0x10000000000000000000000000000000; b <<= 8;}
    if (b < 0x10000000000000000000000000000000) {l -= 0x8000000000000000000000000000000; b <<= 4;}
    if (b < 0x40000000000000000000000000000000) {l -= 0x4000000000000000000000000000000; b <<= 2;}
    if (b < 0x80000000000000000000000000000000) {l -= 0x2000000000000000000000000000000; b <<= 1;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000;}
    b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000;}
    return uint128 (l);
  }
  function pow_2 (uint128 x)
  internal pure returns (uint128) {
    uint r = 0x80000000000000000000000000000000;
    if (x & 0x1000000000000000000000000000000 > 0) r = r * 0xb504f333f9de6484597d89b3754abe9f >> 127;
    if (x & 0x800000000000000000000000000000 > 0) r = r * 0x9837f0518db8a96f46ad23182e42f6f6 >> 127;
    if (x & 0x400000000000000000000000000000 > 0) r = r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90 >> 127;
    if (x & 0x200000000000000000000000000000 > 0) r = r * 0x85aac367cc487b14c5c95b8c2154c1b2 >> 127;
    if (x & 0x100000000000000000000000000000 > 0) r = r * 0x82cd8698ac2ba1d73e2a475b46520bff >> 127;
    if (x & 0x80000000000000000000000000000 > 0) r = r * 0x8164d1f3bc0307737be56527bd14def4 >> 127;
    if (x & 0x40000000000000000000000000000 > 0) r = r * 0x80b1ed4fd999ab6c25335719b6e6fd20 >> 127;
    if (x & 0x20000000000000000000000000000 > 0) r = r * 0x8058d7d2d5e5f6b094d589f608ee4aa2 >> 127;
    if (x & 0x10000000000000000000000000000 > 0) r = r * 0x802c6436d0e04f50ff8ce94a6797b3ce >> 127;
    if (x & 0x8000000000000000000000000000 > 0) r = r * 0x8016302f174676283690dfe44d11d008 >> 127;
    if (x & 0x4000000000000000000000000000 > 0) r = r * 0x800b179c82028fd0945e54e2ae18f2f0 >> 127;
    if (x & 0x2000000000000000000000000000 > 0) r = r * 0x80058baf7fee3b5d1c718b38e549cb93 >> 127;
    if (x & 0x1000000000000000000000000000 > 0) r = r * 0x8002c5d00fdcfcb6b6566a58c048be1f >> 127;
    if (x & 0x800000000000000000000000000 > 0) r = r * 0x800162e61bed4a48e84c2e1a463473d9 >> 127;
    if (x & 0x400000000000000000000000000 > 0) r = r * 0x8000b17292f702a3aa22beacca949013 >> 127;
    if (x & 0x200000000000000000000000000 > 0) r = r * 0x800058b92abbae02030c5fa5256f41fe >> 127;
    if (x & 0x100000000000000000000000000 > 0) r = r * 0x80002c5c8dade4d71776c0f4dbea67d6 >> 127;
    if (x & 0x80000000000000000000000000 > 0) r = r * 0x8000162e44eaf636526be456600bdbe4 >> 127;
    if (x & 0x40000000000000000000000000 > 0) r = r * 0x80000b1721fa7c188307016c1cd4e8b6 >> 127;
    if (x & 0x20000000000000000000000000 > 0) r = r * 0x8000058b90de7e4cecfc487503488bb1 >> 127;
    if (x & 0x10000000000000000000000000 > 0) r = r * 0x800002c5c8678f36cbfce50a6de60b14 >> 127;
    if (x & 0x8000000000000000000000000 > 0) r = r * 0x80000162e431db9f80b2347b5d62e516 >> 127;
    if (x & 0x4000000000000000000000000 > 0) r = r * 0x800000b1721872d0c7b08cf1e0114152 >> 127;
    if (x & 0x2000000000000000000000000 > 0) r = r * 0x80000058b90c1aa8a5c3736cb77e8dff >> 127;
    if (x & 0x1000000000000000000000000 > 0) r = r * 0x8000002c5c8605a4635f2efc2362d978 >> 127;
    if (x & 0x800000000000000000000000 > 0) r = r * 0x800000162e4300e635cf4a109e3939bd >> 127;
    if (x & 0x400000000000000000000000 > 0) r = r * 0x8000000b17217ff81bef9c551590cf83 >> 127;
    if (x & 0x200000000000000000000000 > 0) r = r * 0x800000058b90bfdd4e39cd52c0cfa27c >> 127;
    if (x & 0x100000000000000000000000 > 0) r = r * 0x80000002c5c85fe6f72d669e0e76e411 >> 127;
    if (x & 0x80000000000000000000000 > 0) r = r * 0x8000000162e42ff18f9ad35186d0df28 >> 127;
    if (x & 0x40000000000000000000000 > 0) r = r * 0x80000000b17217f84cce71aa0dcfffe7 >> 127;
    if (x & 0x20000000000000000000000 > 0) r = r * 0x8000000058b90bfc07a77ad56ed22aaa >> 127;
    if (x & 0x10000000000000000000000 > 0) r = r * 0x800000002c5c85fdfc23cdead40da8d6 >> 127;
    if (x & 0x8000000000000000000000 > 0) r = r * 0x80000000162e42fefc25eb1571853a66 >> 127;
    if (x & 0x4000000000000000000000 > 0) r = r * 0x800000000b17217f7d97f692baacded5 >> 127;
    if (x & 0x2000000000000000000000 > 0) r = r * 0x80000000058b90bfbead3b8b5dd254d7 >> 127;
    if (x & 0x1000000000000000000000 > 0) r = r * 0x8000000002c5c85fdf4eedd62f084e67 >> 127;
    if (x & 0x800000000000000000000 > 0) r = r * 0x800000000162e42fefa58aef378bf586 >> 127;
    if (x & 0x400000000000000000000 > 0) r = r * 0x8000000000b17217f7d24a78a3c7ef02 >> 127;
    if (x & 0x200000000000000000000 > 0) r = r * 0x800000000058b90bfbe9067c93e474a6 >> 127;
    if (x & 0x100000000000000000000 > 0) r = r * 0x80000000002c5c85fdf47b8e5a72599f >> 127;
    r >>= 127 - (x >> 121);
    return uint128 (r);
  }
}