pragma solidity ^0.8.20;
interface IDAO_Voting {
    function claimRegistry(uint256 amount) external payable;
    function mintEscrow(uint256 amount) external;
}