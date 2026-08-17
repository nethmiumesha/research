pragma solidity ^0.8.24;
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { Authentication } from "@balancer-labs/v3-solidity-utils/contracts/helpers/Authentication.sol";
abstract contract CommonAuthentication is Authentication {
    error VaultNotSet();
    IVault private immutable _vault;
    modifier onlySwapFeeManagerOrGovernance(address pool) {
        address roleAddress = _vault.getPoolRoleAccounts(pool).swapFeeManager;
        _ensureAuthenticatedByExclusiveRole(pool, roleAddress);
        _;
    }
    constructor(IVault vault, bytes32 actionIdDisambiguator) Authentication(actionIdDisambiguator) {
        if (address(vault) == address(0)) {
            revert VaultNotSet();
        }
        _vault = vault;
    }
    function _getVault() internal view returns (IVault) {
        return _vault;
    }
    function _canPerform(bytes32 actionId, address user) internal view override returns (bool) {
        return _vault.getAuthorizer().canPerform(actionId, user, address(this));
    }
    function _canPerform(bytes32 actionId, address account, address where) internal view returns (bool) {
        return _vault.getAuthorizer().canPerform(actionId, account, where);
    }
    function _ensureAuthenticatedByExclusiveRole(address where, address roleAccount) internal view {
        if (roleAccount == address(0)) {
            if (_canPerform(getActionId(msg.sig), msg.sender, where) == false) {
                revert SenderNotAllowed();
            }
        } else if (msg.sender != roleAccount) {
            revert SenderNotAllowed();
        }
    }
    function _ensureAuthenticatedByRole(address where, address roleAccount) internal view {
        if (msg.sender != roleAccount) {
            if (_canPerform(getActionId(msg.sig), msg.sender, where) == false) {
                revert SenderNotAllowed();
            }
        }
    }
}