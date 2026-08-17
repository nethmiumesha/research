pragma solidity 0.7.5;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
interface IStakedEthToken is IERC20Upgradeable {
    function initialize(address _admin, address _rewardEthToken, address _pool) external;
    function totalDeposits() external view returns (uint256);
    function mint(address account, uint256 amount) external;
}