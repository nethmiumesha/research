pragma solidity ^0.8.4;
library LibERC6551 {
    error AccountCreationFailed();
    address internal constant REGISTRY = 0x000000006551c19487814612e58FE06813775758;
    bytes internal constant REGISTRY_BYTECODE =
        hex"608060405234801561001057600080fd5b50600436106100365760003560e01c8063246a00211461003b5780638a54c52f1461006a575b600080fd5b61004e6100493660046101b7565b61007d565b6040516001600160a01b03909116815260200160405180910390f35b61004e6100783660046101b7565b6100e1565b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b60015284601552605560002060601b60601c60005260206000f35b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b600152846015526055600020803b61018b578560b760556000f580610157576320188a596000526004601cfd5b80606c52508284887f79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf887226060606ca46020606cf35b8060601b60601c60005260206000f35b80356001600160a01b03811681146101b257600080fd5b919050565b600080600080600060a086880312156101cf57600080fd5b6101d88661019b565b945060208601359350604086013592506101f46060870161019b565b94979396509194608001359291505056fea2646970667358221220ea2fe53af507453c64dd7c1db05549fa47a298dfb825d6d11e1689856135f16764736f6c63430008110033";
    function initCode(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal pure returns (bytes memory result) {
        assembly {
            result := mload(0x40)
            mstore(add(result, 0xb7), tokenId_)
            mstore(add(result, 0x97), shr(96, shl(96, tokenContract_)))
            mstore(add(result, 0x77), chainId_)
            mstore(add(result, 0x57), salt_)
            mstore(add(result, 0x37), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(result, 0x28), implementation_)
            mstore(add(result, 0x14), 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
            mstore(result, 0xb7)
            mstore(0x40, add(result, 0xd7))
        }
    }
    function initCodeHash(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal pure returns (bytes32 result) {
        assembly {
            result := mload(0x40)
            mstore(add(result, 0xa3), tokenId_)
            mstore(add(result, 0x83), shr(96, shl(96, tokenContract_)))
            mstore(add(result, 0x63), chainId_)
            mstore(add(result, 0x43), salt_)
            mstore(add(result, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(result, 0x14), implementation_)
            mstore(result, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
            result := keccak256(add(result, 0x0c), 0xb7)
        }
    }
    function createAccount(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal returns (address result) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x14), implementation_)
            mstore(add(m, 0x34), salt_)
            mstore(add(m, 0x54), chainId_)
            mstore(add(m, 0x74), shr(96, shl(96, tokenContract_)))
            mstore(add(m, 0x94), tokenId_)
            mstore(m, 0x8a54c52f000000000000000000000000)
            if iszero(
                and(
                    gt(returndatasize(), 0x1f),
                    call(gas(), REGISTRY, 0, add(m, 0x10), 0xa4, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x20188a59)
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }
    function account(
        address implementation_,
        bytes32 salt_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) internal pure returns (address result) {
        assembly {
            result := mload(0x40)
            mstore(add(result, 0xa3), tokenId_)
            mstore(add(result, 0x83), shr(96, shl(96, tokenContract_)))
            mstore(add(result, 0x63), chainId_)
            mstore(add(result, 0x43), salt_)
            mstore(add(result, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
            mstore(add(result, 0x14), implementation_)
            mstore(result, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
            mstore8(0x00, 0xff)
            mstore(0x35, keccak256(add(result, 0x0c), 0xb7))
            mstore(0x01, shl(96, REGISTRY))
            mstore(0x15, salt_)
            result := keccak256(0x00, 0x55)
            mstore(0x35, 0)
        }
    }
    function isERC6551Account(address a, address expectedImplementation)
        internal
        view
        returns (bool result)
    {
        assembly {
            let m := mload(0x40)
            extcodecopy(a, add(m, 0x20), 0x0a, 0xa3)
            let implementation_ := shr(96, mload(add(m, 0x20)))
            if mul(
                extcodesize(implementation_),
                gt(eq(extcodesize(a), 0xad), shl(96, xor(expectedImplementation, implementation_)))
            ) {
                mstore(add(m, 0x23), 0x5af43d82803e903d91602b57fd5bf3)
                mstore(add(m, 0x14), implementation_)
                mstore(m, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
                mstore8(0x00, 0xff)
                mstore(0x35, keccak256(add(m, 0x0c), 0xb7))
                mstore(0x01, shl(96, REGISTRY))
                mstore(0x15, mload(add(m, 0x43)))
                result := iszero(shl(96, xor(a, keccak256(0x00, 0x55))))
                mstore(0x35, 0)
            }
        }
    }
    function implementation(address a) internal view returns (address result) {
        assembly {
            extcodecopy(a, 0x00, 0x0a, 0x14)
            result := shr(96, mload(0x00))
        }
    }
    function context(address a)
        internal
        view
        returns (bytes32 salt_, uint256 chainId_, address tokenContract_, uint256 tokenId_)
    {
        assembly {
            let m := mload(0x40)
            extcodecopy(a, 0x00, 0x2d, 0x80)
            salt_ := mload(0x00)
            chainId_ := mload(0x20)
            tokenContract_ := mload(0x40)
            tokenId_ := mload(0x60)
            mstore(0x40, m)
            mstore(0x60, 0)
        }
    }
    function salt(address a) internal view returns (bytes32 result) {
        assembly {
            extcodecopy(a, 0x00, 0x2d, 0x20)
            result := mload(0x00)
        }
    }
    function chainId(address a) internal view returns (uint256 result) {
        assembly {
            extcodecopy(a, 0x00, 0x4d, 0x20)
            result := mload(0x00)
        }
    }
    function tokenContract(address a) internal view returns (address result) {
        assembly {
            extcodecopy(a, 0x00, 0x6d, 0x20)
            result := mload(0x00)
        }
    }
    function tokenId(address a) internal view returns (uint256 result) {
        assembly {
            extcodecopy(a, 0x00, 0x8d, 0x20)
            result := mload(0x00)
        }
    }
}