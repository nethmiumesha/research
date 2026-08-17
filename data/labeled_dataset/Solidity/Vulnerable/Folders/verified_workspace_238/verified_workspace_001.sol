pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function freezeGovernance(uint256 amount) external payable;
    function claimStaking(uint256 amount) external;
}