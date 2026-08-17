pragma solidity ^0.8.28;
import "./BalancerArbitrageSwapperV4.sol";
contract BalancerArbitrageSwapperV5 is BalancerArbitrageSwapperV4 {
    using SafeERC20 for IERC20;
    address public immutable WETH;
    event ValidatorTipSent(address indexed coinbase, uint256 tipAmount, uint256 gasUsed, uint256 gasCost);
    event GasAdjustedTip(uint256 originalTip, uint256 adjustedTip, uint256 gasCost, uint256 retainedProfit);
    event TipSkipped(string reason, uint256 profit, uint256 gasCost);
    error TipTransferFailed(address coinbase, uint256 amount);
    error InvalidTipPercentage(uint256 percentage);
    error InsufficientProfitAfterGas(uint256 profit, uint256 gasCost);
    struct FlashLoanDataV5 {
        address originator;
        address borrowToken;
        uint256 borrowAmount;
        ArbSwap[] swaps;
        uint256 minProfit;
        uint256 tipPercentageBps;
        uint256 minTipAmount;
        uint256 gasSafetyMarginBps;
        uint256 startGas;
    }
    constructor(
        address _balancerVault,
        address _poolManager,
        address _weth
    ) BalancerArbitrageSwapperV4(_balancerVault, _poolManager, _weth) {
        require(_weth != address(0), "Invalid WETH address");
        WETH = _weth;
    }
    function executeArbitrageWithTip(
        address borrowToken,
        uint256 borrowAmount,
        ArbSwap[] calldata swaps,
        uint256 minProfit,
        uint256 tipPercentageBps,
        uint256 minTipAmount,
        uint256 gasSafetyMarginBps
    ) external onlyOwner {
        uint256 startGas = gasleft();
        require(swaps.length > 1, "Arbitrage requires at least two swaps");
        require(tipPercentageBps <= 10000, "Tip percentage cannot exceed 100%");
        require(swaps[0].tokenIn == borrowToken, "First swap tokenIn must match borrowed token");
        require(swaps[swaps.length-1].tokenOut == borrowToken, "Last swap tokenOut must match borrowed token for repayment");
        emit ArbitrageStarted(borrowToken, borrowAmount);
        address[] memory tokens = new address[](1);
        tokens[0] = borrowToken;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        bytes memory userData = abi.encode(
            FlashLoanDataV5({
                originator: msg.sender,
                borrowToken: borrowToken,
                borrowAmount: borrowAmount,
                swaps: swaps,
                minProfit: minProfit,
                tipPercentageBps: tipPercentageBps,
                minTipAmount: minTipAmount,
                gasSafetyMarginBps: gasSafetyMarginBps,
                startGas: startGas
            })
        );
        balancerVault.flashLoan(address(this), tokens, amounts, userData);
    }
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        if (msg.sender != address(balancerVault)) {
            revert UnauthorizedCallback();
        }
        FlashLoanDataV5 memory data = abi.decode(userData, (FlashLoanDataV5));
        require(tokens.length == 1, "Only single token flash loans supported");
        require(amounts.length == 1, "Only single amount flash loans supported");
        address tokenBorrowed = tokens[0];
        uint256 amountBorrowed = amounts[0];
        uint256 feeAmount = feeAmounts[0];
        require(tokenBorrowed == data.borrowToken, "Token mismatch");
        require(amountBorrowed == data.borrowAmount, "Amount mismatch");
        uint256 startBalance = IERC20(tokenBorrowed).balanceOf(address(this));
        if (startBalance < amountBorrowed) {
            revert BorrowFailed(tokenBorrowed, amountBorrowed);
        }
        uint256 finalAmount = _executeArbitrageLogic(tokenBorrowed, amountBorrowed, data.swaps);
        uint256 repayAmount = amountBorrowed + feeAmount;
        if (finalAmount < repayAmount) {
            revert ArbitrageUnprofitable(finalAmount, repayAmount);
        }
        uint256 profit = finalAmount - repayAmount;
        if (profit < data.minProfit) {
            revert InsufficientProfit(profit, data.minProfit);
        }
        uint256 balance = IERC20(tokenBorrowed).balanceOf(address(this));
        if (balance < repayAmount) {
            revert ArbitrageUnprofitable(balance, repayAmount);
        }
        if (IERC20(tokenBorrowed).allowance(address(this), address(balancerVault)) < repayAmount) {
            IERC20(tokenBorrowed).forceApprove(address(balancerVault), type(uint256).max);
        }
        _tipValidatorGasAware(
            tokenBorrowed,
            profit,
            data.tipPercentageBps,
            data.minTipAmount,
            data.gasSafetyMarginBps,
            data.startGas
        );
        emit ArbitrageExecuted(tokenBorrowed, amountBorrowed, profit);
    }
    function _tipValidatorGasAware(
        address profitToken,
        uint256 profitAmount,
        uint256 tipPercentageBps,
        uint256 minTipAmount,
        uint256 gasSafetyMarginBps,
        uint256 startGas
    ) internal {
        if (profitToken != WETH) {
            _tipValidatorSimple(profitAmount, tipPercentageBps, minTipAmount);
            return;
        }
        uint256 gasUsedSoFar = startGas - gasleft();
        uint256 estimatedTipGas = 35000;
        uint256 totalEstimatedGas = gasUsedSoFar + estimatedTipGas;
        uint256 gasCost = totalEstimatedGas * tx.gasprice;
        uint256 gasCostWithMargin = gasCost * (10000 + gasSafetyMarginBps) / 10000;
        uint256 desiredTip = (profitAmount * tipPercentageBps) / 10000;
        uint256 retainedAfterTip = profitAmount - desiredTip;
        if (retainedAfterTip < gasCostWithMargin) {
            if (profitAmount <= gasCostWithMargin) {
                emit TipSkipped("Profit below gas cost", profitAmount, gasCostWithMargin);
                return;
            }
            uint256 maxTip = profitAmount - gasCostWithMargin;
            uint256 adjustedTip = maxTip < desiredTip ? maxTip : desiredTip;
            if (adjustedTip < minTipAmount) {
                emit TipSkipped("Adjusted tip below minimum", adjustedTip, gasCostWithMargin);
                return;
            }
            emit GasAdjustedTip(desiredTip, adjustedTip, gasCostWithMargin, profitAmount - adjustedTip);
            _sendTip(adjustedTip, totalEstimatedGas, gasCost);
        } else {
            if (desiredTip < minTipAmount) {
                emit TipSkipped("Tip below minimum", desiredTip, gasCostWithMargin);
                return;
            }
            _sendTip(desiredTip, totalEstimatedGas, gasCost);
        }
    }
    function _sendTip(uint256 tipAmount, uint256 gasUsed, uint256 gasCost) internal {
        IWETH(WETH).withdraw(tipAmount);
        (bool success, ) = block.coinbase.call{value: tipAmount}("");
        if (!success) {
            revert TipTransferFailed(block.coinbase, tipAmount);
        }
        emit ValidatorTipSent(block.coinbase, tipAmount, gasUsed, gasCost);
    }
    function _tipValidatorSimple(
        uint256 profitAmount,
        uint256 tipPercentageBps,
        uint256 minTipAmount
    ) internal {
        uint256 ethBalance = address(this).balance;
        if (ethBalance >= minTipAmount) {
            uint256 ethTipAmount = (ethBalance * tipPercentageBps) / 10000;
            if (ethTipAmount >= minTipAmount) {
                (bool success, ) = block.coinbase.call{value: ethTipAmount}("");
                if (success) {
                    emit ValidatorTipSent(block.coinbase, ethTipAmount, 0, 0);
                }
            }
        }
    }
    function estimateGasCost(uint256 gasAmount) external view returns (uint256) {
        return gasAmount * tx.gasprice;
    }
    function calculateMaxProfitableTip(
        uint256 profitWei,
        uint256 estimatedGasUsed,
        uint256 safetyMarginBps
    ) external view returns (uint256 maxTip) {
        uint256 gasCost = estimatedGasUsed * tx.gasprice;
        uint256 gasCostWithMargin = gasCost * (10000 + safetyMarginBps) / 10000;
        if (profitWei <= gasCostWithMargin) {
            return 0;
        }
        return profitWei - gasCostWithMargin;
    }
}