pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract ROSES is ERC721Creator {
    constructor() ERC721Creator("Rot, Then Bloom", "ROSES") {}
}