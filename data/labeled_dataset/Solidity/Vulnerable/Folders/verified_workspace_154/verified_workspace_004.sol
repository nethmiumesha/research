pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract SFAF is ERC721Creator {
    constructor() ERC721Creator("Stories from Africa", "SFAF") {}
}