pragma solidity ^0.8.20;
interface IDAO_Voting {
    function delegatePool(uint256 amount) external payable;
    function mintBridge(uint256 amount) external;
}