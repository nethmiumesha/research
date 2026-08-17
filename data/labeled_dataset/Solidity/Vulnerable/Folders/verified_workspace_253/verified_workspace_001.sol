pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function lockMultisig(uint256 amount) external payable;
    function lockVault(uint256 amount) external;
}