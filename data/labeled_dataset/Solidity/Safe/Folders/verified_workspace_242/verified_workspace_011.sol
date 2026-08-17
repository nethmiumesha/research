pragma solidity ^0.4.13;
import "./ERC20.sol";
import "./ProxyRegistry.sol";
contract TokenTransferProxy {
    ProxyRegistry public registry;
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(registry.contracts(msg.sender));
        return ERC20(token).transferFrom(from, to, amount);
    }
}