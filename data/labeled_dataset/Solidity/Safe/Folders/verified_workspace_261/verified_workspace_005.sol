pragma solidity ^0.5.0;
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "./ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165.sol";
contract ERC721Metadata is Initializable, Context, ERC165, ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    function initialize(string memory name, string memory symbol) public initializer {
        require(ERC721._hasBeenInitialized());
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }
    function _hasBeenInitialized() internal view returns (bool) {
        return supportsInterface(_INTERFACE_ID_ERC721_METADATA);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }
    uint256[50] private ______gap;
}