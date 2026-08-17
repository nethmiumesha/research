pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ILendingPool {
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata params) external;
}
interface IFlashLoanReceiver {
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params) external returns (bytes32);
}
interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}
contract FlashLoanArbitrage is IFlashLoanReceiver {
    address public owner;
    address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant QUICKSWAP = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant SUSHISWAP = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bytes32) {
        require(msg.sender == AAVE_POOL, "Invalid caller");
        (address tokenOut, uint8 routerChoice) = abi.decode(params, (address, uint8));
        _executeArbitrage(asset, tokenOut, amount, routerChoice);
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(AAVE_POOL, amountOwed);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
    function _executeArbitrage(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint8 routerChoice
    ) internal {
        address router = (routerChoice == 1) ? QUICKSWAP : SUSHISWAP;
        IERC20(tokenIn).approve(router, amountIn);
        address[] memory path1 = new address[](2);
        path1[0] = tokenIn;
        path1[1] = tokenOut;
        uint[] memory amounts1 = IUniswapV2Router(router).swapExactTokensForTokens(
            amountIn, 0, path1, address(this), block.timestamp + 300
        );
        uint256 received = amounts1[amounts1.length - 1];
        address router2 = (routerChoice == 1) ? SUSHISWAP : QUICKSWAP;
        IERC20(tokenOut).approve(router2, received);
        address[] memory path2 = new address[](2);
        path2[0] = tokenOut;
        path2[1] = tokenIn;
        IUniswapV2Router(router2).swapExactTokensForTokens(
            received, 0, path2, address(this), block.timestamp + 300
        );
    }
    function initiateFlashLoan(address token, uint256 amount, address tokenOut, uint8 routerChoice) external onlyOwner {
        bytes memory params = abi.encode(tokenOut, routerChoice);
        ILendingPool(AAVE_POOL).flashLoan(address(this), token, amount, params);
    }
    function withdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No balance");
        IERC20(token).transfer(owner, balance);
    }
    receive() external payable {}
}