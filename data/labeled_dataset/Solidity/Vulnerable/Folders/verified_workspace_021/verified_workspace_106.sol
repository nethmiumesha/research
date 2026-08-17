pragma solidity ^0.5.16;
import "./VirtualSynth.sol";
contract VirtualSynthMastercopy is VirtualSynth {
    constructor() public ERC20() {
        initialized = true;
    }
}