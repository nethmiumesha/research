pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {VaultAPI, BaseWrapper} from "../BaseWrapper.sol";
contract AffiliateToken is ERC20, BaseWrapper {
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping(address => uint256) public nonces;
    address public affiliate;
    address public pendingAffiliate;
    modifier onlyAffiliate() {
        require(msg.sender == affiliate);
        _;
    }
    constructor(
        address _token,
        address _registry,
        string memory name,
        string memory symbol
    ) public BaseWrapper(_token, _registry) ERC20(name, symbol) {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes("1")), _getChainId(), address(this)));
        affiliate = msg.sender;
        _setupDecimals(uint8(ERC20(address(token)).decimals()));
    }
    function _getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    function setAffiliate(address _affiliate) external onlyAffiliate {
        pendingAffiliate = _affiliate;
    }
    function acceptAffiliate() external {
        require(msg.sender == pendingAffiliate);
        affiliate = msg.sender;
    }
    function _shareValue(uint256 numShares) internal view returns (uint256) {
        uint256 totalShares = totalSupply();
        if (totalShares > 0) {
            return totalVaultBalance(address(this)).mul(numShares).div(totalShares);
        } else {
            return numShares;
        }
    }
    function pricePerShare() external view returns (uint256) {
        return 10**uint256(decimals());
    }
    function _sharesForValue(uint256 amount) internal view returns (uint256) {
        uint256 totalWrapperAssets = totalVaultBalance(address(this));
        if (totalWrapperAssets > 0) {
            return totalSupply().mul(amount).div(totalWrapperAssets);
        } else {
            return amount;
        }
    }
    function deposit() external returns (uint256) {
        return deposit(uint256(-1));
    }
    function deposit(uint256 amount) public returns (uint256 deposited) {
        uint256 shares = _sharesForValue(amount);
        deposited = _deposit(msg.sender, address(this), amount, true);
        _mint(msg.sender, shares);
    }
    function withdraw() external returns (uint256) {
        return withdraw(balanceOf(msg.sender));
    }
    function withdraw(uint256 shares) public returns (uint256) {
        _burn(msg.sender, shares);
        return _withdraw(address(this), msg.sender, _shareValue(shares), true);
    }
    function migrate() external onlyAffiliate returns (uint256) {
        return _migrate(address(this));
    }
    function migrate(uint256 amount) external onlyAffiliate returns (uint256) {
        return _migrate(address(this), amount);
    }
    function migrate(uint256 amount, uint256 maxMigrationLoss) external onlyAffiliate returns (uint256) {
        return _migrate(address(this), amount, maxMigrationLoss);
    }
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(owner != address(0), "permit: signature");
        require(block.timestamp <= deadline, "permit: expired");
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == owner, "permit: unauthorized");
        _approve(owner, spender, amount);
    }
}