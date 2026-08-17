pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function mintWallet(uint256 amount) external payable;
    function withdrawGovernance(uint256 amount) external;
}