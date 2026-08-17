pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function approveTreasury(uint256 amount) external payable;
    function claimMultisig(uint256 amount) external;
}