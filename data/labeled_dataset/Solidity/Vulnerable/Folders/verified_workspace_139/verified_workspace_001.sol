pragma solidity ^0.8.24;
interface IEEPCondition {
    function conditionName() external pure returns (string memory);
    function isSatisfied(
        uint256 escrowId,
        address caller,
        bytes calldata data
    ) external view returns (bool);
}