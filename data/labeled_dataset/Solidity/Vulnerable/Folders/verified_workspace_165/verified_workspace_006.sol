pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract VoidHymn is ERC20 {
    constructor() ERC20("ZephyrMoonbeam", "ZEMOO") {
        _mint(msg.sender, 607000000000000 * 10**decimals());
    }
}