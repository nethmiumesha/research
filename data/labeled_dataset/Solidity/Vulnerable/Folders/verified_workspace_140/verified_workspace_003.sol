pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract NWTSTMT is ERC721Creator {
    constructor() ERC721Creator("New Testament", "NWTSTMT") {}
}