pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function emergencyWithdrawVault(uint256 amount) external payable;
    function executeStaking(uint256 amount) external;
}