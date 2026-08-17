pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function depositTimelock(uint256 amount) external payable;
    function emergencyWithdrawMultisig(uint256 amount) external;
}