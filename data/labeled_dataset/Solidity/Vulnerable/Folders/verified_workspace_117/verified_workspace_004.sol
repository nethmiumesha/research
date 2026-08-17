pragma solidity ^0.8.24;
interface ISwapAdapter {
    function swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external returns (uint256 amountOut);
}