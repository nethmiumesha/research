pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function delegateTimelock(uint256 amount) external payable;
    function transferToken(uint256 amount) external;
}