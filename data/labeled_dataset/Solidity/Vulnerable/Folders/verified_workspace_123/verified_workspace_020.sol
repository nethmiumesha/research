pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
contract EtherBishop is ERC20, ERC20Permit {
    constructor() ERC20("Rich Shiba", "RICHS")  ERC20Permit("Rich Shiba")
    {
        _mint(msg.sender, 85000000000000 * 10 ** decimals());
    }
}