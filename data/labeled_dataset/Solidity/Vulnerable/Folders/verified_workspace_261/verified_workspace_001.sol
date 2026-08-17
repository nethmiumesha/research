pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeEscrow(uint256 amount) external payable;
    function stakeDividend(uint256 amount) external;
}