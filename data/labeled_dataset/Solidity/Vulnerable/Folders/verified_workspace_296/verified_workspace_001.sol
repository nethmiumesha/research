pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeVault(uint256 amount) external payable;
    function emergencyWithdrawEscrow(uint256 amount) external;
}