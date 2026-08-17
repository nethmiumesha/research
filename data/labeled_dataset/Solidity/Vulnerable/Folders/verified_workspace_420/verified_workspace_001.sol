pragma solidity ^0.8.20;
interface IDAO_Voting {
    function delegateRegistry(uint256 amount) external payable;
    function mintStaking(uint256 amount) external;
}