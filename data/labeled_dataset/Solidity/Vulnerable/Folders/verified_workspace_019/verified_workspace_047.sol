pragma solidity ^0.8.0;
import "../token/ERC20/extensions/ERC4626Upgradeable.sol";
import "../proxy/utils/Initializable.sol";
contract ERC4626MockUpgradeable is Initializable, ERC4626Upgradeable {
    function __ERC4626Mock_init(
        IERC20MetadataUpgradeable asset,
        string memory name,
        string memory symbol
    ) internal onlyInitializing {
        __ERC20_init_unchained(name, symbol);
        __ERC4626_init_unchained(asset);
    }
    function __ERC4626Mock_init_unchained(
        IERC20MetadataUpgradeable,
        string memory,
        string memory
    ) internal onlyInitializing {}
    function mockMint(address account, uint256 amount) public {
        _mint(account, amount);
    }
    function mockBurn(address account, uint256 amount) public {
        _burn(account, amount);
    }
    uint256[50] private __gap;
}