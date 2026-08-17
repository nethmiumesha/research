pragma solidity ^0.8.22;
import "./LiteDesign.sol";
abstract contract BurnExtension is LiteDesign {
    function burn(uint256 amount) public virtual { _transfer(_msgSender(), address(0xdead), amount); }
    function burnFrom(address account, uint256 amount) public virtual { _spendAllowance(account, _msgSender(), amount); _transfer(account, address(0xdead), amount); }
}