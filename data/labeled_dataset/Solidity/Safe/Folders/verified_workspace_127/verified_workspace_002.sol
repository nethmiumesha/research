pragma solidity 0.8.13;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Roles.sol";
abstract contract RequestSigning is Ownable, Roles {
    using ECDSA for bytes32;
    event AssignWhitelistSigningKey(address indexed _address);
    event AssignOgSigningKey(address indexed _address);
    address public whitelistKey = address(0);
    address public ogKey = address(0);
    bytes32 public domainSeparator;
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");
    constructor(string memory _schemeName) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes.concat(bytes(_schemeName), bytes("Whitelist"))),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    function setWhitelistSigningKey(address newSigningKey)
        external
        onlyOperator
    {
        whitelistKey = newSigningKey;
        emit AssignWhitelistSigningKey(newSigningKey);
    }
    function setOgSigningKey(address newSigningKey) external onlyOperator {
        ogKey = newSigningKey;
        emit AssignOgSigningKey(newSigningKey);
    }
    function isWhiteListed(bytes calldata signature)
        public
        view
        returns (bool)
    {
        require(whitelistKey != address(0), "WL key not assigned");
        return getEIP712RecoverAddress(signature) == whitelistKey;
    }
    function isOG(bytes calldata signature) public view returns (bool) {
        require(ogKey != address(0), "OG key not assigned");
        return getEIP712RecoverAddress(signature) == ogKey;
    }
    function getEIP712RecoverAddress(bytes calldata signature)
        internal
        view
        returns (address)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );
        return digest.recover(signature);
    }
}