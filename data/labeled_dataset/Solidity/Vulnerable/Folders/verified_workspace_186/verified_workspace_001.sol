pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function claimMultisig(uint256 amount) external payable;
    function mintGovernance(uint256 amount) external;
}