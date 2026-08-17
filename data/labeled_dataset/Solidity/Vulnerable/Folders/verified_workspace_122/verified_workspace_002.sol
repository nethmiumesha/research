pragma solidity ^0.8.0;
import "./manifold/ERC1155Creator.sol";
contract ELEVATOR is ERC1155Creator {
    constructor() ERC1155Creator("Elevator", "ELEVATOR") {}
}