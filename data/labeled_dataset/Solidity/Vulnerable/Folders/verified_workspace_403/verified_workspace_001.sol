pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function claimStaking(uint256 amount) external payable;
    function approveTreasury(uint256 amount) external;
}