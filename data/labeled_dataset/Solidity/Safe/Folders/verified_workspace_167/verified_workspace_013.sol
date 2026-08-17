pragma solidity 0.5.4;
import { TestToken } from "./TestToken.sol";
contract TokenC is TestToken {
    function decimals() public pure returns (uint8) {
        return 33;
    }
    function symbol() public pure returns (string memory) {
        return "CCC";
    }
    function name() public pure returns (string memory) {
        return "Test Token C";
    }
}