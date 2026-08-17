pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function withdrawRegistry(uint256 amount) external payable;
    function claimTimelock(uint256 amount) external;
}