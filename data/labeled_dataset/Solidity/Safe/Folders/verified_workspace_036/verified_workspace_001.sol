pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockERC20 is ERC20 {
  address public minter;
  constructor(
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    minter = msg.sender;
    _mint(msg.sender, 10000000 * 10**18);
  }
}