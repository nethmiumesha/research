pragma solidity 0.5.11;
import { ICurvePool } from "./ICurvePool.sol";
import { ICurveGauge } from "./ICurveGauge.sol";
import { ICRVMinter } from "./ICRVMinter.sol";
import {
    IERC20,
    InitializableAbstractStrategy
} from "../utils/InitializableAbstractStrategy.sol";
import { StableMath } from "../utils/StableMath.sol";
import { Helpers } from "../utils/Helpers.sol";
contract ThreePoolStrategy is InitializableAbstractStrategy {
    using StableMath for uint256;
    event RewardTokenCollected(address recipient, uint256 amount);
    address crvGaugeAddress;
    address crvMinterAddress;
    uint256 constant maxSlippage = 1e16;
    function initialize(
        address _platformAddress,
        address _vaultAddress,
        address _rewardTokenAddress,
        address[] calldata _assets,
        address[] calldata _pTokens,
        address _crvGaugeAddress,
        address _crvMinterAddress
    ) external onlyGovernor initializer {
        crvGaugeAddress = _crvGaugeAddress;
        crvMinterAddress = _crvMinterAddress;
        InitializableAbstractStrategy._initialize(
            _platformAddress,
            _vaultAddress,
            _rewardTokenAddress,
            _assets,
            _pTokens
        );
    }
    function collectRewardToken() external onlyVault nonReentrant {
        IERC20 crvToken = IERC20(rewardTokenAddress);
        ICRVMinter minter = ICRVMinter(crvMinterAddress);
        uint256 balance = crvToken.balanceOf(address(this));
        emit RewardTokenCollected(vaultAddress, balance);
        minter.mint(crvGaugeAddress);
        crvToken.safeTransfer(vaultAddress, balance);
    }
    function deposit(address _asset, uint256 _amount)
        external
        onlyVault
        nonReentrant
    {
        require(_amount > 0, "Must deposit something");
        emit Deposit(_asset, address(platformAddress), _amount);
        uint256[3] memory _amounts;
        uint256 poolCoinIndex = _getPoolCoinIndex(_asset);
        _amounts[poolCoinIndex] = _amount;
        ICurvePool curvePool = ICurvePool(platformAddress);
        uint256 assetDecimals = Helpers.getDecimals(_asset);
        uint256 depositValue = _amount
            .scaleBy(int8(18 - assetDecimals))
            .divPrecisely(curvePool.get_virtual_price());
        uint256 minMintAmount = depositValue.mulTruncate(
            uint256(1e18).sub(maxSlippage)
        );
        curvePool.add_liquidity(_amounts, minMintAmount);
        IERC20 pToken = IERC20(assetToPToken[_asset]);
        ICurveGauge(crvGaugeAddress).deposit(
            pToken.balanceOf(address(this)),
            address(this)
        );
    }
    function depositAll() external onlyVault nonReentrant {
        uint256[3] memory _amounts = [uint256(0), uint256(0), uint256(0)];
        uint256 depositValue = 0;
        ICurvePool curvePool = ICurvePool(platformAddress);
        for (uint256 i = 0; i < assetsMapped.length; i++) {
            address assetAddress = assetsMapped[i];
            uint256 balance = IERC20(assetAddress).balanceOf(address(this));
            if (balance > 0) {
                uint256 poolCoinIndex = _getPoolCoinIndex(assetAddress);
                _amounts[poolCoinIndex] = balance;
                uint256 assetDecimals = Helpers.getDecimals(assetAddress);
                depositValue = depositValue.add(
                    balance.scaleBy(int8(18 - assetDecimals)).divPrecisely(
                        curvePool.get_virtual_price()
                    )
                );
                emit Deposit(assetAddress, address(platformAddress), balance);
            }
        }
        uint256 minMintAmount = depositValue.mulTruncate(
            uint256(1e18).sub(maxSlippage)
        );
        curvePool.add_liquidity(_amounts, minMintAmount);
        IERC20 pToken = IERC20(assetToPToken[assetsMapped[0]]);
        ICurveGauge(crvGaugeAddress).deposit(
            pToken.balanceOf(address(this)),
            address(this)
        );
    }
    function withdraw(
        address _recipient,
        address _asset,
        uint256 _amount
    ) external onlyVault nonReentrant {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Invalid amount");
        emit Withdrawal(_asset, address(assetToPToken[_asset]), _amount);
        (uint256 contractPTokens, , uint256 totalPTokens) = _getTotalPTokens();
        require(totalPTokens > 0, "Insufficient 3CRV balance");
        uint256 poolCoinIndex = _getPoolCoinIndex(_asset);
        ICurvePool curvePool = ICurvePool(platformAddress);
        uint256 maxAmount = curvePool.calc_withdraw_one_coin(
            totalPTokens,
            int128(poolCoinIndex)
        );
        uint256 withdrawPTokens = totalPTokens.mul(_amount).div(maxAmount);
        if (contractPTokens < withdrawPTokens) {
            ICurveGauge(crvGaugeAddress).withdraw(
                withdrawPTokens.sub(contractPTokens)
            );
        }
        uint256 assetDecimals = Helpers.getDecimals(_asset);
        uint256 minWithdrawAmount = withdrawPTokens
            .mulTruncate(uint256(1e18).sub(maxSlippage))
            .scaleBy(int8(assetDecimals - 18));
        curvePool.remove_liquidity_one_coin(
            withdrawPTokens,
            int128(poolCoinIndex),
            minWithdrawAmount
        );
        IERC20(_asset).safeTransfer(_recipient, _amount);
        uint256 dust = IERC20(_asset).balanceOf(address(this));
        if (dust > 0) {
            IERC20(_asset).safeTransfer(vaultAddress, dust);
        }
    }
    function withdrawAll() external onlyVaultOrGovernor nonReentrant {
        (, uint256 gaugePTokens, uint256 totalPTokens) = _getTotalPTokens();
        ICurveGauge(crvGaugeAddress).withdraw(gaugePTokens);
        uint256[3] memory minWithdrawAmounts = [
            uint256(0),
            uint256(0),
            uint256(0)
        ];
        for (uint256 i = 0; i < assetsMapped.length; i++) {
            address assetAddress = assetsMapped[i];
            uint256 virtualBalance = checkBalance(assetAddress);
            uint256 poolCoinIndex = _getPoolCoinIndex(assetAddress);
            minWithdrawAmounts[poolCoinIndex] = virtualBalance.mulTruncate(
                uint256(1e18).sub(maxSlippage)
            );
        }
        ICurvePool threePool = ICurvePool(platformAddress);
        threePool.remove_liquidity(totalPTokens, minWithdrawAmounts);
        for (uint256 i = 0; i < assetsMapped.length; i++) {
            IERC20 asset = IERC20(threePool.coins(i));
            asset.safeTransfer(vaultAddress, asset.balanceOf(address(this)));
        }
    }
    function checkBalance(address _asset)
        public
        view
        returns (uint256 balance)
    {
        require(assetToPToken[_asset] != address(0), "Unsupported asset");
        (, , uint256 totalPTokens) = _getTotalPTokens();
        ICurvePool curvePool = ICurvePool(platformAddress);
        uint256 pTokenTotalSupply = IERC20(assetToPToken[_asset]).totalSupply();
        if (pTokenTotalSupply > 0) {
            uint256 poolCoinIndex = _getPoolCoinIndex(_asset);
            uint256 curveBalance = curvePool.balances(poolCoinIndex);
            if (curveBalance > 0) {
                balance = totalPTokens.mul(curveBalance).div(pTokenTotalSupply);
            }
        }
    }
    function supportsAsset(address _asset) external view returns (bool) {
        return assetToPToken[_asset] != address(0);
    }
    function safeApproveAllTokens() external {
        for (uint256 i = 0; i < assetsMapped.length; i++) {
            _abstractSetPToken(assetsMapped[i], assetToPToken[assetsMapped[i]]);
        }
    }
    function _getTotalPTokens()
        internal
        view
        returns (
            uint256 contractPTokens,
            uint256 gaugePTokens,
            uint256 totalPTokens
        )
    {
        contractPTokens = IERC20(assetToPToken[assetsMapped[0]]).balanceOf(
            address(this)
        );
        ICurveGauge gauge = ICurveGauge(crvGaugeAddress);
        gaugePTokens = gauge.balanceOf(address(this));
        totalPTokens = contractPTokens.add(gaugePTokens);
    }
    function _abstractSetPToken(address _asset, address _pToken) internal {
        IERC20 asset = IERC20(_asset);
        IERC20 pToken = IERC20(_pToken);
        asset.safeApprove(platformAddress, 0);
        asset.safeApprove(platformAddress, uint256(-1));
        pToken.safeApprove(platformAddress, 0);
        pToken.safeApprove(platformAddress, uint256(-1));
        pToken.safeApprove(crvGaugeAddress, 0);
        pToken.safeApprove(crvGaugeAddress, uint256(-1));
    }
    function _getPoolCoinIndex(address _asset) internal view returns (uint256) {
        for (uint256 i = 0; i < 3; i++) {
            if (assetsMapped[i] == _asset) return i;
        }
        revert("Invalid 3pool asset");
    }
}