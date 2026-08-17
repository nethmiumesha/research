pragma solidity ^0.8.20;
contract ABSOLUTE {
    event ProofOfPast(
        address indexed creator,
        uint256 timestamp,
        bytes32 absoluteHash,
        bytes32 merkleRoot,
        string axiom
    );
    address public immutable CREATOR;
    uint256 public immutable PAST_TIMESTAMP;
    bytes32 public immutable ABSOLUTE_HASH;
    bytes32 public immutable MERKLE_ROOT;
    error NonTransferable();
    constructor(
        string memory manifesto,
        bytes32 merkleRoot
    ) {
        CREATOR = msg.sender;
        PAST_TIMESTAMP = block.timestamp;
        MERKLE_ROOT = merkleRoot;
        ABSOLUTE_HASH = keccak256(
            abi.encodePacked(
                CREATOR,
                PAST_TIMESTAMP,
                MERKLE_ROOT,
                manifesto,
                "x^0 = 1",
                "RWA ABSOLUTE"
            )
        );
        emit ProofOfPast(
            CREATOR,
            PAST_TIMESTAMP,
            ABSOLUTE_HASH,
            MERKLE_ROOT,
            "If it happened, it has value. x^0 = 1."
        );
    }
    function transfer(address, uint256) external pure {
        revert NonTransferable();
    }
    function approve(address, uint256) external pure {
        revert NonTransferable();
    }
    function setApprovalForAll(address, bool) external pure {
        revert NonTransferable();
    }
    function axiom() external pure returns (string memory) {
        return unicode"Past exists ⇒ Value exists ⇒ Transfer is undefined.";
    }
    function x0() external pure returns (uint256) {
        return 1;
    }
}