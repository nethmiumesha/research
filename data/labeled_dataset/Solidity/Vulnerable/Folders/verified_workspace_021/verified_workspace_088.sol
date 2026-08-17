pragma solidity ^0.5.16;
import "./Owned.sol";
import "./interfaces/ISupplySchedule.sol";
import "./SafeDecimalMath.sol";
import "./Math.sol";
import "./Proxy.sol";
import "./interfaces/ISynthetix.sol";
import "./interfaces/IERC20.sol";
contract SupplySchedule is Owned, ISupplySchedule {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using Math for uint;
    bytes32 public constant CONTRACT_NAME = "SupplySchedule";
    uint public lastMintEvent;
    uint public weekCounter;
    uint public constant INFLATION_START_DATE = 1551830400;
    uint public minterReward = 100 * 1e18;
    uint public inflationAmount;
    uint public maxInflationAmount = 3e6 * 1e18;
    address payable public synthetixProxy;
    uint public constant MAX_MINTER_REWARD = 200 * 1e18;
    uint public constant MINT_PERIOD_DURATION = 1 weeks;
    uint public constant MINT_BUFFER = 1 days;
    constructor(
        address _owner,
        uint _lastMintEvent,
        uint _currentWeek
    ) public Owned(_owner) {
        lastMintEvent = _lastMintEvent;
        weekCounter = _currentWeek;
    }
    function mintableSupply() external view returns (uint) {
        uint totalAmount;
        if (!isMintable()) {
            return totalAmount;
        }
        totalAmount = inflationAmount.mul(weeksSinceLastIssuance());
        return totalAmount;
    }
    function weeksSinceLastIssuance() public view returns (uint) {
        uint timeDiff = lastMintEvent > 0 ? now.sub(lastMintEvent) : now.sub(INFLATION_START_DATE);
        return timeDiff.div(MINT_PERIOD_DURATION);
    }
    function isMintable() public view returns (bool) {
        if (now - lastMintEvent > MINT_PERIOD_DURATION) {
            return true;
        }
        return false;
    }
    function recordMintEvent(uint supplyMinted) external onlySynthetix returns (uint) {
        uint numberOfWeeksIssued = weeksSinceLastIssuance();
        weekCounter = weekCounter.add(numberOfWeeksIssued);
        lastMintEvent = INFLATION_START_DATE.add(weekCounter.mul(MINT_PERIOD_DURATION)).add(MINT_BUFFER);
        emit SupplyMinted(supplyMinted, numberOfWeeksIssued, lastMintEvent, now);
        return minterReward;
    }
    function setMinterReward(uint amount) external onlyOwner {
        require(amount <= MAX_MINTER_REWARD, "Reward cannot exceed max minter reward");
        minterReward = amount;
        emit MinterRewardUpdated(minterReward);
    }
    function setSynthetixProxy(ISynthetix _synthetixProxy) external onlyOwner {
        require(address(_synthetixProxy) != address(0), "Address cannot be 0");
        synthetixProxy = address(uint160(address(_synthetixProxy)));
        emit SynthetixProxyUpdated(synthetixProxy);
    }
    function setInflationAmount(uint amount) external onlyOwner {
        require(amount <= maxInflationAmount, "Amount above maximum inflation");
        inflationAmount = amount;
        emit InflationAmountUpdated(inflationAmount);
    }
    function setMaxInflationAmount(uint amount) external onlyOwner {
        maxInflationAmount = amount;
        emit MaxInflationAmountUpdated(inflationAmount);
    }
    modifier onlySynthetix() {
        require(
            msg.sender == address(Proxy(address(synthetixProxy)).target()),
            "Only the synthetix contract can perform this action"
        );
        _;
    }
    event SupplyMinted(uint supplyMinted, uint numberOfWeeksIssued, uint lastMintEvent, uint timestamp);
    event MinterRewardUpdated(uint newRewardAmount);
    event InflationAmountUpdated(uint newInflationAmount);
    event MaxInflationAmountUpdated(uint newInflationAmount);
    event SynthetixProxyUpdated(address newAddress);
}