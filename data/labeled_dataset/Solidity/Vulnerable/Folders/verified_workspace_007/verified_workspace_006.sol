pragma solidity ^0.8.2;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}
interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);
    function symbol() external view returns (string calldata);
    function decimals() external view returns (uint256);
    function apiVersion() external pure returns (string memory);
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);
    function deposit() external returns (uint256);
    function deposit(uint256 amount) external returns (uint256);
    function deposit(uint256 amount, address recipient) external returns (uint256);
    function withdraw() external returns (uint256);
    function withdraw(uint256 maxShares) external returns (uint256);
    function withdraw(uint256 maxShares, address recipient) external returns (uint256);
    function token() external view returns (address);
    function strategies(address _strategy) external view returns (StrategyParams memory);
    function pricePerShare() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function depositLimit() external view returns (uint256);
    function maxAvailableShares() external view returns (uint256);
    function creditAvailable() external view returns (uint256);
    function debtOutstanding() external view returns (uint256);
    function expectedReturn() external view returns (uint256);
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);
    function revokeStrategy() external;
    function governance() external view returns (address);
    function management() external view returns (address);
    function guardian() external view returns (address);
}
interface RegistryAPI {
    function governance() external view returns (address);
    function latestVault(address token) external view returns (address);
    function numVaults(address token) external view returns (uint256);
    function vaults(address token, uint256 deploymentId) external view returns (address);
}
abstract contract BaseWrapperImplementation {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public token;
    VaultAPI[] private _cachedVaults;
    RegistryAPI public registry;
    uint256 constant UNLIMITED_APPROVAL = type(uint256).max;
    uint256 constant DEPOSIT_EVERYTHING = type(uint256).max;
    uint256 constant WITHDRAW_EVERYTHING = type(uint256).max;
    uint256 constant MIGRATE_EVERYTHING = type(uint256).max;
    uint256 constant UNCAPPED_DEPOSITS = type(uint256).max;
    function setRegistry(address _registry) external {
        require(msg.sender == registry.governance());
        registry = RegistryAPI(_registry);
        require(msg.sender == registry.governance());
    }
    function bestVault() public view virtual returns (VaultAPI) {
        return VaultAPI(registry.latestVault(address(token)));
    }
    function allVaults() public view virtual returns (VaultAPI[] memory) {
        uint256 cache_length = _cachedVaults.length;
        uint256 num_vaults = registry.numVaults(address(token));
        if (cache_length == num_vaults) {
            return _cachedVaults;
        }
        VaultAPI[] memory vaults = new VaultAPI[](num_vaults);
        for (uint256 vault_id = 0; vault_id < cache_length; vault_id++) {
            vaults[vault_id] = _cachedVaults[vault_id];
        }
        for (uint256 vault_id = cache_length; vault_id < num_vaults; vault_id++) {
            vaults[vault_id] = VaultAPI(registry.vaults(address(token), vault_id));
        }
        return vaults;
    }
    function _updateVaultCache(VaultAPI[] memory vaults) internal {
        if (vaults.length > _cachedVaults.length) {
            _cachedVaults = vaults;
        }
    }
    function totalVaultBalance(address account) public view returns (uint256 balance) {
        VaultAPI[] memory vaults = allVaults();
        for (uint256 id = 0; id < vaults.length; id++) {
            balance = balance.add(vaults[id].balanceOf(account).mul(vaults[id].pricePerShare()).div(10**uint256(vaults[id].decimals())));
        }
    }
    function totalAssets() public view returns (uint256 assets) {
        VaultAPI[] memory vaults = allVaults();
        for (uint256 id = 0; id < vaults.length; id++) {
            assets = assets.add(vaults[id].totalAssets());
        }
    }
    function _deposit(
        address depositor,
        address receiver,
        uint256 amount,
        bool pullFunds
    ) internal returns (uint256 deposited) {
        VaultAPI _bestVault = bestVault();
        if (pullFunds) {
            if (amount != DEPOSIT_EVERYTHING) {
                token.safeTransferFrom(depositor, address(this), amount);
            } else {
                token.safeTransferFrom(depositor, address(this), token.balanceOf(depositor));
            }
        }
        if (token.allowance(address(this), address(_bestVault)) < amount) {
            token.safeApprove(address(_bestVault), 0);
            token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL);
        }
        uint256 beforeBal = token.balanceOf(address(this));
        if (receiver != address(this)) {
            _bestVault.deposit(amount, receiver);
        } else if (amount != DEPOSIT_EVERYTHING) {
            _bestVault.deposit(amount);
        } else {
            _bestVault.deposit();
        }
        uint256 afterBal = token.balanceOf(address(this));
        deposited = beforeBal.sub(afterBal);
        if (depositor != address(this) && afterBal > 0) token.safeTransfer(depositor, afterBal);
    }
    function _withdraw(
        address sender,
        address receiver,
        uint256 amount,
        bool withdrawFromBest
    ) internal returns (uint256 withdrawn) {
        VaultAPI _bestVault = bestVault();
        VaultAPI[] memory vaults = allVaults();
        _updateVaultCache(vaults);
        for (uint256 id = 0; id < vaults.length; id++) {
            if (!withdrawFromBest && vaults[id] == _bestVault) {
                continue;
            }
            uint256 availableShares = vaults[id].balanceOf(sender);
            if (sender != address(this)) {
                availableShares = Math.min(availableShares, vaults[id].allowance(sender, address(this)));
            }
            availableShares = Math.min(availableShares, vaults[id].maxAvailableShares());
            if (availableShares > 0) {
                if (sender != address(this)) vaults[id].transferFrom(sender, address(this), availableShares);
                if (amount != WITHDRAW_EVERYTHING) {
                    uint256 estimatedShares =
                        amount
                            .sub(withdrawn)
                            .mul(10**uint256(vaults[id].decimals()))
                            .div(vaults[id].pricePerShare());
                    if (estimatedShares > 0 && estimatedShares < availableShares) {
                        withdrawn = withdrawn.add(vaults[id].withdraw(estimatedShares));
                    } else {
                        withdrawn = withdrawn.add(vaults[id].withdraw(availableShares));
                    }
                } else {
                    withdrawn = withdrawn.add(vaults[id].withdraw());
                }
                if (amount <= withdrawn) break;
            }
        }
        if (withdrawn > amount && withdrawn.sub(amount) > _bestVault.pricePerShare().div(10**_bestVault.decimals())) {
            if (token.allowance(address(this), address(_bestVault)) < withdrawn.sub(amount)) {
                token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL);
            }
            _bestVault.deposit(withdrawn.sub(amount), sender);
            withdrawn = amount;
        }
        if (receiver != address(this)) token.safeTransfer(receiver, withdrawn);
    }
    function _migrate(address account) internal returns (uint256) {
        return _migrate(account, MIGRATE_EVERYTHING);
    }
    function _migrate(address account, uint256 amount) internal returns (uint256) {
        return _migrate(account, amount, 0);
    }
    function _migrate(
        address account,
        uint256 amount,
        uint256 maxMigrationLoss
    ) internal returns (uint256 migrated) {
        VaultAPI _bestVault = bestVault();
        uint256 _depositLimit = _bestVault.depositLimit();
        uint256 _totalAssets = _bestVault.totalAssets();
        if (_depositLimit <= _totalAssets) return 0;
        uint256 _amount = amount;
        if (_depositLimit < UNCAPPED_DEPOSITS && _amount < WITHDRAW_EVERYTHING) {
            uint256 _depositLeft = _depositLimit.sub(_totalAssets);
            if (_amount > _depositLeft) _amount = _depositLeft;
        }
        if (_amount > 0) {
            uint256 withdrawn = _withdraw(account, address(this), _amount, false);
            if (withdrawn == 0) return 0;
            migrated = _deposit(address(this), account, withdrawn, false);
            require(withdrawn.sub(migrated) <= maxMigrationLoss);
        }
    }
}