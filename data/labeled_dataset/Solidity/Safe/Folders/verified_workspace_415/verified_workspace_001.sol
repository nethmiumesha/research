pragma solidity ^0.8.20;
interface IDAO_Voting {
    function depositStaking(uint256 amount) external payable;
    function depositRegistry(uint256 amount) external;
}