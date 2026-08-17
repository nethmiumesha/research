pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function approveEscrow(uint256 amount) external payable;
    function depositVault(uint256 amount) external;
}