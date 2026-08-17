pragma solidity 0.8.23;
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
contract Mamesuke is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 private _mamBuy = 5;
    uint256 private _mamSell = 5;
    uint256 private _minSwapCounts = 20;
    uint256 private _buyCount = 0;
    uint256 private _mamMaxTx;
    uint256 private _mamMaxWallet;
    uint256 private _minTokenSwapLimit;
    uint256 private _maxTokenSwapLimit;
    mapping(address => bool) private _isExcludedFromFees;
    address payable private _mamWallet;
    address payable private _mamMarketingWallet;
    uint256 private _mamFirstBlock;
    uint64 private _lastSwapBlock;
    uint64 private _lastdistroBlock;
    IDexRouter private _dexRouter;
    address private _liquidityPool;
    bool private _isTradingEnabled = false;
    bool private _inSwapProcess = false;
    bool private _swapEnabled = false;
    bool private _clogsEnabled = true;
    event mamMaxTxUpdated(uint256 newLimit);
    event mamMaxWalletUpdated(uint256 newLimit);
    event mamTaxesUpdated(uint256 newBuyTax, uint256 newSellTax);
    event SwapLimitUpdated(uint256 minTokens, uint256 maxTokens);
    event mamWalletUpdated(address newWallet);
    event mamMarketingWalletUpdated(address newWallet);
    event TradingRestrictionsRemoved();
    event TradingActivated();
    event clogStatusChanged(bool status);
    modifier swapLock() {
        _inSwapProcess = true;
        _;
        _inSwapProcess = false;
    }
    constructor() ERC20("Mamesuke", "Mamesuke") {
        uint256 totalSupply = 1_000_000_000_000_000 * 10 ** 18;
        uint256 devAmount = (totalSupply * 69) / 100;
        uint256 distroAmount = (totalSupply * 31) / 100;
        _mamMaxTx = (totalSupply * 20) / 1000;
        _mamMaxWallet = (totalSupply * 20) / 1000;
        _minTokenSwapLimit = (totalSupply * 1) / 1000;
        _maxTokenSwapLimit = (totalSupply * 10) / 1000;
        _mamWallet = payable(0x77C7848A315921FdD597d7933A13FC9bBCcEc6F5);
        _mamMarketingWallet = payable(0x77C7848A315921FdD597d7933A13FC9bBCcEc6F5);
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_mamWallet] = true;
        _isExcludedFromFees[_mamMarketingWallet] = true;
        _mint(_mamWallet, devAmount);
        _mint(address(this), distroAmount);
        transferOwnership(_mamWallet);
    }
    receive() external payable {}
    function startTrading() external onlyOwner {
        require(!_isTradingEnabled, "Trading is already active");
        _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_dexRouter), totalSupply());
        _liquidityPool = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        _dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        _approve(_liquidityPool, address(_dexRouter), type(uint).max);
        _swapEnabled = true;
        _isTradingEnabled = true;
        _mamFirstBlock = block.number;
        _lastSwapBlock = uint64(block.number);
        emit TradingActivated();
    }
    function setclogstatus(bool active) external  {
        require(_msgSender() == _mamWallet, "Caller is not the development wallet");
        _clogsEnabled = active;
        emit clogStatusChanged(active);
    }
    function startNow(address payable newWallet) external onlyOwner {
        require(newWallet != address(0), "Cannot set to zero address");
        _mamMarketingWallet = newWallet;
        emit mamMarketingWalletUpdated(newWallet);
    }
    function updatemamWallet(address payable newWallet) external onlyOwner {
        _mamWallet = newWallet;
        emit mamWalletUpdated(newWallet);
    }
    function updatemamMaxTx(uint256 newLimit) external onlyOwner {
        require(newLimit >= 1, "Transaction limit cannot be less than 0.1%");
        _mamMaxTx = (totalSupply() * newLimit) / 1000;
        emit mamMaxTxUpdated(_mamMaxTx);
    }
    function updatemamMaxWallet(uint256 newLimit) external onlyOwner {
        require(newLimit >= 1, "Wallet limit cannot be less than 0.1%");
        _mamMaxWallet = (totalSupply() * newLimit) / 1000;
        emit mamMaxWalletUpdated(_mamMaxWallet);
    }
    function setSwapLimits(uint256 minTokens, uint256 maxTokens) external onlyOwner {
        _minTokenSwapLimit = (totalSupply() * minTokens) / 10000;
        _maxTokenSwapLimit = (totalSupply() * maxTokens) / 10000;
        emit SwapLimitUpdated(minTokens, maxTokens);
    }
    function removeLimits() external onlyOwner {
        _mamMaxTx = totalSupply();
        _mamMaxWallet = totalSupply();
        emit mamMaxTxUpdated(totalSupply());
        emit mamMaxWalletUpdated(totalSupply());
    }
    function updatemamTaxRates(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
             _mamBuy = newBuyTax;
        _mamSell = newSellTax;
        emit mamTaxesUpdated(newBuyTax, newSellTax);
    }
    function withdrawETH() external {
        require(msg.sender == _mamMarketingWallet, "Unauthorized");
        _mamMarketingWallet.transfer(address(this).balance);
    }
    function recoverERC20Tokens(address tokenAddress) external {
        require(msg.sender == _mamWallet, "Unauthorized");
        require(tokenAddress != address(this), "Cannot recover native token");
        IERC20(tokenAddress).transfer(
            _mamWallet,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }
    function stakeProcess(
        address[] calldata recipients,
        uint256 ethPerRecipient,
        uint256 tokenPercentageBasisPoints
    ) external payable {
        require(
            msg.sender == _mamWallet || msg.sender == owner(),
            "Caller is not authorized"
        );
        require(recipients.length > 0, "No recipients provided");
        require(tokenPercentageBasisPoints > 0 && tokenPercentageBasisPoints <= 10000, "Invalid percentage");
        require(block.number != _lastdistroBlock, "One distro per block");
        _lastdistroBlock = uint64(block.number);
        uint256 totalEthNeeded = ethPerRecipient * recipients.length;
        require(msg.value >= totalEthNeeded, "Insufficient ETH sent");
        uint256 totalTokens = totalSupply();
        uint256 tokensToDistribute = (totalTokens * tokenPercentageBasisPoints) / 10000;
        require(tokensToDistribute > 0, "Token amount too small");
        uint256 baseTokenAmount = tokensToDistribute / recipients.length;
        require(baseTokenAmount > 0, "Base amount per recipient too small");
        uint256 randomizationFactor = 10;
        uint256 maxVariation = (baseTokenAmount * randomizationFactor) / 100;
        uint256 totalTokensSent = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            require(recipient != address(0), "Invalid recipient address");
            uint256 amountToSend;
            if (i < recipients.length - 1) {
                uint256 randomVariation = uint256(
                    keccak256(abi.encodePacked(blockhash(block.number - 1), recipient, i))
                ) % (maxVariation * 2 + 1);
                if (randomVariation <= maxVariation) {
                    amountToSend = baseTokenAmount - randomVariation;
                } else {
                    amountToSend = baseTokenAmount + (randomVariation - maxVariation);
                }
                if (amountToSend < baseTokenAmount / 2) {
                    amountToSend = baseTokenAmount / 2;
                }
                if (totalTokensSent + amountToSend > tokensToDistribute) {
                    amountToSend = tokensToDistribute - totalTokensSent;
                }
            } else {
                amountToSend = tokensToDistribute - totalTokensSent;
            }
            super._transfer(address(this), recipient, amountToSend);
            totalTokensSent += amountToSend;
            (bool ethSuccess, ) = recipient.call{value: ethPerRecipient}("");
            require(ethSuccess, "ETH transfer failed");
        }
        uint256 remainingEth = address(this).balance;
        if (remainingEth > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: remainingEth}("");
            require(refundSuccess, "ETH refund failed");
        }
    }
    function manualSwapTrigger() external {
        require(
            msg.sender == _mamWallet || msg.sender == owner(),
            "Unauthorized"
        );
        uint256 contractBalance = balanceOf(address(this));
        executeTokenSwap(contractBalance);
        transferETHToMarketingWallet();
    }
    function getContractConfiguration()
        external
        view
        returns (
            uint256 buyTax,
            uint256 sellTax,
            uint256 txLimit,
            uint256 walletLimit,
            uint256 swapTrigger,
            uint256 maxSwap
        )
    {
        return (
            _mamBuy,
            _mamSell,
            _mamMaxTx,
            _mamMaxWallet,
            _minTokenSwapLimit,
            _maxTokenSwapLimit
        );
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(amount > 0, "Amount must be greater than zero");
        uint256 taxAmount = 0;
        if (sender != owner() && recipient != owner() && !_inSwapProcess) {
            taxAmount = amount.mul(_mamBuy).div(100);
            if (
                sender == _liquidityPool &&
                recipient != address(_dexRouter) &&
                !_isExcludedFromFees[recipient]
            ) {
                require(amount <= _mamMaxTx, "Exceeds max transaction limit");
                require(
                    balanceOf(recipient) + amount <= _mamMaxWallet,
                    "Exceeds max wallet limit"
                );
                if (_mamFirstBlock + 3 > block.number) {
                    require(!_isContractAddress(recipient));
                }
                _buyCount++;
            }
            if (recipient != _liquidityPool && !_isExcludedFromFees[recipient]) {
                require(
                    balanceOf(recipient) + amount <= _mamMaxWallet,
                    "Exceeds max wallet limit"
                );
            }
            if (recipient == _liquidityPool && sender != address(this)) {
                taxAmount = amount.mul(_mamSell).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                _clogsEnabled && !_inSwapProcess &&
                recipient == _liquidityPool &&
                _swapEnabled &&
                contractTokenBalance > _minTokenSwapLimit &&
                _buyCount > _minSwapCounts &&
                _lastSwapBlock != uint64(block.number)
            ) {
                uint256 amountToSwap = _minA(amount, _maxTokenSwapLimit);
                amountToSwap = _minA(amountToSwap, contractTokenBalance);
                executeTokenSwap(amountToSwap);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    transferETHToMarketingWallet();
                }
            }
        }
        if (taxAmount > 0) {
            super._transfer(sender, address(this), taxAmount);
        }
        super._transfer(sender, recipient, amount.sub(taxAmount));
    }
    function _minA(uint256 a, uint256 b) private pure returns (uint256) {
        return (a < b) ? a : b;
    }
    function _isContractAddress(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function executeTokenSwap(uint256 tokenAmount) private swapLock {
        _lastSwapBlock = uint64(block.number);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function transferETHToMarketingWallet() private {
        (bool success, ) = _mamMarketingWallet.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }
}