pragma solidity 0.5.11;
import { ICurvePool } from "./ICurvePool.sol";
import { ICurveGauge } from "./ICurveGauge.sol";
import { ICRVMinter } from "./ICRVMinter.sol";
import {
    IERC20,
    InitializableAbstractStrategy
} from "../utils/InitializableAbstractStrategy.sol";
import { Helpers } from "../utils/Helpers.sol";
contract ThreePoolStrategy is InitializableAbstractStrategy {
    event RewardTokenCollected(address recipient, uint256 amount);
    address crvGaugeAddress;
    address crvMinterAddress;
    int128 poolCoinIndex = -1;
    function initialize(
        address _platformAddress,
        address _vaultAddress,
        address _rewardTokenAddress,
        address _asset,
        address _pToken,
        address _crvGaugeAddress,
        address _crvMinterAddress
    ) external onlyGovernor initializer {
        ICurvePool threePool = ICurvePool(_platformAddress);
        for (int128 i = 0; i < 3; i++) {
            if (threePool.coins(uint256(i)) == _asset) poolCoinIndex = i;
        }
        require(poolCoinIndex != -1, "Invalid 3pool asset");
        crvGaugeAddress = _crvGaugeAddress;
        crvMinterAddress = _crvMinterAddress;
        InitializableAbstractStrategy._initialize(
            _platformAddress,
            _vaultAddress,
            _rewardTokenAddress,
            _asset,
            _pToken
        );
    }
    function collectRewardToken() external onlyVault {
        ICRVMinter minter = ICRVMinter(crvMinterAddress);
        minter.mint(crvGaugeAddress);
        IERC20 crvToken = IERC20(rewardTokenAddress);
        uint256 balance = crvToken.balanceOf(address(this));
        require(
            crvToken.transfer(vaultAddress, balance),
            "Reward token transfer failed"
        );
        emit RewardTokenCollected(vaultAddress, balance);
    }
    function deposit(address _asset, uint256 _amount)
        external
        onlyVault
        returns (uint256 amountDeposited)
    {
        require(_amount > 0, "Must deposit something");
        uint256[3] memory _amounts;
        _amounts[uint256(poolCoinIndex)] = _amount;
        ICurvePool(platformAddress).add_liquidity(_amounts, 0);
        IERC20 pToken = IERC20(assetToPToken[_asset]);
        ICurveGauge(crvGaugeAddress).deposit(
            pToken.balanceOf(address(this)),
            address(this)
        );
        amountDeposited = _amount;
        emit Deposit(_asset, address(platformAddress), amountDeposited);
    }
    function withdraw(
        address _recipient,
        address _asset,
        uint256 _amount
    ) external onlyVault returns (uint256 amountWithdrawn) {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Invalid amount");
        (
            uint256 contractPTokens,
            uint256 gaugePTokens,
            uint256 totalPTokens
        ) = _getTotalPTokens();
        ICurvePool curvePool = ICurvePool(platformAddress);
        uint256 maxAmount = curvePool.calc_withdraw_one_coin(
            totalPTokens,
            poolCoinIndex
        );
        uint256 withdrawPTokens = totalPTokens.mul(_amount).div(maxAmount);
        if (contractPTokens < withdrawPTokens) {
            ICurveGauge(crvGaugeAddress).withdraw(withdrawPTokens);
        }
        curvePool.remove_liquidity_one_coin(withdrawPTokens, poolCoinIndex, 0);
        IERC20(_asset).safeTransfer(_recipient, _amount);
        uint256 dust = IERC20(_asset).balanceOf(address(this));
        if (dust > 0) {
            IERC20(_asset).safeTransfer(vaultAddress, dust);
        }
        amountWithdrawn = _amount;
        emit Withdrawal(
            _asset,
            address(assetToPToken[_asset]),
            amountWithdrawn
        );
    }
    function liquidate() external onlyVaultOrGovernor {
        (, uint256 gaugePTokens, ) = _getTotalPTokens();
        ICurveGauge(crvGaugeAddress).withdraw(gaugePTokens);
        IERC20 asset = IERC20(assetsMapped[0]);
        uint256 pTokenBalance = IERC20(assetToPToken[address(asset)]).balanceOf(
            address(this)
        );
        ICurvePool(platformAddress).remove_liquidity_one_coin(
            pTokenBalance,
            poolCoinIndex,
            0
        );
        asset.safeTransfer(vaultAddress, asset.balanceOf(address(this)));
    }
    function checkBalance(address _asset)
        external
        view
        returns (uint256 balance)
    {
        (, , uint256 totalPTokens) = _getTotalPTokens();
        balance = 0;
        if (totalPTokens > 0) {
            balance += ICurvePool(platformAddress).calc_withdraw_one_coin(
                totalPTokens,
                poolCoinIndex
            );
        }
    }
    function supportsAsset(address _asset) external view returns (bool) {
        return assetToPToken[_asset] != address(0);
    }
    function safeApproveAllTokens() external {
        address assetAddress = assetsMapped[0];
        _abstractSetPToken(assetAddress, assetToPToken[assetAddress]);
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
}