pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function lockStaking(uint256 amount) external payable;
    function stakeLending(uint256 amount) external;
}