pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
contract VoidNova is ERC20, ERC20Permit {
    constructor() ERC20("Joke Coin", "JOKE")  ERC20Permit("Joke Coin")
    {
        _mint(msg.sender, 80000000000000 * 10 ** decimals());
    }
}