pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function transferTimelock(uint256 amount) external payable;
    function mintToken(uint256 amount) external;
}