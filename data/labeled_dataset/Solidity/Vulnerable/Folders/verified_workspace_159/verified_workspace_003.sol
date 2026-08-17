pragma solidity >=0.8.29 <0.9.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBaseFeeOracle } from "@superearn/interface/IBaseFeeOracle.sol";
import { IStrategy } from "@superearn/interface/IStrategy.sol";
import { IVault, StrategyParams } from "@superearn/interface/IVault.sol";
import { IHealthCheck } from "@superearn/interface/IHealthCheck.sol";
abstract contract BaseStrategy is IStrategy {
    using SafeERC20 for IERC20;
    error StrategyAlreadyInitialized();
    error FailedHealthCheck();
    error NotVault();
    error NotOriginal();
    error SweepTokenIsWant();
    error SweepTokenIsVaultShares();
    error TokenProtected();
    string public metadataURI;
    bool public doHealthCheck;
    address public healthCheck;
    function apiVersion() public pure returns (string memory) {
        return "0.4.6";
    }
    function name() external view virtual returns (string memory);
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }
    IVault public vault;
    address public strategist;
    address public rewards;
    address public keeper;
    IERC20 public want;
    uint256 public minReportDelay;
    uint256 public maxReportDelay;
    bool public emergencyExit;
    address public baseFeeOracle;
    uint256 public creditThreshold;
    bool public forceHarvestTriggerOnce;
    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }
    modifier onlyEmergencyAuthorized() {
        _onlyEmergencyAuthorized();
        _;
    }
    modifier onlyStrategist() {
        _onlyStrategist();
        _;
    }
    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }
    modifier onlyRewarder() {
        _onlyRewarder();
        _;
    }
    modifier onlyKeepers() {
        _onlyKeepers();
        _;
    }
    modifier onlyVaultManagers() {
        _onlyVaultManagers();
        _;
    }
    function _onlyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance());
    }
    function _onlyEmergencyAuthorized() internal {
        require(
            msg.sender == strategist || msg.sender == governance() || msg.sender == vault.guardian()
                || msg.sender == vault.management()
        );
    }
    function _onlyStrategist() internal {
        require(msg.sender == strategist);
    }
    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }
    function _onlyRewarder() internal {
        require(msg.sender == governance() || msg.sender == strategist);
    }
    function _onlyKeepers() internal {
        require(
            msg.sender == keeper || msg.sender == strategist || msg.sender == governance()
                || msg.sender == vault.guardian() || msg.sender == vault.management()
        );
    }
    function _onlyVaultManagers() internal {
        require(msg.sender == vault.management() || msg.sender == governance());
    }
    constructor(address _vault) {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }
    function _initialize(address _vault, address _strategist, address _rewards, address _keeper) internal {
        if (address(want) != address(0)) revert StrategyAlreadyInitialized();
        vault = IVault(_vault);
        want = IERC20(vault.token());
        want.forceApprove(_vault, type(uint256).max);
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;
        maxReportDelay = 30 days;
        creditThreshold = 1_000_000 * 10 ** vault.decimals();
        vault.approve(rewards, type(uint256).max);
    }
    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        emit SetHealthCheck(_healthCheck);
        healthCheck = _healthCheck;
    }
    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        emit SetDoHealthCheck(_doHealthCheck);
        doHealthCheck = _doHealthCheck;
    }
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }
    function setRewards(address _rewards) external onlyRewarder {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, type(uint256).max);
        emit UpdatedRewards(_rewards);
    }
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }
    function setCreditThreshold(uint256 _creditThreshold) external onlyVaultManagers {
        creditThreshold = _creditThreshold;
        emit UpdatedCreditThreshold(_creditThreshold);
    }
    function setForceHarvestTriggerOnce(bool _forceHarvestTriggerOnce) external onlyVaultManagers {
        forceHarvestTriggerOnce = _forceHarvestTriggerOnce;
        emit ForcedHarvestTrigger(_forceHarvestTriggerOnce);
    }
    function setBaseFeeOracle(address _baseFeeOracle) external onlyVaultManagers {
        baseFeeOracle = _baseFeeOracle;
        emit UpdatedBaseFeeOracle(_baseFeeOracle);
    }
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }
    function governance() internal view returns (address) {
        return vault.governance();
    }
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);
    function estimatedTotalAssets() public view virtual returns (uint256);
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment);
    function adjustPosition(uint256 _debtOutstanding) internal virtual;
    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);
    function liquidateAllPositions() internal virtual returns (uint256 _amountFreed);
    function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        return false;
    }
    function tend() external onlyKeepers {
        adjustPosition(vault.debtOutstanding());
    }
    function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        if (!isActive()) return false;
        if (!isBaseFeeAcceptable()) return false;
        if (forceHarvestTriggerOnce) return true;
        StrategyParams memory params = vault.strategies(address(this));
        if ((block.timestamp - params.lastReport) >= maxReportDelay) return true;
        return (vault.creditAvailable() > creditThreshold);
    }
    function isBaseFeeAcceptable() public view returns (bool) {
        if (baseFeeOracle == address(0)) return true;
        else return IBaseFeeOracle(baseFeeOracle).isCurrentBaseFeeAcceptable();
    }
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding - amountFreed;
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed - debtOutstanding;
            }
            debtPayment = debtOutstanding - loss;
        } else {
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }
        forceHarvestTriggerOnce = false;
        emit ForcedHarvestTrigger(false);
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);
        adjustPosition(debtOutstanding);
        if (doHealthCheck && healthCheck != address(0)) {
            if (!IHealthCheck(healthCheck).check(profit, loss, debtPayment, debtOutstanding, totalDebt)) {
                revert FailedHealthCheck();
            }
        } else {
            emit SetDoHealthCheck(true);
            doHealthCheck = true;
        }
        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        if (msg.sender != address(vault)) revert NotVault();
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        want.safeTransfer(msg.sender, amountFreed);
    }
    function prepareMigration(address _newStrategy) internal virtual;
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        if (vault.strategies(address(this)).debtRatio != 0) {
            vault.revokeStrategy();
        }
        emit EmergencyExitEnabled();
    }
    function protectedTokens() internal view virtual returns (address[] memory);
    function sweep(address _token) external onlyGovernance {
        if (_token == address(want)) revert SweepTokenIsWant();
        if (_token == address(vault)) revert SweepTokenIsVaultShares();
        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) {
            if (_token == _protectedTokens[i]) revert TokenProtected();
        }
        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}
abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;
    event Cloned(address indexed clone);
    constructor(address _vault) BaseStrategy(_vault) { }
    function initialize(address _vault, address _strategist, address _rewards, address _keeper) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }
    function clone(address _vault) external returns (address) {
        return clone(_vault, msg.sender, msg.sender, msg.sender);
    }
    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    )
        public
        returns (address newStrategy)
    {
        if (!isOriginal) revert NotOriginal();
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }
        BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);
        emit Cloned(newStrategy);
    }
}