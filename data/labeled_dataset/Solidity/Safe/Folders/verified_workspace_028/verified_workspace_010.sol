pragma solidity 0.6.11;
import "../Dependencies/LiquityMath.sol";
contract LiquityMathTester {
    function callMax(uint _a, uint _b) external pure returns (uint) {
        return LiquityMath._max(_a, _b);
    }
    function callDecPowTx(uint _base, uint _n) external returns (uint) {
        return LiquityMath._decPow(_base, _n);
    }
    function callDecPow(uint _base, uint _n) external pure returns (uint) {
        return LiquityMath._decPow(_base, _n);
    }
}