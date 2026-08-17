pragma solidity ^0.8.3;
import "../interfaces/IERC20.sol";
import "../interfaces/IVotingVault.sol";
import "../interfaces/ILockingVault.sol";
import "../libraries/Authorizable.sol";
import "../libraries/MerkleRewards.sol";
contract OptimisticRewards is MerkleRewards, Authorizable, IVotingVault {
    bytes32 public pendingRoot;
    uint256 public proposalTime;
    address public proposer;
    uint256 public challengePeriod = 60 * 60 * 24 * 7;
    constructor(
        address _governance,
        bytes32 _startingRoot,
        address _proposer,
        address _revoker,
        IERC20 _token,
        ILockingVault _lockingVault
    ) MerkleRewards(_startingRoot, _token, _lockingVault) {
        proposer = _proposer;
        _authorize(_revoker);
        setOwner(_governance);
    }
    function proposeRewards(bytes32 newRoot) external {
        require(msg.sender == proposer, "Not proposer");
        if (
            pendingRoot != bytes32(0) &&
            proposalTime != 0 &&
            block.timestamp > proposalTime + challengePeriod
        ) {
            rewardsRoot = pendingRoot;
        }
        pendingRoot = newRoot;
        proposalTime = block.timestamp;
    }
    function queryVotePower(
        address user,
        uint256,
        bytes calldata extraData
    ) external override returns (uint256) {
        (uint256 totalGrant, bytes32[] memory proof) =
            abi.decode(extraData, (uint256, bytes32[]));
        bytes32 leafHash = keccak256(abi.encodePacked(user, totalGrant));
        require(
            MerkleProof.verify(proof, rewardsRoot, leafHash),
            "Invalid Proof"
        );
        uint256 votes = totalGrant - claimed[user];
        return (votes);
    }
    function challengeRewards() external onlyAuthorized {
        pendingRoot = bytes32(0);
        proposalTime = 0;
    }
    function setProposer(address _proposer) external onlyOwner {
        proposer = _proposer;
    }
    function setChallengePeriod(uint256 _challengePeriod) external onlyOwner {
        challengePeriod = _challengePeriod;
    }
}