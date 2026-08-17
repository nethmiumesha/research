pragma solidity >=0.8.29 <0.9.0;
import { ICustomStrategyHelper } from "@superearn/v2/interfaces/ICustomStrategyHelper.sol";
contract CustomStrategyHelper {
    address public governance;
    address public pendingGovernance;
    mapping(address => address) public helpers;
    event HelperSet(address indexed strategy, address indexed helper);
    event GovernanceTransferSubmitted(address indexed pendingGovernance);
    event GovernanceTransferred(address indexed oldGovernance, address indexed newGovernance);
    error ZeroAddress();
    error OnlyGovernance();
    error OnlyPendingGovernance();
    error NoPendingGovernance();
    error HelperNotRegistered(address strategy);
    modifier onlyGovernance() {
        if (msg.sender != governance) revert OnlyGovernance();
        _;
    }
    constructor(address _governance) {
        if (_governance == address(0)) revert ZeroAddress();
        governance = _governance;
    }
    function setHelper(address strategy, address helper) external onlyGovernance {
        if (strategy == address(0)) revert ZeroAddress();
        helpers[strategy] = helper;
        emit HelperSet(strategy, helper);
    }
    function transferGovernance(address newGovernance) external onlyGovernance {
        if (newGovernance == address(0)) revert ZeroAddress();
        pendingGovernance = newGovernance;
        emit GovernanceTransferSubmitted(newGovernance);
    }
    function acceptGovernance() external {
        if (pendingGovernance == address(0)) revert NoPendingGovernance();
        if (msg.sender != pendingGovernance) revert OnlyPendingGovernance();
        address oldGovernance = governance;
        governance = pendingGovernance;
        pendingGovernance = address(0);
        emit GovernanceTransferred(oldGovernance, governance);
    }
    function getWithdrawCalldata(
        address strategy,
        uint256 amount
    ) external view returns (address[] memory targets, bytes[] memory calldatas) {
        address helper = helpers[strategy];
        if (helper == address(0)) revert HelperNotRegistered(strategy);
        return ICustomStrategyHelper(helper).getWithdrawCalldata(strategy, amount);
    }
}