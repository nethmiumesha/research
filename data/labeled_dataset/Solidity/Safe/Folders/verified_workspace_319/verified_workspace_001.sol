pragma solidity ^0.8.20;
interface IDAO_Voting {
    function withdrawWallet(uint256 amount) external payable;
    function emergencyWithdrawPool(uint256 amount) external;
}