pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function depositTimelock(uint256 amount) external payable;
    function mintBridge(uint256 amount) external;
}