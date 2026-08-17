pragma solidity 0.8.33;
interface IRouter {
    /
    event ZapDeposit(
        address indexed user, address indexed token_in, uint256 amount_in, uint256 weth_out, uint256 shares_out
    );
    event ZapWithdraw(
        address indexed user, uint256 shares_in, uint256 weth_redeemed, address indexed token_out, uint256 amount_out
    );
    /
    function weth() external view returns (address weth_address);
    function vault() external view returns (address vault_address);
    function swap_router() external view returns (address swap_router_address);
    /
    function zapDepositETH() external payable returns (uint256 shares);
    function zapDepositERC20(address token_in, uint256 amount_in, uint24 pool_fee, uint256 min_weth_out)
        external
        returns (uint256 shares);
    function zapWithdrawETH(uint256 shares) external returns (uint256 eth_out);
    function zapWithdrawERC20(uint256 shares, address token_out, uint24 pool_fee, uint256 min_token_out)
        external
        returns (uint256 amount_out);
}