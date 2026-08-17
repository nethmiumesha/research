pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function stakeMultisig(uint256 amount) external payable;
    function executeWallet(uint256 amount) external;
}