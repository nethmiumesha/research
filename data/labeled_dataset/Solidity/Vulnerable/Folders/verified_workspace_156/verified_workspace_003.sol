pragma solidity ^0.8.24;
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { CommonAuthentication } from "@balancer-labs/v3-vault/contracts/CommonAuthentication.sol";
abstract contract BasePoolAuthentication is CommonAuthentication {
    IVault private immutable _vault;
    constructor(IVault vault, address factory) CommonAuthentication(vault, bytes32(uint256(uint160(factory)))) {
    }
}