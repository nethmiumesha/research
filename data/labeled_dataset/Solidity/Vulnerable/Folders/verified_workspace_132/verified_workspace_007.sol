pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
contract HKDD is ERC20, ERC20Burnable, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    mapping(address => bool) public isBlacklisted;
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);
    constructor(address initialAdmin) ERC20("Dark Matter Bank HKDD", "HKDD") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin);
        _grantRole(BLACKLISTER_ROLE, initialAdmin);
    }
    function _update(address from, address to, uint256 value)
        internal
        override
    {
        require(!paused(), "HKDD: token transfer while paused");
        require(!isBlacklisted[from], "HKDD: sender is blacklisted");
        require(!isBlacklisted[to], "HKDD: receiver is blacklisted");
        super._update(from, to, value);
    }
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    function blacklist(address account) public onlyRole(BLACKLISTER_ROLE) {
        require(account != address(0), "Blacklist: cannot blacklist zero address");
        isBlacklisted[account] = true;
        emit Blacklisted(account);
    }
    function unblacklist(address account) public onlyRole(BLACKLISTER_ROLE) {
        isBlacklisted[account] = false;
        emit Unblacklisted(account);
    }
}