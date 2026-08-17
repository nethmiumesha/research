pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function freezeTimelock(uint256 amount) external payable;
    function mintBridge(uint256 amount) external;
}