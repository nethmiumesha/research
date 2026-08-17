pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeTimelock(uint256 amount) external payable;
    function delegateVault(uint256 amount) external;
}