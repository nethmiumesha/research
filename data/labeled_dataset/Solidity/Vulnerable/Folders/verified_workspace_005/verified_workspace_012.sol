pragma solidity ^0.8.10;
import "./FixedPoint96.sol";
import "./FullMath.sol";
import "./Math.sol";
import "./TickMath.sol";
library Volatility {
    struct PoolMetadata {
        uint32 oldestObservation;
        uint24 gamma0;
        uint24 gamma1;
        int24 tickSpacing;
    }
    struct PoolData {
        uint160 sqrtPriceX96;
        int24 currentTick;
        int24 arithmeticMeanTick;
        uint160 secondsPerLiquidityX128;
        uint32 oracleLookback;
        uint128 tickLiquidity;
    }
    struct FeeGrowthGlobals {
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
        uint32 timestamp;
    }
    function estimate24H(
        PoolMetadata memory metadata,
        PoolData memory data,
        FeeGrowthGlobals memory a,
        FeeGrowthGlobals memory b
    ) internal pure returns (uint256) {
        uint256 volumeGamma0Gamma1;
        {
            uint128 revenue0Gamma1 = computeRevenueGamma(
                a.feeGrowthGlobal0X128,
                b.feeGrowthGlobal0X128,
                data.secondsPerLiquidityX128,
                data.oracleLookback,
                metadata.gamma1
            );
            uint128 revenue1Gamma0 = computeRevenueGamma(
                a.feeGrowthGlobal1X128,
                b.feeGrowthGlobal1X128,
                data.secondsPerLiquidityX128,
                data.oracleLookback,
                metadata.gamma0
            );
            volumeGamma0Gamma1 = revenue1Gamma0 + amount0ToAmount1(revenue0Gamma1, data.arithmeticMeanTick);
        }
        uint128 sqrtTickTVLX32 = uint128(
            Math.sqrt(computeTickTVLX64(metadata.tickSpacing, data.currentTick, data.sqrtPriceX96, data.tickLiquidity))
        );
        uint48 timeAdjustmentX32 = uint48(Math.sqrt((uint256(1 days) << 64) / (b.timestamp - a.timestamp)));
        if (sqrtTickTVLX32 == 0) return 0;
        unchecked {
            return (uint256(2e18) * uint256(timeAdjustmentX32) * Math.sqrt(volumeGamma0Gamma1)) / sqrtTickTVLX32;
        }
    }
    function amount0ToAmount1(uint128 amount0, int24 tick) internal pure returns (uint256 amount1) {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        uint224 geometricMeanPriceX96 = uint224(FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96));
        amount1 = FullMath.mulDiv(amount0, geometricMeanPriceX96, FixedPoint96.Q96);
    }
    function computeRevenueGamma(
        uint256 feeGrowthGlobalAX128,
        uint256 feeGrowthGlobalBX128,
        uint160 secondsPerLiquidityX128,
        uint32 secondsAgo,
        uint24 gamma
    ) internal pure returns (uint128) {
        unchecked {
            uint256 temp;
            if (feeGrowthGlobalBX128 >= feeGrowthGlobalAX128) {
                temp = feeGrowthGlobalBX128 - feeGrowthGlobalAX128;
            } else {
                temp = type(uint256).max - feeGrowthGlobalAX128 + feeGrowthGlobalBX128;
            }
            temp = FullMath.mulDiv(temp, secondsAgo * gamma, secondsPerLiquidityX128 * 1e6);
            return temp > type(uint128).max ? type(uint128).max : uint128(temp);
        }
    }
    function computeTickTVLX64(
        int24 tickSpacing,
        int24 tick,
        uint160 sqrtPriceX96,
        uint128 liquidity
    ) internal pure returns (uint256 tickTVL) {
        tick = TickMath.floor(tick, tickSpacing);
        (uint256 value0, uint256 value1) = _getValuesOfLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tick),
            TickMath.getSqrtRatioAtTick(tick + tickSpacing),
            liquidity
        );
        tickTVL = (value0 + value1) << 64;
    }
    function _getValuesOfLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) private pure returns (uint256 value0, uint256 value1) {
        assert(sqrtRatioAX96 <= sqrtRatioX96 && sqrtRatioX96 <= sqrtRatioBX96);
        unchecked {
            uint224 numerator = uint224(FullMath.mulDiv(sqrtRatioX96, sqrtRatioBX96 - sqrtRatioX96, FixedPoint96.Q96));
            value0 = FullMath.mulDiv(liquidity, numerator, sqrtRatioBX96);
            value1 = FullMath.mulDiv(liquidity, sqrtRatioX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }
}