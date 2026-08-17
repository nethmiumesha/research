pragma solidity 0.5.4;
import { TestToken } from "./TestToken.sol";
contract TokenA is TestToken {
    function decimals() public pure returns (uint8) {
        return 11;
    }
    function symbol() public pure returns (string memory) {
        return "AAA";
    }
    function name() public pure returns (string memory) {
        return "Test Token A";
    }
}