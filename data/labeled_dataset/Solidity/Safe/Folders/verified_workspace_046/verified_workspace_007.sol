pragma solidity 0.6.10;
import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777.sol";
import "../interfaces/IMintableToken.sol";
import "../Permissions.sol";
contract SkaleManagerMock is Permissions, IERC777Recipient {
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant public ADMIN_ROLE = keccak256("ADMIN_ROLE");
    constructor (address contractManagerAddress) public {
        Permissions.initialize(contractManagerAddress);
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }
    function payBounty(uint validatorId, uint amount) external {
        IERC777 skaleToken = IERC777(contractManager.getContract("SkaleToken"));
        require(IMintableToken(address(skaleToken)).mint(address(this), amount, "", ""), "Token was not minted");
        require(
            IMintableToken(address(skaleToken))
                .mint(contractManager.getContract("Distributor"), amount, abi.encode(validatorId), ""),
            "Token was not minted"
        );
    }
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )
        external override allow("SkaleToken")
    {
    }
}