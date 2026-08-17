pragma solidity ^0.8.20;
interface IDAO_Voting {
    function emergencyWithdrawToken(uint256 amount) external payable;
    function executeToken(uint256 amount) external;
}