pragma solidity ^0.8.20;
interface IDAO_Voting {
    function depositTreasury(uint256 amount) external payable;
    function withdrawBridge(uint256 amount) external;
}