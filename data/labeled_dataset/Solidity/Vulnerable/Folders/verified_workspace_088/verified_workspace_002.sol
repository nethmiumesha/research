pragma solidity ^0.8.3;
import "../libraries/History.sol";
import "../libraries/Storage.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IVotingVault.sol";
contract LockingVault is IVotingVault {
    using History for *;
    using Storage for *;
    IERC20 public immutable token;
    uint256 public immutable staleBlockLag;
    event VoteChange(address indexed to, address indexed from, int256 amount);
    constructor(IERC20 _token, uint256 _staleBlockLag) {
        token = _token;
        staleBlockLag = _staleBlockLag;
    }
    function _deposits()
        internal
        pure
        returns (mapping(address => Storage.AddressUint) storage)
    {
        return (Storage.mappingAddressToPackedAddressUint("deposits"));
    }
    function deposits(address who) external view returns (address, uint96) {
        Storage.AddressUint storage userData = _deposits()[who];
        return (userData.who, userData.amount);
    }
    function _votingPower()
        internal
        pure
        returns (History.HistoricalBalances memory)
    {
        return (History.load("votingPower"));
    }
    function queryVotePower(
        address user,
        uint256 blockNumber,
        bytes calldata
    ) external override returns (uint256) {
        History.HistoricalBalances memory votingPower = _votingPower();
        return
            votingPower.findAndClear(
                user,
                blockNumber,
                block.number - staleBlockLag
            );
    }
    function queryVotePowerView(address user, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        History.HistoricalBalances memory votingPower = _votingPower();
        return votingPower.find(user, blockNumber);
    }
    function deposit(
        address fundedAccount,
        uint256 amount,
        address firstDelegation
    ) external {
        token.transferFrom(msg.sender, address(this), amount);
        Storage.AddressUint storage userData = _deposits()[fundedAccount];
        address delegate = userData.who;
        if (delegate == address(0)) {
            delegate = firstDelegation;
            userData.who = delegate;
            userData.amount += uint96(amount);
        } else {
            userData.amount += uint96(amount);
        }
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(delegate);
        emit VoteChange(fundedAccount, delegate, int256(amount));
        votingPower.push(delegate, delegateeVotes + amount);
    }
    function withdraw(uint256 amount) external {
        Storage.AddressUint storage userData = _deposits()[msg.sender];
        userData.amount -= uint96(amount);
        address delegate = userData.who;
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(delegate);
        votingPower.push(delegate, delegateeVotes - amount);
        emit VoteChange(msg.sender, delegate, -1 * int256(amount));
        token.transfer(msg.sender, amount);
    }
    function changeDelegation(address newDelegate) external {
        Storage.AddressUint storage userData = _deposits()[msg.sender];
        uint256 userBalance = uint256(userData.amount);
        address oldDelegate = userData.who;
        userData.who = newDelegate;
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 oldDelegateVotes = votingPower.loadTop(oldDelegate);
        votingPower.push(oldDelegate, oldDelegateVotes - userBalance);
        emit VoteChange(msg.sender, oldDelegate, -1 * int256(userBalance));
        uint256 newDelegateVotes = votingPower.loadTop(newDelegate);
        votingPower.push(newDelegate, newDelegateVotes + userBalance);
        emit VoteChange(msg.sender, newDelegate, int256(userBalance));
    }
}