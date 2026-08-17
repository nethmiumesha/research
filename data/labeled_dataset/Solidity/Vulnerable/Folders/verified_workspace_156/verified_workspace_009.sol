pragma solidity ^0.8.24;
interface IAuthentication {
    error SenderNotAllowed();
    function getActionId(bytes4 selector) external view returns (bytes32 actionId);
}