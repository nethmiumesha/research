pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract CM is ERC721Creator {
    constructor() ERC721Creator("Crow Motion", "CM") {}
}