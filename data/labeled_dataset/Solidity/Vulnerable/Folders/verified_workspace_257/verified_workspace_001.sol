pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function delegateStaking(uint256 amount) external payable;
    function claimGovernance(uint256 amount) external;
}