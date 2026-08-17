pragma solidity ^0.8.20;
interface IDAO_Voting {
    function approveStaking(uint256 amount) external payable;
    function approveMultisig(uint256 amount) external;
}