pragma solidity ^0.5.3;
import "./ERC777/LockableERC777.sol";
import "./Permissions.sol";
import "./interfaces/delegation/IDelegatableToken.sol";
import "./delegation/DelegationService.sol";
contract SkaleToken is LockableERC777, Permissions, IDelegatableToken {
    string public constant NAME = "SKALE";
    string public constant SYMBOL = "SKL";
    uint public constant DECIMALS = 18;
    uint public constant CAP = 7 * 1e9 * (10 ** DECIMALS);
    constructor(address contractsAddress, address[] memory defOps)
    Permissions(contractsAddress)
    LockableERC777("SKALE", "SKL", defOps) public
    {
        uint money = 1e7 * 10 ** DECIMALS;
        _mint(
            address(0),
            address(msg.sender),
            money, bytes(""),
            bytes("")
        );
    }
    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )
        external
        allow("SkaleManager")
        returns (bool)
    {
        require(amount <= CAP - totalSupply(), "Amount is too big");
        _mint(
            operator,
            account,
            amount,
            userData,
            operatorData
        );
        return true;
    }
    function getDelegatedOf(address wallet) external returns (uint) {
        return DelegationService(contractManager.getContract("DelegationService")).getDelegatedOf(wallet);
    }
    function getSlashedOf(address wallet) external returns (uint) {
        return DelegationService(contractManager.getContract("DelegationService")).getSlashedOf(wallet);
    }
    function getLockedOf(address wallet) public returns (uint) {
        return DelegationService(contractManager.getContract("DelegationService")).getLockedOf(wallet);
    }
    function _getLockedOf(address wallet) internal returns (uint) {
        return getLockedOf(wallet);
    }
}