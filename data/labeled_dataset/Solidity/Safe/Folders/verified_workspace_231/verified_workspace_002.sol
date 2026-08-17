pragma solidity 0.7.6;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
contract ERC20PresetMinterPermitted is Context, AccessControl, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    mapping(address => uint256) public nonces;
    constructor(
        string memory name,
        string memory symbol,
        address owner,
        uint8 decimals
    ) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupDecimals(decimals);
    }
    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20PresetMinterPermitted: must have minter role to mint"
        );
        _mint(to, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
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
        bytes32 domainSeparator =
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name())),
                    getChainId(),
                    address(this)
                )
            );
        bytes32 structHash =
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    owner,
                    spender,
                    amount,
                    nonces[owner]++,
                    deadline
                )
            );
        bytes32 digest =
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Permit: invalid signature");
        require(signatory == owner, "Permit: unauthorized");
        require(block.timestamp <= deadline, "Permit: signature expired");
        _approve(owner, spender, amount);
    }
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}