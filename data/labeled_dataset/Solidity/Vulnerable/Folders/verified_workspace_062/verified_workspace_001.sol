pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}
interface IPancakeRouter02 is IPancakeRouter01 {
}
interface IVenusDistribution {
    function claimVenus(address holder) external;
    function enterMarkets(address[] memory _vtokens) external;
    function exitMarket(address _vtoken) external;
    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);
    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}
interface IWBNB is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
interface IVBNB {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow() external payable;
    function balanceOfUnderlying(address owner) external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
}
interface IVToken is IERC20 {
    function underlying() external returns (address);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
}
interface IBurningStrategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(uint256) external;
    function updateBalance() external;
    function balanceOf() external view returns (uint256);
    function retireStrat() external;
    function harvest() external;
}
interface ISimpleStrategy {
    function deposit(uint256 _tokenAmount) external;
    function withdraw(uint256 _tokenAmount) external;
    function totalBalance() external view returns (uint256);
    function harvest(uint256 priceMin) external;
}