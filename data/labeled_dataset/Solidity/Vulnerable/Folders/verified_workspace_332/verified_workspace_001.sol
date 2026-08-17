pragma solidity ^0.8.20;
interface IDAO_Voting {
    function burnEscrow(uint256 amount) external payable;
    function lockTimelock(uint256 amount) external;
}