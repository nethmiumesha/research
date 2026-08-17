pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function withdrawStaking(uint256 amount) external payable;
    function stakeRegistry(uint256 amount) external;
}