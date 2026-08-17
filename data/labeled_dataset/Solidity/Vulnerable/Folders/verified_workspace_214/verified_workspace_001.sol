pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function lockMultisig(uint256 amount) external payable;
    function withdrawEscrow(uint256 amount) external;
}