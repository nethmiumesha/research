pragma solidity ^0.5.16;
import "./Owned.sol";
import "./State.sol";
contract TokenState is Owned, State {
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}
    function setAllowance(
        address tokenOwner,
        address spender,
        uint value
    ) external onlyAssociatedContract {
        allowance[tokenOwner][spender] = value;
    }
    function setBalanceOf(address account, uint value) external onlyAssociatedContract {
        balanceOf[account] = value;
    }
}