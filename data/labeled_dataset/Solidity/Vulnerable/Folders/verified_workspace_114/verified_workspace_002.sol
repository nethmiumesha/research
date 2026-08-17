pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract CADIZ is ERC721Creator {
    constructor() ERC721Creator("COE - Collapse of the Element", "CADIZ") {}
}