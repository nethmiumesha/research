pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MoonTorch is ERC20 {
    constructor() ERC20("EtherealDream", "ETDRE") {
        _mint(msg.sender, 422000000000000 * 10**decimals());
    }
}