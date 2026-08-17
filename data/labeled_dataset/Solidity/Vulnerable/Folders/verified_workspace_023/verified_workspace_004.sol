pragma solidity 0.8.4;
import '../interfaces/IERC20Minimal.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract RevertableERC20 is ERC20 {
  bool public shouldRevert = false;
  constructor() ERC20("Revertable Token", "RVRT") {
    _mint(msg.sender, 1000000 ether);
  }
  function mint(address account, uint256 amount) external {
     require(!shouldRevert, "mint: SHOULD_REVERT");
    _mint(account, amount);
  }
  function burn(address account, uint256 amount) external {
    require(!shouldRevert, "burn: SHOULD_REVERT");
    _burn(account, amount);
  }
  function transfer(address account, uint256 amount) public override returns (bool) {
    require(!shouldRevert, "transfer: SHOULD_REVERT");
    _transfer(msg.sender, account, amount);
    return true;
  }
  function setShouldRevert(bool _shouldRevert) external {
    shouldRevert = _shouldRevert;
  }
}