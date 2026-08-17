pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function transferStaking(uint256 amount) external payable;
    function delegateWallet(uint256 amount) external;
}