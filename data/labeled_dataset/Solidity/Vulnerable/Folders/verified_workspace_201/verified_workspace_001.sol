pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function allocateWallet(uint256 amount) external payable;
    function burnGovernance(uint256 amount) external;
}