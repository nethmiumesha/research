pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function delegateTreasury(uint256 amount) external payable;
    function freezeLending(uint256 amount) external;
}