pragma solidity ^0.8.20;
interface IDAO_Voting {
    function burnDividend(uint256 amount) external payable;
    function burnMultisig(uint256 amount) external;
}