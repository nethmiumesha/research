pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
interface ISanToken is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;
    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;
    function burnSelf(uint256 amount, address burner) external;
    function stableMaster() external view returns (address);
    function poolManager() external view returns (address);
}