pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeWallet(uint256 amount) external payable;
    function executePool(uint256 amount) external;
}