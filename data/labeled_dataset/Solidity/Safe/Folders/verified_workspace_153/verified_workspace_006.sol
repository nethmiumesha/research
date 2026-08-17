pragma solidity ^0.4.21;
import './ManagedToken.sol';
contract TransferLimitedToken is ManagedToken {
    uint256 public constant LIMIT_TRANSFERS_PERIOD = 365 days;
    mapping(address => bool) public limitedWallets;
    uint256 public limitEndDate;
    address public limitedWalletsManager;
    bool public isLimitEnabled;
    modifier onlyManager() {
        require(msg.sender == limitedWalletsManager);
        _;
    }
    modifier canTransfer(address _from, address _to)  {
        require(now >= limitEndDate || !isLimitEnabled || (!limitedWallets[_from] && !limitedWallets[_to]));
        _;
    }
    function TransferLimitedToken(
        uint256 _limitStartDate,
        address _listener,
        address[] _owners,
        address _limitedWalletsManager
    ) public ManagedToken(_listener, _owners)
    {
        limitEndDate = _limitStartDate + LIMIT_TRANSFERS_PERIOD;
        isLimitEnabled = true;
        limitedWalletsManager = _limitedWalletsManager;
    }
    function addLimitedWalletAddress(address _wallet) public {
        require(msg.sender == limitedWalletsManager || ownerByAddress[msg.sender]);
        limitedWallets[_wallet] = true;
    }
    function delLimitedWalletAddress(address _wallet) public onlyManager {
        limitedWallets[_wallet] = false;
    }
    function disableLimit() public onlyManager {
        isLimitEnabled = false;
    }
    function transfer(address _to, uint256 _value) public canTransfer(msg.sender, _to) returns (bool) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer(_from, _to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) public canTransfer(msg.sender, _spender) returns (bool) {
        return super.approve(_spender,_value);
    }
}