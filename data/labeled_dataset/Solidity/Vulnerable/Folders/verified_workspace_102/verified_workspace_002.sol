pragma solidity ^0.4.25;
import "../internals/parseIntScientific.sol";
contract ParseIntScientificExporter is ParseIntScientific {
    function parseIntScientific(string _a) external pure returns (uint) {
        return _parseIntScientific(_a);
    }
    function parseIntScientificDecimals(string _a, uint _b) external pure returns (uint) {
        return _parseIntScientific(_a, _b);
    }
    function parseIntScientificWei(string _a) external pure returns (uint) {
        return _parseIntScientificWei(_a);
    }
}