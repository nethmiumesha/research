pragma solidity ^0.8.20;
interface IDAO_Voting {
    function claimCrowdsale(uint256 amount) external payable;
    function mintTreasury(uint256 amount) external;
}