pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function lockRegistry(uint256 amount) external payable;
    function stakeTreasury(uint256 amount) external;
}