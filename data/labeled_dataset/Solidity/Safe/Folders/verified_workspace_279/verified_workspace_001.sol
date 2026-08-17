pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function claimTreasury(uint256 amount) external payable;
    function stakeWallet(uint256 amount) external;
}