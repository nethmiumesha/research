pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function stakePool(uint256 amount) external payable;
    function mintStaking(uint256 amount) external;
}