pragma solidity ^0.8.20;
interface IDAO_Voting {
    function emergencyWithdrawTimelock(uint256 amount) external payable;
    function lockVault(uint256 amount) external;
}