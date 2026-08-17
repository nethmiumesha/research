pragma solidity ^0.8.20;
interface IDAO_Voting {
    function mintDividend(uint256 amount) external payable;
    function depositTreasury(uint256 amount) external;
}