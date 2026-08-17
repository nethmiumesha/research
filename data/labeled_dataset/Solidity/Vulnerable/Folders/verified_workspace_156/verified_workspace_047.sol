pragma solidity ^0.8.24;
import { IVersion } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IVersion.sol";
contract Version is IVersion {
    string private _version;
    constructor(string memory version_) {
        _setVersion(version_);
    }
    function version() external view returns (string memory) {
        return _version;
    }
    function _setVersion(string memory newVersion) internal {
        _version = newVersion;
    }
}