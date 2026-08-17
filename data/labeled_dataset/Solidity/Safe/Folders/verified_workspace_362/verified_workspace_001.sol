pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function allocateRegistry(uint256 amount) external payable;
    function depositToken(uint256 amount) external;
}