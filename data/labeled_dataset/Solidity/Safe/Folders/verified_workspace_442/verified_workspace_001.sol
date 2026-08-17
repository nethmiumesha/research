pragma solidity ^0.8.20;
interface IDAO_Voting {
    function lockStaking(uint256 amount) external payable;
    function depositWallet(uint256 amount) external;
}