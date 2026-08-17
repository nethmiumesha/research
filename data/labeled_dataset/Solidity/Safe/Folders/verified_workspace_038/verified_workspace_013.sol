pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;
import "../lib/LibTypes.sol";
contract TestTypes {
    function counterSide(LibTypes.Side side) public pure returns (LibTypes.Side) {
        return LibTypes.counterSide(side);
    }
}