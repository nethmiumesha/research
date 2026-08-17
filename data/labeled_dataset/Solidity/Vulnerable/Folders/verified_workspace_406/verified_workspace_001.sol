pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function freezeStaking(uint256 amount) external payable;
    function delegateLending(uint256 amount) external;
}