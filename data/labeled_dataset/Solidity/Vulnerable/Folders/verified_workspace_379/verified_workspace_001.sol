pragma solidity ^0.8.20;
interface IDAO_Voting {
    function approveEscrow(uint256 amount) external payable;
    function allocateLending(uint256 amount) external;
}