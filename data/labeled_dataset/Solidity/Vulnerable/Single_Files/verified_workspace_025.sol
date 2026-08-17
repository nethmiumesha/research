pragma solidity ^0.8.20;
interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}
interface IAavePool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}
interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params)
        external payable returns (uint256 amountOut);
}
contract FlashLoanExecutor {
    address public botAddress;
    address public adminAddress;
    address public immutable balancerVault;
    address public immutable aavePool;
    address public immutable swapRouter;
    bool private _inExecution;
    uint256 public totalExecutions;
    uint256 public totalProfitWei;
    event ArbitrageExecuted(
        bytes32 indexed opportunityId,
        uint256 profit,
        uint256 gasUsed,
        address indexed provider
    );
    event AdminChanged(address oldAdmin, address newAdmin);
    event BotChanged(address oldBot, address newBot);
    modifier onlyBot() {
        require(msg.sender == botAddress, "FlashLoanExecutor: not bot");
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "FlashLoanExecutor: not admin");
        _;
    }
    constructor(
        address _botAddress,
        address _adminAddress,
        address _balancerVault,
        address _aavePool,
        address _swapRouter
    ) {
        require(_botAddress   != address(0), "zero bot");
        require(_adminAddress != address(0), "zero admin");
        require(_swapRouter   != address(0), "zero router");
        botAddress    = _botAddress;
        adminAddress  = _adminAddress;
        balancerVault = _balancerVault;
        aavePool      = _aavePool;
        swapRouter    = _swapRouter;
    }
    function executeArbitrage(
        bytes32            opportunityId,
        address            token,
        uint256            amount,
        address[] calldata tokens,
        uint24[]  calldata fees,
        uint256[] calldata minAmountOuts,
        uint256            minProfit,
        bool               useAave
    ) external onlyBot {
        require(!_inExecution, "reentrant");
        require(tokens.length >= 2,                   "min 2 tokens");
        require(fees.length == tokens.length,          "fees length mismatch");
        require(minAmountOuts.length == tokens.length, "minOuts length mismatch");
        require(tokens[0] == token, "token mismatch");
        _inExecution = true;
        bytes memory params = abi.encode(
            opportunityId, tokens, fees, minAmountOuts, minProfit
        );
        if (!useAave && balancerVault != address(0)) {
            address[] memory flashTokens = new address[](1);
            flashTokens[0] = token;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            IBalancerVault(balancerVault).flashLoan(
                address(this), flashTokens, amounts, params
            );
        } else {
            require(aavePool != address(0), "no provider");
            IAavePool(aavePool).flashLoanSimple(
                address(this), token, amount, params, 0
            );
        }
        _inExecution = false;
    }
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == balancerVault, "not balancer");
        require(_inExecution,               "not in execution");
        (
            bytes32           opportunityId,
            address[] memory  swapTokens,
            uint24[]  memory  poolFees,
            uint256[] memory  minAmountOuts,
            uint256           minProfit
        ) = abi.decode(userData, (bytes32, address[], uint24[], uint256[], uint256));
        uint256 gasStart    = gasleft();
        uint256 repayAmount = amounts[0] + feeAmounts[0];
        _executeSwaps(swapTokens, poolFees, amounts[0], minAmountOuts);
        uint256 finalBalance = IERC20(tokens[0]).balanceOf(address(this));
        require(finalBalance >= repayAmount + minProfit, "insufficient profit");
        uint256 profit = finalBalance - repayAmount;
        require(IERC20(tokens[0]).transfer(balancerVault, repayAmount), "repay failed");
        if (profit > 0) {
            require(IERC20(tokens[0]).transfer(botAddress, profit), "profit transfer failed");
        }
        uint256 gasUsed = gasStart - gasleft();
        totalExecutions++;
        totalProfitWei += profit;
        emit ArbitrageExecuted(opportunityId, profit, gasUsed, balancerVault);
    }
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == aavePool,          "not aave");
        require(initiator  == address(this),     "bad initiator");
        require(_inExecution,                    "not in execution");
        (
            bytes32           opportunityId,
            address[] memory  swapTokens,
            uint24[]  memory  poolFees,
            uint256[] memory  minAmountOuts,
            uint256           minProfit
        ) = abi.decode(params, (bytes32, address[], uint24[], uint256[], uint256));
        uint256 gasStart    = gasleft();
        uint256 repayAmount = amount + premium;
        _executeSwaps(swapTokens, poolFees, amount, minAmountOuts);
        uint256 finalBalance = IERC20(asset).balanceOf(address(this));
        require(finalBalance >= repayAmount + minProfit, "insufficient profit");
        uint256 profit = finalBalance - repayAmount;
        require(IERC20(asset).approve(aavePool, repayAmount), "approve failed");
        if (profit > 0) {
            require(IERC20(asset).transfer(botAddress, profit), "profit transfer failed");
        }
        uint256 gasUsed = gasStart - gasleft();
        totalExecutions++;
        totalProfitWei += profit;
        emit ArbitrageExecuted(opportunityId, profit, gasUsed, aavePool);
        return true;
    }
    function _executeSwaps(
        address[] memory tokens,
        uint24[]  memory fees,
        uint256          amountIn,
        uint256[] memory minOuts
    ) internal {
        uint256 N = tokens.length;
        uint256 currentAmount = amountIn;
        for (uint256 i = 0; i < N; i++) {
            address tokenIn  = tokens[i];
            address tokenOut = tokens[(i + 1) % N];
            IERC20(tokenIn).approve(swapRouter, currentAmount);
            currentAmount = ISwapRouter02(swapRouter).exactInputSingle(
                ISwapRouter02.ExactInputSingleParams({
                    tokenIn:           tokenIn,
                    tokenOut:          tokenOut,
                    fee:               fees[i],
                    recipient:         address(this),
                    amountIn:          currentAmount,
                    amountOutMinimum:  minOuts[i],
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }
    function setBotAddress(address newBot) external onlyAdmin {
        require(newBot != address(0), "zero address");
        emit BotChanged(botAddress, newBot);
        botAddress = newBot;
    }
    function setAdminAddress(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "zero address");
        emit AdminChanged(adminAddress, newAdmin);
        adminAddress = newAdmin;
    }
    function rescueToken(address token, uint256 amount) external onlyAdmin {
        require(IERC20(token).transfer(adminAddress, amount), "rescue failed");
    }
    function getMetrics() external view returns (
        uint256 executions,
        uint256 profitWei
    ) {
        return (totalExecutions, totalProfitWei);
    }
}