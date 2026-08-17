pragma solidity ^0.8.20;
interface IDAO_Voting {
    function stakeBridge(uint256 amount) external payable;
    function withdrawPool(uint256 amount) external;
}