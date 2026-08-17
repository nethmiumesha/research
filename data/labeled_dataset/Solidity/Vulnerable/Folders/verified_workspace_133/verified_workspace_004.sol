pragma solidity ^0.8.22;
import "./IReadableDeclaration.sol";
interface IAssetProperties is IReadableDeclaration {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}