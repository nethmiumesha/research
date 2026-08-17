pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function transferGovernance(uint256 amount) external payable;
    function executeRegistry(uint256 amount) external;
}