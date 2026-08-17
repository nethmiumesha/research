pragma solidity ^0.8.20;
interface IDAO_Voting {
    function claimDividend(uint256 amount) external payable;
    function burnDividend(uint256 amount) external;
}