pragma solidity ^0.5.0;
import "./ERC721Metadata.sol";
import "../../access/roles/MinterRole.sol";
contract ERC721MetadataMintable is ERC721, ERC721Metadata, MinterRole {
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return true;
    }
}