pragma solidity 0.6.10;
import "./Permissions.sol";
import "./SchainsInternal.sol";
import "./Nodes.sol";
contract Pricing is Permissions {
    uint public constant INITIAL_PRICE = 5 * 10**6;
    uint public price;
    uint public totalNodes;
    uint public lastUpdated;
    function initNodes() external {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        totalNodes = nodes.getNumberOnlineNodes();
    }
    function adjustPrice() external {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        require(now > lastUpdated.add(constantsHolder.COOLDOWN_TIME()), "It's not a time to update a price");
        checkAllNodes();
        uint load = _getTotalLoad();
        uint capacity = _getTotalCapacity();
        bool networkIsOverloaded = load.mul(100) > constantsHolder.OPTIMAL_LOAD_PERCENTAGE().mul(capacity);
        uint loadDiff;
        if (networkIsOverloaded) {
            loadDiff = load.mul(100).sub(constantsHolder.OPTIMAL_LOAD_PERCENTAGE().mul(capacity));
        } else {
            loadDiff = constantsHolder.OPTIMAL_LOAD_PERCENTAGE().mul(capacity).sub(load.mul(100));
        }
        uint priceChangeSpeedMultipliedByCapacityAndMinPrice =
            constantsHolder.ADJUSTMENT_SPEED().mul(loadDiff).mul(price);
        uint timeSkipped = now.sub(lastUpdated);
        uint priceChange = priceChangeSpeedMultipliedByCapacityAndMinPrice
            .mul(timeSkipped)
            .div(constantsHolder.COOLDOWN_TIME())
            .div(capacity)
            .div(constantsHolder.MIN_PRICE());
        if (networkIsOverloaded) {
            assert(priceChange > 0);
            price = price.add(priceChange);
        } else {
            if (priceChange > price) {
                price = constantsHolder.MIN_PRICE();
            } else {
                price = price.sub(priceChange);
                if (price < constantsHolder.MIN_PRICE()) {
                    price = constantsHolder.MIN_PRICE();
                }
            }
        }
        lastUpdated = now;
    }
    function getTotalLoadPercentage() external view returns (uint) {
        return _getTotalLoad().mul(100).div(_getTotalCapacity());
    }
    function initialize(address newContractsAddress) public override initializer {
        Permissions.initialize(newContractsAddress);
        lastUpdated = now;
        price = INITIAL_PRICE;
    }
    function checkAllNodes() public {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        uint numberOfActiveNodes = nodes.getNumberOnlineNodes();
        require(totalNodes != numberOfActiveNodes, "No changes to node supply");
        totalNodes = numberOfActiveNodes;
    }
    function _getTotalLoad() private view returns (uint) {
        SchainsInternal schainsInternal = SchainsInternal(contractManager.getContract("SchainsInternal"));
        uint load = 0;
        uint numberOfSchains = schainsInternal.numberOfSchains();
        for (uint i = 0; i < numberOfSchains; i++) {
            bytes32 schain = schainsInternal.schainsAtSystem(i);
            uint numberOfNodesInSchain = schainsInternal.getNumberOfNodesInGroup(schain);
            uint part = schainsInternal.getSchainsPartOfNode(schain);
            load = load.add(
                numberOfNodesInSchain.mul(part)
            );
        }
        return load;
    }
    function _getTotalCapacity() private view returns (uint) {
        Nodes nodes = Nodes(contractManager.getContract("Nodes"));
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        return nodes.getNumberOnlineNodes().mul(constantsHolder.TOTAL_SPACE_ON_NODE());
    }
}