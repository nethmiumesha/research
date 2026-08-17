pragma solidity ^0.8.24;
interface IResolver {
    error RESOLVED_TO_ZERO_ADDRESS();
    function resolve(
        uint64 _chainId,
        bytes32 _name,
        bool _allowZeroAddress
    )
        external
        view
        returns (address);
}