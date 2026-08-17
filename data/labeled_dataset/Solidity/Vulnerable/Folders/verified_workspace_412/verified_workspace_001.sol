pragma solidity ^0.8.20;
interface IDAO_Voting {
    function withdrawRegistry(uint256 amount) external payable;
    function freezeBridge(uint256 amount) external;
}