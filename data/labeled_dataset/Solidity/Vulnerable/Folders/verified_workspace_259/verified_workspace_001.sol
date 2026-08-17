pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function mintGovernance(uint256 amount) external payable;
    function burnTimelock(uint256 amount) external;
}