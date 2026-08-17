pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function allocateToken(uint256 amount) external payable;
    function approveBridge(uint256 amount) external;
}