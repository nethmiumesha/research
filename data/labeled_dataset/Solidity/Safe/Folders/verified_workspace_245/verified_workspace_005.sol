pragma solidity 0.6.12;
import { Proxy } from "./Proxy.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
contract UpgradeabilityProxy is Proxy {
    event Upgraded(address implementation);
    bytes32
        private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;
    constructor(address implementationContract) public {
        assert(
            IMPLEMENTATION_SLOT ==
                keccak256("org.zeppelinos.proxy.implementation")
        );
        _setImplementation(implementationContract);
    }
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}