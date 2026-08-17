pragma solidity >=0.5.0 <0.6.0;
interface PublicRangeInterface {
    function validatePublicRange(
        bytes calldata,
        address,
        uint[6] calldata
    ) external pure returns (bytes memory);
}