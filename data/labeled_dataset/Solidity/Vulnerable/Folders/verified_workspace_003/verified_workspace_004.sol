pragma solidity 0.7.6;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1000000000000000000000);
    }
    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        require(recipient != address(0x1));
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}