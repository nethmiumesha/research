pragma solidity ^0.8.7;
import "./IFeeManager.sol";
import "./IPerpetualManager.sol";
import "./IOracle.sol";
struct StrategyParams {
    uint256 lastReport;
    uint256 totalStrategyDebt;
    uint256 debtRatio;
}
interface IPoolManagerFunctions {
    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IPerpetualManager _perpetualManager,
        IFeeManager feeManager,
        IOracle oracle
    ) external;
    function creditAvailable() external view returns (uint256);
    function debtOutstanding() external view returns (uint256);
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external;
    function addGovernor(address _governor) external;
    function removeGovernor(address _governor) external;
    function setGuardian(address _guardian, address guardian) external;
    function revokeGuardian(address guardian) external;
    function setFeeManager(IFeeManager _feeManager) external;
    function getBalance() external view returns (uint256);
    function getTotalAsset() external view returns (uint256);
}
interface IPoolManager is IPoolManagerFunctions {
    function stableMaster() external view returns (address);
    function perpetualManager() external view returns (address);
    function token() external view returns (address);
    function feeManager() external view returns (address);
    function totalDebt() external view returns (uint256);
    function strategies(address _strategy) external view returns (StrategyParams memory);
}