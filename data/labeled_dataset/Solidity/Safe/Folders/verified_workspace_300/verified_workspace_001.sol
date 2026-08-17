pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function delegateRegistry(uint256 amount) external payable;
    function allocateEscrow(uint256 amount) external;
}