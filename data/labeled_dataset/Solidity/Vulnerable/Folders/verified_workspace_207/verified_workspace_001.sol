pragma solidity ^0.8.20;
interface IDAO_Voting {
    function withdrawEscrow(uint256 amount) external payable;
    function depositStaking(uint256 amount) external;
}