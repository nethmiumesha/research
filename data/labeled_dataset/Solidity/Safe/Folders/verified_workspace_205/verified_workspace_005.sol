pragma solidity 0.5.13;
import '../../interfaces/IRCProxyMainnet.sol';
import '../../interfaces/IBridge.sol';
import '../../interfaces/ITreasury.sol';
import '../../interfaces/IRCMarket.sol';
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
contract RCProxyXdaiV2 is Ownable
{
    using SafeMath for uint256;
    IBridge public bridge;
    address public proxyMainnetAddress;
    address public factoryAddress;
    address public treasuryAddress;
    mapping (address => question) public questions;
    struct question {
        string question;
        uint32 oracleResolutionTime;
        bool set; }
    mapping (address => bool) public isMarket;
    mapping(uint256 => nft) public upgradedNfts;
    struct nft {
        string tokenURI;
        address owner;
        bool set; }
    uint256 public validatorCount;
    mapping (address => bool) public isValidator;
    mapping (uint256 => Deposit) public deposits;
    mapping (uint256 => mapping(address => bool)) public hasConfirmedDeposit;
    uint256 public floatSize;
    struct Deposit {
        address user;
        uint256 amount;
        uint256 confirmations;
        bool confirmed;
        bool executed; }
    event LogFloatIncreased(address indexed funder, uint256 amount);
    event LogFloatWithdrawn(address indexed recipient, uint256 amount);
    event LogDepositConfirmed(uint256 indexed nonce);
    event LogDepositExecuted(uint256 indexed nonce);
    constructor(address _bridgeXdaiAddress, address _factoryAddress, address _treasuryAddress) public {
        setBridgeXdaiAddress(_bridgeXdaiAddress);
        setFactoryAddress(_factoryAddress);
        setTreasuryAddress(_treasuryAddress);
    }
    function addMarket(address _newMarket) external returns(bool) {
        require(msg.sender == factoryAddress, "Not factory");
        isMarket[_newMarket] = true;
        return true;
    }
    function setProxyMainnetAddress(address _newAddress) onlyOwner external {
        proxyMainnetAddress = _newAddress;
    }
    function setBridgeXdaiAddress(address _newAddress) onlyOwner public {
        bridge = IBridge(_newAddress);
    }
    function setFactoryAddress(address _newAddress) onlyOwner public {
        factoryAddress = _newAddress;
    }
    function setTreasuryAddress(address _newAddress) onlyOwner public {
        treasuryAddress = _newAddress;
    }
    function setAmicableResolution(address _marketAddress, uint256 _winningOutcome) onlyOwner public {
        IRCMarket market = IRCMarket(_marketAddress);
        market.setWinner(_winningOutcome);
    }
    function withdrawFloat(uint256 _amount) onlyOwner external {
        floatSize = floatSize.sub(_amount);
        address _thisAddressNotPayable = owner();
        address payable _recipient = address(uint160(_thisAddressNotPayable));
        (bool _success, ) = _recipient.call.value(_amount)("");
        require(_success, "Transfer failed");
        emit LogFloatWithdrawn(msg.sender, _amount);
    }
    function setValidator(address _validatorAddress, bool _add) onlyOwner external {
        if(_add) {
            if(!isValidator[_validatorAddress]) {
                isValidator[_validatorAddress] = true;
                validatorCount = validatorCount.add(1);
            }
        } else {
            if(isValidator[_validatorAddress]) {
                isValidator[_validatorAddress] = false;
                validatorCount = validatorCount.sub(1);
            }
        }
    }
    function saveQuestion(address _marketAddress, string calldata _question, uint32 _oracleResolutionTime) external {
        require(msg.sender == factoryAddress, "Not factory");
        questions[_marketAddress].question = _question;
        questions[_marketAddress].oracleResolutionTime = _oracleResolutionTime;
        questions[_marketAddress].set = true;
        postQuestionToBridge(_marketAddress);
    }
    function postQuestionToBridge(address _marketAddress) public {
        require(questions[_marketAddress].set, "No question");
        bytes4 _methodSelector = IRCProxyMainnet(address(0)).postQuestionToOracle.selector;
        bytes memory data = abi.encodeWithSelector(_methodSelector, _marketAddress, questions[_marketAddress].question, questions[_marketAddress].oracleResolutionTime);
        bridge.requireToPassMessage(proxyMainnetAddress,data,200000);
    }
    function setWinner(address _marketAddress, uint256 _winningOutcome) external {
        require(msg.sender == address(bridge), "Not bridge");
        require(bridge.messageSender() == proxyMainnetAddress, "Not proxy");
        IRCMarket market = IRCMarket(_marketAddress);
        market.setWinner(_winningOutcome.mul(2));
    }
    function saveCardToUpgrade(uint256 _tokenId, string calldata _tokenUri, address _owner) external {
        require(isMarket[msg.sender], "Not market");
        assert(!upgradedNfts[_tokenId].set);
        upgradedNfts[_tokenId].tokenURI = _tokenUri;
        upgradedNfts[_tokenId].owner = _owner;
        upgradedNfts[_tokenId].set = true;
        postCardToUpgrade(_tokenId);
    }
    function postCardToUpgrade(uint256 _tokenId) public {
        require(upgradedNfts[_tokenId].set, "Nft not set");
        bytes4 _methodSelector = IRCProxyMainnet(address(0)).upgradeCard.selector;
        bytes memory data = abi.encodeWithSelector(_methodSelector, _tokenId, upgradedNfts[_tokenId].tokenURI, upgradedNfts[_tokenId].owner);
        bridge.requireToPassMessage(proxyMainnetAddress,data,200000);
    }
    function() external payable {
        floatSize = floatSize.add(msg.value);
        emit LogFloatIncreased(msg.sender, msg.value);
    }
    function confirmDaiDeposit(address _user, uint256 _amount, uint256 _nonce) external {
        require(isValidator[msg.sender], "Not a validator");
        if(deposits[_nonce].user == address(0)) {
            Deposit memory newDeposit = Deposit(_user, _amount, 0, false, false);
            deposits[_nonce] = newDeposit;
        }
        require(deposits[_nonce].user == _user, "Addresses don't match");
        require(deposits[_nonce].amount == _amount, "Amounts don't match");
        if(!hasConfirmedDeposit[_nonce][msg.sender]) {
            hasConfirmedDeposit[_nonce][msg.sender] = true;
            deposits[_nonce].confirmations = deposits[_nonce].confirmations.add(1);
        }
        if(!deposits[_nonce].confirmed && deposits[_nonce].confirmations >= (validatorCount.div(2)).add(1)) {
            deposits[_nonce].confirmed = true;
            executeDaiDeposit(_nonce);
            emit LogDepositConfirmed(_nonce);
        }
    }
    function executeDaiDeposit(uint256 _nonce) public {
        require(deposits[_nonce].confirmed, "Not confirmed");
        require(!deposits[_nonce].executed, "Already executed");
        uint256 _amount = deposits[_nonce].amount;
        address _user = deposits[_nonce].user;
        if (address(this).balance >= _amount) {
            ITreasury treasury = ITreasury(treasuryAddress);
            assert(treasury.deposit.value(_amount)(_user));
            deposits[_nonce].executed = true;
            emit LogDepositExecuted(_nonce);
        }
    }
}