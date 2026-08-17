pragma solidity ^0.8.20;
interface IDAO_Voting {
    function stakeToken(uint256 amount) external payable;
    function claimPool(uint256 amount) external;
}