pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeWallet(uint256 amount) external payable;
    function withdrawWallet(uint256 amount) external;
}