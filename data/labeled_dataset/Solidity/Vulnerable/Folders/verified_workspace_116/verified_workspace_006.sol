pragma solidity ^0.8.34;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Constants.sol";
import "../interfaces/ICurvePool_Mk2.sol";
import "./CurveConvexExtraStratBaseMk2.sol";
contract CurveConvexStrat_crvUSD_USDT is CurveConvexExtraStratBaseMk2 {
    using SafeERC20 for IERC20Metadata;
    int128 public constant CURVE_USDT_COIN_ID_INT = 0;
    ICurvePool_Mk2 public pool;
    constructor(
        Config memory config,
        address poolAddr,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID,
        address tokenAddr,
        address extraRewardsAddr,
        address extraTokenAddr
    )
        CurveConvexExtraStratBaseMk2(
            config,
            poolLPAddr,
            rewardsAddr,
            poolPID,
            tokenAddr,
            extraRewardsAddr,
            extraTokenAddr
        )
    {
        pool = ICurvePool_Mk2(poolAddr);
    }
    function checkDepositSuccessful(uint256[3] memory amounts)
        internal
        view
        override
        returns (bool)
    {
        uint256 amountsTotalNorm1e18;
        for (uint256 i = 0; i < 3; i++) {
            amountsTotalNorm1e18 += amounts[i] * decimalsMultipliers[i];
        }
        uint256 amountsMinNorm1e18 = (amountsTotalNorm1e18 * minDepositAmount) / DEPOSIT_DENOMINATOR;
        if (amountsMinNorm1e18 == 0) return false;
        return true;
    }
    function depositPool(uint256[3] memory amounts) internal override returns (uint256 poolLPs) {
        uint256 usdtBefore = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));
        if (amounts[DSF_DAI_TOKEN_ID] > 0) {
            IERC20Metadata dai = _config.tokens[DSF_DAI_TOKEN_ID];
            dai.forceApprove(address(_config.router), amounts[DSF_DAI_TOKEN_ID]);
            address[] memory path = new address[](2);
            path[0] = address(dai);
            path[1] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
            uint256[] memory outs = _config.router.getAmountsOut(amounts[DSF_DAI_TOKEN_ID], path);
            uint256 minOut = (outs[outs.length - 1] * swapSlippageBps) / DEPOSIT_DENOMINATOR;
            _config.router.swapExactTokensForTokens(
                amounts[DSF_DAI_TOKEN_ID],
                minOut,
                path,
                address(this),
                block.timestamp + Constants.TRADE_DEADLINE
            );
        }
        if (amounts[DSF_USDC_TOKEN_ID] > 0) {
            IERC20Metadata usdc = _config.tokens[DSF_USDC_TOKEN_ID];
            usdc.forceApprove(address(_config.router), amounts[DSF_USDC_TOKEN_ID]);
            address[] memory path = new address[](2);
            path[0] = address(usdc);
            path[1] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
            uint256[] memory outs = _config.router.getAmountsOut(amounts[DSF_USDC_TOKEN_ID], path);
            uint256 minOut = (outs[outs.length - 1] * swapSlippageBps) / DEPOSIT_DENOMINATOR;
            _config.router.swapExactTokensForTokens(
                amounts[DSF_USDC_TOKEN_ID],
                minOut,
                path,
                address(this),
                block.timestamp + Constants.TRADE_DEADLINE
            );
        }
        uint256 usdtAfter = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));
        require(usdtAfter >= usdtBefore, "USDT delta underflow");
        uint256 usdtToDeposit = usdtAfter - usdtBefore + amounts[DSF_USDT_TOKEN_ID];
        require(usdtToDeposit > 0, "deposit=0");
        uint256[2] memory amounts2;
        amounts2[0] = usdtToDeposit;
        amounts2[1] = 0;
        _config.tokens[DSF_USDT_TOKEN_ID].forceApprove(address(pool), usdtToDeposit);
        uint256 expectedLp = pool.calc_token_amount(amounts2, true);
        uint256 minMint = (expectedLp * minDepositAmount) / DEPOSIT_DENOMINATOR;
        poolLPs = pool.add_liquidity(amounts2, minMint);
        poolLP.forceApprove(address(_config.booster), poolLPs);
        _config.booster.depositAll(cvxPoolPID, true);
    }
    function getCurvePoolPrice() internal view override returns (uint256) {
        return pool.get_virtual_price();
    }
    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps, uint128 tokenIndex)
        external
        view
        override
        returns (uint256 tokenAmount)
    {
        uint256 removingCrvLps = (cvxRewards.balanceOf(address(this)) * userRatioOfCrvLps) / 1e18;
        uint256 usdtOut = pool.calc_withdraw_one_coin(removingCrvLps, CURVE_USDT_COIN_ID_INT);
        if (tokenIndex == DSF_USDT_TOKEN_ID) return usdtOut;
        address[] memory path = new address[](2);
        path[0] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
        path[1] = address(_config.tokens[tokenIndex]);
        uint256[] memory outs = _config.router.getAmountsOut(usdtOut, path);
        return outs[outs.length - 1];
    }
    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        override
        returns (uint256 sharesAmount)
    {
        uint256 totalNorm1e18;
        for (uint256 i = 0; i < 3; i++) totalNorm1e18 += tokenAmounts[i] * decimalsMultipliers[i];
        if (totalNorm1e18 == 0) return 0;
        uint256 usdtApprox = totalNorm1e18 / decimalsMultipliers[DSF_USDT_TOKEN_ID];
        uint256[2] memory a2;
        a2[0] = usdtApprox;
        sharesAmount = pool.calc_token_amount(a2, isDeposit);
    }
    function calcCrvLps(
        WithdrawalType withdrawalType,
        uint256 userRatioOfCrvLps,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    )
        internal
        view
        override
        returns (
            bool success,
            uint256 removingCrvLps,
            uint256[] memory tokenAmountsDynamic
        )
    {
        removingCrvLps = (cvxRewards.balanceOf(address(this)) * userRatioOfCrvLps) / 1e18;
        uint256 usdtOut = pool.calc_withdraw_one_coin(removingCrvLps, CURVE_USDT_COIN_ID_INT);
        if (withdrawalType == WithdrawalType.OneCoin) {
            if (tokenIndex == DSF_USDT_TOKEN_ID) {
                success = usdtOut >= tokenAmounts[DSF_USDT_TOKEN_ID];
            } else {
                address[] memory path = new address[](2);
                path[0] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
                path[1] = address(_config.tokens[tokenIndex]);
                uint256[] memory outs = _config.router.getAmountsOut(usdtOut, path);
                success = outs[outs.length - 1] >= tokenAmounts[tokenIndex];
            }
        } else {
            success = usdtOut >= tokenAmounts[DSF_USDT_TOKEN_ID];
            if (success && tokenAmounts[DSF_DAI_TOKEN_ID] > 0) {
                address[] memory path = new address[](2);
                path[0] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
                path[1] = address(_config.tokens[DSF_DAI_TOKEN_ID]);
                uint256[] memory outs = _config.router.getAmountsOut(usdtOut, path);
                success = outs[outs.length - 1] >= tokenAmounts[DSF_DAI_TOKEN_ID];
            }
            if (success && tokenAmounts[DSF_USDC_TOKEN_ID] > 0) {
                address[] memory path = new address[](2);
                path[0] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
                path[1] = address(_config.tokens[DSF_USDC_TOKEN_ID]);
                uint256[] memory o1 = _config.router.getAmountsOut(usdtOut, path);
                success = o1[o1.length - 1] >= tokenAmounts[DSF_USDC_TOKEN_ID];
            }
        }
        tokenAmountsDynamic = new uint256[](1);
        tokenAmountsDynamic[0] = 0;
    }
    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory tokenAmountsDynamic,
        WithdrawalType withdrawalType,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    ) internal override {
        pool.remove_liquidity_one_coin(removingCrvLps, CURVE_USDT_COIN_ID_INT, 0);
        if (withdrawalType == WithdrawalType.OneCoin) {
            if (tokenIndex == DSF_USDT_TOKEN_ID) {
                return;
            }
            uint256 usdtBal = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));
            if (usdtBal == 0) return;
            address[] memory path = new address[](2);
            path[0] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
            path[1] = address(_config.tokens[tokenIndex]);
            uint256[] memory outsFull = _config.router.getAmountsOut(usdtBal, path);
            uint256 maxOut = outsFull[outsFull.length - 1];
            require(maxOut >= tokenAmounts[tokenIndex], "swap:insufficient");
            uint256 usdtToSwap = (usdtBal * tokenAmounts[tokenIndex]) / maxOut;
            if (usdtToSwap == 0) usdtToSwap = usdtBal;
            _config.tokens[DSF_USDT_TOKEN_ID].forceApprove(address(_config.router), usdtToSwap);
            _config.router.swapExactTokensForTokens(
                usdtToSwap,
                tokenAmounts[tokenIndex],
                path,
                address(this),
                block.timestamp + Constants.TRADE_DEADLINE
            );
            return;
        }
        if (tokenAmounts[DSF_DAI_TOKEN_ID] > 0) {
            _swapFromUsdtToToken(DSF_DAI_TOKEN_ID, tokenAmounts[DSF_DAI_TOKEN_ID]);
        }
        if (tokenAmounts[DSF_USDC_TOKEN_ID] > 0) {
            _swapFromUsdtToToken(DSF_USDC_TOKEN_ID, tokenAmounts[DSF_USDC_TOKEN_ID]);
        }
    }
    function _swapFromUsdtToToken(uint256 outTokenIndex, uint256 minOut) internal {
        uint256 usdtBal = _config.tokens[DSF_USDT_TOKEN_ID].balanceOf(address(this));
        if (usdtBal == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
        path[1] = address(_config.tokens[outTokenIndex]);
        uint256[] memory outsFull = _config.router.getAmountsOut(usdtBal, path);
        uint256 maxOut = outsFull[outsFull.length - 1];
        require(maxOut >= minOut, "swap:insufficient");
        uint256 usdtToSwap = (usdtBal * minOut) / maxOut;
        if (usdtToSwap == 0) usdtToSwap = usdtBal;
        _config.tokens[DSF_USDT_TOKEN_ID].forceApprove(address(_config.router), usdtToSwap);
        _config.router.swapExactTokensForTokens(
            usdtToSwap,
            minOut,
            path,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );
    }
    function withdrawAllSpecific() internal override {
        uint256 lpBal = poolLP.balanceOf(address(this));
        if (lpBal == 0) return;
        pool.remove_liquidity_one_coin(lpBal, CURVE_USDT_COIN_ID_INT, 0);
    }
    function getEfficiencyByIndex(uint256 amount, uint128 tokenIndex)
        external
        view
        returns (uint256 depositEfficiency1e18, uint256 roundTripEfficiency1e18)
    {
        require(tokenIndex < 3, "bad index");
        require(amount > 0, "amount=0");
        uint256 amountNorm1e18 = amount * decimalsMultipliers[tokenIndex];
        uint256 usdtIn;
        if (tokenIndex == DSF_USDT_TOKEN_ID) {
            usdtIn = amount;
        } else {
            address[] memory pathIn = new address[](2);
            pathIn[0] = address(_config.tokens[tokenIndex]);
            pathIn[1] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
            uint256[] memory outsIn = _config.router.getAmountsOut(amount, pathIn);
            usdtIn = outsIn[outsIn.length - 1];
        }
        uint256[2] memory a2;
        a2[0] = usdtIn;
        a2[1] = 0;
        uint256 expectedLp = pool.calc_token_amount(a2, true);
        uint256 lpPrice = pool.get_virtual_price();
        uint256 depositValueUsd1e18 = (expectedLp * lpPrice) / CURVE_PRICE_DENOMINATOR;
        depositEfficiency1e18 = (depositValueUsd1e18 * 1e18) / amountNorm1e18;
        uint256 usdtOut = pool.calc_withdraw_one_coin(expectedLp, CURVE_USDT_COIN_ID_INT);
        uint256 tokenOut;
        if (tokenIndex == DSF_USDT_TOKEN_ID) {
            tokenOut = usdtOut;
        } else {
            address[] memory pathOut = new address[](2);
            pathOut[0] = address(_config.tokens[DSF_USDT_TOKEN_ID]);
            pathOut[1] = address(_config.tokens[tokenIndex]);
            uint256[] memory outsOut = _config.router.getAmountsOut(usdtOut, pathOut);
            tokenOut = outsOut[outsOut.length - 1];
        }
        uint256 tokenOutNorm1e18 = tokenOut * decimalsMultipliers[tokenIndex];
        roundTripEfficiency1e18 = (tokenOutNorm1e18 * 1e18) / amountNorm1e18;
    }
}