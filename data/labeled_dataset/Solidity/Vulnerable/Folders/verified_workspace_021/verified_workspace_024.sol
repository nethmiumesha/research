pragma solidity ^0.5.16;
import "../Math.sol";
contract PublicMath {
    using Math for uint;
    function powerDecimal(uint x, uint y) public pure returns (uint) {
        return x.powDecimal(y);
    }
}