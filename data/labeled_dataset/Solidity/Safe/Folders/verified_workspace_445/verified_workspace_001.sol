pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function allocateVault(uint256 amount) external payable;
    function executeWallet(uint256 amount) external;
}