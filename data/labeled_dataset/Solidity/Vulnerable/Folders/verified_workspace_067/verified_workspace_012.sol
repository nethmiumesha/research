pragma solidity 0.5.11;
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./WhitelistedPausableToken.sol";
contract MockOGN is ERC20Burnable, WhitelistedPausableToken, ERC20Detailed {
    event AddCallSpenderWhitelist(address enabler, address spender);
    event RemoveCallSpenderWhitelist(address disabler, address spender);
    mapping(address => bool) public callSpenderWhitelist;
    constructor(uint256 _initialSupply)
        public
        ERC20Detailed("OriginToken", "OGN", 18)
    {
        owner = msg.sender;
        _mint(owner, _initialSupply);
    }
    function mint(uint256 _value) external returns (bool) {
        _mint(msg.sender, _value);
        return true;
    }
    function burn(uint256 _value) public onlyOwner {
        super.burn(_value);
    }
    function burn(address _who, uint256 _value) public onlyOwner {
        _burn(_who, _value);
    }
    function addCallSpenderWhitelist(address _spender) public onlyOwner {
        callSpenderWhitelist[_spender] = true;
        emit AddCallSpenderWhitelist(msg.sender, _spender);
    }
    function removeCallSpenderWhitelist(address _spender) public onlyOwner {
        delete callSpenderWhitelist[_spender];
        emit RemoveCallSpenderWhitelist(msg.sender, _spender);
    }
    function approveAndCallWithSender(
        address _spender,
        uint256 _value,
        bytes4 _selector,
        bytes memory _callParams
    ) public payable returns (bool) {
        require(_spender != address(this), "token contract can't be approved");
        require(callSpenderWhitelist[_spender], "spender not in whitelist");
        require(super.approve(_spender, _value), "approve failed");
        bytes memory callData = abi.encodePacked(
            _selector,
            uint256(msg.sender),
            _callParams
        );
        (bool success, ) = _spender.call.value(msg.value)(callData);
        require(success, "proxied call failed");
        return true;
    }
}