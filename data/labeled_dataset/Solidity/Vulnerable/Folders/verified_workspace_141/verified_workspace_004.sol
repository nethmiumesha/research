pragma solidity ^0.8.20;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISafe} from "../interfaces/ISafe.sol";
abstract contract OkaYieldModuleBase is ReentrancyGuard {
    struct VaultConfig {
        uint16 feeBps;
        bool registered;
    }
    address public immutable okaOwner;
    address public immutable feeReceiver;
    uint256 public immutable maxHarvestBps;
    uint16 public constant MAX_FEE_BPS = 3000;
    uint256 public constant MIN_COOLDOWN = 1 hours;
    uint256 public constant MAX_COOLDOWN = 30 days;
    uint256 public constant GUARDIAN_PAUSE_DURATION = 7 days;
    uint8 public constant SKIP_NO_YIELD = 1;
    uint8 public constant SKIP_ZERO_FEE = 2;
    uint8 public constant SKIP_NOT_MAPPED = 3;
    uint8 public constant SKIP_NO_CHECKPOINT = 4;
    bool public paused;
    bool public deprecated;
    address public guardian;
    uint256 public harvestCooldown;
    uint256 public pausedAt;
    address public pausedBy;
    mapping(address => VaultConfig) public vaultConfigs;
    mapping(address => mapping(address => uint256)) public lastCheckpoints;
    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public lastHarvestTime;
    mapping(address => mapping(address => uint256)) public totalFeeCollected;
    mapping(address => uint256) public harvestCount;
    event SafeRegistered(address indexed safe, uint16 feeBps);
    event SafeUnregistered(address indexed safe);
    event DepositRegistered(address indexed safe, address indexed token, uint256 amount);
    event WithdrawalRegistered(address indexed safe, address indexed token, uint256 amount);
    event TokenWhitelisted(address indexed token);
    event TokenRemovedFromWhitelist(address indexed token);
    event Harvested(
        address indexed safe,
        address indexed token,
        uint256 yield,
        uint256 fee,
        uint16 feeBps,
        uint256 checkpointBefore,
        uint256 checkpointAfter
    );
    event HarvestSkipped(address indexed safe, address indexed token, uint8 reason);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);
    event ContractDeprecated();
    event GuardianUpdated(address indexed oldGuardian, address indexed newGuardian);
    event HarvestCooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
    event CheckpointReset(address indexed safe, address indexed token, uint256 oldCheckpoint);
    event FeeBpsUpdated(address indexed safe, uint16 oldFeeBps, uint16 newFeeBps);
    error OnlyOka();
    error ZeroAddress();
    error ZeroAmount();
    error FeeTooHigh(uint16 feeBps, uint16 maxFeeBps);
    error MaxHarvestBpsTooHigh(uint256 maxHarvestBps);
    error CooldownOutOfBounds(uint256 cooldown, uint256 min, uint256 max);
    error SafeAlreadyRegistered(address safe);
    error SafeNotRegistered(address safe);
    error TokenNotWhitelisted(address token);
    error SafeExecFailed(address safe, address to);
    error Paused();
    error Deprecated();
    error CooldownNotElapsed(uint256 availableAt);
    error OnlyOkaOrGuardian();
    error SafeStillRegistered(address safe);
    error WithdrawalExceedsCheckpoint(uint256 amount, uint256 checkpoint);
    modifier onlyOka() {
        if (msg.sender != okaOwner) revert OnlyOka();
        _;
    }
    modifier onlyOkaOrGuardian() {
        if (msg.sender != okaOwner && msg.sender != guardian) revert OnlyOkaOrGuardian();
        _;
    }
    modifier whenNotPaused() {
        if (paused) {
            if (pausedBy != okaOwner && block.timestamp >= pausedAt + GUARDIAN_PAUSE_DURATION) {
                paused = false;
                emit ContractUnpaused(address(0));
            } else {
                revert Paused();
            }
        }
        _;
    }
    modifier whenNotDeprecated() {
        if (deprecated) revert Deprecated();
        _;
    }
    constructor(
        address _okaOwner,
        address _feeReceiver,
        address _guardian,
        uint256 _harvestCooldown,
        uint256 _maxHarvestBps
    ) {
        if (_okaOwner == address(0)) revert ZeroAddress();
        if (_feeReceiver == address(0)) revert ZeroAddress();
        if (_guardian == address(0)) revert ZeroAddress();
        if (_maxHarvestBps > 10_000) revert MaxHarvestBpsTooHigh(_maxHarvestBps);
        _validateCooldown(_harvestCooldown);
        okaOwner = _okaOwner;
        feeReceiver = _feeReceiver;
        guardian = _guardian;
        harvestCooldown = _harvestCooldown;
        maxHarvestBps = _maxHarvestBps;
    }
    function pause() external onlyOkaOrGuardian {
        paused = true;
        pausedAt = block.timestamp;
        pausedBy = msg.sender;
        emit ContractPaused(msg.sender);
    }
    function unpause() external onlyOka {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }
    function deprecate() external onlyOka {
        deprecated = true;
        emit ContractDeprecated();
    }
    function setGuardian(address _guardian) external onlyOka {
        if (_guardian == address(0)) revert ZeroAddress();
        address oldGuardian = guardian;
        guardian = _guardian;
        emit GuardianUpdated(oldGuardian, _guardian);
    }
    function setHarvestCooldown(uint256 _cooldown) external onlyOka {
        _validateCooldown(_cooldown);
        uint256 oldCooldown = harvestCooldown;
        harvestCooldown = _cooldown;
        emit HarvestCooldownUpdated(oldCooldown, _cooldown);
    }
    function nextHarvestTime(address safe) external view returns (uint256) {
        return lastHarvestTime[safe] + harvestCooldown;
    }
    function registerSafe(address safe, uint16 feeBps) external onlyOka whenNotPaused whenNotDeprecated {
        if (safe == address(0)) revert ZeroAddress();
        if (feeBps > MAX_FEE_BPS) revert FeeTooHigh(feeBps, MAX_FEE_BPS);
        if (vaultConfigs[safe].registered) revert SafeAlreadyRegistered(safe);
        vaultConfigs[safe] = VaultConfig({feeBps: feeBps, registered: true});
        lastHarvestTime[safe] = block.timestamp;
        emit SafeRegistered(safe, feeBps);
    }
    function registerDeposit(address safe, address token, uint256 amount) external nonReentrant onlyOka whenNotPaused {
        if (!vaultConfigs[safe].registered) revert SafeNotRegistered(safe);
        if (!whitelistedTokens[token]) revert TokenNotWhitelisted(token);
        if (amount == 0) revert ZeroAmount();
        lastCheckpoints[safe][token] += amount;
        emit DepositRegistered(safe, token, amount);
    }
    function registerWithdrawal(address safe, address token, uint256 amount)
        external
        nonReentrant
        onlyOka
        whenNotPaused
    {
        if (!vaultConfigs[safe].registered) revert SafeNotRegistered(safe);
        if (!whitelistedTokens[token]) revert TokenNotWhitelisted(token);
        if (amount == 0) revert ZeroAmount();
        uint256 current = lastCheckpoints[safe][token];
        if (amount > current) revert WithdrawalExceedsCheckpoint(amount, current);
        lastCheckpoints[safe][token] = current - amount;
        emit WithdrawalRegistered(safe, token, amount);
    }
    function unregisterSafe(address safe) external onlyOka {
        if (!vaultConfigs[safe].registered) revert SafeNotRegistered(safe);
        delete vaultConfigs[safe];
        emit SafeUnregistered(safe);
    }
    function resetCheckpoint(address safe, address token) external onlyOka {
        if (vaultConfigs[safe].registered) revert SafeStillRegistered(safe);
        uint256 oldCheckpoint = lastCheckpoints[safe][token];
        delete lastCheckpoints[safe][token];
        emit CheckpointReset(safe, token, oldCheckpoint);
    }
    function updateFeeBps(address safe, uint16 feeBps) external onlyOka {
        if (!vaultConfigs[safe].registered) revert SafeNotRegistered(safe);
        if (feeBps > MAX_FEE_BPS) revert FeeTooHigh(feeBps, MAX_FEE_BPS);
        uint16 oldFeeBps = vaultConfigs[safe].feeBps;
        vaultConfigs[safe].feeBps = feeBps;
        emit FeeBpsUpdated(safe, oldFeeBps, feeBps);
    }
    function whitelistToken(address token) external onlyOka {
        if (token == address(0)) revert ZeroAddress();
        whitelistedTokens[token] = true;
        emit TokenWhitelisted(token);
    }
    function removeTokenFromWhitelist(address token) external onlyOka {
        whitelistedTokens[token] = false;
        emit TokenRemovedFromWhitelist(token);
    }
    function harvest(address safe, address token) external nonReentrant whenNotPaused {
        if (!vaultConfigs[safe].registered) revert SafeNotRegistered(safe);
        if (!whitelistedTokens[token]) revert TokenNotWhitelisted(token);
        uint256 available = lastHarvestTime[safe] + harvestCooldown;
        if (block.timestamp < available) revert CooldownNotElapsed(available);
        lastHarvestTime[safe] = block.timestamp;
        _harvestInternal(safe, token);
    }
    function _harvestInternal(address safe, address token) internal virtual;
    function _calculateDefensiveFee(uint256 yield_, uint256 currentBalance, uint16 feeBps)
        internal
        view
        returns (uint256 fee)
    {
        fee = (yield_ * feeBps) / 10000;
        fee = _capFee(fee, currentBalance);
        if (fee > yield_) fee = yield_;
        uint256 absoluteCap = (currentBalance * MAX_FEE_BPS) / 10000;
        if (fee > absoluteCap) fee = absoluteCap;
    }
    function _capFee(uint256 fee, uint256 totalBalance) internal view returns (uint256) {
        if (maxHarvestBps == 0) return fee;
        uint256 cap = (totalBalance * maxHarvestBps) / 10000;
        return fee < cap ? fee : cap;
    }
    function _executeFromModule(ISafe safe, address to, uint256 value, bytes memory data) internal {
        bool success = safe.execTransactionFromModule(to, value, data, ISafe.Operation.Call);
        if (!success) revert SafeExecFailed(address(safe), to);
    }
    function _validateCooldown(uint256 _cooldown) internal pure {
        if (_cooldown != 0 && (_cooldown < MIN_COOLDOWN || _cooldown > MAX_COOLDOWN)) {
            revert CooldownOutOfBounds(_cooldown, MIN_COOLDOWN, MAX_COOLDOWN);
        }
    }
}