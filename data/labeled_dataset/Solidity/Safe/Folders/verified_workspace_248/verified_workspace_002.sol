pragma solidity ^0.8.24;
import { IEEPCondition } from "../interfaces/IEEPCondition.sol";
contract TimeLockCondition is IEEPCondition {
    function conditionName() external pure override returns (string memory) {
        return "TimeLock";
    }
    function isSatisfied(
        uint256,
        address,
        bytes calldata data
    ) external view override returns (bool) {
        uint64 unlockAt = abi.decode(data, (uint64));
        return block.timestamp >= unlockAt;
    }
    function encode(uint64 unlockAt) external pure returns (bytes memory) {
        return abi.encode(unlockAt);
    }
    function decode(bytes calldata data) external pure returns (uint64 unlockAt) {
        return abi.decode(data, (uint64));
    }
}