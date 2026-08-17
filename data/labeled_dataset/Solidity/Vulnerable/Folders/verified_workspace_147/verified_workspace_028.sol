pragma solidity ^0.8.17;
import "../../../interfaces/IStandardizedYield.sol";
import "../../erc20/PendleERC20Upg.sol";
import "../../libraries/math/PMath.sol";
import "../../libraries/ArrayLib.sol";
import "../../libraries/TokenHelper.sol";
import "../../libraries/Errors.sol";
import "../../libraries/BoringOwnableUpgradeableV2.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../../interfaces/IStandardizedYieldExtended.sol";
abstract contract SYBaseUpgV2 is IStandardizedYield, PendleERC20Upg, TokenHelper, BoringOwnableUpgradeableV2, Pausable {
    using PMath for uint256;
    address public immutable yieldToken;
    uint256[100] private __gap;
    constructor(address _yieldToken) PendleERC20Upg(IERC20Metadata(_yieldToken).decimals()) {
        yieldToken = _yieldToken;
        _disableInitializers();
    }
    function __SYBaseUpgV2_init(string memory name_, string memory symbol_, address _owner) internal onlyInitializing {
        __ERC20Upg_init(name_, symbol_);
        __BoringOwnableV2_init(_owner);
    }
    receive() external payable {}
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    ) external payable nonReentrant returns (uint256 amountSharesOut) {
        if (!isValidTokenIn(tokenIn)) revert Errors.SYInvalidTokenIn(tokenIn);
        if (amountTokenToDeposit == 0) revert Errors.SYZeroDeposit();
        _transferIn(tokenIn, msg.sender, amountTokenToDeposit);
        amountSharesOut = _deposit(tokenIn, amountTokenToDeposit);
        if (amountSharesOut < minSharesOut) revert Errors.SYInsufficientSharesOut(amountSharesOut, minSharesOut);
        _mint(receiver, amountSharesOut);
        emit Deposit(msg.sender, receiver, tokenIn, amountTokenToDeposit, amountSharesOut);
    }
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external nonReentrant returns (uint256 amountTokenOut) {
        if (!isValidTokenOut(tokenOut)) revert Errors.SYInvalidTokenOut(tokenOut);
        if (amountSharesToRedeem == 0) revert Errors.SYZeroRedeem();
        if (burnFromInternalBalance) {
            _burn(address(this), amountSharesToRedeem);
        } else {
            _burn(msg.sender, amountSharesToRedeem);
        }
        amountTokenOut = _redeem(receiver, tokenOut, amountSharesToRedeem);
        if (amountTokenOut < minTokenOut) revert Errors.SYInsufficientTokenOut(amountTokenOut, minTokenOut);
        emit Redeem(msg.sender, receiver, tokenOut, amountSharesToRedeem, amountTokenOut);
    }
    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual returns (uint256 amountSharesOut);
    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal virtual returns (uint256 amountTokenOut);
    function exchangeRate() external view virtual override returns (uint256 res);
    function claimRewards(address ) external virtual override returns (uint256[] memory rewardAmounts) {
        rewardAmounts = new uint256[](0);
    }
    function getRewardTokens() external view virtual override returns (address[] memory rewardTokens) {
        rewardTokens = new address[](0);
    }
    function accruedRewards(address ) external view virtual override returns (uint256[] memory rewardAmounts) {
        rewardAmounts = new uint256[](0);
    }
    function rewardIndexesCurrent() external virtual override returns (uint256[] memory indexes) {
        indexes = new uint256[](0);
    }
    function rewardIndexesStored() external view virtual override returns (uint256[] memory indexes) {
        indexes = new uint256[](0);
    }
    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) external view virtual returns (uint256 amountSharesOut) {
        if (!isValidTokenIn(tokenIn)) revert Errors.SYInvalidTokenIn(tokenIn);
        return _previewDeposit(tokenIn, amountTokenToDeposit);
    }
    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) external view virtual returns (uint256 amountTokenOut) {
        if (!isValidTokenOut(tokenOut)) revert Errors.SYInvalidTokenOut(tokenOut);
        return _previewRedeem(tokenOut, amountSharesToRedeem);
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(address, address, uint256) internal virtual override whenNotPaused {}
    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view virtual returns (uint256 amountSharesOut);
    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view virtual returns (uint256 amountTokenOut);
    function getTokensIn() public view virtual returns (address[] memory res);
    function getTokensOut() public view virtual returns (address[] memory res);
    function isValidTokenIn(address token) public view virtual returns (bool);
    function isValidTokenOut(address token) public view virtual returns (bool);
    function pricingInfo() external view virtual returns (address refToken, bool refStrictlyEqual) {
        return (yieldToken, true);
    }
}