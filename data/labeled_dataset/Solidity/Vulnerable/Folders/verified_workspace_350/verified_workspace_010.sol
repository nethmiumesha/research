pragma solidity 0.6.6;
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "../interfaces/IDebtToken.sol";
import "../interfaces/IVaultConfig.sol";
import "../interfaces/IWorker.sol";
import "../interfaces/IVault.sol";
import "../../token/interfaces/IFairLaunch.sol";
import "../../utils/SafeToken.sol";
import "../WNativeRelayer.sol";
contract MockVaultForStrategy is IVault, ERC20UpgradeSafe, ReentrancyGuardUpgradeSafe, OwnableUpgradeSafe {
  address public mockOwner;
  address public override token;
  function initialize() external initializer {}
  function setMockOwner(address owner) external {
    mockOwner = owner;
  }
  function totalToken() public view override returns (uint256) {
    return 0;
  }
  function deposit(uint256 amountToken) external payable override {}
  function withdraw(uint256 share) external override nonReentrant {}
  function requestFunds(address targetedToken, uint256 amount) external override {
    SafeToken.safeTransferFrom(targetedToken, mockOwner, msg.sender, amount);
  }
}