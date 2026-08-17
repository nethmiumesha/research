pragma solidity ^0.8.20;
interface IDAO_Voting {
    function emergencyWithdrawCrowdsale(uint256 amount) external payable;
    function burnStaking(uint256 amount) external;
}