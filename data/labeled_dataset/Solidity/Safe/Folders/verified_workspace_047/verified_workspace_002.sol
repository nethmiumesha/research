pragma solidity ^0.5.3;
interface IHolderDelegation {
    event DelegationRequestIsSent(uint id);
    function delegate(
        uint validatorId,
        uint amount,
        uint delegationPeriod,
        string calldata info
    ) external;
    function requestUndelegation(uint delegationId) external;
    function cancelPendingDelegation(uint delegationId) external;
    function getDelegationRequestsForValidator(uint validatorId) external returns (uint[] memory);
    function getValidators() external view returns (uint[] memory validatorIds);
    function withdrawBounty(address bountyCollectionAddress, uint amount) external;
    function getEarnedBountyAmount() external returns (uint);
}