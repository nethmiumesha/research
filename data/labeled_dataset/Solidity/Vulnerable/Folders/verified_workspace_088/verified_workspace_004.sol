pragma solidity ^0.8.3;
import "../interfaces/IERC20.sol";
import "../libraries/History.sol";
import "../libraries/VestingVaultStorage.sol";
import "../libraries/Storage.sol";
import "../interfaces/IVotingVault.sol";
contract VestingVault is IVotingVault {
    using History for *;
    using VestingVaultStorage for *;
    using Storage for *;
    IERC20 public immutable token;
    uint256 public immutable staleBlockLag;
    event VoteChange(address indexed to, address indexed from, int256 amount);
    constructor(
        IERC20 _token,
        uint256 _stale,
        address _manager,
        address _timelock
    ) {
        Storage.set(Storage.addressPtr("manager"), _manager);
        Storage.set(Storage.addressPtr("timelock"), _timelock);
        Storage.set(Storage.uint256Ptr("unvestedMultiplier"), 100);
        token = _token;
        staleBlockLag = _stale;
    }
    function _grants()
        internal
        pure
        returns (mapping(address => VestingVaultStorage.Grant) storage)
    {
        return (VestingVaultStorage.mappingAddressToGrantPtr("grants"));
    }
    function _unassigned() internal pure returns (Storage.Uint256 storage) {
        return Storage.uint256Ptr("unassigned");
    }
    function _manager() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("manager");
    }
    function _timelock() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("timelock");
    }
    function _unvestedMultiplier()
        internal
        pure
        returns (Storage.Uint256 memory)
    {
        return Storage.uint256Ptr("unvestedMultiplier");
    }
    modifier onlyManager() {
        _;
        require(msg.sender == _manager().data, "!manager");
    }
    modifier onlyTimelock() {
        _;
        require(msg.sender == _timelock().data, "!timelock");
    }
    function getGrant(address _who)
        external
        view
        returns (VestingVaultStorage.Grant memory)
    {
        return _grants()[_who];
    }
    function addGrantAndDelegate(
        address _who,
        uint128 _amount,
        uint128 _expiration,
        uint128 _cliff,
        address _delegatee
    ) public onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        Storage.Uint256 memory unvestedMultiplier = _unvestedMultiplier();
        require(unassigned.data >= _amount, "Insufficient balance");
        VestingVaultStorage.Grant storage grant = _grants()[_who];
        require(grant.allocation == 0, "Has Grant");
        address _delegatee = _delegatee == address(0) ? _who : _delegatee;
        uint128 newVotingPower =
            (_amount * uint128(unvestedMultiplier.data)) / 100;
        _grants()[_who] = VestingVaultStorage.Grant(
            _amount,
            0,
            uint128(block.number),
            _expiration,
            _cliff,
            newVotingPower,
            _delegatee
        );
        unassigned.data -= _amount;
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);
        votingPower.push(grant.delegatee, delegateeVotes + newVotingPower);
        emit VoteChange(grant.delegatee, _who, int256(int128(newVotingPower)));
    }
    function removeGrant(address _who) public onlyManager {
        VestingVaultStorage.Grant storage grant = _grants()[_who];
        uint256 withdrawable = _getWithdrawableAmount(grant);
        token.transfer(_who, withdrawable);
        Storage.Uint256 storage unassigned = _unassigned();
        uint256 locked = grant.allocation - (grant.withdrawn + withdrawable);
        unassigned.data += locked;
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);
        votingPower.push(
            grant.delegatee,
            delegateeVotes - grant.latestVotingPower
        );
        delete _grants()[_who];
        emit VoteChange(
            grant.delegatee,
            _who,
            -1 * int256(int128(grant.latestVotingPower))
        );
    }
    function claim() public {
        VestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        uint256 withdrawable = _getWithdrawableAmount(grant);
        token.transfer(msg.sender, withdrawable);
        grant.withdrawn += uint128(withdrawable);
        _syncVotingPower(msg.sender, grant);
    }
    function delegate(address _to) public {
        VestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 oldDelegateeVotes = votingPower.loadTop(grant.delegatee);
        uint256 newDelegateeVotes = votingPower.loadTop(_to);
        uint256 newVotingPower = _currentVotingPower(grant);
        votingPower.push(
            grant.delegatee,
            oldDelegateeVotes - grant.latestVotingPower
        );
        emit VoteChange(
            grant.delegatee,
            msg.sender,
            -1 * int256(int128(grant.latestVotingPower))
        );
        emit VoteChange(_to, msg.sender, int256(newVotingPower));
        votingPower.push(_to, newDelegateeVotes + newVotingPower);
        grant.latestVotingPower = uint128(newVotingPower);
        grant.delegatee = _to;
    }
    function deposit(uint256 _amount) public onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        unassigned.data += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
    }
    function withdraw(uint256 _amount, address _recipient) public onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        require(unassigned.data >= _amount, "Insufficient balance");
        unassigned.data -= _amount;
        token.transfer(_recipient, _amount);
    }
    function updateVotingPower(address _who) public {
        VestingVaultStorage.Grant storage grant = _grants()[_who];
        _syncVotingPower(_who, grant);
    }
    function _syncVotingPower(
        address _who,
        VestingVaultStorage.Grant storage _grant
    ) internal {
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(_grant.delegatee);
        uint256 newVotingPower = _currentVotingPower(_grant);
        int256 change =
            int256(newVotingPower) - int256(int128(_grant.latestVotingPower));
        if (change == 0) return;
        if (change > 0) {
            votingPower.push(
                _grant.delegatee,
                delegateeVotes + uint256(change)
            );
        } else {
            votingPower.push(
                _grant.delegatee,
                delegateeVotes - uint256(change * -1)
            );
        }
        emit VoteChange(_grant.delegatee, _who, change);
        _grant.latestVotingPower = uint128(newVotingPower);
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
    function _getWithdrawableAmount(VestingVaultStorage.Grant memory _grant)
        internal
        view
        returns (uint256)
    {
        if (block.number < _grant.cliff) {
            return 0;
        }
        if (block.number >= _grant.expiration) {
            return (_grant.allocation - _grant.withdrawn);
        }
        uint256 unlocked =
            (_grant.allocation * (block.number - _grant.created)) /
                (_grant.expiration - _grant.created);
        return (unlocked - _grant.withdrawn);
    }
    function _votingPower()
        internal
        pure
        returns (History.HistoricalBalances memory)
    {
        return (History.load("votingPower"));
    }
    function _currentVotingPower(VestingVaultStorage.Grant memory _grant)
        internal
        view
        returns (uint256)
    {
        uint256 withdrawable = _getWithdrawableAmount(_grant);
        uint256 locked = _grant.allocation - (withdrawable + _grant.withdrawn);
        return (withdrawable + (locked * _unvestedMultiplier().data) / 100);
    }
    function changeUnvestedMultiplier(uint256 _multiplier) public onlyTimelock {
        Storage.set(Storage.uint256Ptr("unvestedMultiplier"), _multiplier);
    }
}