pragma solidity 0.6.10;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./thirdparty/openzeppelin/ERC777.sol";
import "./Permissions.sol";
import "./interfaces/delegation/IDelegatableToken.sol";
import "./interfaces/IMintableToken.sol";
import "./delegation/Punisher.sol";
import "./delegation/TokenState.sol";
contract SkaleToken is ERC777, Permissions, ReentrancyGuard, IDelegatableToken, IMintableToken {
    using SafeMath for uint;
    string public constant NAME = "SKALE";
    string public constant SYMBOL = "SKL";
    uint public constant DECIMALS = 18;
    uint public constant CAP = 7 * 1e9 * (10 ** DECIMALS);
    constructor(address contractsAddress, address[] memory defOps) public
    ERC777("SKALE", "SKL", defOps)
    {
        Permissions.initialize(contractsAddress);
    }
    function mint(
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )
        external
        override
        allow("SkaleManager")
        returns (bool)
    {
        require(amount <= CAP.sub(totalSupply()), "Amount is too big");
        _mint(
            account,
            amount,
            userData,
            operatorData
        );
        return true;
    }
    function getAndUpdateDelegatedAmount(address wallet) external override returns (uint) {
        return DelegationController(contractManager.getContract("DelegationController"))
            .getAndUpdateDelegatedAmount(wallet);
    }
    function getAndUpdateSlashedAmount(address wallet) external override returns (uint) {
        return Punisher(contractManager.getContract("Punisher")).getAndUpdateLockedAmount(wallet);
    }
    function getAndUpdateLockedAmount(address wallet) public override returns (uint) {
        return TokenState(contractManager.getContract("TokenState")).getAndUpdateLockedAmount(wallet);
    }
    function _beforeTokenTransfer(
        address,
        address from,
        address,
        uint256 tokenId)
        internal override
    {
        uint locked = getAndUpdateLockedAmount(from);
        if (locked > 0) {
            require(balanceOf(from) >= locked.add(tokenId), "Token should be unlocked for transferring");
        }
    }
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal override nonReentrant {
        super._callTokensToSend(operator, from, to, amount, userData, operatorData);
    }
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal override nonReentrant {
        super._callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }
    function _msgData() internal view override(Context, ContextUpgradeSafe) returns (bytes memory) {
        return Context._msgData();
    }
    function _msgSender() internal view override(Context, ContextUpgradeSafe) returns (address payable) {
        return Context._msgSender();
    }
}