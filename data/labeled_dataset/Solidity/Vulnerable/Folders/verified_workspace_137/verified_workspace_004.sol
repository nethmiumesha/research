pragma solidity >=0.8.29 <0.9.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICustomStrategyHelper } from "@superearn/v2/interfaces/ICustomStrategyHelper.sol";
import { IMorphoBlue, MorphoMarketParams } from "@superearn/interface/IMorphoBlue.sol";
interface IMultiMorphoDirectAssetsProvider {
    function STRATEGY() external view returns (address);
    function MORPHO() external view returns (address);
    function LOAN_TOKEN() external view returns (address);
    function getMarketIds() external view returns (bytes32[] memory);
}
contract MultiMorphoCustomStrategyHelper is ICustomStrategyHelper {
    uint256 internal constant VIRTUAL_SHARES = 1e6;
    uint256 internal constant VIRTUAL_ASSETS = 1;
    address public immutable PROVIDER;
    address public immutable MORPHO;
    address public immutable LOAN_TOKEN;
    error ZeroAddress();
    error ZeroAmount();
    constructor(address _provider) {
        if (_provider == address(0)) revert ZeroAddress();
        PROVIDER = _provider;
        MORPHO = IMultiMorphoDirectAssetsProvider(_provider).MORPHO();
        LOAN_TOKEN = IMultiMorphoDirectAssetsProvider(_provider).LOAN_TOKEN();
    }
    function getWithdrawCalldata(
        address strategy,
        uint256 amount
    ) external view override returns (address[] memory targets, bytes[] memory calldatas) {
        if (amount == 0) revert ZeroAmount();
        uint256 idleBalance = IERC20(LOAN_TOKEN).balanceOf(strategy);
        if (idleBalance >= amount) {
            return (new address[](0), new bytes[](0));
        }
        uint256 remaining = amount - idleBalance;
        bytes32[] memory marketIds = IMultiMorphoDirectAssetsProvider(PROVIDER).getMarketIds();
        uint256 marketCount = marketIds.length;
        address[] memory tmpTargets = new address[](marketCount);
        bytes[] memory tmpCalldatas = new bytes[](marketCount);
        uint256 count = 0;
        for (uint256 i = 0; i < marketCount; i++) {
            if (remaining == 0) break;
            (uint256 toWithdraw, bytes memory withdrawCalldata) =
                _buildMarketWithdrawCalldata(marketIds[i], strategy, remaining);
            if (toWithdraw == 0) continue;
            tmpTargets[count] = MORPHO;
            tmpCalldatas[count] = withdrawCalldata;
            count++;
            remaining -= toWithdraw;
        }
        targets = new address[](count);
        calldatas = new bytes[](count);
        for (uint256 i = 0; i < count; i++) {
            targets[i] = tmpTargets[i];
            calldatas[i] = tmpCalldatas[i];
        }
    }
    function _buildMarketWithdrawCalldata(
        bytes32 marketId,
        address strategy,
        uint256 remaining
    ) internal view returns (uint256 toWithdraw, bytes memory withdrawCalldata) {
        uint256 supplyAssets = _getSupplyAssets(marketId, strategy);
        if (supplyAssets == 0) return (0, "");
        uint256 availableLiquidity = _getAvailableLiquidity(marketId);
        uint256 withdrawable = supplyAssets < availableLiquidity ? supplyAssets : availableLiquidity;
        if (withdrawable == 0) return (0, "");
        toWithdraw = withdrawable < remaining ? withdrawable : remaining;
        MorphoMarketParams memory marketParams = _getMarketParams(marketId);
        withdrawCalldata = abi.encodeCall(IMorphoBlue.withdraw, (marketParams, toWithdraw, 0, strategy, strategy));
    }
    function _getAvailableLiquidity(bytes32 marketId) internal view returns (uint256) {
        (uint128 totalSupplyAssets,, uint128 totalBorrowAssets,,,) = IMorphoBlue(MORPHO).market(marketId);
        return uint256(totalSupplyAssets) - uint256(totalBorrowAssets);
    }
    function _getMarketParams(bytes32 marketId) internal view returns (MorphoMarketParams memory) {
        (address loanToken, address collateralToken, address oracle, address irm, uint256 lltv) =
            IMorphoBlue(MORPHO).idToMarketParams(marketId);
        return MorphoMarketParams({
            loanToken: loanToken,
            collateralToken: collateralToken,
            oracle: oracle,
            irm: irm,
            lltv: lltv
        });
    }
    function _getSupplyAssets(bytes32 marketId, address strategy) internal view returns (uint256) {
        (uint256 supplyShares,,) = IMorphoBlue(MORPHO).position(marketId, strategy);
        if (supplyShares == 0) return 0;
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) = IMorphoBlue(MORPHO).market(marketId);
        return _toAssetsDown(supplyShares, uint256(totalSupplyAssets), uint256(totalSupplyShares));
    }
    function _toAssetsDown(uint256 shares, uint256 totalAssets, uint256 totalShares) internal pure returns (uint256) {
        return shares * (totalAssets + VIRTUAL_ASSETS) / (totalShares + VIRTUAL_SHARES);
    }
}