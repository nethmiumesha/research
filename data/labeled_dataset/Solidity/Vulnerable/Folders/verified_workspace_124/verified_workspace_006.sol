pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract EtherMonolith is ERC20 {
    constructor() ERC20("EclipseAura", "ECAUR") {
        _mint(msg.sender, 611000000000000 * 10**decimals());
    }
}