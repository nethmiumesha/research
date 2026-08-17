pragma solidity ^0.8.20;
interface IDAO_Voting {
    function lockEscrow(uint256 amount) external payable;
    function lockRegistry(uint256 amount) external;
}