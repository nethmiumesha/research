pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeLending(uint256 amount) external payable;
    function transferCrowdsale(uint256 amount) external;
}