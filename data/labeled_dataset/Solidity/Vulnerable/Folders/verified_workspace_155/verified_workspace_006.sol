pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract SolarFlux is ERC20 {
    constructor() ERC20("MysticEmber", "MYEMB") {
        _mint(msg.sender, 783000000000000 * 10**decimals());
    }
}