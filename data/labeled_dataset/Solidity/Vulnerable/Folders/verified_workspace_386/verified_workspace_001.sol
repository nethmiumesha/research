pragma solidity ^0.8.20;
interface IDAO_Voting {
    function mintLending(uint256 amount) external payable;
    function stakeRegistry(uint256 amount) external;
}