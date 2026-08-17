pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function stakeToken(uint256 amount) external payable;
    function lockGovernance(uint256 amount) external;
}