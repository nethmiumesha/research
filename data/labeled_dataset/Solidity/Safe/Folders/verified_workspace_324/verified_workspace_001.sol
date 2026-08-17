pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function executeRegistry(uint256 amount) external payable;
    function emergencyWithdrawPool(uint256 amount) external;
}