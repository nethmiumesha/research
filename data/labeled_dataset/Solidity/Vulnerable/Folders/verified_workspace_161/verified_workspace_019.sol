pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IHandler} from "./interfaces/IHandler.sol";
import {IMorpho, MarketParams} from "./interfaces/IMorpho.sol";
import {IAToken} from "./interfaces/IAToken.sol";
import {IAavePool} from "./interfaces/IAavePool.sol";
contract VaultHopper is Ownable {
    error InvalidAddress();
    error HandlerNotWhitelisted();
    error InvalidParams();
    error MorphoBlueAlreadySet();
    error InvalidMorphoMarket();
    using SafeERC20 for IERC20;
    enum SourceType { ASSET, VAULT, MORPHO_MARKET, AAVE_A_TOKEN }
    address internal constant SAME_CHAIN_VAULT_DEPOSIT = address(0);
    address internal constant SAME_CHAIN_MORPHO_MARKET_DEPOSIT = address(1);
    uint256 public constant MAX_PROTOCOL_FEE_USDC = 10e6;
    uint256 public constant VERSION = 1;
    event HandlerSet(address indexed handler, bool status);
    event FeeRecipientSet(address feeRecipient);
    event ExecutedWithHandler(
        address indexed sender,
        address indexed startToken,
        address indexed handler,
        SourceType sourceType,
        address asset,
        uint256 shares,
        uint256 assets,
        bytes32 sourceMorphoMarketId,
        address receiver
    );
    mapping(address => bool) public whitelistedHandlers;
    address public feeRecipient;
    address public morphoBlue;
    constructor(address _owner) Ownable(_owner) {}
    function setHandler(address handler, bool status) external onlyOwner {
        if (handler == address(0)) revert InvalidAddress();
        whitelistedHandlers[handler] = status;
        emit HandlerSet(handler, status);
    }
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientSet(_feeRecipient);
    }
    function setMorphoBlue(address _morphoBlue) external onlyOwner {
        if (morphoBlue != address(0)) revert MorphoBlueAlreadySet();
        if (_morphoBlue == address(0)) revert InvalidAddress();
        morphoBlue = _morphoBlue;
    }
    function executeWithHandler(
        address startToken,
        SourceType sourceType,
        uint256 shares,
        uint256 assetsToWithdraw,
        address handler,
        bytes calldata handlerData,
        bytes32 sourceMorphoMarketId,
        address receiver
    )
        public
        payable
        returns (uint256 assetAmount)
    {
        if (startToken == address(0) || receiver == address(0)) revert InvalidAddress();
        if ((shares == 0) == (assetsToWithdraw == 0)) revert InvalidParams();
        IERC20 asset;
        if (sourceType == SourceType.VAULT) {
            (asset, assetAmount) = _withdrawFromVault(startToken, shares, assetsToWithdraw);
        }
        else if (sourceType == SourceType.MORPHO_MARKET) {
            (asset, assetAmount) = _withdrawFromMorpho(shares, assetsToWithdraw, sourceMorphoMarketId);
        }
        else if (sourceType == SourceType.AAVE_A_TOKEN) {
            (asset, assetAmount) = _withdrawFromAave(startToken, assetsToWithdraw);
        }
        else {
            asset = IERC20(startToken);
            asset.safeTransferFrom(msg.sender, address(this), assetsToWithdraw);
            assetAmount = assetsToWithdraw;
        }
        if (handler == SAME_CHAIN_VAULT_DEPOSIT) {
            _depositToVault(asset, assetAmount, handlerData, receiver);
        } else if (handler == SAME_CHAIN_MORPHO_MARKET_DEPOSIT) {
            _depositToMorpho(asset, assetAmount, handlerData, receiver);
        } else {
            if (!whitelistedHandlers[handler]) revert HandlerNotWhitelisted();
            asset.safeIncreaseAllowance(handler, assetAmount);
            IHandler(handler).executeOnSourceChain{value: msg.value}(address(asset), receiver, assetAmount, handlerData);
        }
        emit ExecutedWithHandler(msg.sender, startToken, handler, sourceType, address(asset), shares, assetAmount, sourceMorphoMarketId, receiver);
    }
    function permitAndExecuteWithHandler(
        address startToken,
        SourceType sourceType,
        uint256 shares,
        uint256 assetsToWithdraw,
        address handler,
        bytes calldata handlerData,
        bytes32 sourceMorphoMarketId,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        payable
        returns (uint256 assetAmount)
    {
        uint256 permitAmount = (sourceType == SourceType.VAULT && shares > 0) ? shares : assetsToWithdraw;
        if (assetsToWithdraw > 0) {
            shares = 0;
        }
        try IERC20Permit(startToken).permit(
            msg.sender,
            address(this),
            permitAmount,
            deadline,
            v,
            r,
            s
        ) {} catch {}
        return executeWithHandler(
            startToken,
            sourceType,
            shares,
            assetsToWithdraw,
            handler,
            handlerData,
            sourceMorphoMarketId,
            receiver
        );
    }
    function _withdrawFromVault(address vault, uint256 shares, uint256 assetsToWithdraw) internal returns (IERC20 asset, uint256 assetAmount) {
        IERC4626 vaultToken = IERC4626(vault);
        asset = IERC20(vaultToken.asset());
        uint256 balanceBefore = asset.balanceOf(address(this));
        if (shares > 0) {
            assetAmount = vaultToken.redeem(shares, address(this), msg.sender);
        } else {
            vaultToken.withdraw(assetsToWithdraw, address(this), msg.sender);
            assetAmount = assetsToWithdraw;
        }
        require(asset.balanceOf(address(this)) - balanceBefore == assetAmount, "Invalid vault");
    }
    function _withdrawFromMorpho(uint256 shares, uint256 assetsToWithdraw, bytes32 sourceMorphoMarketId) internal returns (IERC20 asset, uint256 assetAmount) {
        MarketParams memory mp = _getMorphoMarketParams(sourceMorphoMarketId);
        asset = IERC20(mp.loanToken);
        uint256 balanceBefore = asset.balanceOf(address(this));
        (assetAmount,) = IMorpho(morphoBlue).withdraw(mp, assetsToWithdraw, shares, msg.sender, address(this));
        require(asset.balanceOf(address(this)) - balanceBefore == assetAmount, "Invalid morpho withdraw");
    }
    function _withdrawFromAave(address aToken, uint256 assetsToWithdraw) internal returns (IERC20 asset, uint256 assetAmount) {
        address underlying = IAToken(aToken).UNDERLYING_ASSET_ADDRESS();
        address pool = IAToken(aToken).POOL();
        asset = IERC20(underlying);
        IERC20(aToken).safeTransferFrom(msg.sender, address(this), assetsToWithdraw);
        uint256 balanceBefore = asset.balanceOf(address(this));
        IAavePool(pool).withdraw(underlying, assetsToWithdraw, address(this));
        assetAmount = asset.balanceOf(address(this)) - balanceBefore;
    }
    function _depositToVault(IERC20 asset, uint256 assetAmount, bytes calldata handlerData, address receiver) internal {
        (address toVault) = abi.decode(handlerData, (address));
        asset.safeIncreaseAllowance(toVault, assetAmount);
        IERC4626(toVault).deposit(assetAmount, receiver);
    }
    function _depositToMorpho(IERC20 asset, uint256 assetAmount, bytes calldata handlerData, address receiver) internal {
        (MarketParams memory mp) = abi.decode(handlerData, (MarketParams));
        asset.safeIncreaseAllowance(morphoBlue, assetAmount);
        IMorpho(morphoBlue).supply(mp, assetAmount, 0, receiver, "");
    }
    function _getMorphoMarketParams(bytes32 morphoMarketId) internal view returns (MarketParams memory mp) {
        mp = IMorpho(morphoBlue).idToMarketParams(morphoMarketId);
        if (mp.loanToken == address(0)) revert InvalidMorphoMarket();
    }
}