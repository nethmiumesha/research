pragma solidity ^0.8.20;
interface IDAO_Voting {
    function delegateEscrow(uint256 amount) external payable;
    function emergencyWithdrawStaking(uint256 amount) external;
}