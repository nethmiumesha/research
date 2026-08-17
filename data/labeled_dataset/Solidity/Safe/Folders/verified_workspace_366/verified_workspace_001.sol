pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function approveStaking(uint256 amount) external payable;
    function emergencyWithdrawGovernance(uint256 amount) external;
}