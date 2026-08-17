pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function withdrawRegistry(uint256 amount) external payable;
    function burnToken(uint256 amount) external;
}