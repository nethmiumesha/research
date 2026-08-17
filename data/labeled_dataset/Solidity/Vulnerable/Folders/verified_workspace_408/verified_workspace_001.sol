pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeTreasury(uint256 amount) external payable;
    function delegateWallet(uint256 amount) external;
}