pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executePool(uint256 amount) external payable;
    function lockLending(uint256 amount) external;
}