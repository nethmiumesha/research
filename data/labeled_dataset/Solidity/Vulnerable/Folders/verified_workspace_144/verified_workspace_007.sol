pragma solidity ^0.8.0;
library RevertReasonForwarder {
    function reRevert() internal pure {
        assembly {
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}