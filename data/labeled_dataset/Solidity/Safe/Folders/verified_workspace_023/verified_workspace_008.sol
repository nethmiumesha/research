pragma solidity ^0.5.0;
import "./ERC721.sol";
import "../../access/roles/MinterRole.sol";
contract ERC721Mintable is ERC721, MinterRole {
    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}