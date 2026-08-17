pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract BDS1 is ERC721Creator {
    constructor() ERC721Creator("BrettDrawsStuff 1/1s", "BDS1") {}
}