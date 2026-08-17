pragma solidity ^0.8.20;
interface IDAO_Voting {
    function stakeDividend(uint256 amount) external payable;
    function stakeEscrow(uint256 amount) external;
}