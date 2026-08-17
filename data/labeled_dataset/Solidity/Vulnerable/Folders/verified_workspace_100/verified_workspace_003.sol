pragma solidity =0.7.6;
pragma abicoder v2;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IController} from "../interfaces/IController.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {IWPowerPerp} from "../interfaces/IWPowerPerp.sol";
import {IShortPowerPerp} from "../interfaces/IShortPowerPerp.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {VaultLib} from "../libs/VaultLib.sol";
import {Uint256Casting} from "../libs/Uint256Casting.sol";
import {Power2Base} from "../libs/Power2Base.sol";
contract LiquidationHelper  {
    using SafeMath for uint256;
    using Uint256Casting for uint256;
    using VaultLib for VaultLib.Vault;
    uint256 public constant MIN_COLLATERAL = 0.5 ether;
    uint32 public constant TWAP_PERIOD = 5 minutes;
    address immutable public controller;
    address immutable public oracle;
    address immutable public wPowerPerp;
    address immutable public weth;
    address immutable public quoteCurrency;
    address immutable public ethQuoteCurrencyPool;
    address immutable public wPowerPerpPool;
    address immutable public uniswapPositionManager;
    bool immutable isWethToken0;
    constructor(
        address _controller,
        address _oracle,
        address _wPowerPerp,
        address _weth,
        address _quoteCurrency,
        address _ethQuoteCurrencyPool,
        address _wPowerPerpPool,
        address _uniPositionManager
    ) {
        controller = _controller;
        oracle = _oracle;
        wPowerPerp = _wPowerPerp;
        weth = _weth;
        quoteCurrency = _quoteCurrency;
        ethQuoteCurrencyPool = _ethQuoteCurrencyPool;
        wPowerPerpPool = _wPowerPerpPool;
        uniswapPositionManager = _uniPositionManager;
        isWethToken0 = _weth < _wPowerPerp;
    }
    function checkLiquidation(uint256 _vaultId)
        external
        view
        returns (
            bool,
            bool,
            uint256,
            uint256
        )
    {
        uint256 _newNormalizationFactor = IController(controller).getExpectedNormalizationFactor();
        return _checkLiquidation(_vaultId, _newNormalizationFactor);
    }
    function _isVaultSafe(VaultLib.Vault memory _vault, uint256 _normalizationFactor) internal view returns (bool) {
        (bool isSafe, ) = _getVaultStatus(_vault, _normalizationFactor);
        return isSafe;
    }
    function _getVaultStatus(VaultLib.Vault memory _vault, uint256 _normalizationFactor)
        internal
        view
        returns (bool, bool)
    {
        uint256 scaledEthPrice = Power2Base._getScaledTwap(
            oracle,
            ethQuoteCurrencyPool,
            weth,
            quoteCurrency,
            TWAP_PERIOD,
            true
        );
        return
            VaultLib.getVaultStatus(
                _vault,
                uniswapPositionManager,
                _normalizationFactor,
                scaledEthPrice,
                MIN_COLLATERAL,
                IOracle(oracle).getTimeWeightedAverageTickSafe(wPowerPerpPool, TWAP_PERIOD),
                isWethToken0
            );
    }
    function _checkLiquidation(uint256 _vaultId, uint256 _normalizationFactor)
        internal
        view
        returns (
            bool,
            bool,
            uint256,
            uint256
        )
    {
        VaultLib.Vault memory cachedVault = IController(controller).vaults(_vaultId);
        if (_isVaultSafe(cachedVault, _normalizationFactor)) {
            return (false, false, 0, 0);
        }
        if (cachedVault.NftCollateralId != 0) {
            (, int24 spotTick, , , , , ) = IUniswapV3Pool(wPowerPerpPool).slot0();
            (uint256 nftEthAmount, uint256 nftWPowerperpAmount) = VaultLib._getUniPositionBalances(
                uniswapPositionManager,
                cachedVault.NftCollateralId,
                spotTick,
                isWethToken0
            );
            (, , uint256 bounty) = _getReduceDebtResultInVault(
                cachedVault,
                nftEthAmount,
                nftWPowerperpAmount,
                _normalizationFactor,
                true
            );
            if (_isVaultSafe(cachedVault, _normalizationFactor)) {
                return (true, false, 0, bounty);
            }
            cachedVault.addEthCollateral(bounty);
        }
        (uint256 wMaxAmountToLiquidate, uint256 collateralToPay) = _getLiquidationResult(
            cachedVault.shortAmount,
            cachedVault.shortAmount,
            cachedVault.collateralAmount,
            _normalizationFactor
        );
        return (true, true, wMaxAmountToLiquidate, collateralToPay);
    }
    function _getReduceDebtResultInVault(
        VaultLib.Vault memory _vault,
        uint256 nftEthAmount,
        uint256 nftWPowerperpAmount,
        uint256 _normalizationFactor,
        bool _payBounty
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 bounty;
        if (_payBounty) bounty = _getReduceDebtBounty(nftEthAmount, nftWPowerperpAmount, _normalizationFactor);
        uint256 burnAmount = nftWPowerperpAmount;
        uint256 wPowerPerpExcess;
        if (nftWPowerperpAmount > _vault.shortAmount) {
            wPowerPerpExcess = nftWPowerperpAmount.sub(_vault.shortAmount);
            burnAmount = _vault.shortAmount;
        }
        _vault.removeShort(burnAmount);
        _vault.removeUniNftCollateral();
        _vault.addEthCollateral(nftEthAmount);
        _vault.removeEthCollateral(bounty);
        return (burnAmount, wPowerPerpExcess, bounty);
    }
    function _getReduceDebtBounty(
        uint256 _ethWithdrawn,
        uint256 _wPowerPerpReduced,
        uint256 _normalizationFactor
    ) internal view returns (uint256) {
        return
            Power2Base
                ._getDebtValueInEth(
                    _wPowerPerpReduced,
                    oracle,
                    ethQuoteCurrencyPool,
                    weth,
                    quoteCurrency,
                    _normalizationFactor
                )
                .add(_ethWithdrawn)
                .mul(2)
                .div(100);
    }
    function _getLiquidationResult(
        uint256 _maxWPowerPerpAmount,
        uint256 _vaultShortAmount,
        uint256 _vaultCollateralAmount,
        uint256 _normalizationFactor
    ) internal view returns (uint256, uint256) {
        (uint256 finalLiquidateAmount, uint256 collateralToPay) = _getSingleLiquidationAmount(
            _maxWPowerPerpAmount,
            _vaultShortAmount.div(2),
            _normalizationFactor
        );
        if (_vaultCollateralAmount > collateralToPay) {
            if (_vaultCollateralAmount.sub(collateralToPay) < MIN_COLLATERAL) {
                (finalLiquidateAmount, collateralToPay) = _getSingleLiquidationAmount(
                    _maxWPowerPerpAmount,
                    _vaultShortAmount,
                    _normalizationFactor
                );
            }
        }
        if (collateralToPay > _vaultCollateralAmount) {
            finalLiquidateAmount = _vaultShortAmount;
            collateralToPay = _vaultCollateralAmount;
        }
        return (finalLiquidateAmount, collateralToPay);
    }
    function _getSingleLiquidationAmount(
        uint256 _maxInputWAmount,
        uint256 _maxLiquidatableWAmount,
        uint256 _normalizationFactor
    ) internal view returns (uint256, uint256) {
        uint256 finalWAmountToLiquidate = _maxInputWAmount > _maxLiquidatableWAmount
            ? _maxLiquidatableWAmount
            : _maxInputWAmount;
        uint256 collateralToPay = Power2Base._getDebtValueInEth(
            finalWAmountToLiquidate,
            oracle,
            ethQuoteCurrencyPool,
            weth,
            quoteCurrency,
            _normalizationFactor
        );
        collateralToPay = collateralToPay.add(collateralToPay.div(10));
        return (finalWAmountToLiquidate, collateralToPay);
    }
}