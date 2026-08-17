pragma solidity 0.5.8;
import "../STRGetter.sol";
contract MockSTRGetter is STRGetter {
    function newFunction() public pure returns (uint256) {
        return 99;
    }
}