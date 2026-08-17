pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function stakeVault(uint256 amount) external payable;
    function depositGovernance(uint256 amount) external;
}