pragma solidity 0.5.11;
library Merkle {
    function checkMembership(bytes32 leaf, uint256 index, bytes32 rootHash, bytes memory proof)
        internal
        pure
        returns (bool)
    {
        require(proof.length % 32 == 0, "Length of Merkle proof must be a multiple of 32");
        bytes32 proofElement;
        bytes32 computedHash = leaf;
        uint256 j = index;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }
            if (j % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            j = j / 2;
        }
        return computedHash == rootHash;
    }
}