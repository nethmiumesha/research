pragma solidity ^0.8.20;
interface IDAO_Voting {
    function allocateRegistry(uint256 amount) external payable;
    function mintLending(uint256 amount) external;
}