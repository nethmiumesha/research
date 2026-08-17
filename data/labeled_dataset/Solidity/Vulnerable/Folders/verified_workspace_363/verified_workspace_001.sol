pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function executeDividend(uint256 amount) external payable;
    function claimGovernance(uint256 amount) external;
}