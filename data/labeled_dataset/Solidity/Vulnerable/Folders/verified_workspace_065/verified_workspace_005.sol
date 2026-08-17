pragma solidity ^0.7.6;
interface ISNXFlashLoanTool {
    event Burn(address sender, uint256 sUSDAmount, uint256 snxAmount);
    function burn(
        uint256 sUSDAmount,
        uint256 snxAmount,
        address exchange,
        bytes calldata exchangeData
    ) external;
}