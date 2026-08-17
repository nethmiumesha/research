pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function stakeBridge(uint256 amount) external payable;
    function lockWallet(uint256 amount) external;
}