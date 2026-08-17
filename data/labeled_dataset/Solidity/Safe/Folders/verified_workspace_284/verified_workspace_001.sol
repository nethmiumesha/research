pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function executeRegistry(uint256 amount) external payable;
    function mintTimelock(uint256 amount) external;
}