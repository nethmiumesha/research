pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function emergencyWithdrawEscrow(uint256 amount) external payable;
    function lockEscrow(uint256 amount) external;
}