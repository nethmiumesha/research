pragma solidity ^0.8.24;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VaultTypes.sol";
interface IVaultMain {
    function unlock(bytes calldata data) external returns (bytes memory result);
    function settle(IERC20 token, uint256 amountHint) external returns (uint256 credit);
    function sendTo(IERC20 token, address to, uint256 amount) external;
    function swap(
        VaultSwapParams memory vaultSwapParams
    ) external returns (uint256 amountCalculatedRaw, uint256 amountInRaw, uint256 amountOutRaw);
    function addLiquidity(
        AddLiquidityParams memory params
    ) external returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData);
    function removeLiquidity(
        RemoveLiquidityParams memory params
    ) external returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData);
    function getPoolTokenCountAndIndexOfToken(
        address pool,
        IERC20 token
    ) external view returns (uint256 tokenCount, uint256 index);
    function transfer(address owner, address to, uint256 amount) external returns (bool);
    function transferFrom(address spender, address from, address to, uint256 amount) external returns (bool success);
    function erc4626BufferWrapOrUnwrap(
        BufferWrapOrUnwrapParams memory params
    ) external returns (uint256 amountCalculatedRaw, uint256 amountInRaw, uint256 amountOutRaw);
    function getVaultExtension() external view returns (address vaultExtension);
}