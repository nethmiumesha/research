pragma solidity ^0.4.11;
import "./Owned.sol";
import "./MiniMeToken.sol";
import "./SafeMath.sol";
import "./ERC20Token.sol";
contract REALCrowdsale is Owned, TokenController {
    using SafeMath for uint256;
    uint256 constant public fundingLimit = 100000 ether;
    uint256 constant public failSafeLimit = 200000 ether;
    uint256 constant public maxGuaranteedLimit = 30000 ether;
    uint256 constant public exchangeRate = 220;
    uint256 constant public maxGasPrice = 50000000000;
    uint256 constant public maxCallFrequency = 100;
    uint256 constant public bonus1cap = 25000 ether;
    uint256 constant public bonus1 = 25;
    uint256 constant public bonus2cap = 50000 ether;
    uint256 constant public bonus2 = 20;
    uint256 constant public bonus3cap = 100000 ether;
    uint256 constant public bonus3 = 15;
    uint256 constant public bonus4cap = 150000 ether;
    uint256 constant public bonus4 = 5;
    MiniMeToken public REAL;
    uint256 public startBlock;
    uint256 public endBlock;
    address public destEthTeam;
    address public destTokensTeam;
    address public destTokensReserve;
    address public destTokensBounties;
    address public realController;
    mapping (address => uint256) public guaranteedBuyersLimit;
    mapping (address => uint256) public guaranteedBuyersBought;
    uint256 public totalGuaranteedCollected;
    uint256 public totalNormalCollected;
    uint256 public reservedGuaranteed;
    uint256 public finalizedBlock;
    uint256 public finalizedTime;
    mapping (address => uint256) public lastCallBlock;
    bool public paused;
    modifier initialized() {
        require(address(REAL) != 0x0);
        _;
    }
    modifier contributionOpen() {
        require(getBlockNumber() >= startBlock &&
                getBlockNumber() <= endBlock &&
                finalizedBlock == 0 &&
                address(REAL) != 0x0);
        _;
    }
    modifier notPaused() {
        require(!paused);
        _;
    }
    function REALCrowdsale() {
        paused = false;
    }
    function initialize(
        address _real,
        address _realController,
        uint256 _startBlock,
        uint256 _endBlock,
        address _destEthTeam,
        address _destTokensReserve,
        address _destTokensTeam,
        address _destTokensBounties
    ) public onlyOwner {
        require(address(REAL) == 0x0);
        REAL = MiniMeToken(_real);
        require(REAL.totalSupply() == 0);
        require(REAL.controller() == address(this));
        require(REAL.decimals() == 18);
        require(_realController != 0x0);
        realController = _realController;
        require(_startBlock >= getBlockNumber());
        require(_startBlock < _endBlock);
        startBlock = _startBlock;
        endBlock = _endBlock;
        require(_destEthTeam != 0x0);
        destEthTeam = _destEthTeam;
        require(_destTokensReserve != 0x0);
        destTokensReserve = _destTokensReserve;
        require(_destTokensTeam != 0x0);
        destTokensTeam = _destTokensTeam;
        require(_destTokensBounties != 0x0);
        destTokensBounties = _destTokensBounties;
    }
    function setGuaranteedAddress(address _th, uint256 _limit) public initialized onlyOwner {
        require(getBlockNumber() < startBlock);
        require(_limit > 0 && _limit <= maxGuaranteedLimit);
        guaranteedBuyersLimit[_th] = _limit;
        reservedGuaranteed = reservedGuaranteed + _limit;
        GuaranteedAddress(_th, _limit);
    }
    function () public payable notPaused {
        proxyPayment(msg.sender);
    }
    function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
        require(_th != 0x0);
        uint256 guaranteedRemaining = guaranteedBuyersLimit[_th].sub(guaranteedBuyersBought[_th]);
        if (guaranteedRemaining > 0) {
            buyGuaranteed(_th);
        } else {
            buyNormal(_th);
        }
        return true;
    }
    function onTransfer(address, address, uint256) public returns (bool) {
        return false;
    }
    function onApprove(address, address, uint256) public returns (bool) {
        return false;
    }
    function buyNormal(address _th) internal {
        require(tx.gasprice <= maxGasPrice);
        address caller;
        if (msg.sender == address(REAL)) {
            caller = _th;
        } else {
            caller = msg.sender;
        }
        require(!isContract(caller));
        require(getBlockNumber().sub(lastCallBlock[caller]) >= maxCallFrequency);
        lastCallBlock[caller] = getBlockNumber();
        uint256 toCollect = failSafeLimit - totalNormalCollected;
        uint256 toFund;
        if (msg.value <= toCollect) {
            toFund = msg.value;
        } else {
            toFund = toCollect;
        }
        totalNormalCollected = totalNormalCollected.add(toFund);
        doBuy(_th, toFund, false);
    }
    function buyGuaranteed(address _th) internal {
        uint256 toCollect = guaranteedBuyersLimit[_th];
        uint256 toFund;
        if (guaranteedBuyersBought[_th].add(msg.value) > toCollect) {
            toFund = toCollect.sub(guaranteedBuyersBought[_th]);
        } else {
            toFund = msg.value;
        }
        guaranteedBuyersBought[_th] = guaranteedBuyersBought[_th].add(toFund);
        totalGuaranteedCollected = totalGuaranteedCollected.add(toFund);
        doBuy(_th, toFund, true);
    }
    function doBuy(address _th, uint256 _toFund, bool _guaranteed) internal {
        assert(msg.value >= _toFund);
        assert(totalCollected() <= failSafeLimit);
        uint256 collected = totalCollected();
        uint256 totCollected = collected;
        collected = collected.sub(_toFund);
        if (_toFund > 0) {
            uint256 tokensGenerated = _toFund.mul(exchangeRate);
            uint256 tokensToBonusCap = 0;
            uint256 tokensToNextBonusCap = 0;
            uint256 bonusTokens = 0;
            if(_guaranteed) {
              uint256 guaranteedCollected = totalGuaranteedCollected - _toFund;
              if (guaranteedCollected < bonus1cap) {
                if (totalGuaranteedCollected < bonus1cap) {
                  tokensGenerated = tokensGenerated.add(tokensGenerated.percent(bonus1));
                } else {
                  bonusTokens = bonus1cap.sub(guaranteedCollected).percent(bonus1).mul(exchangeRate);
                  tokensToBonusCap = tokensGenerated.add(bonusTokens);
                  tokensToNextBonusCap = totalGuaranteedCollected.sub(bonus1cap).percent(bonus2).mul(exchangeRate);
                  tokensGenerated = tokensToBonusCap.add(tokensToNextBonusCap);
                }
              } else {
                if (totalGuaranteedCollected < bonus2cap) {
                  tokensGenerated = tokensGenerated.add(tokensGenerated.percent(bonus2));
                } else {
                  bonusTokens = bonus2cap.sub(guaranteedCollected).percent(bonus2).mul(exchangeRate);
                  tokensToBonusCap = tokensGenerated.add(bonusTokens);
                  tokensToNextBonusCap = totalGuaranteedCollected.sub(bonus2cap).percent(bonus3).mul(exchangeRate);
                  tokensGenerated = tokensToBonusCap.add(tokensToNextBonusCap);
                }
              }
            } else if (collected < bonus1cap) {
              if (collected.add(_toFund) < bonus1cap) {
                tokensGenerated = tokensGenerated.add(tokensGenerated.percent(bonus1));
              } else {
                bonusTokens = bonus1cap.sub(collected).percent(bonus1).mul(exchangeRate);
                tokensToBonusCap = tokensGenerated.add(bonusTokens);
                tokensToNextBonusCap = totCollected.sub(bonus1cap).percent(bonus2).mul(exchangeRate);
                tokensGenerated = tokensToBonusCap.add(tokensToNextBonusCap);
              }
            } else if (collected < bonus2cap) {
              if (collected.add(_toFund) < bonus2cap) {
                tokensGenerated = tokensGenerated.add(tokensGenerated.percent(bonus2));
              } else {
                bonusTokens = bonus2cap.sub(collected).percent(bonus2).mul(exchangeRate);
                tokensToBonusCap = tokensGenerated.add(bonusTokens);
                tokensToNextBonusCap = totCollected.sub(bonus2cap).percent(bonus3).mul(exchangeRate);
                tokensGenerated = tokensToBonusCap.add(tokensToNextBonusCap);
              }
            } else if (collected < bonus3cap) {
              if (collected.add(_toFund) < bonus3cap) {
                tokensGenerated = tokensGenerated.add(tokensGenerated.percent(bonus3));
              } else {
                bonusTokens = bonus3cap.sub(collected).percent(bonus3).mul(exchangeRate);
                tokensToBonusCap = tokensGenerated.add(bonusTokens);
                tokensToNextBonusCap = totCollected.sub(bonus3cap).percent(bonus4).mul(exchangeRate);
                tokensGenerated = tokensToBonusCap.add(tokensToNextBonusCap);
              }
            } else if (collected < bonus4cap) {
              if (collected.add(_toFund) < bonus4cap) {
                tokensGenerated = tokensGenerated.add(tokensGenerated.percent(bonus4));
              } else {
                bonusTokens = bonus4cap.sub(collected).percent(bonus4).mul(exchangeRate);
                tokensGenerated = tokensGenerated.add(bonusTokens);
              }
            }
            assert(REAL.generateTokens(_th, tokensGenerated));
            destEthTeam.transfer(_toFund);
            NewSale(_th, _toFund, tokensGenerated, _guaranteed);
        }
        uint256 toReturn = msg.value.sub(_toFund);
        if (toReturn > 0) {
            if (msg.sender == address(REAL)) {
                _th.transfer(toReturn);
            } else {
                msg.sender.transfer(toReturn);
            }
        }
    }
    function finalize() public initialized {
        require(getBlockNumber() >= startBlock);
        require(msg.sender == owner || getBlockNumber() > endBlock);
        require(finalizedBlock == 0);
        if (getBlockNumber() <= endBlock) {
            require(totalNormalCollected >= fundingLimit);
        }
        finalizedBlock = getBlockNumber();
        finalizedTime = now;
        uint256 percentageToTeam = percent(20);
        uint256 percentageToContributors = percent(51);
        uint256 percentageToReserve = percent(15);
        uint256 percentageToBounties = percent(14);
        uint256 totalTokens = REAL.totalSupply().mul(percent(100)).div(percentageToContributors);
        assert(REAL.generateTokens(
            destTokensBounties,
            totalTokens.mul(percentageToBounties).div(percent(100))));
        assert(REAL.generateTokens(
            destTokensReserve,
            totalTokens.mul(percentageToReserve).div(percent(100))));
        assert(REAL.generateTokens(
            destTokensTeam,
            totalTokens.mul(percentageToTeam).div(percent(100))));
        REAL.changeController(realController);
        Finalized();
    }
    function percent(uint256 p) internal returns (uint256) {
        return p.mul(10**16);
    }
    function isContract(address _sender) constant internal returns (bool) {
        return tx.origin != _sender;
    }
    function tokensIssued() public constant returns (uint256) {
        return REAL.totalSupply();
    }
    function totalCollected() public constant returns (uint256) {
        return totalNormalCollected.add(totalGuaranteedCollected);
    }
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }
    function claimTokens(address _token) public onlyOwner {
        if (REAL.controller() == address(this)) {
            REAL.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }
    function pauseContribution() onlyOwner {
        paused = true;
    }
    function resumeContribution() onlyOwner {
        paused = false;
    }
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event NewSale(address indexed _th, uint256 _amount, uint256 _tokens, bool _guaranteed);
    event GuaranteedAddress(address indexed _th, uint256 _limit);
    event Finalized();
    event LogQuantity(uint256 _amount, string _message);
    event LogGuaranteed(address _address, uint256 _buyersLimit, uint256 _buyersBought, uint256 _buyersRemaining, string _message);
}