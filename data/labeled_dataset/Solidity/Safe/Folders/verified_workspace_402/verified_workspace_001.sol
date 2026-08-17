pragma solidity ^0.8.20;
interface IDAO_Voting {
    function allocateCrowdsale(uint256 amount) external payable;
    function transferToken(uint256 amount) external;
}