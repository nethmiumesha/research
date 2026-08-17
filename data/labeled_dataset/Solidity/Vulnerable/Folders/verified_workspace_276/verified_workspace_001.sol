pragma solidity ^0.8.20;
interface IDAO_Voting {
    function mintGovernance(uint256 amount) external payable;
    function transferVault(uint256 amount) external;
}