pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function approveWallet(uint256 amount) external payable;
    function claimStaking(uint256 amount) external;
}