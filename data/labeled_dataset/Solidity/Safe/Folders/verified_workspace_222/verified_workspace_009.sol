pragma solidity 0.7.5;
interface IValidators {
    function initialize(address _admin, address _pool, address _solos) external;
    function isOperator(address _account) external view returns (bool);
    function addOperator(address _account) external;
    function removeOperator(address _account) external;
    function publicKeys(bytes32 _publicKey) external view returns (bool);
    function register(bytes32 _validatorId) external;
}