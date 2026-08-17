pragma solidity ^0.8.24;
import {IAxioms} from "./interfaces/IAxioms.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract Proofs is Ownable {
    enum InferenceRule {
        AXIOM,
        MODUS_PONENS,
        MODUS_TOLLENS,
        CONJUNCTION_I,
        CONJUNCTION_E,
        DISJUNCTION_I,
        DISJUNCTION_E,
        HYPOTHETICAL_SYL
    }
    struct ProofStep {
        bytes32 claim;
        InferenceRule rule;
        bytes32[] antecedents;
    }
    struct Theorem {
        bytes32 conclusion;
        bytes32[] premises;
        address prover;
        uint256 timestamp;
        uint256 blockNumber;
    }
    IAxioms public immutable AXIOMS;
    uint256 public submissionFee;
    address public feeRecipient;
    mapping(bytes32 => bool) public isTheorem;
    mapping(bytes32 => Theorem) public theorems;
    mapping(address => uint256) public proverCount;
    bytes32[] public theoremList;
    event TheoremVerified(
        bytes32 indexed theoremId,
        bytes32 indexed conclusion,
        address indexed prover,
        InferenceRule[] rules
    );
    event FeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address indexed recipient);
    event FeesWithdrawn(uint256 amount, address indexed recipient);
    error UngroundedPremise(bytes32 statementHash);
    error CircularReasoning(bytes32 statementHash);
    error InvalidRuleApplication(InferenceRule rule, string reason);
    error AntecedentNotVerified(bytes32 antecedent);
    error AffirmingTheConsequent(bytes32 claim);
    error EmptyProof();
    constructor(address axiomsAddress, address initialOwner) Ownable(initialOwner) {
        AXIOMS = IAxioms(axiomsAddress);
        feeRecipient = initialOwner;
    }
    function setSubmissionFee(uint256 newFee) external onlyOwner {
        submissionFee = newFee;
        emit FeeUpdated(newFee);
    }
    function setFeeRecipient(address recipient) external onlyOwner {
        feeRecipient = recipient;
        emit FeeRecipientUpdated(recipient);
    }
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = feeRecipient.call{value: balance}("");
            require(success, "Withdrawal failed");
        }
        emit FeesWithdrawn(balance, feeRecipient);
    }
    function submitProof(
        ProofStep[] calldata steps,
        bytes32[] calldata premises
    ) external payable returns (bytes32 theoremId) {
        require(msg.value >= submissionFee, "Insufficient fee");
        if (steps.length == 0) revert EmptyProof();
        for (uint256 i = 0; i < premises.length; i++) {
            if (!_isGrounded(premises[i])) {
                revert UngroundedPremise(premises[i]);
            }
        }
        for (uint256 i = 0; i < steps.length; i++) {
            ProofStep calldata step = steps[i];
            if (_inProof[step.claim]) revert CircularReasoning(step.claim);
            _inProof[step.claim] = true;
            _validateStep(step, premises);
        }
        for (uint256 i = 0; i < steps.length; i++) {
            _inProof[steps[i].claim] = false;
        }
        bytes32 conclusion = steps[steps.length - 1].claim;
        theoremId = keccak256(abi.encodePacked(conclusion, block.number, msg.sender));
        Theorem storage t = theorems[theoremId];
        t.conclusion = conclusion;
        t.premises = premises;
        t.prover = msg.sender;
        t.timestamp = block.timestamp;
        t.blockNumber = block.number;
        isTheorem[conclusion] = true;
        theoremList.push(theoremId);
        proverCount[msg.sender]++;
        InferenceRule[] memory rules = new InferenceRule[](steps.length);
        for (uint256 i = 0; i < steps.length; i++) {
            rules[i] = steps[i].rule;
        }
        emit TheoremVerified(theoremId, conclusion, msg.sender, rules);
    }
    mapping(bytes32 => bool) private _inProof;
    function _validateStep(
        ProofStep calldata step,
        bytes32[] calldata premises
    ) internal view {
        if (step.rule == InferenceRule.AXIOM) {
            if (!_isGrounded(step.claim)) revert UngroundedPremise(step.claim);
            return;
        }
        for (uint256 j = 0; j < step.antecedents.length; j++) {
            if (!_isGrounded(step.antecedents[j])) {
                revert AntecedentNotVerified(step.antecedents[j]);
            }
        }
        if (step.rule == InferenceRule.MODUS_PONENS) {
            if (step.antecedents.length != 2) {
                revert InvalidRuleApplication(step.rule, "MP requires 2 antecedents");
            }
            if (step.claim == step.antecedents[0]) {
                revert AffirmingTheConsequent(step.claim);
            }
        }
        else if (step.rule == InferenceRule.MODUS_TOLLENS) {
            if (step.antecedents.length != 2) {
                revert InvalidRuleApplication(step.rule, "MT requires 2 antecedents");
            }
            if (step.claim == step.antecedents[0]) {
                revert AffirmingTheConsequent(step.claim);
            }
        }
        else if (step.rule == InferenceRule.CONJUNCTION_I) {
            if (step.antecedents.length != 2) {
                revert InvalidRuleApplication(step.rule, "AND-I requires 2 antecedents");
            }
        }
        else if (step.rule == InferenceRule.CONJUNCTION_E) {
            if (step.antecedents.length != 1) {
                revert InvalidRuleApplication(step.rule, "AND-E requires 1 antecedent");
            }
        }
        else if (step.rule == InferenceRule.DISJUNCTION_I) {
            if (step.antecedents.length != 1) {
                revert InvalidRuleApplication(step.rule, "OR-I requires 1 antecedent");
            }
        }
        else if (step.rule == InferenceRule.DISJUNCTION_E) {
            if (step.antecedents.length != 3) {
                revert InvalidRuleApplication(step.rule, "OR-E requires 3 antecedents");
            }
        }
        else if (step.rule == InferenceRule.HYPOTHETICAL_SYL) {
            if (step.antecedents.length != 2) {
                revert InvalidRuleApplication(step.rule, "HYP-SYL requires 2 antecedents");
            }
        }
    }
    function _isGrounded(bytes32 h) internal view returns (bool) {
        return AXIOMS.isAxiom(h) || isTheorem[h];
    }
    function totalTheorems() external view returns (uint256) {
        return theoremList.length;
    }
    function getTheorem(bytes32 theoremId) external view returns (Theorem memory) {
        return theorems[theoremId];
    }
    function hash(string calldata s) external pure returns (bytes32) {
        return keccak256(bytes(s));
    }
}