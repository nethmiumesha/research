pragma solidity ^0.8.24;
import { IEEPCondition } from "../interfaces/IEEPCondition.sol";
contract MultiSigCondition is IEEPCondition {
    mapping(uint256 => mapping(address => bool)) public approvals;
    mapping(uint256 => uint256) public approvalCount;
    event Approved(uint256 indexed escrowId, address indexed signer);
    event ApprovalRevoked(uint256 indexed escrowId, address indexed signer);
    function conditionName() external pure override returns (string memory) {
        return "MultiSig";
    }
    function approve(uint256 escrowId) external {
        require(!approvals[escrowId][msg.sender], "MultiSig: already approved");
        approvals[escrowId][msg.sender] = true;
        approvalCount[escrowId]++;
        emit Approved(escrowId, msg.sender);
    }
    function revokeApproval(uint256 escrowId) external {
        require(approvals[escrowId][msg.sender], "MultiSig: not approved");
        approvals[escrowId][msg.sender] = false;
        approvalCount[escrowId]--;
        emit ApprovalRevoked(escrowId, msg.sender);
    }
    function isSatisfied(
        uint256 escrowId,
        address caller,
        bytes calldata data
    ) external view override returns (bool) {
        (address[] memory signers, uint8 threshold) = abi.decode(data, (address[], uint8));
        bool callerIsSigner;
        for (uint256 i; i < signers.length; ++i) {
            if (signers[i] == caller) {
                callerIsSigner = true;
                break;
            }
        }
        if (!callerIsSigner) return false;
        uint256 validApprovals;
        for (uint256 i; i < signers.length; ++i) {
            if (approvals[escrowId][signers[i]]) ++validApprovals;
        }
        return validApprovals >= threshold;
    }
    function encode(address[] calldata signers, uint8 threshold)
        external
        pure
        returns (bytes memory)
    {
        require(threshold > 0 && threshold <= signers.length, "MultiSig: invalid threshold");
        return abi.encode(signers, threshold);
    }
}