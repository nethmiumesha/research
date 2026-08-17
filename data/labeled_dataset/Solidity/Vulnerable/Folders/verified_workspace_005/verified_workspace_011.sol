pragma solidity ^0.8.0;
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./FixedPoint128.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";
library Uniswap {
    struct Position {
        int24 lower;
        int24 upper;
    }
    function poke(Position memory position, IUniswapV3Pool pool) internal {
        (uint128 liquidity, , , , ) = info(position, pool);
        if (liquidity == 0) return;
        pool.burn(position.lower, position.upper, 0);
    }
    function deposit(
        Position memory position,
        IUniswapV3Pool pool,
        uint128 liquidity
    ) internal {
        if (liquidity == 0) return;
        pool.mint(address(this), position.lower, position.upper, liquidity, "");
    }
    function withdraw(
        Position memory position,
        IUniswapV3Pool pool,
        uint128 liquidity
    )
        internal
        returns (
            uint256 burned0,
            uint256 burned1,
            uint256 earned0,
            uint256 earned1
        )
    {
        (burned0, burned1) = pool.burn(position.lower, position.upper, liquidity);
        (uint256 collected0, uint256 collected1) = pool.collect(
            address(this),
            position.lower,
            position.upper,
            type(uint128).max,
            type(uint128).max
        );
        unchecked {
            earned0 = collected0 - burned0;
            earned1 = collected1 - burned1;
        }
    }
    function collectableAmountsAsOfLastPoke(
        Position memory position,
        IUniswapV3Pool pool,
        uint160 sqrtPriceX96
    ) internal view returns (uint256, uint256) {
        (uint128 liquidity, , , uint128 earnable0, uint128 earnable1) = info(position, pool);
        (uint256 burnable0, uint256 burnable1) = amountsForLiquidity(position, sqrtPriceX96, liquidity);
        return (burnable0 + earnable0, burnable1 + earnable1);
    }
    function info(Position memory position, IUniswapV3Pool pool)
        internal
        view
        returns (
            uint128,
            uint256,
            uint256,
            uint128,
            uint128
        )
    {
        return pool.positions(keccak256(abi.encodePacked(address(this), position.lower, position.upper)));
    }
    function amountsForLiquidity(
        Position memory position,
        uint160 sqrtPriceX96,
        uint128 liquidity
    ) internal pure returns (uint256, uint256) {
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                liquidity
            );
    }
    function liquidityForAmounts(
        Position memory position,
        uint160 sqrtPriceX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128) {
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                amount0,
                amount1
            );
    }
    function liquidityForAmount0(Position memory position, uint256 amount0) internal pure returns (uint128) {
        return
            LiquidityAmounts.getLiquidityForAmount0(
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                amount0
            );
    }
    function liquidityForAmount1(Position memory position, uint256 amount1) internal pure returns (uint128) {
        return
            LiquidityAmounts.getLiquidityForAmount1(
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                amount1
            );
    }
}