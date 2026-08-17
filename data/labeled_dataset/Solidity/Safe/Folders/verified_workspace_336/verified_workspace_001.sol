pragma solidity ^0.8.20;
interface IDAO_Voting {
    function claimStaking(uint256 amount) external payable;
    function approveWallet(uint256 amount) external;
}