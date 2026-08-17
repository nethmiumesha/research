pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract AstraCrux is ERC20 {
    constructor() ERC20("MysticRadiance", "MYRAD") {
        _mint(msg.sender, 91000000000000 * 10**decimals());
    }
}