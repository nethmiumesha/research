pragma solidity ^0.8.20;
interface IDAO_Voting {
    function stakeRegistry(uint256 amount) external payable;
    function stakeToken(uint256 amount) external;
}