pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function emergencyWithdrawGovernance(uint256 amount) external payable;
    function stakeCrowdsale(uint256 amount) external;
}