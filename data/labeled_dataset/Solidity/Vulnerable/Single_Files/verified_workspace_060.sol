pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }
}
contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public pure virtual returns (uint8) { return 18; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner_, address spender) public view virtual override returns (uint256) {
        return _allowances[owner_][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: from zero");
        require(recipient != address(0), "ERC20: to zero");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: insufficient balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to zero");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _approve(address owner_, address spender, uint256 amount) internal virtual {
        require(owner_ != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
contract W3K is ERC20, Ownable {
    uint8 private immutable DECIMALS = 8;
    uint256 private constant INITIAL_SUPPLY = 30_000_000_000_000_000_000;
    address public  feeAddress;
    address public  usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public immutable pancakeRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    bool public tradingOpen = false;
    uint256 public  swapFeeBuy;
    uint256 public  swapFeeSell;
    mapping(address => bool) public isExcludedFromTrading;
    event TradingStatusChanged(bool enabled);
    event SwapFeesChanged(uint256 buyFee, uint256 sellFee);
    event FeeAddressChanged(address indexed oldFeeAddress, address indexed newFeeAddress);
    event PairInitialized(address indexed pair, address indexed quoteToken);
    constructor(address receiveAdd) ERC20("World30001", "W3K1") {
        require(receiveAdd != address(0), "Receive address zero");
        _mint(receiveAdd, INITIAL_SUPPLY);
    }
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from zero");
        require(recipient != address(0), "ERC20: transfer to zero");
        bool isBuy = (sender == pair);
        bool isSell = (recipient == pair);
        bool isTrade = (isBuy || isSell);
        if (isTrade && !tradingOpen) {
            require(
                isExcludedFromTrading[sender] || isExcludedFromTrading[recipient],
                "Trading not open"
            );
        }
        uint256 feeAmount = 0;
        if (isTrade) {
            uint256 fee = isBuy ? swapFeeBuy : swapFeeSell;
            if (fee > 0) {
                feeAmount = (amount * fee) / 1000;
            }
        }
        if (feeAmount > 0) {
            super._transfer(sender, feeAddress, feeAmount);
            amount -= feeAmount;
        }
        super._transfer(sender, recipient, amount);
    }
    function setSwapFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        require(buyFee <= 200 && sellFee <= 200, "Fee too high");
        swapFeeBuy = buyFee;
        swapFeeSell = sellFee;
        emit SwapFeesChanged(buyFee, sellFee);
    }
    function setFeeAddress(address newFeeAddress) external onlyOwner {
        require(newFeeAddress != address(0), "Fee address zero");
        address oldFeeAddress = feeAddress;
        feeAddress = newFeeAddress;
        emit FeeAddressChanged(oldFeeAddress, newFeeAddress);
    }
    function initPair() external onlyOwner {
        require(pair == address(0), "Pair already initialized");
        IUniswapV2Router02 router = IUniswapV2Router02(pancakeRouter);
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), usdt);
        emit PairInitialized(pair, usdt);
    }
    function setTradingOpen(bool enabled) external onlyOwner {
        tradingOpen = enabled;
        emit TradingStatusChanged(enabled);
    }
    function setExcludedFromTrading(address account, bool excluded) external onlyOwner {
        isExcludedFromTrading[account] = excluded;
    }
    function isWhitelisted(address account) external view returns (bool) {
        return isExcludedFromTrading[account];
    }
}