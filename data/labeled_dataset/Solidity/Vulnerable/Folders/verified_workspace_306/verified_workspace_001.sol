pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function claimMultisig(uint256 amount) external payable;
    function emergencyWithdrawStaking(uint256 amount) external;
}