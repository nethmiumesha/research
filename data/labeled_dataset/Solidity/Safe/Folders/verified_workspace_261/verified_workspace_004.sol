pragma solidity ^0.5.0;
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";
contract ERC721Full is Initializable, ERC721, ERC721Enumerable, ERC721Metadata {
    uint256[50] private ______gap;
}