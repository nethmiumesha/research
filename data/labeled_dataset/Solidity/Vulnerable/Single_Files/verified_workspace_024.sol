pragma solidity ^0.8.20;
interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
contract FlashArbitrage {
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }
    function executeArbitrage(
        address flashPool,
        uint amount0Out,
        uint amount1Out,
        bytes calldata data
    ) external onlyOwner {
        IUniswapV2Pair(flashPool).swap(amount0Out, amount1Out, address(this), data);
    }
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _flashCallback(sender, amount0, amount1, data);
    }
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _flashCallback(sender, amount0, amount1, data);
    }
    function _flashCallback(address sender, uint, uint, bytes calldata data) internal {
        require(sender == address(this), "Sender must be this contract");
        (address tokenBorrow, uint amountBorrow, address targetRouter, address tokenPay, uint amountToPay) = abi.decode(
            data, (address, uint, address, address, uint)
        );
        IERC20(tokenBorrow).approve(targetRouter, type(uint).max);
        address[] memory path = new address[](2);
        path[0] = tokenBorrow;
        path[1] = tokenPay;
        IUniswapV2Router(targetRouter).swapExactTokensForTokens(
            amountBorrow,
            amountToPay,
            path,
            address(this),
            block.timestamp + 100
        );
        IERC20(tokenPay).transfer(msg.sender, amountToPay);
        uint profit = IERC20(tokenPay).balanceOf(address(this));
        require(profit > 0, "No profit generated");
        IERC20(tokenPay).transfer(owner, profit);
    }
    function rescueTokens(address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(owner, balance);
    }
}