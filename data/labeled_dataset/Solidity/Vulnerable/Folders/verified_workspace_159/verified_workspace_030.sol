pragma solidity >=0.8.29 <0.9.0;
library TimelockExecutionLib {
    using TimelockExecutionLib for TimelockStorage;
    struct PendingExecution {
        address[] targets;
        bytes[] calldatas;
        uint256 executeAfter;
    }
    event ExecutionSubmitted(address[] targets, bytes[] calldatas, uint256 executeAfter);
    event ExecutionAccepted(address[] targets, bytes[] calldatas, bytes[] returnData);
    event ExecutionCancelled(address[] targets);
    event TargetAllowlistUpdated(address indexed target, bool allowed);
    event TimelockDelayUpdated(uint256 oldDelay, uint256 newDelay);
    error InvalidExecutionState(string reason);
    error ExecutionFailed();
    uint256 public constant MIN_TIMELOCK_DELAY = 0 hours;
    uint256 public constant MAX_TIMELOCK_DELAY = 1 days;
    uint256 public constant EXECUTION_WINDOW = 7 days;
    struct TimelockStorage {
        PendingExecution pendingExecution;
        mapping(address => bool) allowedTargets;
        uint256 timelockDelay;
    }
    function submitExecution(
        TimelockStorage storage self,
        address[] calldata targets,
        bytes[] calldata calldatas,
        bytes4[] calldata allowedSelfCallSelectors
    )
        external
    {
        if (self.pendingExecution.targets.length > 0) {
            revert InvalidExecutionState("PENDING_EXISTS");
        }
        if (targets.length == 0) revert InvalidExecutionState("EMPTY_ARRAYS");
        if (targets.length != calldatas.length) revert InvalidExecutionState("ARRAY_MISMATCH");
        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == address(this)) {
                if (!_isAllowedSelector(bytes4(calldatas[i]), allowedSelfCallSelectors)) {
                    revert InvalidExecutionState("INVALID_SELF_CALL");
                }
            } else if (!self.allowedTargets[targets[i]]) {
                revert InvalidExecutionState("NOTALLOWED");
            }
        }
        uint256 executeAfter = block.timestamp + self.timelockDelay;
        self.pendingExecution = PendingExecution({ targets: targets, calldatas: calldatas, executeAfter: executeAfter });
        emit ExecutionSubmitted(targets, calldatas, executeAfter);
    }
    function _isAllowedSelector(bytes4 selector, bytes4[] memory allowedSelectors) private pure returns (bool) {
        for (uint256 i = 0; i < allowedSelectors.length; i++) {
            if (selector == allowedSelectors[i]) return true;
        }
        return false;
    }
    function acceptExecution(TimelockStorage storage self) external returns (bool success, bytes memory returnData) {
        address[] memory targets = self.pendingExecution.targets;
        if (targets.length == 0) revert InvalidExecutionState("NOPENDING");
        if (block.timestamp < self.pendingExecution.executeAfter) {
            revert InvalidExecutionState("TIMELOCKED");
        }
        uint256 expireAt = self.pendingExecution.executeAfter + EXECUTION_WINDOW;
        if (block.timestamp > expireAt) {
            revert InvalidExecutionState("EXPIRED");
        }
        bytes[] memory calldatas = self.pendingExecution.calldatas;
        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] != address(this) && !self.allowedTargets[targets[i]]) {
                revert InvalidExecutionState("NOTALLOWED");
            }
        }
        delete self.pendingExecution;
        bytes[] memory returnDataArray = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            (bool callSuccess, bytes memory callReturnData) = targets[i].call(calldatas[i]);
            if (!callSuccess) revert ExecutionFailed();
            returnDataArray[i] = callReturnData;
        }
        returnData = abi.encode(returnDataArray);
        success = true;
        emit ExecutionAccepted(targets, calldatas, returnDataArray);
    }
    function cancelExecution(TimelockStorage storage self) external {
        address[] memory targets = self.pendingExecution.targets;
        if (targets.length == 0) revert InvalidExecutionState("NOPENDING");
        delete self.pendingExecution;
        emit ExecutionCancelled(targets);
    }
    function setAllowedTarget(TimelockStorage storage self, address target, bool allowed) external {
        if (target == address(this)) revert InvalidExecutionState("SELFWHITELIST");
        self.allowedTargets[target] = allowed;
        if (!allowed && self.pendingExecution.targets.length > 0) {
            address[] memory targets = self.pendingExecution.targets;
            for (uint256 i = 0; i < targets.length; i++) {
                if (targets[i] == target) {
                    delete self.pendingExecution;
                    emit ExecutionCancelled(targets);
                    break;
                }
            }
        }
        emit TargetAllowlistUpdated(target, allowed);
    }
    function setTimelockDelay(TimelockStorage storage self, uint256 newDelay) external {
        if (newDelay < MIN_TIMELOCK_DELAY || newDelay > MAX_TIMELOCK_DELAY) {
            revert InvalidExecutionState("INVALID_DELAY");
        }
        uint256 oldDelay = self.timelockDelay;
        self.timelockDelay = newDelay;
        emit TimelockDelayUpdated(oldDelay, newDelay);
    }
}