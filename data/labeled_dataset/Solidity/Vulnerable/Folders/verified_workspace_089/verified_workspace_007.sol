pragma solidity ^0.8.0;
interface IStakefishServicesContractFactory {
    event ContractCreated(
        bytes32 create2Salt
    );
    event CommissionRateChanged(
        uint256 newCommissionRate
    );
    event OperatorChanged(
        address newOperatorAddress
    );
    event MinimumDepositChanged(
        uint256 newMinimumDeposit
    );
    function changeCommissionRate(uint24 newCommissionRate) external;
    function changeOperatorAddress(address newAddress) external;
    function changeMinimumDeposit(uint256 newMinimumDeposit) external;
    function createContract(bytes32 saltValue, bytes32 operatorDataCommitmet) external payable returns (address);
    function createMultipleContracts(uint256 baseSaltValue, bytes32[] calldata operatorDataCommitmets) external payable;
    function fundMultipleContracts(bytes32[] calldata saltValues, bool force) external payable returns (uint256);
    function getOperatorAddress() external view returns (address);
    function getCommissionRate() external view returns (uint24);
    function getServicesContractImpl() external view returns (address payable);
    function getMinimumDeposit() external view returns (uint256);
}