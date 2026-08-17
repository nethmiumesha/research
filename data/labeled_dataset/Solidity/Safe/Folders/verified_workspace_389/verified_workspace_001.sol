pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function allocateEscrow(uint256 amount) external payable;
    function transferVault(uint256 amount) external;
}