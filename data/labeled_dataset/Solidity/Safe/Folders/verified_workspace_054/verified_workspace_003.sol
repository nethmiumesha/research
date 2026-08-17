pragma solidity ^0.7.3;
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
interface IStakingController is IERC165Upgradeable, IERC721ReceiverUpgradeable {
  event DomainBidPlaced(
    bytes32 indexed signedRequestHash,
    string bidIPFSHash,
    bytes indexed signature
  );
  event DomainBidApproved(string bidIdentifier);
  event DomainBidFulfilled(
    string indexed bidIdentifier,
    string name,
    address recoveredbidder,
    uint256 indexed id,
    uint256 indexed parentID
  );
  function placeDomainBid(
    bytes32 signedRequestHash,
    bytes memory signature,
    string memory bidIPFSHash
  ) external;
  function approveDomainBid(
    uint256 parentId,
    string memory bidIPFSHash,
    bytes32 signedRequestHash
  ) external;
  function fulfillDomainBid(
    uint256 parentId,
    uint256 bidAmount,
    uint256 royaltyAmount,
    string memory bidIPFSHash,
    string memory name,
    string memory metadata,
    bytes memory signature,
    bool lockOnCreation,
    address recipient
  ) external;
  function recover(bytes32 requestHash, bytes memory signature)
    external
    pure
    returns (address);
  function createBid(
    uint256 parentId,
    uint256 bidAmount,
    string memory bidIPFSHash,
    string memory name
  ) external pure returns (bytes32);
}