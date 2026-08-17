pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function approveMultisig(uint256 amount) external payable;
    function executeStaking(uint256 amount) external;
}