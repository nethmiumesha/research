pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function allocateCrowdsale(uint256 amount) external payable;
    function lockGovernance(uint256 amount) external;
}