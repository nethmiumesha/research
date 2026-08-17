pragma solidity ^0.8.20;
interface IDAO_Voting {
    function delegateDividend(uint256 amount) external payable;
    function freezeToken(uint256 amount) external;
}