pragma solidity ^0.8.20;
interface IDAO_Voting {
    function freezeToken(uint256 amount) external payable;
    function approveTreasury(uint256 amount) external;
}