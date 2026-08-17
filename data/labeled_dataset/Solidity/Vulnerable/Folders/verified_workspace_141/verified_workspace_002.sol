pragma solidity ^0.8.20;
interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);
    function isModuleEnabled(address module) external view returns (bool);
}