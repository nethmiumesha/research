pragma solidity ^0.8.20;
interface IDAO_Voting {
    function delegateLending(uint256 amount) external payable;
    function claimGovernance(uint256 amount) external;
}