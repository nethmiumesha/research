pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function depositTreasury(uint256 amount) external payable;
    function stakeVault(uint256 amount) external;
}