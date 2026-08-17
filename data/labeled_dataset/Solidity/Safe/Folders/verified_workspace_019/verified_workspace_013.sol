pragma solidity ^0.4.24;
import "./IERC721.sol";
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}