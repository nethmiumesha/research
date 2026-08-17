pragma solidity 0.5.11;
interface IEthDepositVerifier {
    function verify(bytes calldata depositTx, uint256 amount, address sender) external view;
}