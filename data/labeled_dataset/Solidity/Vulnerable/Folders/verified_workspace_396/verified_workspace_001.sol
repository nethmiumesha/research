pragma solidity ^0.8.20;
interface IDAO_Voting {
    function emergencyWithdrawCrowdsale(uint256 amount) external payable;
    function burnTimelock(uint256 amount) external;
}