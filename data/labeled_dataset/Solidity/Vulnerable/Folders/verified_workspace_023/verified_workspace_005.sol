pragma solidity 0.8.4;
import '../interfaces/IERC20Minimal.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract TestERC20 is ERC20 {
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 1000000 ether);
    }
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}