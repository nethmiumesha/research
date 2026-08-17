pragma solidity ^0.5.4;
import "./StakeDelegatable.sol";
import "./utils/UintArrayUtils.sol";
import "./Registry.sol";
contract TokenStaking is StakeDelegatable {
    using UintArrayUtils for uint256[];
    event Staked(address indexed from, uint256 value);
    event Undelegated(address indexed operator, uint256 undelegatedAt);
    event RecoveredStake(address operator, uint256 recoveredAt);
    Registry public registry;
    mapping(address => mapping (address => bool)) internal authorizations;
    modifier onlyApprovedOperatorContract(address operatorContract) {
        require(
            registry.isApprovedOperatorContract(operatorContract),
            "Operator contract is not approved"
        );
        _;
    }
    constructor(address _tokenAddress, address _registry, uint256 _initializationPeriod, uint256 _undelegationPeriod) public {
        require(_tokenAddress != address(0x0), "Token address can't be zero.");
        token = ERC20Burnable(_tokenAddress);
        registry = Registry(_registry);
        initializationPeriod = _initializationPeriod;
        undelegationPeriod = _undelegationPeriod;
    }
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public {
        require(ERC20Burnable(_token) == token, "Token contract must be the same one linked to this contract.");
        require(_value <= token.balanceOf(_from), "Sender must have enough tokens.");
        require(_extraData.length == 60, "Stake delegation data must be provided.");
        address payable magpie = address(uint160(_extraData.toAddress(0)));
        address operator = _extraData.toAddress(20);
        require(operators[operator].owner == address(0), "Operator address is already in use.");
        address authorizer = _extraData.toAddress(40);
        token.transferFrom(_from, address(this), _value);
        operators[operator] = Operator(_value, block.number, 0, _from, magpie, authorizer);
        ownerOperators[_from].push(operator);
        emit Staked(operator, _value);
    }
    function cancelStake(address _operator) public {
        address owner = operators[_operator].owner;
        require(
            msg.sender == _operator ||
            msg.sender == owner, "Only operator or the owner of the stake can cancel the delegation."
        );
        require(
            block.number <= operators[_operator].createdAt.add(initializationPeriod),
            "Initialization period is over"
        );
        uint256 amount = operators[_operator].amount;
        delete operators[_operator];
        token.safeTransfer(owner, amount);
    }
    function undelegate(address _operator) public {
        address owner = operators[_operator].owner;
        require(
            msg.sender == _operator ||
            msg.sender == owner, "Only operator or the owner of the stake can undelegate."
        );
        operators[_operator].undelegatedAt = block.number;
        emit Undelegated(_operator, block.number);
    }
    function recoverStake(address _operator) public {
        require(
            block.number >= operators[_operator].undelegatedAt.add(undelegationPeriod),
            "Can not recover stake before undelegation period is over."
        );
        address owner = operators[_operator].owner;
        uint256 amount = operators[_operator].amount;
        delete operators[_operator];
        token.safeTransfer(owner, amount);
        emit RecoveredStake(_operator, block.number);
    }
    function getUndelegation(address _operator) public view returns (uint256 amount, uint256 undelegatedAt) {
        return (operators[_operator].amount, operators[_operator].undelegatedAt);
    }
    function slash(uint256 amount, address[] memory misbehavedOperators)
        public
        onlyApprovedOperatorContract(msg.sender) {
        for (uint i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(authorizations[msg.sender][operator], "Not authorized");
            operators[operator].amount = operators[operator].amount.sub(amount);
        }
        token.burn(misbehavedOperators.length.mul(amount));
    }
    function seize(
        uint256 amount,
        uint256 rewardMultiplier,
        address tattletale,
        address[] memory misbehavedOperators
    ) public onlyApprovedOperatorContract(msg.sender) {
        for (uint i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(authorizations[msg.sender][operator], "Not authorized");
            operators[operator].amount = operators[operator].amount.sub(amount);
        }
        uint256 total = misbehavedOperators.length.mul(amount);
        uint256 tattletaleReward = (total.mul(5).div(100)).mul(rewardMultiplier).div(100);
        token.transfer(tattletale, tattletaleReward);
        token.burn(total.sub(tattletaleReward));
    }
    function authorizeOperatorContract(address _operator, address _operatorContract)
        public
        onlyOperatorAuthorizer(_operator)
        onlyApprovedOperatorContract(_operatorContract) {
        authorizations[_operatorContract][_operator] = true;
    }
    function eligibleStake(
        address _operator,
        address _operatorContract
    ) public view returns (uint256 balance) {
        bool isAuthorized = authorizations[_operatorContract][_operator];
        Operator memory operator = operators[_operator];
        bool isActive = block.number >= operator.createdAt.add(initializationPeriod);
        bool notUndelegated = block.number <= operator.undelegatedAt || operator.undelegatedAt == 0;
        if (isAuthorized && isActive && notUndelegated) {
            balance = operator.amount;
        }
    }
    function activeStake(
        address _operator,
        address _operatorContract
    ) public view returns (uint256 balance) {
        bool isAuthorized = authorizations[_operatorContract][_operator];
        Operator memory operator = operators[_operator];
        bool isActive = block.number >= operator.createdAt.add(initializationPeriod);
        if (isAuthorized && isActive) {
            balance = operator.amount;
        }
    }
}