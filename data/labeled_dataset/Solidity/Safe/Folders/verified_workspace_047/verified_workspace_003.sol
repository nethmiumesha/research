pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;
interface IValidatorDelegation {
    function acceptPendingDelegation(uint delegationId) external;
    function deleteNode(uint nodeIndex) external;
    function registerValidator(
        string calldata name,
        string calldata description,
        uint feeRatePromille,
        uint minimumDelegationAmount
    ) external returns (uint validatorId);
    function unregisterValidator(uint validatorId) external;
    function getBondAmount(uint validatorId) external returns (uint amount);
    function setValidatorName(string calldata newName) external;
    function setValidatorDescription(string calldata descripton) external;
    function requestForNewAddress(address newAddress) external;
    function confirmNewAddress(uint validatorId) external;
    function setMinimumDelegationAmount(uint amount) external;
}