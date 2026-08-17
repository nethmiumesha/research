pragma solidity ^0.8.20;
interface IDAO_Voting {
    function withdrawDividend(uint256 amount) external payable;
    function transferWallet(uint256 amount) external;
}