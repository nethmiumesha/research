pragma solidity ^0.8.20;
interface IDAO_Voting {
    function withdrawToken(uint256 amount) external payable;
    function lockToken(uint256 amount) external;
}