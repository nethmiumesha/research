pragma solidity ^0.8.0;
import '../UniswapPairOracle.sol';
contract UniswapPairOracle_USDT_WETH is UniswapPairOracle {
    constructor(
        address factory,
        address tokenA,
        address tokenB,
        address ownerAddress,
        address timelock_address
    )
        UniswapPairOracle(
            factory,
            tokenA,
            tokenB,
            ownerAddress,
            timelock_address
        )
    {}
}