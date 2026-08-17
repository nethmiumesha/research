pragma solidity ^0.8.0;
library VaultLibrary {
    function vaultFor(address manager, uint256 vaultId, bytes32 code) internal pure returns (address vault) {
        vault = address(uint160(uint(keccak256(abi.encodePacked(
                hex"ff",
                manager,
                keccak256(abi.encodePacked(vaultId)),
                code
            )))));
    }
}