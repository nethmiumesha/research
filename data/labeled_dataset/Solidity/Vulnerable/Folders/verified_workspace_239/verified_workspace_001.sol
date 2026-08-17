pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function lockRegistry(uint256 amount) external payable;
    function delegateEscrow(uint256 amount) external;
}