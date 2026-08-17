pragma solidity 0.6.11;
import "../Dependencies/LiquityMath.sol";
contract LiquityMathTester {
    function callDecPowTx(uint _base, uint _n) external returns (uint) {
        return LiquityMath._decPow(_base, _n);
    }
    function callDecPow(uint _base, uint _n) external pure returns (uint) {
        return LiquityMath._decPow(_base, _n);
    }
}