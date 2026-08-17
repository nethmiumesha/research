pragma solidity 0.5.13;
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "hardhat/console.sol";
import "../../interfaces/IRealitio.sol";
import "../../interfaces/IFactory.sol";
import "../../interfaces/ITreasury.sol";
import '../../interfaces/IRCProxyXdai.sol';
import '../../interfaces/IRCNftHubXdai.sol';
import '../../lib/NativeMetaTransaction.sol';
contract RCMarketXdaiV2 is Initializable, NativeMetaTransaction {
    using SafeMath for uint256;
    uint256 public numberOfTokens;
    uint256 public constant MAX_ITERATIONS = 10;
    uint256 public constant MAX_UINT256 = 2**256 - 1;
    enum States {CLOSED, OPEN, LOCKED, WITHDRAW}
    States public state;
    uint256 public mode;
    bool public constant isMarket = true;
    uint256 public totalNftMintCount;
    ITreasury public treasury;
    IFactory public factory;
    IRCProxyXdai public proxy;
    IRCNftHubXdai public nfthub;
    mapping (uint256 => uint256) public price;
    mapping (address => uint256) public collectedPerUser;
    mapping (uint256 => uint256) public collectedPerToken;
    uint256 public totalCollected;
    uint256 public minimumPriceIncrease;
    uint256 public minRentalDivisor;
    mapping (address => uint256) public ownershipLostTimestamp;
    mapping (uint256 => mapping(address => Bid)) public orderbook;
    struct Bid{
  		uint256 price;
        uint256 timeHeldLimit;
        address next;
        address prev;
    }
    mapping (uint256 => mapping (address => uint256) ) public timeHeld;
    mapping (uint256 => uint256) public totalTimeHeld;
    mapping (uint256 => uint256) public timeLastCollected;
    mapping (uint256 => uint256) public longestTimeHeld;
    mapping (uint256 => address) public longestOwner;
    uint32 public marketOpeningTime;
    uint32 public marketLockingTime;
    uint32 public oracleResolutionTime;
    uint256 public winningOutcome;
    mapping (address => bool) public userAlreadyWithdrawn;
    address public artistAddress;
    uint256 public artistCut;
    bool public artistPaid = false;
    address public affiliateAddress;
    uint256 public affiliateCut;
    bool public affiliatePaid = false;
    uint256 public winnerCut;
    address public marketCreatorAddress;
    uint256 public creatorCut;
    bool public creatorPaid = false;
    address[] public cardAffiliateAddresses;
    uint256 public cardAffiliateCut;
    bool public cardAffiliatePaid = false;
    event LogNewRental(address indexed newOwner, uint256 indexed newPrice, uint256 timeHeldLimit, uint256 indexed tokenId);
    event LogForeclosure(address indexed prevOwner, uint256 indexed tokenId);
    event LogRentCollection(uint256 indexed rentCollected, uint256 indexed tokenId, address indexed owner);
    event LogCardTransferredToUnderbidder(uint256 indexed tokenId, address indexed previousOwner);
    event LogContractLocked(bool indexed didTheEventFinish);
    event LogWinnerKnown(uint256 indexed winningOutcome);
    event LogWinningsPaid(address indexed paidTo, uint256 indexed amountPaid);
    event LogStakeholderPaid(address indexed paidTo, uint256 indexed amountPaid);
    event LogRentReturned(address indexed returnedTo, uint256 indexed amountReturned);
    event LogTimeHeldUpdated(uint256 indexed newTimeHeld, address indexed owner, uint256 indexed tokenId);
    event LogStateChange(uint256 indexed newState);
    event LogUpdateTimeHeldLimit(address indexed owner, uint256 newLimit, uint256 tokenId);
    event LogExit(address indexed owner, uint256 tokenId, bool exit);
    event LogSponsor(uint256 indexed amount);
    event LogNftUpgraded(uint256 indexed currentTokenId, uint256 indexed newTokenId);
    event LogPayoutDetails(address indexed artistAddress, address marketCreatorAddress, address affiliateAddress, address[] cardAffiliateAddresses, uint256 indexed artistCut, uint256 winnerCut, uint256 creatorCut, uint256 affiliateCut, uint256 cardAffiliateCut);
    event LogTransferCardToLongestOwner(uint256 tokenId, address longestOwner);
    function initialize(
        uint256 _mode,
        uint32[] memory _timestamps,
        uint256 _numberOfTokens,
        uint256 _totalNftMintCount,
        address _artistAddress,
        address _affiliateAddress,
        address[] memory _cardAffiliateAddresses,
        address _marketCreatorAddress
    ) public initializer {
        assert(_mode <= 2);
        _initializeEIP712("RealityCardsMarket","1");
        factory = IFactory(msg.sender);
        treasury = factory.treasury();
        proxy = factory.proxy();
        nfthub = factory.nfthub();
        winningOutcome = MAX_UINT256;
        mode = _mode;
        numberOfTokens = _numberOfTokens;
        totalNftMintCount = _totalNftMintCount;
        marketOpeningTime = _timestamps[0];
        marketLockingTime = _timestamps[1];
        oracleResolutionTime = _timestamps[2];
        artistAddress = _artistAddress;
        marketCreatorAddress = _marketCreatorAddress;
        affiliateAddress = _affiliateAddress;
        cardAffiliateAddresses = _cardAffiliateAddresses;
        uint256[5] memory _potDistribution = factory.getPotDistribution();
        minimumPriceIncrease = factory.minimumPriceIncrease();
        minRentalDivisor = treasury.minRentalDivisor();
        artistCut = _potDistribution[0];
        winnerCut = _potDistribution[1];
        creatorCut = _potDistribution[2];
        affiliateCut = _potDistribution[3];
        cardAffiliateCut = _potDistribution[4];
        if (_artistAddress == address(0)) {
            artistCut = 0;
        }
        if (_affiliateAddress == address(0)) {
            affiliateCut = 0;
        }
        if (_cardAffiliateAddresses.length == _numberOfTokens) {
            for (uint i = 0; i < _numberOfTokens; i++) {
                if (_cardAffiliateAddresses[i] == address(0)) {
                    cardAffiliateCut = 0;
                }
            }
        } else {
            cardAffiliateCut = 0;
        }
        if (_mode == 1) {
            winnerCut = (((uint256(1000).sub(artistCut)).sub(creatorCut)).sub(affiliateCut)).sub(cardAffiliateCut);
        }
        if (marketOpeningTime <= now) {
            _incrementState();
        }
        emit LogPayoutDetails(_artistAddress, _marketCreatorAddress, _affiliateAddress, cardAffiliateAddresses, artistCut, winnerCut, creatorCut, affiliateCut, cardAffiliateCut);
    }
    modifier checkState(States currentState) {
        require(state == currentState, "Incorrect state");
        _;
    }
    modifier autoUnlock() {
        if (marketOpeningTime <= now && state == States.CLOSED) {
            _incrementState();
        }
        _;
    }
    modifier autoLock() {
        _;
        if (marketLockingTime <= now) {
            lockMarket();
        }
    }
    modifier amountNotZero(uint256 _dai) {
        require(_dai > 0, "Amount must be above zero");
       _;
    }
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(msgSender() == ownerOf(_tokenId), "Not owner");
       _;
    }
    function upgradeCard(uint256 _tokenId) external checkState(States.WITHDRAW) onlyTokenOwner(_tokenId) {
        require(!factory.trapIfUnapproved() || factory.isMarketApproved(address(this)), "Upgrade blocked");
        string memory _tokenUri = tokenURI(_tokenId);
        address _owner = ownerOf(_tokenId);
        uint256 _actualTokenId = _tokenId.add(totalNftMintCount);
        proxy.saveCardToUpgrade(_actualTokenId, _tokenUri, _owner);
        _transferCard(ownerOf(_tokenId), address(this), _tokenId);
        emit LogNftUpgraded(_tokenId, _actualTokenId);
    }
    function _getWinner() internal view returns(uint256) {
        uint256 _winningOutcome = proxy.getWinner(address(this));
        return _winningOutcome;
    }
    function _isQuestionFinalized() internal view returns (bool) {
        return proxy.isFinalized(address(this));
    }
    function ownerOf(uint256 _tokenId) public view returns(address) {
        uint256 _actualTokenId = _tokenId.add(totalNftMintCount);
        return nfthub.ownerOf(_actualTokenId);
    }
    function tokenURI(uint256 _tokenId) public view returns(string memory) {
        uint256 _actualTokenId = _tokenId.add(totalNftMintCount);
        return nfthub.tokenURI(_actualTokenId);
    }
    function _transferCard(address _from, address _to, uint256 _tokenId) internal {
        require(_from != address(0) && _to != address(0) , "Cannot send to/from zero address");
        uint256 _actualTokenId = _tokenId.add(totalNftMintCount);
        assert(nfthub.transferNft(_from, _to, _actualTokenId));
    }
    function lockMarket() public checkState(States.OPEN) {
        require(marketLockingTime < now, "Market has not finished");
        collectRentAllCards();
        _incrementState();
        emit LogContractLocked(true);
    }
    function determineWinner() external checkState(States.LOCKED) {
        require(_isQuestionFinalized(), "Oracle not resolved");
        winningOutcome = _getWinner();
        _incrementState();
        _processCardsAfterEvent();
        emit LogWinnerKnown(winningOutcome);
    }
    function withdraw() external checkState(States.WITHDRAW) {
        require(!userAlreadyWithdrawn[msgSender()], "Already withdrawn");
        userAlreadyWithdrawn[msgSender()] = true;
        if (totalTimeHeld[winningOutcome] > 0) {
            _payoutWinnings();
        } else {
             _returnRent();
        }
    }
    function _payoutWinnings() internal {
        uint256 _winningsToTransfer;
        uint256 _remainingCut = ((((uint256(1000).sub(artistCut)).sub(affiliateCut))).sub(cardAffiliateCut).sub(winnerCut)).sub(creatorCut);
        if (longestOwner[winningOutcome] == msgSender() && winnerCut > 0){
            _winningsToTransfer = (totalCollected.mul(winnerCut)).div(1000);
        }
        uint256 _remainingPot = (totalCollected.mul(_remainingCut)).div(1000);
        uint256 _winnersTimeHeld = timeHeld[winningOutcome][msgSender()];
        uint256 _numerator = _remainingPot.mul(_winnersTimeHeld);
        _winningsToTransfer = _winningsToTransfer.add(_numerator.div(totalTimeHeld[winningOutcome]));
        require(_winningsToTransfer > 0, "Not a winner");
        _payout(msgSender(), _winningsToTransfer);
        emit LogWinningsPaid(msgSender(), _winningsToTransfer);
    }
    function _returnRent() internal {
        uint256 _remainingCut = ((uint256(1000).sub(artistCut)).sub(affiliateCut)).sub(cardAffiliateCut);
        uint256 _rentCollected = collectedPerUser[msgSender()];
        require(_rentCollected > 0, "Paid no rent");
        uint256 _rentCollectedAdjusted = (_rentCollected.mul(_remainingCut)).div(1000);
        _payout(msgSender(), _rentCollectedAdjusted);
        emit LogRentReturned(msgSender(), _rentCollectedAdjusted);
    }
    function _payout(address _recipient, uint256 _amount) internal {
        assert(treasury.payout(_recipient, _amount));
    }
    function _processCardsAfterEvent() internal {
        for (uint i = 0; i < numberOfTokens; i++) {
            if (longestOwner[i] != address(0)) {
                _transferCard(ownerOf(i), longestOwner[i], i);
                emit LogTransferCardToLongestOwner(i, longestOwner[i]);
            }
        }
    }
    function payArtist() external checkState(States.WITHDRAW) {
        require(!artistPaid, "Artist already paid");
        artistPaid = true;
        _processStakeholderPayment(artistCut, artistAddress);
    }
    function payMarketCreator() external checkState(States.WITHDRAW) {
        require(totalTimeHeld[winningOutcome] > 0, "No winner");
        require(!creatorPaid, "Creator already paid");
        creatorPaid = true;
        _processStakeholderPayment(creatorCut, marketCreatorAddress);
    }
    function payAffiliate() external checkState(States.WITHDRAW) {
        require(!affiliatePaid, "Affiliate already paid");
        affiliatePaid = true;
        _processStakeholderPayment(affiliateCut, affiliateAddress);
    }
    function _processStakeholderPayment(uint256 _cut, address _recipient) internal {
        if (_cut > 0) {
            uint256 _payment = (totalCollected.mul(_cut)).div(1000);
            _payout(_recipient, _payment);
            emit LogStakeholderPaid(_recipient, _payment);
        }
    }
    function payCardAffiliate() external checkState(States.WITHDRAW) {
        require(!cardAffiliatePaid, "Card recipients already paid");
        cardAffiliatePaid = true;
        if (cardAffiliateCut > 0) {
            for (uint i = 0; i < numberOfTokens; i++) {
                uint256 _cardAffiliatePayment = (collectedPerToken[i].mul(cardAffiliateCut)).div(1000);
                if (_cardAffiliatePayment > 0) {
                    _payout(cardAffiliateAddresses[i], _cardAffiliatePayment);
                }
                emit LogStakeholderPaid(cardAffiliateAddresses[i], _cardAffiliatePayment);
            }
        }
    }
    function collectRentAllCards() public checkState(States.OPEN) {
       for (uint i = 0; i < numberOfTokens; i++) {
            _collectRent(i);
        }
    }
    function rentAllCards(uint256 _maxSumOfPrices) external {
        uint256 _actualSumOfPrices;
        for (uint i = 0; i < numberOfTokens; i++) {
            _actualSumOfPrices = _actualSumOfPrices.add(price[i]);
        }
        require(_actualSumOfPrices <= _maxSumOfPrices, "Prices too high");
        for (uint i = 0; i < numberOfTokens; i++) {
            if (ownerOf(i) != msgSender()) {
                uint _newPrice;
                if (price[i]>0) {
                    _newPrice = (price[i].mul(minimumPriceIncrease.add(100))).div(100);
                } else {
                    _newPrice = 1 ether;
                }
                newRental(_newPrice, 0, address(0), i);
            }
        }
    }
    function newRental(uint256 _newPrice, uint256 _timeHeldLimit, address _startingPosition, uint256 _tokenId) public payable autoUnlock() autoLock() checkState(States.OPEN) {
        require(_newPrice >= 1 ether, "Minimum rental 1 Dai");
        require(_tokenId < numberOfTokens, "This token does not exist");
        require(ownershipLostTimestamp[msgSender()] != now, "Cannot lose and re-rent in same block");
        _newPrice = _newPrice.mul(2);
        collectRentAllCards();
        if (msg.value > 0) {
            assert(treasury.deposit.value(msg.value)(msgSender()));
        }
        uint256 _minRentalTime = uint256(1 days).div(minRentalDivisor);
        require(treasury.deposits(msgSender()) >= _newPrice.div(_minRentalTime), "Insufficient deposit");
        if (_timeHeldLimit == 0) {
            _timeHeldLimit = MAX_UINT256;
        }
        require(_timeHeldLimit >= timeHeld[_tokenId][msgSender()].add(_minRentalTime), "Limit too low");
        if (orderbook[_tokenId][msgSender()].price == 0) {
            _newBid(_newPrice, _tokenId, _timeHeldLimit, _startingPosition);
        } else {
            _updateBid(_newPrice, _tokenId, _timeHeldLimit, _startingPosition);
        }
        emit LogNewRental(msgSender(), _newPrice, _timeHeldLimit, _tokenId);
    }
    function updateTimeHeldLimit(uint256 _timeHeldLimit, uint256 _tokenId) external checkState(States.OPEN) {
        collectRentAllCards();
        if (_timeHeldLimit == 0) {
            _timeHeldLimit = MAX_UINT256;
        }
        uint256 _minRentalTime = uint256(1 days).div(minRentalDivisor);
        require(_timeHeldLimit >= timeHeld[_tokenId][msgSender()].add(_minRentalTime), "Limit too low");
        orderbook[_tokenId][msgSender()].timeHeldLimit = _timeHeldLimit;
        emit LogUpdateTimeHeldLimit(msgSender(), _timeHeldLimit, _tokenId);
    }
    function exit(uint256 _tokenId) public checkState(States.OPEN) {
        if (ownerOf(_tokenId) == msgSender()) {
            _collectRent(_tokenId);
            if (ownerOf(_tokenId) == msgSender()) {
                _revertToUnderbidder(_tokenId);
            } else {
                assert(orderbook[_tokenId][msgSender()].price == 0);
            }
        } else {
            orderbook[_tokenId][orderbook[_tokenId][msgSender()].next].prev = orderbook[_tokenId][msgSender()].prev;
            orderbook[_tokenId][orderbook[_tokenId][msgSender()].prev].next = orderbook[_tokenId][msgSender()].next;
            delete orderbook[_tokenId][msgSender()];
        }
        emit LogExit(msgSender(), _tokenId, true);
    }
    function exitAll() external {
        for (uint i = 0; i < numberOfTokens; i++) {
            exit(i);
        }
    }
    function sponsor() external payable {
        require(msg.value > 0, "Must send something");
        require(state != States.LOCKED, "Incorrect state");
        require(state != States.WITHDRAW, "Incorrect state");
        assert(treasury.sponsor.value(msg.value)());
        totalCollected = totalCollected.add(msg.value);
        collectedPerUser[msgSender()] = collectedPerUser[msgSender()].add(msg.value);
        for (uint i = 0; i < numberOfTokens; i++) {
            collectedPerToken[i] =  collectedPerToken[i].add(msg.value.div(numberOfTokens));
        }
        emit LogSponsor(msg.value);
    }
    function _collectRent(uint256 _tokenId) internal {
        uint256 _timeOfThisCollection = now;
        if (ownerOf(_tokenId) != address(this)) {
            uint256 _rentOwed = price[_tokenId].mul(now.sub(timeLastCollected[_tokenId])).div(1 days);
            address _collectRentFrom = ownerOf(_tokenId);
            uint256 _deposit = treasury.deposits(_collectRentFrom);
            uint256 _rentOwedLimit;
            uint256 _timeHeldLimit = orderbook[_tokenId][_collectRentFrom].timeHeldLimit;
            if (_timeHeldLimit == MAX_UINT256) {
                _rentOwedLimit = MAX_UINT256;
            } else {
                _rentOwedLimit = price[_tokenId].mul(_timeHeldLimit.sub(timeHeld[_tokenId][_collectRentFrom])).div(1 days);
            }
            if (_rentOwed >= _deposit || _rentOwed >= _rentOwedLimit)  {
                if (_deposit <= _rentOwedLimit)
                {
                    _timeOfThisCollection = timeLastCollected[_tokenId].add(((now.sub(timeLastCollected[_tokenId])).mul(_deposit).div(_rentOwed)));
                    _rentOwed = _deposit;
                } else {
                    _timeOfThisCollection = timeLastCollected[_tokenId].add(((now.sub(timeLastCollected[_tokenId])).mul(_rentOwedLimit).div(_rentOwed)));
                    _rentOwed = _rentOwedLimit;
                }
                _revertToUnderbidder(_tokenId);
            }
            if (_rentOwed > 0) {
                assert(treasury.payRent(_collectRentFrom, _rentOwed));
                uint256 _timeHeldToIncrement = (_timeOfThisCollection.sub(timeLastCollected[_tokenId]));
                timeHeld[_tokenId][_collectRentFrom] = timeHeld[_tokenId][_collectRentFrom].add(_timeHeldToIncrement);
                totalTimeHeld[_tokenId] = totalTimeHeld[_tokenId].add(_timeHeldToIncrement);
                collectedPerUser[_collectRentFrom] = collectedPerUser[_collectRentFrom].add(_rentOwed);
                collectedPerToken[_tokenId] = collectedPerToken[_tokenId].add(_rentOwed);
                totalCollected = totalCollected.add(_rentOwed);
                if (timeHeld[_tokenId][_collectRentFrom] > longestTimeHeld[_tokenId]) {
                    longestTimeHeld[_tokenId] = timeHeld[_tokenId][_collectRentFrom];
                    longestOwner[_tokenId] = _collectRentFrom;
                }
                emit LogTimeHeldUpdated(timeHeld[_tokenId][_collectRentFrom], _collectRentFrom, _tokenId);
                emit LogRentCollection(_rentOwed, _tokenId, _collectRentFrom);
            }
        }
        timeLastCollected[_tokenId] = _timeOfThisCollection;
    }
    function _newBid(uint256 _newPrice, uint256 _tokenId, uint256 _timeHeldLimit, address _startingPosition) internal
    {
        assert(orderbook[_tokenId][msgSender()].price == 0);
        uint256 _minPriceToOwn = (price[_tokenId].mul(minimumPriceIncrease.add(100))).div(100);
        if(ownerOf(_tokenId) == address(this) || _newPrice >= _minPriceToOwn) {
            _setNewOwner(_newPrice, _tokenId, _timeHeldLimit);
        } else {
            _placeInList(_newPrice, _tokenId, _timeHeldLimit, _startingPosition);
        }
    }
    function _updateBid(uint256 _newPrice, uint256 _tokenId, uint256 _timeHeldLimit, address _startingPosition) internal
    {
        uint256 _minPriceToOwn;
        assert(orderbook[_tokenId][msgSender()].price > 0);
        if(msgSender() == ownerOf(_tokenId)) {
            _minPriceToOwn = (price[_tokenId].mul(minimumPriceIncrease.add(100))).div(100);
            if(_newPrice >= _minPriceToOwn) {
                orderbook[_tokenId][msgSender()].price = _newPrice;
                orderbook[_tokenId][msgSender()].timeHeldLimit = _timeHeldLimit;
                price[_tokenId] = _newPrice;
            } else if (_newPrice > price[_tokenId]) {
                _revertToUnderbidder(_tokenId);
            } else {
                _minPriceToOwn = (orderbook[_tokenId][orderbook[_tokenId][msgSender()].next].price.mul(minimumPriceIncrease.add(100))).div(100);
                if(_newPrice >= _minPriceToOwn) {
                    orderbook[_tokenId][msgSender()].price = _newPrice;
                    orderbook[_tokenId][msgSender()].timeHeldLimit = _timeHeldLimit;
                    price[_tokenId] = _newPrice;
                } else {
                    _revertToUnderbidder(_tokenId);
                    _newBid(_newPrice, _tokenId, _timeHeldLimit, _startingPosition);
                }
            }
        } else {
            orderbook[_tokenId][orderbook[_tokenId][msgSender()].prev].next = orderbook[_tokenId][msgSender()].next;
            orderbook[_tokenId][orderbook[_tokenId][msgSender()].next].prev = orderbook[_tokenId][msgSender()].prev;
            delete orderbook[_tokenId][msgSender()];
            _minPriceToOwn = (price[_tokenId].mul(minimumPriceIncrease.add(100))).div(100);
            if(_newPrice >= _minPriceToOwn)
            {
                _setNewOwner(_newPrice, _tokenId, _timeHeldLimit);
            } else {
                _placeInList(_newPrice, _tokenId, _timeHeldLimit, _startingPosition);
            }
        }
    }
    function _setNewOwner(uint256 _newPrice, uint256 _tokenId, uint256 _timeHeldLimit) internal
    {
        if (mode == 2) {
        }
        orderbook[_tokenId][msgSender()] = Bid(_newPrice, _timeHeldLimit, ownerOf(_tokenId), address(this));
        orderbook[_tokenId][ownerOf(_tokenId)].prev = msgSender();
        price[_tokenId] = _newPrice;
        _transferCard(ownerOf(_tokenId), msgSender(), _tokenId);
    }
    function _placeInList(uint256 _newPrice, uint256 _tokenId, uint256 _timeHeldLimit, address _startingPosition) internal
    {
        if (_startingPosition == address(0)) {
            _startingPosition = ownerOf(_tokenId);
            if (orderbook[_tokenId][_startingPosition].price <_newPrice) {
                _newPrice = orderbook[_tokenId][_startingPosition].price;
            }
        }
        require(orderbook[_tokenId][_startingPosition].price >= _newPrice, "Invalid starting location");
        address _tempNext = _startingPosition;
        address _tempPrev;
        uint256 _loopCount;
        uint256 _requiredPrice;
        do {
            _tempPrev = _tempNext;
            _tempNext = orderbook[_tokenId][_tempPrev].next;
            _requiredPrice = (orderbook[_tokenId][_tempNext].price.mul(minimumPriceIncrease.add(100))).div(100);
            _loopCount = _loopCount.add(1);
        } while (
            _newPrice < _requiredPrice &&
            _loopCount < MAX_ITERATIONS );
        require(_loopCount < MAX_ITERATIONS, "Incorrect starting location");
        if (orderbook[_tokenId][_tempPrev].price < _newPrice) {
            _newPrice = orderbook[_tokenId][_tempPrev].price;
        }
        orderbook[_tokenId][msgSender()] = Bid(_newPrice, _timeHeldLimit, _tempNext, _tempPrev);
        orderbook[_tokenId][_tempPrev].next = msgSender();
        orderbook[_tokenId][_tempNext].prev = msgSender();
    }
    function _revertToUnderbidder(uint256 _tokenId) internal {
        address _tempNext = ownerOf(_tokenId);
        address _tempPrev;
        uint256 _tempNextDeposit;
        uint256 _requiredDeposit;
        uint256 _loopCount;
        do {
            _tempPrev = _tempNext;
            _tempNext = orderbook[_tokenId][_tempPrev].next;
            orderbook[_tokenId][_tempNext].prev = address(this);
            delete orderbook[_tokenId][_tempPrev];
            _tempNextDeposit = treasury.deposits(_tempNext);
            _requiredDeposit = orderbook[_tokenId][_tempNext].price.div(minRentalDivisor);
            _loopCount = _loopCount.add(1);
        } while (
            _tempNext != address(this) &&
            _tempNextDeposit < _requiredDeposit &&
            _loopCount < MAX_ITERATIONS );
        if (_tempNext == address(this)) {
            _foreclose(_tokenId);
        } else {
            address _currentOwner = ownerOf(_tokenId);
            price[_tokenId] = orderbook[_tokenId][_tempNext].price;
            ownershipLostTimestamp[ownerOf(_tokenId)] = now;
            _transferCard(_currentOwner, _tempNext, _tokenId);
            emit LogCardTransferredToUnderbidder(_tokenId, _tempNext);
        }
    }
    function _foreclose(uint256 _tokenId) internal {
        address _currentOwner = ownerOf(_tokenId);
        price[_tokenId] = 0;
        _transferCard(_currentOwner, address(this), _tokenId);
        emit LogForeclosure(_currentOwner, _tokenId);
    }
    function _incrementState() internal {
        assert(uint256(state) < 4);
        state = States(uint256(state) + 1);
        emit LogStateChange(uint256(state));
    }
    function circuitBreaker() external {
        require(now > (oracleResolutionTime + 12 weeks), "Too early");
        _incrementState();
        _processCardsAfterEvent();
        state = States.WITHDRAW;
    }
}