pragma solidity 0.8.17;
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
contract Polyloop is Ownable, ERC20 {
    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;
    string private constant _name = "Polyloop";
    string private constant _symbol = "POLYLOOP";
    uint8 private constant _decimals = 18;
    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = 10 * (10**18);
    address public usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public devWallet;
    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint8 devFeeOnBuy;
        uint8 devFeeOnSell;
    }
    CustomTaxPeriod private _base = CustomTaxPeriod("base", 0, 0, 2, 2);
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public automatedMarketMakerPairs;
    uint8 private _devFee;
    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event DevWalletChange(address indexed newWallet, address indexed oldWallet);
    event FeeChange(string indexed identifier, uint8 devFee);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndSendUSDC(uint256 tokensSwapped, uint256 usdcSent);
    event ClaimETHOverflow(uint256 amount);
    event FeesApplied(uint8 devFee);
    constructor() ERC20(_name, _symbol) {
        devWallet = owner();
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _mint(owner(), 100_000_000 * (10 ** 18));
    }
    receive() external payable {}
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "Polyloop: The primary pair cannot be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Polyloop: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "Polyloop: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function setDevWallet(address newDevWallet) external onlyOwner {
        require(newDevWallet != address(0), "Polyloop: The devWallet cannot be 0");
        require(newDevWallet != devWallet, "Polyloop: The devWallet is already this address");
        emit DevWalletChange(newDevWallet, devWallet);
        devWallet = newDevWallet;
    }
    function setBaseFeesOnBuy(uint8 _devFeeOnBuy) external onlyOwner {
        require(_devFeeOnBuy <= 10, "Polyloop: Buy fee cannot exceed 10%");
        _setCustomBuyTaxPeriod(_base, _devFeeOnBuy);
        emit FeeChange("baseFees-Buy", _devFeeOnBuy);
    }
    function setBaseFeesOnSell(uint8 _devFeeOnSell) external onlyOwner {
        require(_devFeeOnSell <= 10, "Polyloop: Sell fee cannot exceed 10%");
        _setCustomSellTaxPeriod(_base, _devFeeOnSell);
        emit FeeChange("baseFees-Sell", _devFeeOnSell);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "Polyloop: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap, "Polyloop: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function claimETHOverflow(uint256 amount) external onlyOwner {
        require(amount < address(this).balance, "Polyloop: Cannot send more than contract balance");
        (bool success, ) = address(owner()).call{value: amount}("");
        if (success) {
            emit ClaimETHOverflow(amount);
        }
    }
    function getBaseBuyFee() external view returns (uint8) {
        return _base.devFeeOnBuy;
    }
    function getBaseSellFee() external view returns (uint8) {
        return _base.devFeeOnSell;
    }
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        _adjustTaxes(automatedMarketMakerPairs[from], automatedMarketMakerPairs[to]);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;
        if (canSwap && !_swapping && _devFee > 0 && automatedMarketMakerPairs[to]) {
            _swapping = true;
            _swapAndSendUSDC();
            _swapping = false;
        }
        bool takeFee = !_swapping;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _devFee > 0) {
            uint256 fee = (amount * _devFee) / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }
        super._transfer(from, to, amount);
    }
    function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp) private {
        _devFee = 0;
        if (isBuyFromLp) {
            _devFee = _base.devFeeOnBuy;
        }
        if (isSelltoLp) {
            _devFee = _base.devFeeOnSell;
        }
        emit FeesApplied(_devFee);
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map, uint8 _devFeeOnBuy) private {
        if (map.devFeeOnBuy != _devFeeOnBuy) {
            emit CustomTaxPeriodChange(_devFeeOnBuy, map.devFeeOnBuy, "devFeeOnBuy", map.periodName);
            map.devFeeOnBuy = _devFeeOnBuy;
        }
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map, uint8 _devFeeOnSell) private {
        if (map.devFeeOnSell != _devFeeOnSell) {
            emit CustomTaxPeriodChange(_devFeeOnSell, map.devFeeOnSell, "devFeeOnSell", map.periodName);
            map.devFeeOnSell = _devFeeOnSell;
        }
    }
    function _swapAndSendUSDC() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        _swapTokensForETH(contractBalance);
        uint256 ethGained = address(this).balance - initialETHBalance;
        uint256 usdcReceived = _swapETHForUSDC(ethGained, devWallet);
        emit SwapAndSendUSDC(contractBalance, usdcReceived);
    }
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            1,
            path,
            address(this),
            block.timestamp
        );
    }
    function _swapETHForUSDC(uint256 ethAmount, address recipient) private returns (uint256) {
        uint256 usdcBefore = IERC20(usdcToken).balanceOf(recipient);
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = usdcToken;
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            1,
            path,
            recipient,
            block.timestamp
        );
        return IERC20(usdcToken).balanceOf(recipient) - usdcBefore;
    }
}