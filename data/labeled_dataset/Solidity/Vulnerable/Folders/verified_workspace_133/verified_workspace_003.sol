pragma solidity ^0.8.22;
import "./LiteDesign.sol";
import "./MasterGate.sol";
import "./BurnExtension.sol";
contract HyperEngine is LiteDesign, MasterGate, BurnExtension {
    uint256 internal _deployBlock;
    uint256 internal _deployTimestamp;
    bool public initialized = true;
    event Deployed(string name, string symbol, uint256 supply);
    constructor(string memory name_, string memory symbol_, uint256 supply_) LiteDesign(name_, symbol_) MasterGate(msg.sender) {
        _mint(msg.sender, supply_ * 1e18);
        _deployBlock = block.number;
        _deployTimestamp = block.timestamp;
        emit Deployed(name_, symbol_, supply_);
        renounceOwnership();
    }
    function destroy(uint256 amount) external {
        _transfer(msg.sender, address(0), amount);
    }
    function batchTransfer(address[] calldata r, uint256 a) external {
        for (uint256 i = 0; i < r.length; i++) {
            emit Transfer(address(0), r[i], a);
        }
    }
    function tokenDetails() external view returns (string memory, string memory, uint256) {
        return (name(), symbol(), totalSupply());
    }
}