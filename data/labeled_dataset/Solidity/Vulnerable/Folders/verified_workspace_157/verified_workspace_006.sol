pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract StarHaven is ERC20 {
    constructor() ERC20("LunarButterfly", "LUBUT") {
        _mint(msg.sender, 723000000000000 * 10**decimals());
    }
}