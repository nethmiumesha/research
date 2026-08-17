pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function executeWallet(uint256 amount) external payable;
    function depositBridge(uint256 amount) external;
}