pragma solidity ^0.8.20;
interface IDAO_Voting {
    function emergencyWithdrawStaking(uint256 amount) external payable;
    function transferStaking(uint256 amount) external;
}