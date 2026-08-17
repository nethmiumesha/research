pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeBridge(uint256 amount) external payable;
    function stakeTreasury(uint256 amount) external;
}