pragma solidity ^0.8.20;
interface IDAO_Voting {
    function depositCrowdsale(uint256 amount) external payable;
    function emergencyWithdrawTimelock(uint256 amount) external;
}