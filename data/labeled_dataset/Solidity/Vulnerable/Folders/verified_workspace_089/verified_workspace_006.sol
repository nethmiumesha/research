pragma solidity ^0.8.0;
interface IStakefishServicesContract {
    enum State {
        NotInitialized,
        PreDeposit,
        PostDeposit,
        Withdrawn
    }
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event WithdrawalApproval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Withdrawal(
        address indexed owner,
        address indexed to,
        uint256 amount,
        uint256 value
    );
    event ValidatorDeposited(
        bytes pubkey
    );
    event ServiceEnd(
        uint256 timestamp
    );
    event Deposit(
        address from,
        uint256 amount
    );
    function updateExitDate(uint64 newExitDate) external;
    function createValidator(
        bytes calldata validatorPubKey,
        bytes calldata depositSignature,
        bytes32 depositDataRoot,
        uint64 exitDate
    ) external;
    function deposit() external payable returns (uint256 surplus);
    function depositOnBehalfOf(address depositor) external payable returns (uint256 surplus);
    function endOperatorServices() external;
    function withdrawAll() external returns (uint256);
    function withdraw(uint256 amount) external returns (uint256);
    function withdrawTo(uint256 amount, address payable beneficiary) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function approveWithdrawal(address spender, uint256 amount) external;
    function withdrawFrom(
        address depositor,
        address payable beneficiary,
        uint256 amount
    ) external returns (uint256);
    function transferDeposit(address to, uint256 amount) external returns (bool);
    function transferDepositFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function withdrawalAllowance(address depositor, address spender) external view returns (uint256);
    function getCommissionRate() external view returns (uint256);
    function getExitDate() external view returns (uint256);
    function getState() external view returns (State);
    function getOperatorAddress() external view returns (address);
    function getDeposit(address depositor) external view returns (uint256);
    function getTotalDeposits() external view returns (uint256);
    function getAllowance(address owner, address spender) external view returns (uint256);
    function getOperatorDataCommitment() external view returns (bytes32);
}