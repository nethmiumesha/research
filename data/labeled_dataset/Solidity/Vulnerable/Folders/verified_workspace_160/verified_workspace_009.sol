pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract SuperPesitoMX is ERC20, Ownable, ReentrancyGuard {
    constructor() ERC20("Super Pesito MX", "SPMX") Ownable(msg.sender) {
        _mint(msg.sender, 130000000 * 10 ** decimals());
    }
    using SafeMath for uint256;
    uint256 public constant TOTAL_SUPPLY = 130000000 * (10 ** 18);
    uint256 public buyTax = 1;
    uint256 public sellTax = 3;
    uint256 public maxBuyAmount = 0.5 * (10 ** 18);
    uint256 public cooldownPeriod = 1 days;
    uint256 public lastBuyTime;
    uint256 public liquidityFee = 5;
    bool public traded;
    bool public renounced;
    mapping(address => uint256) public lastBuyTimes;
    event TaxesUpdated(uint256 buyTax, uint256 sellTax);
    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event CooldownPeriodUpdated(uint256 cooldownPeriod);
    event LiquidityFeeUpdated(uint256 liquidityFee);
    event TradingEnabled(bool enabled);
    event OwnershipRenounced();
    modifier notTraded() {
        require(!traded, "Trading is not allowed yet");
        _;
    }
    modifier cooldown(address _buyer) {
        require(block.timestamp >= lastBuyTimes[_buyer], "Cooldown period not over");
        _;
    }
    modifier maxBuy(uint256 _amount) {
        require(_amount <= maxBuyAmount, "Maximum buy amount exceeded");
        _;
    }
    function setTraded(bool _traded) external onlyOwner notTraded {
        traded = _traded;
        emit TradingEnabled(_traded);
    }
    function setTaxes(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        require(_buyTax <= 100 && _sellTax <= 100, "Tax cannot be more than 100%");
        buyTax = _buyTax;
        sellTax = _sellTax;
        emit TaxesUpdated(_buyTax, _sellTax);
    }
    function setMaxBuyAmount(uint256 _maxBuyAmount) external onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }
    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyOwner {
        cooldownPeriod = _cooldownPeriod;
        emit CooldownPeriodUpdated(_cooldownPeriod);
    }
    function setLiquidityFee(uint256 _liquidityFee) external onlyOwner {
        require(_liquidityFee <= 100, "Liquidity fee cannot be more than 100%");
        liquidityFee = _liquidityFee;
        emit LiquidityFeeUpdated(_liquidityFee);
    }
    function renounceOwnership() public override onlyOwner {
        require(!renounced, "Ownership already renounced");
        renounced = true;
        super.renounceOwnership();
        emit OwnershipRenounced();
    }
    function burn(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        _burn(msg.sender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        super._update(from, to, amount);
        require(from != address(0) || to != address(0), "Invalid transfer");
        if (from == address(0)) {
            lastBuyTime = block.timestamp;
            lastBuyTimes[msg.sender] = block.timestamp;
        } else if (to == address(0)) {
        } else {
            require(block.timestamp >= lastBuyTimes[from] + cooldownPeriod, "Cooldown period not over");
            require(from != address(this) || to != address(this), "Cannot transfer to self");
            uint256 taxAmount;
            if (from != owner()) {
                taxAmount = amount.mul(buyTax).div(100);
                amount = amount.sub(taxAmount);
                _transfer(from, address(this), taxAmount);
            }
            if (to != owner()) {
                taxAmount = amount.mul(sellTax).div(100);
                amount = amount.sub(taxAmount);
                _transfer(to, address(this), taxAmount);
            }
            lastBuyTimes[from] = block.timestamp;
        }
    }
    function addLiquidity() external nonReentrant onlyOwner {
        uint256 tokensForLiquidity = balanceOf(address(this)).mul(liquidityFee).div(100);
        _transfer(address(this), owner(), tokensForLiquidity);
    }
}