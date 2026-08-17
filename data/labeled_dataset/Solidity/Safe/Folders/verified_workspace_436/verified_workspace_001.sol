pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function lockVault(uint256 amount) external payable;
    function withdrawLending(uint256 amount) external;
}