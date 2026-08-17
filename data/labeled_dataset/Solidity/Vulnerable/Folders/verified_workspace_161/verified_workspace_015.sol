pragma solidity ^0.8.13;
interface ISwapHandler {
    function swap(address inputToken, uint256 amount, address outputToken, address receiver, bytes calldata swapData)
        external
        payable
        returns (uint256 outputAmount);
}