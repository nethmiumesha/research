pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function emergencyWithdrawTreasury(uint256 amount) external payable;
    function transferGovernance(uint256 amount) external;
}