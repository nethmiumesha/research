pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract ZenSphere is ERC20 {
    constructor() ERC20("EclipseFox", "ECFOX") {
        _mint(msg.sender, 548000000000000 * 10**decimals());
    }
}