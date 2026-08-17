pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract NebulaQuill is ERC20 {
    constructor() ERC20("CelestialMystic", "CEMYS") {
        _mint(msg.sender, 40000000000000 * 10**decimals());
    }
}