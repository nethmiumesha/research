pragma solidity ^0.8.0;
import "./manifold/ERC721Creator.sol";
contract B3DSV is ERC721Creator {
    constructor() ERC721Creator("BIONIKA 3.0: DATA SOVEREIGNTY VAULT", "B3DSV") {}
}