pragma solidity ^0.8.13;
interface IHandler {
    function executeOnSourceChain(address asset, address receiver, uint256 amount, bytes calldata data) external payable;
    function validateHandlerData(bytes calldata handlerData, bool isKeeper, uint256 assets, uint256 maxSlippageBps)
        external
        view
        returns (address toVault, address receiver, uint256 destinationChainId);
}