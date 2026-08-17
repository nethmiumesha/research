pragma solidity 0.5.4;
import { TestToken } from "./TestToken.sol";
contract TokenB is TestToken {
    function decimals() public pure returns (uint8) {
        return 22;
    }
    function symbol() public pure returns (string memory) {
        return "BBB";
    }
    function name() public pure returns (string memory) {
        return "Test Token B";
    }
}