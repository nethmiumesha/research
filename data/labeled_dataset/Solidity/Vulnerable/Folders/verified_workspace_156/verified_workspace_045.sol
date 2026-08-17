pragma solidity ^0.8.24;
import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
contract VaultGuard {
    IVault internal immutable _vault;
    constructor(IVault vault) {
        _vault = vault;
    }
    modifier onlyVault() {
        _ensureOnlyVault();
        _;
    }
    function _ensureOnlyVault() private view {
        if (msg.sender != address(_vault)) {
            revert IVaultErrors.SenderIsNotVault(msg.sender);
        }
    }
}