pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function delegateBridge(uint256 amount) external payable;
    function allocateMultisig(uint256 amount) external;
}