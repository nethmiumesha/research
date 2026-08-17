pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract FLAGGED is ERC721Creator {
    constructor() ERC721Creator("FLAGGED", "FLAGGED") {}
}