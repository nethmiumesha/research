pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function burnGovernance(uint256 amount) external payable;
    function freezeDividend(uint256 amount) external;
}