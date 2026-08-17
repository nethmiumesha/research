pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ILinearTokenTimelock {
    event Release(address indexed _beneficiary, address indexed _recipient, uint256 _amount);
    event BeneficiaryUpdate(address indexed _beneficiary);
    event PendingBeneficiaryUpdate(address indexed _pendingBeneficiary);
    function release(address to, uint256 amount) external;
    function releaseMax(address to) external;
    function setPendingBeneficiary(address _pendingBeneficiary) external;
    function acceptBeneficiary() external;
    function lockedToken() external view returns (IERC20);
    function beneficiary() external view returns (address);
    function pendingBeneficiary() external view returns (address);
    function initialBalance() external view returns (uint256);
    function availableForRelease() external view returns (uint256);
    function totalToken() external view returns(uint256);
    function alreadyReleasedAmount() external view returns (uint256);
}