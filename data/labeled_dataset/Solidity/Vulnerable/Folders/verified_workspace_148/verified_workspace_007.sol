pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract PolishPepe is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;
    constructor(address treasuryWallet)
        ERC20("PolishPepe", "PLPE")
        Ownable(msg.sender)
    {
        require(treasuryWallet != address(0), "Invalid treasury");
        _mint(treasuryWallet, MAX_SUPPLY);
    }
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}