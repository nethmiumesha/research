pragma solidity ^0.8.28;
import {LibERC6551} from "solady/accounts/LibERC6551.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IDelegateRegistry} from "./interfaces/IDelegateRegistry.sol";
contract GuardPledge is ERC721 {
    using LibString for uint256;
    event Pledged(uint256 indexed id, bool isShielded);
    error GuardPledge_NotOwner();
    error GuardPledge_InvalidProof();
    error GuardPledge_NoHiring();
    error GuardPledge_AlreadyPledged();
    error GuardPledge_NotPledged();
    error GuardPledge_TokenNotFound();
    bytes32 public constant ROOT = 0x1f295ed4990e3b54fb7eba836df9f8898962d57b62119e58b5e91646b2de019b;
    address public constant WARRIORS = 0x9690b63Eb85467BE5267A3603f770589Ab12Dc95;
    address public constant DELEGATE_REGISTRY = 0x00000000000000447e69651d841bD8D104Bed493;
    address public constant TBA_IMPLEMENTATION = 0x55266d75D1a14E4572138116aF39863Ed6596E7F;
    string public baseURI = "https:
    uint256 public pledgedWithShield;
    uint256 public pledgedWithoutShield;
    modifier onlyOwnerOfWarrior(uint256 id) {
        address tokenOwner = ERC721(WARRIORS).ownerOf(id);
        require(
            tokenOwner == msg.sender
                || IDelegateRegistry(DELEGATE_REGISTRY)
                    .checkDelegateForERC721(msg.sender, tokenOwner, address(WARRIORS), id, ""),
            GuardPledge_NotOwner()
        );
        _;
    }
    function pledgeWithShield(uint256 id, bytes32[] memory proof) external onlyOwnerOfWarrior(id) {
        require(!_exists(id), GuardPledge_AlreadyPledged());
        require(verify(proof, id), GuardPledge_InvalidProof());
        pledgedWithShield++;
        _mint(LibERC6551.account(TBA_IMPLEMENTATION, 0, 1, WARRIORS, id), id);
        emit Pledged(id, true);
    }
    function pledge(uint256 id) external onlyOwnerOfWarrior(id) {
        require(!_exists(id), GuardPledge_AlreadyPledged());
        require(pledgedWithShield > (pledgedWithoutShield + 1) * 100 / 66, GuardPledge_NoHiring());
        pledgedWithoutShield++;
        _mint(LibERC6551.account(TBA_IMPLEMENTATION, 0, 1, WARRIORS, id), id);
        emit Pledged(id, false);
    }
    function name() public pure override returns (string memory) {
        return "GuardPledge";
    }
    function symbol() public pure override returns (string memory) {
        return "PLEDGE";
    }
    function verify(bytes32[] memory proof, uint256 id) internal pure returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(id))));
        return MerkleProof.verify(proof, ROOT, leaf);
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), GuardPledge_TokenNotFound());
        return string.concat(baseURI, tokenId.toString());
    }
}