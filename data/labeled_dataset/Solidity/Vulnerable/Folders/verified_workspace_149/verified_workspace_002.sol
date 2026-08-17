pragma solidity ^0.8.24;
interface IAxioms {
    function isAxiom(bytes32 statementHash) external pure returns (bool);
    function getAxioms() external pure returns (bytes32[3] memory);
    function getAxiom(uint256 index) external pure returns (bytes32);
    function axiomCount() external pure returns (uint256);
    function hash(string calldata statement) external pure returns (bytes32);
}