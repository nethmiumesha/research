pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function withdrawVault(uint256 amount) external payable;
    function transferTreasury(uint256 amount) external;
}