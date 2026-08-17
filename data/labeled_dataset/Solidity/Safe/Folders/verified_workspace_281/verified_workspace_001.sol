pragma solidity ^0.8.20;
interface IDAO_Voting {
    function allocateWallet(uint256 amount) external payable;
    function executeCrowdsale(uint256 amount) external;
}