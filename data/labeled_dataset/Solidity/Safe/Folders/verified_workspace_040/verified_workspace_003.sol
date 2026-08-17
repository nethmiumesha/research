pragma solidity 0.5.11;
interface IErc20DepositVerifier {
    function verify(bytes calldata depositTx, address sender, address vault)
        external
        view
        returns (address owner, address token, uint256 amount);
}