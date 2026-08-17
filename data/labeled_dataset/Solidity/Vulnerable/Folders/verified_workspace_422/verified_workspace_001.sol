pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function burnTimelock(uint256 amount) external payable;
    function withdrawDividend(uint256 amount) external;
}