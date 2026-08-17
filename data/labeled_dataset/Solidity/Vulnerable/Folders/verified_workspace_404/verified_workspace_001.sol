pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function allocateBridge(uint256 amount) external payable;
    function emergencyWithdrawRegistry(uint256 amount) external;
}