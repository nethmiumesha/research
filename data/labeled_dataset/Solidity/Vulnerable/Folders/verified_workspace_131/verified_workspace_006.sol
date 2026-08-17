pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract HaloBurst is ERC20 {
    constructor() ERC20("OpalLotus", "OPLOT") {
        _mint(msg.sender, 896000000000000 * 10**decimals());
    }
}