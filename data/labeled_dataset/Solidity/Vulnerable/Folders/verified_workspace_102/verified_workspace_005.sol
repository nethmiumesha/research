pragma solidity ^0.4.25;
import "../externals/ens/ENS.sol";
import "../externals/ens/PublicResolver.sol";
contract ENSResolvable {
    ENS private _ens;
    address private _ensRegistry;
    constructor(address _ensReg_) internal {
        _ensRegistry = _ensReg_;
        _ens = ENS(_ensRegistry);
    }
    function ensRegistry() external view returns (address) {
        return _ensRegistry;
    }
    function _ensResolve(bytes32 _nodeHash) internal view returns (address) {
        return PublicResolver(_ens.resolver(_nodeHash)).addr(_nodeHash);
    }
}