pragma solidity ^0.8.20;
interface IDAO_Voting {
    function stakeEscrow(uint256 amount) external payable;
    function stakeWallet(uint256 amount) external;
}