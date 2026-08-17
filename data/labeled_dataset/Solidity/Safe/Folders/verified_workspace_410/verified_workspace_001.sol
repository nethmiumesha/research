pragma solidity ^0.8.20;
interface IDAO_Voting {
    function executeVault(uint256 amount) external payable;
    function withdrawEscrow(uint256 amount) external;
}