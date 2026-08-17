pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function depositStaking(uint256 amount) external payable;
    function freezeMultisig(uint256 amount) external;
}