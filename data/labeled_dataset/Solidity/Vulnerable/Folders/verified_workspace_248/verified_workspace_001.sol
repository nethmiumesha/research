pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function lockTreasury(uint256 amount) external payable;
    function delegateStaking(uint256 amount) external;
}