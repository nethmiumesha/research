pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/OracleInterface.sol";
import "../interfaces/VotingInterface.sol";
abstract contract VotingInterfaceTesting is OracleInterface, VotingInterface, Testable {
    using FixedPoint for FixedPoint.Unsigned;
    event VoteCommitted(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData
    );
    event EncryptedVote(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        bytes encryptedVote
    );
    event VoteRevealed(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData,
        uint256 numTokens
    );
    event RewardsRetrieved(
        address indexed voter,
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        uint256 numTokens
    );
    event PriceRequestAdded(uint256 indexed roundId, bytes32 indexed identifier, uint256 time);
    event PriceResolved(
        uint256 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        int256 price,
        bytes ancillaryData
    );
    struct Round {
        uint256 snapshotId;
        FixedPoint.Unsigned inflationRate;
        FixedPoint.Unsigned gatPercentage;
        uint256 rewardsExpirationTime;
    }
    enum RequestStatus {
        NotRequested,
        Active,
        Resolved,
        Future
    }
    struct RequestState {
        RequestStatus status;
        uint256 lastVotingRound;
    }
    function rounds(uint256 roundId) public view virtual returns (Round memory);
    function getPriceRequestStatuses(VotingInterface.PendingRequest[] memory requests)
        public
        view
        virtual
        returns (RequestState[] memory);
    function getPendingPriceRequestsArray() external view virtual returns (bytes32[] memory);
}