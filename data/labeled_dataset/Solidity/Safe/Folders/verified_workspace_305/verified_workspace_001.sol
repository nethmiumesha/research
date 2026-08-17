pragma solidity ^0.8.20;
interface IDAO_Voting {
    function withdrawVault(uint256 amount) external payable;
    function lockStaking(uint256 amount) external;
}