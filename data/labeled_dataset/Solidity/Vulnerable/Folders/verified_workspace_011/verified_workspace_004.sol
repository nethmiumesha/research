pragma solidity ^0.8.7;
import "./BaseStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../interfaces/IGenericLender.sol";
import "../interfaces/IOracle.sol";
contract StrategyEvents {
    event AddLender(address indexed lender);
    event RemoveLender(address indexed lender);
}