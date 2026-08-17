pragma solidity ^0.8.24;
interface IAuthorizer {
    function canPerform(bytes32 actionId, address account, address where) external view returns (bool success);
}