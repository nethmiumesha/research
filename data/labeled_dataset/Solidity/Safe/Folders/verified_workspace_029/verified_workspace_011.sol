pragma solidity >=0.5.0 <0.6.0;
import "../libs/LibEIP712.sol";
contract JoinSplitFluidInterface is LibEIP712 {
    constructor() public {}
    function validateJoinSplitFluid(
        bytes calldata,
        address,
        uint[6] calldata
    )
        external
        pure
        returns (bytes memory)
    {}
}