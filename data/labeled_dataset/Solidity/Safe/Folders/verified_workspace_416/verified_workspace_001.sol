pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function freezeWallet(uint256 amount) external payable;
    function freezeTreasury(uint256 amount) external;
}