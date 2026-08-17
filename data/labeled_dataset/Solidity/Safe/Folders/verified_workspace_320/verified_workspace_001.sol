pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function emergencyWithdrawLending(uint256 amount) external payable;
    function claimEscrow(uint256 amount) external;
}