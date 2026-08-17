pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function getReserveData(address asset) external view returns (
        uint256, uint128, uint128, uint128, uint128, uint128,
        uint40, uint16,
        address aTokenAddress,
        address, address, address, uint128, uint128, uint128
    );
}
interface IMorphoVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function balanceOf(address account) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}
interface IEthena {
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function cooldownAssets(uint256 assets, address owner) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}
struct AllocationBps {
    uint16 aave;
    uint16 morphoVaultA;
    uint16 morphoVaultB;
    uint16 ethena;
}
struct UserPosition {
    uint256 depositedUsdc;
    uint256 depositedAt;
    bool active;
}
contract BlockRockYieldVault is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    uint256 public constant MAX_DEPOSIT      = 100_000e6;
    uint256 public constant MIN_DEPOSIT      = 1e6;
    uint256 public          vaultTVLCap      = 100_000e6;
    uint256 public constant BPS_DENOMINATOR  = 10_000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public constant MAX_FEE_BPS      = 200;
    address public immutable USDC;
    address public aavePool;
    address public morphoVaultA;
    address public morphoVaultB;
    address public ethenaSUsde;
    uint256 public totalDeposited;
    uint256 public managementFeeBps = 50;
    uint256 public lastFeeAccrual;
    address public feeRecipient;
    address public rebalancer;
    AllocationBps public allocation;
    mapping(address => UserPosition) public positions;
    event Deposited(address indexed user, uint256 usdcAmount, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 usdcReturned);
    event Rebalanced(uint256 timestamp);
    event AllocationsUpdated();
    event FeesAccrued(uint256 usdcAmount);
    event RebalancerUpdated(address newRebalancer);
    event FeeRecipientUpdated(address newRecipient);
    event ManagementFeeUpdated(uint256 newBps);
    event EmergencyPause(address by);
    event TVLCapUpdated(uint256 newCap);
    modifier onlyRebalancer() {
        require(msg.sender == rebalancer || msg.sender == owner(), "Not authorised");
        _;
    }
    constructor(
        address _usdc,
        address _feeRecipient,
        address _rebalancer,
        address[4] memory _protocols
    )
        ERC20("blockrock Yield Vault USDC", "brv-USDC")
        Ownable(msg.sender)
    {
        require(_usdc != address(0),         "Zero USDC");
        require(_feeRecipient != address(0), "Zero fee recipient");
        require(_rebalancer != address(0),   "Zero rebalancer");
        USDC           = _usdc;
        feeRecipient   = _feeRecipient;
        rebalancer     = _rebalancer;
        lastFeeAccrual = block.timestamp;
        aavePool     = _protocols[0];
        morphoVaultA = _protocols[1];
        morphoVaultB = _protocols[2];
        ethenaSUsde  = _protocols[3];
        allocation = AllocationBps({
            aave:        4000,
            morphoVaultA: 3000,
            morphoVaultB: 3000,
            ethena:       0
        });
    }
    function deposit(uint256 usdcAmount)
        external
        nonReentrant
        whenNotPaused
    {
        require(usdcAmount >= MIN_DEPOSIT,                   "Below minimum deposit");
        require(usdcAmount <= MAX_DEPOSIT,                   "Exceeds single-tx cap");
        require(totalDeposited + usdcAmount <= vaultTVLCap,  "TVL cap reached");
        _accrueManagementFee();
        uint256 sharesToMint = _usdcToShares(usdcAmount);
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), usdcAmount);
        _mint(msg.sender, sharesToMint);
        UserPosition storage pos = positions[msg.sender];
        pos.depositedUsdc += usdcAmount;
        pos.depositedAt    = block.timestamp;
        pos.active         = true;
        totalDeposited += usdcAmount;
        _deployCapital(usdcAmount);
        emit Deposited(msg.sender, usdcAmount, sharesToMint);
    }
    function withdraw(uint256 shares)
        external
        nonReentrant
        whenNotPaused
    {
        require(shares > 0,                      "Zero shares");
        require(balanceOf(msg.sender) >= shares, "Insufficient shares");
        _accrueManagementFee();
        uint256 usdcOut = _sharesToUsdc(shares);
        _recallCapital(usdcOut);
        _burn(msg.sender, shares);
        if (totalDeposited >= usdcOut) {
            totalDeposited -= usdcOut;
        } else {
            totalDeposited = 0;
        }
        if (balanceOf(msg.sender) == 0) {
            positions[msg.sender].active = false;
        }
        IERC20(USDC).safeTransfer(msg.sender, usdcOut);
        emit Withdrawn(msg.sender, shares, usdcOut);
    }
    function _deployCapital(uint256 amount) internal {
        AllocationBps memory a = allocation;
        _approveAll(amount);
        if (a.aave > 0 && aavePool != address(0)) {
            uint256 slice = amount * a.aave / BPS_DENOMINATOR;
            IAavePool(aavePool).supply(USDC, slice, address(this), 0);
        }
        if (a.morphoVaultA > 0 && morphoVaultA != address(0)) {
            uint256 slice = amount * a.morphoVaultA / BPS_DENOMINATOR;
            IMorphoVault(morphoVaultA).deposit(slice, address(this));
        }
        if (a.morphoVaultB > 0 && morphoVaultB != address(0)) {
            uint256 slice = amount * a.morphoVaultB / BPS_DENOMINATOR;
            IMorphoVault(morphoVaultB).deposit(slice, address(this));
        }
        if (a.ethena > 0 && ethenaSUsde != address(0)) {
            uint256 slice = amount * a.ethena / BPS_DENOMINATOR;
            IEthena(ethenaSUsde).deposit(slice, address(this));
        }
    }
    function _recallCapital(uint256 amount) internal {
        AllocationBps memory a = allocation;
        if (a.aave > 0 && aavePool != address(0)) {
            uint256 slice = amount * a.aave / BPS_DENOMINATOR;
            IAavePool(aavePool).withdraw(USDC, slice, address(this));
        }
        if (a.morphoVaultA > 0 && morphoVaultA != address(0)) {
            uint256 slice = amount * a.morphoVaultA / BPS_DENOMINATOR;
            IMorphoVault(morphoVaultA).withdraw(slice, address(this), address(this));
        }
        if (a.morphoVaultB > 0 && morphoVaultB != address(0)) {
            uint256 slice = amount * a.morphoVaultB / BPS_DENOMINATOR;
            IMorphoVault(morphoVaultB).withdraw(slice, address(this), address(this));
        }
        if (a.ethena > 0 && ethenaSUsde != address(0)) {
            uint256 slice = amount * a.ethena / BPS_DENOMINATOR;
            IEthena(ethenaSUsde).cooldownAssets(slice, address(this));
        }
    }
    function _approveAll(uint256 amount) internal {
        address[4] memory targets = [aavePool, morphoVaultA, morphoVaultB, ethenaSUsde];
        for (uint i = 0; i < targets.length; i++) {
            if (targets[i] != address(0)) {
                uint256 current = IERC20(USDC).allowance(address(this), targets[i]);
                if (current < amount) {
                    IERC20(USDC).forceApprove(targets[i], type(uint256).max);
                }
            }
        }
    }
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    function totalAssets() public view returns (uint256) {
        uint256 total = IERC20(USDC).balanceOf(address(this));
        if (aavePool != address(0)) {
            try IAavePool(aavePool).getReserveData(USDC) returns (
                uint256, uint128, uint128, uint128, uint128, uint128,
                uint40, uint16, address aToken, address, address, address, uint128, uint128, uint128
            ) {
                if (aToken != address(0)) {
                    total += IERC20(aToken).balanceOf(address(this));
                }
            } catch {}
        }
        if (morphoVaultA != address(0)) {
            uint256 shares = IMorphoVault(morphoVaultA).balanceOf(address(this));
            if (shares > 0) {
                try IMorphoVault(morphoVaultA).convertToAssets(shares) returns (uint256 assets) {
                    total += assets;
                } catch {}
            }
        }
        if (morphoVaultB != address(0)) {
            uint256 shares = IMorphoVault(morphoVaultB).balanceOf(address(this));
            if (shares > 0) {
                try IMorphoVault(morphoVaultB).convertToAssets(shares) returns (uint256 assets) {
                    total += assets;
                } catch {}
            }
        }
        if (ethenaSUsde != address(0)) {
            uint256 shares = IEthena(ethenaSUsde).balanceOf(address(this));
            if (shares > 0) {
                try IEthena(ethenaSUsde).convertToAssets(shares) returns (uint256 assets) {
                    total += assets;
                } catch {}
            }
        }
        return total;
    }
    function sharePrice() public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return 1e6;
        return totalAssets() * 1e6 / supply;
    }
    function _usdcToShares(uint256 usdc) internal view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return usdc;
        return usdc * supply / totalAssets();
    }
    function _sharesToUsdc(uint256 shares) internal view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        return shares * totalAssets() / supply;
    }
    function _accrueManagementFee() internal {
        if (totalDeposited == 0) {
            lastFeeAccrual = block.timestamp;
            return;
        }
        uint256 elapsed = block.timestamp - lastFeeAccrual;
        if (elapsed == 0) return;
        uint256 fee = totalDeposited * managementFeeBps * elapsed
            / (BPS_DENOMINATOR * SECONDS_PER_YEAR);
        lastFeeAccrual = block.timestamp;
        if (fee > 0 && IERC20(USDC).balanceOf(address(this)) >= fee) {
            IERC20(USDC).safeTransfer(feeRecipient, fee);
            emit FeesAccrued(fee);
        }
    }
    function accrueManagementFee() external {
        _accrueManagementFee();
    }
    function rebalance() external onlyRebalancer whenNotPaused {
        _accrueManagementFee();
        emit Rebalanced(block.timestamp);
    }
    function updateAllocations(AllocationBps calldata newAlloc) external onlyOwner {
        uint256 total = uint256(newAlloc.aave)
            + newAlloc.morphoVaultA
            + newAlloc.morphoVaultB
            + newAlloc.ethena;
        require(total == BPS_DENOMINATOR, "Allocations must sum to 100%");
        allocation = newAlloc;
        emit AllocationsUpdated();
    }
    function getUserPosition(address user) external view returns (UserPosition memory) {
        return positions[user];
    }
    function getUserValue(address user) external view returns (uint256 usdcValue) {
        uint256 shares = balanceOf(user);
        return _sharesToUsdc(shares);
    }
    function getAllocation() external view returns (AllocationBps memory) {
        return allocation;
    }
    function pause() external onlyOwner {
        _pause();
        emit EmergencyPause(msg.sender);
    }
    function unpause() external onlyOwner {
        _unpause();
    }
    function rescueToken(address token, uint256 amount) external onlyOwner {
        require(token != USDC, "Cannot rescue USDC principal");
        IERC20(token).safeTransfer(owner(), amount);
    }
    function setTVLCap(uint256 _cap) external onlyOwner {
        require(_cap >= totalDeposited, "Cap below current TVL");
        vaultTVLCap = _cap;
        emit TVLCapUpdated(_cap);
    }
    function setRebalancer(address _r) external onlyOwner {
        require(_r != address(0), "Zero address");
        rebalancer = _r;
        emit RebalancerUpdated(_r);
    }
    function setFeeRecipient(address _f) external onlyOwner {
        require(_f != address(0), "Zero address");
        feeRecipient = _f;
        emit FeeRecipientUpdated(_f);
    }
    function setManagementFee(uint256 _bps) external onlyOwner {
        require(_bps <= MAX_FEE_BPS, "Exceeds 2% cap");
        managementFeeBps = _bps;
        emit ManagementFeeUpdated(_bps);
    }
}