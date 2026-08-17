pragma solidity ^0.8.7;
import "./IAccessControl.sol";
interface IFeeManagerFunctions is IAccessControl {
    function updateUsersSLP() external;
    function updateHA() external;
    function deployCollateral(
        address[] memory governorList,
        address guardian,
        address _perpetualManager
    ) external;
    function setFees(
        uint256[] memory xArray,
        uint64[] memory yArray,
        uint8 typeChange
    ) external;
    function setHAFees(uint64 _haFeeDeposit, uint64 _haFeeWithdraw) external;
}
interface IFeeManager is IFeeManagerFunctions {
    function stableMaster() external view returns (address);
    function perpetualManager() external view returns (address);
}