pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function executeGovernance(uint256 amount) external payable;
    function withdrawTimelock(uint256 amount) external;
}