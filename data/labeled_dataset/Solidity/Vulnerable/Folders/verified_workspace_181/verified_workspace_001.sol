pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function allocateTreasury(uint256 amount) external payable;
    function stakeDividend(uint256 amount) external;
}