pragma solidity 0.6.11;
import '../UniswapPairOracle.sol';
contract UniswapPairOracle_USDC_WETH is UniswapPairOracle {
    constructor(address factory, address tokenA, address tokenB, address owner_address, address timelock_address)
    UniswapPairOracle(factory, tokenA, tokenB, owner_address, timelock_address)
    public {}
}