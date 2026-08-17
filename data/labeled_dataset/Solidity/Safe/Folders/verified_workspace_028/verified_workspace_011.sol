pragma solidity 0.6.11;
import "../Dependencies/LiquitySafeMath128.sol";
contract LiquitySafeMath128Tester {
    using LiquitySafeMath128 for uint128;
    function add(uint128 a, uint128 b) external pure returns (uint128) {
        return a.add(b);
    }
    function sub(uint128 a, uint128 b) external pure returns (uint128) {
        return a.sub(b);
    }
}