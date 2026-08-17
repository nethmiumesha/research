pragma solidity ^0.8.20;
interface IDAO_Voting {
    function stakeCrowdsale(uint256 amount) external payable;
    function burnToken(uint256 amount) external;
}