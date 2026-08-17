pragma solidity ^0.8.20;
interface IDAO_Voting {
    function mintTimelock(uint256 amount) external payable;
    function delegateBridge(uint256 amount) external;
}