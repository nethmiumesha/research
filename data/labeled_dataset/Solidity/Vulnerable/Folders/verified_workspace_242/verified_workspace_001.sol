pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function executeToken(uint256 amount) external payable;
    function depositStaking(uint256 amount) external;
}