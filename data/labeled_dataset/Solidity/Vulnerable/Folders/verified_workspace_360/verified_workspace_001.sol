pragma solidity ^0.8.20;
interface IDAO_Voting {
    function depositTimelock(uint256 amount) external payable;
    function depositPool(uint256 amount) external;
}