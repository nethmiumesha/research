pragma solidity 0.5.11;
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
contract WhitelistedPausableToken is ERC20Pausable {
    address public owner = msg.sender;
    uint256 public whitelistExpiration;
    mapping(address => bool) public allowedTransactors;
    event SetWhitelistExpiration(uint256 expiration);
    event AllowedTransactorAdded(address sender);
    event AllowedTransactorRemoved(address sender);
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier allowedTransfer(address _from, address _to) {
        require(
            !whitelistActive() ||
                allowedTransactors[_from] ||
                allowedTransactors[_to],
            "neither sender nor recipient are allowed"
        );
        _;
    }
    function whitelistActive() public view returns (bool) {
        return block.timestamp < whitelistExpiration;
    }
    function addAllowedTransactor(address _transactor) public onlyOwner {
        emit AllowedTransactorAdded(_transactor);
        allowedTransactors[_transactor] = true;
    }
    function removeAllowedTransactor(address _transactor) public onlyOwner {
        emit AllowedTransactorRemoved(_transactor);
        delete allowedTransactors[_transactor];
    }
    function setWhitelistExpiration(uint256 _expiration) public onlyOwner {
        require(
            whitelistExpiration == 0 || whitelistActive(),
            "an expired whitelist cannot be extended"
        );
        require(
            _expiration >= block.timestamp + 1 days,
            "whitelist expiration not far enough into the future"
        );
        emit SetWhitelistExpiration(_expiration);
        whitelistExpiration = _expiration;
    }
    function transfer(address _to, uint256 _value)
        public
        allowedTransfer(msg.sender, _to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public allowedTransfer(_from, _to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}