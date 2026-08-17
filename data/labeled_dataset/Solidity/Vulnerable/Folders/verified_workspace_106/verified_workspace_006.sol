pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract AstraCinder is ERC20 {
    constructor() ERC20("CosmicDragon", "CODRA") {
        _mint(msg.sender, 512000000000000 * 10**decimals());
    }
}