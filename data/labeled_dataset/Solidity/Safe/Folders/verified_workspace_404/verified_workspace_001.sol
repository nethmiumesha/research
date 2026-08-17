pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function lockVault(uint256 amount) external payable;
    function emergencyWithdrawMultisig(uint256 amount) external;
}