pragma solidity ^0.8.4;
contract MockPCVSwapper {
    bool public swapped;
    function swap() public {
        swapped = true;
    }
}