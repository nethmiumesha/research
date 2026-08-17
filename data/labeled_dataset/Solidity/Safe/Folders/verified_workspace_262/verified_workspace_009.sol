pragma solidity 0.7.6;
pragma abicoder v2;
interface ISwapToPositionRatio {
    struct SwapToPositionInput {
        address token0Address;
        address token1Address;
        uint24 fee;
        uint256 amount0In;
        uint256 amount1In;
        int24 tickLower;
        int24 tickUpper;
    }
    function swapToPositionRatio(SwapToPositionInput memory inputs)
        external
        returns (uint256 amount0Out, uint256 amount1Out);
}