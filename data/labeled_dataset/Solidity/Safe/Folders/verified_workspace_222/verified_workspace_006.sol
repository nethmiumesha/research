pragma solidity 0.7.5;
pragma abicoder v2;
import "./IDepositContract.sol";
interface ISolos {
    struct Solo {
        uint256 amount;
        bytes32 withdrawalCredentials;
        uint256 releaseTime;
    }
    struct Validator {
        bytes publicKey;
        bytes signature;
        bytes32 depositDataRoot;
        bytes32 soloId;
    }
    event DepositAdded(
        bytes32 indexed soloId,
        address sender,
        uint256 amount,
        bytes32 withdrawalCredentials
    );
    event DepositCanceled(
        bytes32 indexed soloId,
        address sender,
        uint256 amount,
        bytes32 withdrawalCredentials
    );
    event CancelLockDurationUpdated(uint256 cancelLockDuration);
    event ValidatorPriceUpdated(uint256 validatorPrice);
    event ValidatorRegistered(bytes32 indexed soloId, bytes publicKey, uint256 price, address operator);
    function solos(bytes32 _soloId) external view returns (
        uint256 amount,
        bytes32 withdrawalCredentials,
        uint256 releaseTime
    );
    function validatorRegistration() external view returns (IDepositContract);
    function validatorPrice() external view returns (uint256);
    function setValidatorPrice(uint256 _validatorPrice) external;
    function cancelLockDuration() external view returns (uint256);
    function setCancelLockDuration(uint256 newCancelLockDuration) external;
    function addDeposit(bytes32 _withdrawalCredentials) external payable;
    function cancelDeposit(bytes32 _withdrawalCredentials, uint256 _amount) external;
    function registerValidator(Validator calldata _validator) external;
}