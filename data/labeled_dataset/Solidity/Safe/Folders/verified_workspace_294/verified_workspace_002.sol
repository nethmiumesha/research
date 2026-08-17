pragma solidity 0.4.24;
contract Ownable {
    address public owner;
    address public pendingOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }
    constructor() public {
        owner = msg.sender;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    uint256 public decimals;
    function allowance(address owner, address spender)
        public view returns (uint256);
    function transferFrom(address from, address to, uint256 value)
        public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function mint(
        address _to,
        uint256 _amountusingOraclize
    )
        public
        returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }
    function addAddressToWhitelist(address addr) public onlyOwner returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }
    function addAddressesToWhitelist(address[] addrs) public onlyOwner returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
    function removeAddressFromWhitelist(address addr) public onlyOwner returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }
    function removeAddressesFromWhitelist(address[] addrs) public onlyOwner returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}
contract PriceChecker {
    uint256 public priceETHUSD;
    uint256 public centsInDollar = 100;
    uint256 public lastPriceUpdate;
    uint256 public minUpdatePeriod = 3300;
    event NewOraclizeQuery(string description);
    event PriceUpdated(uint256 price);
    constructor() public {
    }
    modifier onlyActualPrice {
        require(lastPriceUpdate > now - 3720);
        _;
    }
    function __callback(uint256 result) external {
        require((lastPriceUpdate + minUpdatePeriod) < now);
        priceETHUSD = result;
        lastPriceUpdate = now;
        emit PriceUpdated(priceETHUSD);
        return;
    }
}
contract BeamCrowdsale_TEST_ONLY is Whitelist, PriceChecker, Pausable {
    using SafeMath for uint256;
    mapping(address => uint256) public funds;
    ERC20 public token;
    address public wallet;
    uint256 public weiRaised;
    uint256 public discountSeed = 20;
    uint256 public discountPrivate = 15;
    uint256 public discountPublic = 10;
    uint256 public decimals;
    uint256 public bonuses;
    bool public publicRound;
    bool public seedFinished;
    bool public crowdsaleFinished;
    bool public softCapReached;
    uint256 public increasing = 10 ** 9;
    uint256 public tokensForSeed = 100 * 10 ** 6 * 10 ** 18;
    uint256 public softCap = 2 * 10 ** 6 * 10 ** 18;
    uint256 public usdRaised;
    uint256 public unitsToInt = 10 ** 18;
    event TokenPurchase(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );
    event SeedRoundFinished();
    event PrivateRoundFinished();
    event StartPrivateRound();
    event StartPublicRound();
    event PublicRoundFinished();
    event CrowdsaleFinished(uint256 weiRaised, uint256 usdRaised);
    event SoftCapReached();
    modifier onlyWhileOpen {
        require(!crowdsaleFinished);
        _;
    }
    constructor(address _wallet, ERC20 _token) public {
        require(_wallet != address(0));
        require(_token != address(0));
        wallet = _wallet;
        token = _token;
        decimals = token.decimals();
    }
    function () external
        payable
        onlyActualPrice
        onlyWhileOpen
        onlyWhitelisted
        whenNotPaused
    {
        buyTokens();
    }
    function payToContract() external payable onlyOwner {}
    function withdrawFunds(address _beneficiary, uint256 _weiAmount)
        external
        onlyOwner
    {
        require(address(this).balance > _weiAmount);
        _beneficiary.transfer(_weiAmount);
    }
    function finishCrowdsale() external onlyOwner onlyWhileOpen {
        crowdsaleFinished = true;
        uint256 _soldAmount = token.totalSupply().sub(bonuses);
        token.mint(address(this), _soldAmount);
        emit TokenPurchase(address(this), 0, _soldAmount);
        emit CrowdsaleFinished(weiRaised, usdRaised);
    }
    function claimFunds() external {
        require(crowdsaleFinished);
        require(!softCapReached);
        require(funds[msg.sender] > 0);
        require(address(this).balance >= funds[msg.sender]);
        uint256 toSend = funds[msg.sender];
        delete funds[msg.sender];
        msg.sender.transfer(toSend);
    }
    function transferTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        external
        onlyOwner
    {
        require(token.balanceOf(address(this)) >= _tokenAmount);
        token.transfer(_beneficiary, _tokenAmount);
    }
    function buyForFiat(address _beneficiary, uint256 _usdUnits)
        external
        onlyOwner
        onlyWhileOpen
        onlyActualPrice
    {
        uint256 _weiAmount = _usdUnits.mul(centsInDollar).div(priceETHUSD);
        _preValidatePurchase(_beneficiary, _weiAmount);
        uint256 tokens = _getTokenAmount(_weiAmount);
        weiRaised = weiRaised.add(_weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            _beneficiary,
            _weiAmount,
            tokens
        );
        _postValidatePurchase();
    }
    function mintBonus(address _beneficiary, uint256 _tokenUnits)
        external
        onlyOwner
        onlyWhileOpen
    {
        _processPurchase(_beneficiary, _tokenUnits);
        emit TokenPurchase(_beneficiary, 0, _tokenUnits);
        bonuses = bonuses.add(_tokenUnits);
        _postValidatePurchase();
    }
    function finishSeedRound() external onlyOwner onlyWhileOpen {
        require(!seedFinished);
        seedFinished = true;
        emit SeedRoundFinished();
        emit StartPrivateRound();
    }
    function setDiscountSeed(uint256 _discountSeed) external onlyOwner onlyWhileOpen {
        discountSeed = _discountSeed;
    }
    function setDiscountPrivate(uint256 _discountPrivate) external onlyOwner onlyWhileOpen {
        discountPrivate = _discountPrivate;
    }
    function setDiscountPublic(uint256 _discountPublic) external onlyOwner onlyWhileOpen {
        discountPublic = _discountPublic;
    }
    function setPublicRound(bool _enable) external onlyOwner onlyWhileOpen {
        require(seedFinished);
        publicRound = _enable;
        if (_enable) {
            emit PrivateRoundFinished();
            emit StartPublicRound();
        } else {
            emit PublicRoundFinished();
            emit StartPrivateRound();
        }
    }
    function buyTokens()
        public
        payable
        onlyWhileOpen
        onlyWhitelisted
        whenNotPaused
        onlyActualPrice
    {
        address _beneficiary = msg.sender;
        uint256 _weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, _weiAmount);
        uint256 tokens = _getTokenAmount(_weiAmount);
        _weiAmount = _weiAmount.sub(_applyDiscount(_weiAmount));
        funds[_beneficiary] = funds[_beneficiary].add(_weiAmount);
        weiRaised = weiRaised.add(_weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(_beneficiary, _weiAmount, tokens);
        _forwardFunds(_weiAmount);
        _postValidatePurchase();
    }
    function tokenPrice() public view returns(uint256) {
        uint256 _supplyInt = token.totalSupply().div(10 ** decimals);
        return uint256(10 ** 18).add(_supplyInt.mul(increasing));
    }
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal
        pure
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x.add(1)).div(2);
        uint256 y = x;
        while (z < y) {
            y = z;
            z = ((x.div(z)).add(z)).div(2);
        }
        return y;
    }
    function tokenIntAmount(uint256 _startPrice, uint256 _usdUnits)
        internal
        view
        returns(uint256)
    {
        uint256 sqrtVal = sqrt(((_startPrice.mul(2).sub(increasing)).pow(2)).add(_usdUnits.mul(8).mul(increasing)));
        return (increasing.add(sqrtVal).sub(_startPrice.mul(2))).div(increasing.mul(2));
    }
    function _remainderAmount(
        uint256 _startPrice,
        uint256 _usdUnits,
        uint256 _tokenIntAmount
    )
        internal
        view
        returns(uint256)
    {
        uint256 _summ = (_startPrice.mul(2).add(increasing.mul(_tokenIntAmount.sub(1))).mul(_tokenIntAmount)).div(2);
        return _usdUnits.sub(_summ);
    }
    function _postValidatePurchase() internal {
        if (!seedFinished) _checkSeed();
        if (!softCapReached) _checkSoftCap();
    }
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        token.mint(_beneficiary, _tokenAmount);
    }
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    function _getTokenAmount(uint256 _weiAmount)
        internal returns (uint256)
    {
        uint256 _usdUnits = _weiAmount.mul(priceETHUSD).div(centsInDollar);
        usdRaised = usdRaised.add(_usdUnits);
        uint256 _tokenPrice = tokenPrice();
        uint256 _tokenIntAmount = tokenIntAmount(_tokenPrice, _usdUnits);
        uint256 _tokenUnitAmount = _tokenIntAmount.mul(10 ** decimals);
        uint256 _newPrice = tokenPrice().add(_tokenIntAmount.mul(increasing));
        uint256 _usdRemainder;
        if (_tokenIntAmount == 0)
            _usdRemainder = _usdUnits;
        else
            _usdRemainder = _remainderAmount(_tokenPrice, _usdUnits, _tokenIntAmount);
        _tokenUnitAmount = _tokenUnitAmount.add(_usdRemainder.mul(10 ** decimals).div(_newPrice));
        return _tokenUnitAmount;
    }
    function _checkSeed() internal {
        if (token.totalSupply() >= tokensForSeed) {
            seedFinished = true;
            emit SeedRoundFinished();
            emit StartPrivateRound();
        }
    }
    function _checkSoftCap() internal {
        if (usdRaised >= softCap) {
            softCapReached = true;
            emit SoftCapReached();
        }
    }
    function _applyDiscount(uint256 _weiAmount) internal returns (uint256) {
        address _payer = msg.sender;
        uint256 _refundAmount;
        if (!seedFinished) {
            _refundAmount = _weiAmount.mul(discountSeed).div(100);
        } else if (!publicRound) {
            _refundAmount = _weiAmount.mul(discountPrivate).div(100);
        } else {
            _refundAmount = _weiAmount.mul(discountPublic).div(100);
        }
        _payer.transfer(_refundAmount);
        return _refundAmount;
    }
    function _forwardFunds(uint256 _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }
    function setMinUpdatePeriod(uint256 _minUpdatePeriod) public onlyOwner {
        minUpdatePeriod = _minUpdatePeriod;
    }
}