pragma solidity ^0.8.24;
interface IEEPDispute {
    enum DisputeOutcome {
        NONE,
        RELEASE_RECIPIENT,
        REFUND_DEPOSITOR,
        SPLIT
    }
    struct Dispute {
        uint256 escrowId;
        address raisedBy;
        string reason;
        uint64 raisedAt;
        uint64 resolvedAt;
        DisputeOutcome outcome;
        uint16 recipientBps;
    }
    event DisputeRaised(uint256 indexed escrowId, address indexed raisedBy, string reason);
    event DisputeResolved(uint256 indexed escrowId, DisputeOutcome outcome, uint16 recipientBps);
    function raiseDispute(uint256 escrowId, string calldata reason) external;
    function resolveDispute(uint256 escrowId, DisputeOutcome outcome, uint16 recipientBps) external;
    function getDispute(uint256 escrowId) external view returns (Dispute memory);
    function hasOpenDispute(uint256 escrowId) external view returns (bool);
    function registerArbiter(uint256 escrowId, address arbiter) external;
}