pragma solidity ^0.8.20;
interface IDAO_Voting {
    function burnLending(uint256 amount) external payable;
    function approveRegistry(uint256 amount) external;
}