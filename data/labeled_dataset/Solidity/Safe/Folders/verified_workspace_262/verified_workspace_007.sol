pragma solidity 0.7.6;
pragma abicoder v2;
interface IMint {
    struct MintInput {
        address token0Address;
        address token1Address;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }
    function mint(MintInput calldata inputs)
        external
        returns (
            uint256 tokenId,
            uint256 amount0Deposited,
            uint256 amount1Deposited
        );
}