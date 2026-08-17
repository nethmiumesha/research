pragma solidity ^0.8.24;
import { IEEPDispute } from "./interfaces/IEEPDispute.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
contract EEPDispute is IEEPDispute, Ownable {
    mapping(uint256 => Dispute) private _disputes;
    mapping(uint256 => address) public arbiters;
    address public escrowContract;
    modifier onlyEscrow() {
        require(msg.sender == escrowContract, "Dispute: caller is not EEPEscrow");
        _;
    }
    modifier disputeExists(uint256 escrowId) {
        require(_disputes[escrowId].raisedAt != 0, "Dispute: no dispute for escrow");
        _;
    }
    modifier notResolved(uint256 escrowId) {
        require(
            _disputes[escrowId].outcome == DisputeOutcome.NONE,
            "Dispute: already resolved"
        );
        _;
    }
    constructor(address initialOwner) Ownable(initialOwner) {}
    function setEscrowContract(address _escrow) external onlyOwner {
        require(escrowContract == address(0), "Dispute: escrow already set");
        require(_escrow != address(0), "Dispute: zero address");
        escrowContract = _escrow;
    }
    function raiseDispute(uint256 escrowId, string calldata reason) external override onlyEscrow {
        require(_disputes[escrowId].raisedAt == 0, "Dispute: dispute already open");
        _disputes[escrowId] = Dispute({
            escrowId: escrowId,
            raisedBy: tx.origin,
            reason: reason,
            raisedAt: uint64(block.timestamp),
            resolvedAt: 0,
            outcome: DisputeOutcome.NONE,
            recipientBps: 0
        });
        emit DisputeRaised(escrowId, tx.origin, reason);
    }
    function resolveDispute(
        uint256 escrowId,
        DisputeOutcome outcome,
        uint16 recipientBps
    ) external override disputeExists(escrowId) notResolved(escrowId) {
        address arbiter = arbiters[escrowId];
        bool callerIsArbiter = arbiter != address(0) && msg.sender == arbiter;
        bool callerIsDAO = msg.sender == owner();
        require(callerIsArbiter || callerIsDAO, "Dispute: not authorised to resolve");
        require(outcome != DisputeOutcome.NONE, "Dispute: invalid outcome");
        if (outcome == DisputeOutcome.SPLIT) {
            require(recipientBps <= 10_000, "Dispute: bps > 10000");
        } else {
            recipientBps = outcome == DisputeOutcome.RELEASE_RECIPIENT ? 10_000 : 0;
        }
        _disputes[escrowId].outcome = outcome;
        _disputes[escrowId].recipientBps = recipientBps;
        _disputes[escrowId].resolvedAt = uint64(block.timestamp);
        emit DisputeResolved(escrowId, outcome, recipientBps);
    }
    function registerArbiter(uint256 escrowId, address arbiter) external onlyEscrow {
        arbiters[escrowId] = arbiter;
    }
    function getDispute(uint256 escrowId)
        external
        view
        override
        returns (Dispute memory)
    {
        return _disputes[escrowId];
    }
    function hasOpenDispute(uint256 escrowId) external view override returns (bool) {
        Dispute storage d = _disputes[escrowId];
        return d.raisedAt != 0 && d.outcome == DisputeOutcome.NONE;
    }
}