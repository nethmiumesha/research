pragma solidity 0.4.24;
import "./XRT.sol";
import "./Ambix.sol";
import "./LiabilityFactory.sol";
contract DutchAuction {
    event BidSubmission(address indexed sender, uint256 amount);
    uint constant public MAX_TOKENS_SOLD = 9000000 * 10**9;
    uint constant public WAITING_PERIOD = 7 days;
    XRT              public xrt;
    Ambix            public ambix;
    LiabilityFactory public factory;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier isWallet() {
        require(msg.sender == wallet);
        _;
    }
    modifier isValidPayload() {
        require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }
    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }
    constructor(address _wallet, uint _ceiling, uint _priceFactor)
        public
    {
        require(_wallet != 0 && _ceiling != 0 && _priceFactor != 0);
        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }
    function setup(address _xrt, address _ambix, address _factory)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        require(_xrt != 0 && _ambix != 0 && _factory != 0);
        xrt = XRT(_xrt);
        ambix = Ambix(_ambix);
        factory = LiabilityFactory(_factory);
        require(xrt.balanceOf(this) == MAX_TOKENS_SOLD);
        stage = Stages.AuctionSetUp;
    }
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }
    function changeSettings(uint _ceiling, uint _priceFactor)
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
    }
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
    }
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        require(msg.value > 0);
        amount = msg.value;
        if (receiver == 0)
            receiver = msg.sender;
        uint maxWei = (MAX_TOKENS_SOLD / 10**18) * calcTokenPrice() - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
        if (amount > maxWei) {
            amount = maxWei;
            receiver.transfer(msg.value - amount);
        }
        wallet.transfer(amount);
        bids[receiver] += amount;
        totalReceived += amount;
        if (maxWei == amount)
            finalizeAuction();
        BidSubmission(receiver, amount);
    }
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0)
            receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        require(xrt.transfer(receiver, tokenCount));
    }
    function calcStopPrice()
        constant
        public
        returns (uint)
    {
        return totalReceived * 10**18 / MAX_TOKENS_SOLD + 1;
    }
    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        require(xrt.transfer(ambix, MAX_TOKENS_SOLD - soldTokens));
        endTime = now;
    }
}