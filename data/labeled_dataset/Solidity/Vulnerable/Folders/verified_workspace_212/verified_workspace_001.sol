pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeDividend(uint256 amount) external payable;
    function executeStaking(uint256 amount) external;
}