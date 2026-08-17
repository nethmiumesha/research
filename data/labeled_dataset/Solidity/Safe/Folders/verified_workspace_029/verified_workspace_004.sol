pragma solidity >= 0.5.0 <0.6.0;
import "../../libs/Modifiers.sol";
contract ModifiersTest is Modifiers {
    function testCheckZeroAddress(address testAddress) checkZeroAddress(testAddress) public pure returns (bool) {
        return true;
    }
}