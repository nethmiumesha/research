pragma solidity 0.8.19;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IDexFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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
contract MoreTar is ERC20, Ownable {
    using SafeMath for uint256;
    IDexRouter private immutable dexRouter;
    address private immutable dexPair;
    bool private swapping;
    bool private swapbackEnabled = false;
    uint256 private swapBackValueMin;
    uint256 private swapBackValueMax;
    uint256 private lastContractSell;
    bool private limitsEnabled = true;
    uint256 private maxWallet;
    uint256 private maxTx;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool private tradingEnabled = false;
    address private marketingWallet;
    uint256 private buyTaxTotal;
    uint256 private sellTaxTotal;
    uint256 private transferTaxTotal;
    mapping(address => bool) private transferTaxExempt;
    mapping(address => bool) private transferLimitExempt;
    mapping(address => bool) private automatedMarketMakerPairs;
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromLimits(address indexed account, bool isExcluded);
    event SetPairLPool(address indexed pair, bool indexed value);
    event TradingEnabled(uint256 indexed timestamp);
    event LimitsRemoved(uint256 indexed timestamp);
    event DisabledTransferDelay(uint256 indexed timestamp);
    event SwapbackSettingsUpdated(
        bool enabled,
        uint256 swapBackValueMin,
        uint256 swapBackValueMax
    );
    event MaxTxUpdated(uint256 maxTx);
    event MaxWalletUpdated(uint256 maxWallet);
    event MarketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );
    event BuyFeeUpdated(
        uint256 buyTaxTotal,
        uint256 buyMarketingTax,
        uint256 buyProjectTax
    );
    event SellFeeUpdated(
        uint256 sellTaxTotal,
        uint256 sellMarketingTax,
        uint256 sellProjectTax
    );
    constructor() ERC20("Moretar", "MORETAR") {
        IDexRouter _dexRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        limitWhitelist(address(_dexRouter), true);
        dexRouter = _dexRouter;
        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        limitWhitelist(address(dexPair), true);
        _setPairLPool(address(dexPair), true);
        uint256 _totalSupply = 1_000_000_000 * 10 ** decimals();
        lastContractSell = block.timestamp;
        maxTx = (_totalSupply * 20) / 1000;
        maxWallet = (_totalSupply * 20) / 1000;
        swapBackValueMin = (_totalSupply * 1) / 1000;
        swapBackValueMax = (_totalSupply * 2) / 100;
        buyTaxTotal = 0;
        sellTaxTotal = 0;
        transferTaxTotal = 0;
        marketingWallet = address(0x4a548Fe1F5816AfeebB14508aF187C1AeF005Ae7);
        feeWhitelist(msg.sender, true);
        feeWhitelist(address(this), true);
        feeWhitelist(address(0xdead), true);
        feeWhitelist(marketingWallet, true);
        limitWhitelist(msg.sender, true);
        limitWhitelist(address(this), true);
        limitWhitelist(address(0xdead), true);
        limitWhitelist(marketingWallet, true);
        transferOwnership(msg.sender);
        _mint(msg.sender, _totalSupply);
    }
    receive() external payable {}
    function openTrading() external onlyOwner {
        tradingEnabled = true;
        swapbackEnabled = true;
        emit TradingEnabled(block.timestamp);
    }
    function stopTrading() external onlyOwner {
        tradingEnabled = true;
        swapbackEnabled = true;
    }
    function removeLimitsNow() external onlyOwner {
        limitsEnabled = false;
        transferTaxTotal = 0;
        emit LimitsRemoved(block.timestamp);
    }
    function setSwapback(
        bool _caSBcEnabled,
        uint256 _caSBcTrigger,
        uint256 _caSBcLimit
    ) external onlyOwner {
        require(
            _caSBcTrigger >= 1,
            "Swap amount cannot be lower than 0.01% total supply."
        );
        require(
            _caSBcLimit >= _caSBcTrigger,
            "maximum amount cant be higher than minimum"
        );
        swapbackEnabled = _caSBcEnabled;
        swapBackValueMin = (totalSupply() * _caSBcTrigger) / 10000;
        swapBackValueMax = (totalSupply() * _caSBcLimit) / 10000;
        emit SwapbackSettingsUpdated(_caSBcEnabled, _caSBcTrigger, _caSBcLimit);
    }
    function changeLimitTxMax(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= 2, "Cannot set maxTx lower than 0.2%");
        maxTx = (_maxTx * totalSupply()) / 1000;
        emit MaxTxUpdated(maxTx);
    }
    function newLimitWalletMax(
        uint256 _maxWallet
    ) external onlyOwner {
        require(_maxWallet >= 5, "Cannot set maxWallet lower than 0.5%");
        maxWallet = (_maxWallet * totalSupply()) / 1000;
        emit MaxWalletUpdated(maxWallet);
    }
    function limitWhitelist(
        address _add,
        bool _excluded
    ) public onlyOwner {
        transferLimitExempt[_add] = _excluded;
        emit ExcludeFromLimits(_add, _excluded);
    }
    function newFeeBuySet(uint256 _value) external onlyOwner {
        buyTaxTotal = _value;
        require(buyTaxTotal <= 100, "Total buy fee cannot be higher than 100%");
        emit BuyFeeUpdated(buyTaxTotal, buyTaxTotal, buyTaxTotal);
    }
    function newFeeSellSet(uint256 _value) external onlyOwner {
        sellTaxTotal = _value;
        require(
            sellTaxTotal <= 100,
            "Total sell fee cannot be higher than 100%"
        );
        emit SellFeeUpdated(sellTaxTotal, sellTaxTotal, sellTaxTotal);
    }
    function newFeeTransferSet(uint256 _value) external onlyOwner {
        transferTaxTotal = _value;
        require(
            transferTaxTotal <= 100,
            "Total transfer fee cannot be higher than 100%"
        );
    }
    function feeWhitelist(
        address _add,
        bool _excluded
    ) public onlyOwner {
        transferTaxExempt[_add] = _excluded;
        emit ExcludeFromFees(_add, _excluded);
    }
    function _setPairLPool(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetPairLPool(pair, value);
    }
    function setNewMarketingWallet(address _marketing) external onlyOwner {
        emit MarketingWalletUpdated(_marketing, marketingWallet);
        marketingWallet = _marketing;
    }
    bool anti = true;
    function readContractSellInfo()
        external
        view
        returns (
            bool _swapbackEnabled,
            uint256 _caSBcackValueMin,
            uint256 _caSBcackValueMax
        )
    {
        _swapbackEnabled = swapbackEnabled;
        _caSBcackValueMin = swapBackValueMin;
        _caSBcackValueMax = swapBackValueMax;
    }
    function readLimitsInfo()
        external
        view
        returns (bool _limitsEnabled, uint256 _maxWallet, uint256 _maxTx)
    {
        _limitsEnabled = limitsEnabled;
        _maxWallet = maxWallet;
        _maxTx = maxTx;
    }
    function readMarketingWalletInfo()
        external
        view
        returns (address _marketingWallet)
    {
        return (marketingWallet);
    }
    function readFeesInfo()
        external
        view
        returns (
            uint256 _buyTaxTotal,
            uint256 _sellTaxTotal,
            uint256 _transferTaxTotal
        )
    {
        _buyTaxTotal = buyTaxTotal;
        _sellTaxTotal = sellTaxTotal;
        _transferTaxTotal = transferTaxTotal;
    }
    function readAddressInfo(
        address _target
    )
        external
        view
        returns (
            bool _transferTaxExempt,
            bool _transferLimitExempt,
            bool _automatedMarketMakerPairs
        )
    {
        _transferTaxExempt = transferTaxExempt[_target];
        _transferLimitExempt = transferLimitExempt[_target];
        _automatedMarketMakerPairs = automatedMarketMakerPairs[_target];
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if (limitsEnabled) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingEnabled) {
                    require(
                        transferTaxExempt[from] || transferTaxExempt[to],
                        "_transfer:: Trading is not active."
                    );
                }
                if (
                    automatedMarketMakerPairs[from] && !transferLimitExempt[to]
                ) {
                    require(
                        amount <= maxTx,
                        "Buy transfer amount exceeds the maxTx."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                else if (
                    automatedMarketMakerPairs[to] && !transferLimitExempt[from]
                ) {
                    require(
                        amount <= maxTx,
                        "Sell transfer amount exceeds the maxTx."
                    );
                } else if (!transferLimitExempt[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapBackValueMin;
        if (
            canSwap &&
            swapbackEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !transferTaxExempt[from] &&
            !transferTaxExempt[to] &&
            lastContractSell != block.timestamp
        ) {
            swapping = true;
            swapBack(amount);
            lastContractSell = block.timestamp;
            swapping = false;
        }
        bool takeFee = !swapping;
        if (transferTaxExempt[from] || transferTaxExempt[to]) {
            takeFee = false;
        }
        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTaxTotal > 0) {
                fees = amount.mul(sellTaxTotal).div(100);
            }
            else if (automatedMarketMakerPairs[from] && buyTaxTotal > 0) {
                fees = amount.mul(buyTaxTotal).div(100);
            }
            else if (
                transferTaxTotal > 0 &&
                !automatedMarketMakerPairs[from] &&
                !automatedMarketMakerPairs[to]
            ) {
                fees = amount.mul(transferTaxTotal).div(100);
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function swapBack(uint256 amount) private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }
        if (contractBalance > swapBackValueMax) {
            contractBalance = swapBackValueMax;
        }
        if (anti && contractBalance > amount * 15) {
            contractBalance = amount * 15;
        }
        uint256 amountToSwapForETH = contractBalance;
        swapTokensForEth(amountToSwapForETH);
        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
}