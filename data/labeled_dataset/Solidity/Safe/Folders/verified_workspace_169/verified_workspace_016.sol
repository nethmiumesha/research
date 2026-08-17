pragma solidity ^0.6.0;
import "../../common/implementation/ExpandedERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
contract VotingToken is ExpandedERC20, ERC20Snapshot {
    constructor() public ExpandedERC20("UMA Voting Token v1", "UMA", 18) {}
    function snapshot() external returns (uint256) {
        return _snapshot();
    }
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Snapshot) {
        super._transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal override(ERC20, ERC20Snapshot) {
        super._mint(account, value);
    }
    function _burn(address account, uint256 value) internal override(ERC20, ERC20Snapshot) {
        super._burn(account, value);
    }
}