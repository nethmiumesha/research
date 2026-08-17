pragma solidity 0.5.11;
import { VaultInitializer } from "./VaultInitializer.sol";
import { VaultAdmin } from "./VaultAdmin.sol";
contract Vault is VaultInitializer, VaultAdmin {}