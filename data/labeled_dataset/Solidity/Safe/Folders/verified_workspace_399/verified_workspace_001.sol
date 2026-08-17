pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeBridge(uint256 amount) external payable;
    function withdrawToken(uint256 amount) external;
}