pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function emergencyWithdrawGovernance(uint256 amount) external payable;
    function stakePool(uint256 amount) external;
}