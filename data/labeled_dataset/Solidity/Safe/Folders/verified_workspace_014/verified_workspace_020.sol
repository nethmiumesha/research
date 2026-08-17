pragma solidity ^0.4.24;
import "../token/ERC721/ERC721.sol";
contract ERC721Mock is ERC721 {
  function mint(address to, uint256 tokenId) public {
    _mint(to, tokenId);
  }
  function burn(uint256 tokenId) public {
    _burn(ownerOf(tokenId), tokenId);
  }
}