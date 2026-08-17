pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Recoverable is Ownable {
    function recoverERC20(address token, uint amount) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        require(erc20.balanceOf(address(this)) >= amount, "Invalid input amount.");
        require(erc20.transfer(owner(), amount), "Recover failed");
    }
}