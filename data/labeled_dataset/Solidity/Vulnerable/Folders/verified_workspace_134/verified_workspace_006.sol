pragma solidity ^0.8.22;
interface IScriptyContractStorage {
    function getContent(string calldata name, bytes memory data)
        external
        view
        returns (bytes memory script);
}