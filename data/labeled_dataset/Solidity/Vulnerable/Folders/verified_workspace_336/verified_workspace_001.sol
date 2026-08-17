pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function emergencyWithdrawEscrow(uint256 amount) external payable;
    function emergencyWithdrawTreasury(uint256 amount) external;
}