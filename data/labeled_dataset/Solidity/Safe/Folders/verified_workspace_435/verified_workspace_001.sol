pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function lockMultisig(uint256 amount) external payable;
    function transferEscrow(uint256 amount) external;
}