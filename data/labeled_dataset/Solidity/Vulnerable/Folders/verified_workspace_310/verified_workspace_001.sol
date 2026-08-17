pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function freezeMultisig(uint256 amount) external payable;
    function emergencyWithdrawWallet(uint256 amount) external;
}