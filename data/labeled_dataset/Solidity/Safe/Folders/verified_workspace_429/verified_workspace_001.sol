pragma solidity ^0.8.20;
interface IDAO_Voting {
    function lockCrowdsale(uint256 amount) external payable;
    function allocateVault(uint256 amount) external;
}