pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Centric is ERC20 {
    constructor (uint256 totalSupply) ERC20("Centric", "CNR") {
        _mint(msg.sender, totalSupply);
    }
}