pragma solidity ^0.5.0 || ^0.6.0;
import "../pool/YieldMath.sol";
contract YieldMathDAIWrapper {
  function yDaiOutForDaiIn (
    uint128 daiReserves, uint128 yDAIReserves, uint128 daiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.yDaiOutForDaiIn (
        daiReserves, yDAIReserves, daiAmount, timeTillMaturity, k, g));
  }
  function daiOutForYDaiIn (
    uint128 daiReserves, uint128 yDAIReserves, uint128 yDAIAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.daiOutForYDaiIn (
        daiReserves, yDAIReserves, yDAIAmount, timeTillMaturity, k, g));
  }
  function yDaiInForDaiOut (
    uint128 daiReserves, uint128 yDAIReserves, uint128 daiAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.yDaiInForDaiOut (
        daiReserves, yDAIReserves, daiAmount, timeTillMaturity, k, g));
  }
  function daiInForYDaiOut (
    uint128 daiReserves, uint128 yDAIReserves, uint128 yDAIAmount,
    uint128 timeTillMaturity, int128 k, int128 g)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.daiInForYDaiOut (
        daiReserves, yDAIReserves, yDAIAmount, timeTillMaturity, k, g));
  }
  function pow (uint128 x, uint128 y, uint128 z)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.pow (x, y, z));
  }
  function log_2 (uint128 x)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.log_2 (x));
  }
  function pow_2 (uint128 x)
  public pure returns (bool, uint128) {
    return (
      true,
      YieldMath.pow_2 (x));
  }
}