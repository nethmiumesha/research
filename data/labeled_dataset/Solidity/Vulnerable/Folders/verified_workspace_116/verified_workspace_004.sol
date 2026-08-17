pragma solidity ^0.8.34;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Constants.sol";
import "../interfaces/ICurvePool_Mk3.sol";
import "../interfaces/IConvexRewards.sol";
import "./CurveConvexStratBaseMk2.sol";
abstract contract CurveConvexExtraStratBaseMk2 is Context, CurveConvexStratBaseMk2 {
    using SafeERC20 for IERC20Metadata;
    uint256 public constant DSF_EXTRA_TOKEN_ID = 3;
    IERC20Metadata public token;
    IERC20Metadata public extraToken;
    IConvexRewards public extraRewards;
    address[] extraTokenSwapPath;
    constructor(
        Config memory config,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID,
        address tokenAddr,
        address extraRewardsAddr,
        address extraTokenAddr
    ) CurveConvexStratBaseMk2(config, poolLPAddr, rewardsAddr, poolPID) {
        token = IERC20Metadata(tokenAddr);
        if (extraTokenAddr != address(0)) {
            extraToken = IERC20Metadata(extraTokenAddr);
            extraTokenSwapPath = [extraTokenAddr, Constants.WETH_ADDRESS, Constants.USDT_ADDRESS];
            extraRewards = IConvexRewards(extraRewardsAddr);
        } else {
            extraRewards = IConvexRewards(address(0));
        }
        decimalsMultipliers[DSF_EXTRA_TOKEN_ID] = calcTokenDecimalsMultiplier(token);
    }
    function totalHoldings() public view virtual override returns (uint256) {
        uint256 extraEarningsUSDT = 0;
        if (address(extraToken) != address(0)) {
            uint256 amountIn = extraToken.balanceOf(address(this));
            if (address(extraRewards) != address(0)) {
                amountIn += extraRewards.earned(address(this));
            }
            extraEarningsUSDT = priceTokenByExchange(amountIn, extraTokenSwapPath);
        }
        uint256 extraNetUSDT = extraEarningsUSDT;
        if (extraNetUSDT > 0) {
            uint256 feeUSDT = DSF.calcManagementFee(extraNetUSDT);
            extraNetUSDT = (feeUSDT < extraNetUSDT) ? (extraNetUSDT - feeUSDT) : 0;
        }
        return
            super.totalHoldings() +
            extraNetUSDT *
            decimalsMultipliers[DSF_USDT_TOKEN_ID] +
            token.balanceOf(address(this)) *
            decimalsMultipliers[DSF_EXTRA_TOKEN_ID];
    }
    function sellExtraToken() public {
        if (address(extraToken) == address(0)) return;
        uint256 extraBalance = extraToken.balanceOf(address(this));
        if (extraBalance == 0) return;
        uint256 usdtBalanceBefore = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));
        extraToken.forceApprove(address(_config.router), extraBalance);
        _config.router.swapExactTokensForTokens(
            extraBalance,
            0,
            extraTokenSwapPath,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );
        managementFees += DSF.calcManagementFee(
            _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this)) - usdtBalanceBefore
        );
        emit SoldRewards(0, 0, extraBalance);
    }
    function withdrawAll() external virtual onlyDSF {
        cvxRewards.withdrawAllAndUnwrap(true);
        if (address(extraRewards) != address(0)) {
            extraRewards.getReward();
        }
        if (rewardManager != address(0)) {
            _pushToken(_config.crv);
            _pushCvxToManager();
            if (address(extraToken) != address(0)) {
                _pushToken(extraToken);
            }
        }
        withdrawAllSpecific();
        transferDSFAllTokens();
    }
    function withdrawAllSpecific() internal virtual;
}