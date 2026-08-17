pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract AstraDrift is ERC20 {
    constructor() ERC20("ZephyrDawn", "ZEDAW") {
        _mint(msg.sender, 283000000000000 * 10**decimals());
    }
}