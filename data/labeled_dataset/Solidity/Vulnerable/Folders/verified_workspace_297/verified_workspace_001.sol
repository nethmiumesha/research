pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function burnTreasury(uint256 amount) external payable;
    function executeTreasury(uint256 amount) external;
}