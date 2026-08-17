pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function lockEscrow(uint256 amount) external payable;
    function delegateStaking(uint256 amount) external;
}