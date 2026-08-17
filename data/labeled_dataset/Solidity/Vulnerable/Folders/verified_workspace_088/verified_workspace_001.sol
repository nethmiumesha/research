pragma solidity ^0.8.3;
import "../interfaces/ICoreVoting.sol";
import "../interfaces/IVotingVault.sol";
import "../libraries/Authorizable.sol";
contract GSCVault is Authorizable {
    mapping(address => Member) public members;
    ICoreVoting public coreVoting;
    uint256 public votingPowerBound;
    uint256 public idleDuration = 60 * 60 * 24 * 4;
    event MembershipProved(address indexed who, uint256 when);
    event Kicked(address indexed who, uint256 when);
    struct Member {
        address[] vaults;
        uint256 joined;
    }
    constructor(
        ICoreVoting _coreVoting,
        uint256 _votingPowerBound,
        address _owner
    ) {
        coreVoting = _coreVoting;
        votingPowerBound = _votingPowerBound;
        setOwner(address(_owner));
    }
    function proveMembership(
        address[] calldata votingVaults,
        bytes[] calldata extraData
    ) external {
        assert(votingVaults.length > 0);
        for (uint256 i = 0; i < votingVaults.length; i++) {
            bool vaultStatus = coreVoting.approvedVaults(votingVaults[i]);
            require(vaultStatus, "Voting vault not approved");
        }
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < votingVaults.length; i++) {
            uint256 votes =
                IVotingVault(votingVaults[i]).queryVotePower(
                    msg.sender,
                    block.number - 1,
                    extraData[i]
                );
            totalVotes += votes;
        }
        require(totalVotes >= votingPowerBound, "Not enough votes");
        if (members[msg.sender].joined != 0) {
            members[msg.sender] = Member(
                votingVaults,
                members[msg.sender].joined
            );
        } else {
            members[msg.sender] = Member(votingVaults, block.timestamp);
        }
        emit MembershipProved(msg.sender, block.timestamp);
    }
    function kick(address who, bytes[] calldata extraData) external {
        address[] memory votingVaults = members[who].vaults;
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < votingVaults.length; i++) {
            if (coreVoting.approvedVaults(votingVaults[i])) {
                uint256 votes =
                    IVotingVault(votingVaults[i]).queryVotePower(
                        who,
                        block.number - 1,
                        extraData[i]
                    );
                totalVotes += votes;
            }
        }
        require(totalVotes < votingPowerBound, "Not kick-able");
        delete members[who];
        emit Kicked(who, block.number);
    }
    function queryVotingPower(
        address who,
        uint256,
        bytes calldata
    ) public view returns (uint256) {
        if (who == owner) {
            return 100000;
        }
        if (
            members[who].joined > 0 &&
            (members[who].joined + idleDuration) <= block.timestamp
        ) {
            return 1;
        } else {
            return 0;
        }
    }
    function getUserVaults(address who) public view returns (address[] memory) {
        return members[who].vaults;
    }
    function setCoreVoting(ICoreVoting _newVoting) external onlyOwner() {
        coreVoting = _newVoting;
    }
    function setVotePowerBound(uint256 _newBound) external onlyOwner() {
        votingPowerBound = _newBound;
    }
    function setIdleDuration(uint256 _idleDuration) external onlyOwner() {
        idleDuration = _idleDuration;
    }
}