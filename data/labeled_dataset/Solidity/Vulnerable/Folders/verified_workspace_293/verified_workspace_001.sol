pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function burnRegistry(uint256 amount) external payable;
    function approveMultisig(uint256 amount) external;
}